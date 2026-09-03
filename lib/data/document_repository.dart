import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:elapsa/data/database.dart';
import 'package:elapsa/domain/document.dart' as domain;
import 'package:elapsa/domain/document_detail.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/services/document_image_store.dart';
import 'package:elapsa/services/document_archive.dart';
import 'package:elapsa/services/notification_service.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/services/secure_store.dart';

const _uuid = Uuid();

/// Reads and writes documents, and keeps the scheduled reminders in step.
///
/// Every mutation reschedules the full notification set. That sounds heavy but
/// it is a handful of rows and it is the only way to respect the iOS pending
/// limit correctly — see [NotificationService.rescheduleAll].
class DocumentRepository {
  DocumentRepository(this._db, this._notifications, this._images, this._l);

  final AppDatabase _db;
  final NotificationService _notifications;
  final DocumentImageStore _images;
  final L _l;

  Stream<List<domain.TrackedDocument>> watchAll() =>
      _db.watchAll().map((rows) => rows.map(_toDomain).toList());

  Future<List<domain.TrackedDocument>> getAll() async =>
      (await _db.getAll()).map(_toDomain).toList();

  Future<domain.TrackedDocument> create({
    required DocumentType type,
    required String label,
    required DateTime expiryDate,
    int? renewalLeadDays,
    String? holder,
    String? documentNumber,
    String? issuingCountry,
    DateTime? issueDate,
    Map<DocumentDetail, String> details = const {},
    List<int>? reminderOffsets,

    /// Pictures from a scan, already flattened. Encrypted into the app's own
    /// storage before anything is written to the database.
    List<Uint8List> images = const [],
    String? customType,
    String? scanText,
    Map<String, String> extras = const {},
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final imagePath = await _images.saveAll(id, images);

    final doc = domain.TrackedDocument(
      id: id,
      type: type,
      label: label,
      expiryDate: expiryDate,
      renewalLeadDays: renewalLeadDays ?? type.defaultRenewalLeadDays,
      holder: holder,
      documentNumber: documentNumber,
      issuingCountry: issuingCountry,
      issueDate: issueDate,
      imagePath: imagePath,
      imageCount: images.length,
      details: details,
      reminderOffsets: reminderOffsets,
      customType: customType,
      scanText: scanText,
      extras: extras,
      createdAt: now,
      updatedAt: now,
    );
    await save(doc);
    return doc;
  }

  Future<void> save(domain.TrackedDocument doc) async {
    await _db.upsert(_toCompanion(doc));
    await _resync();
  }

  Future<void> delete(String id) async {
    await _db.deleteById(id);
    // The encrypted scans go with the record. Leaving an orphaned image of
    // someone's passport behind after they deleted it would be indefensible.
    await _images.deleteAll(id);
    await _resync();
  }

  /// Replaces every picture on a document with the given set, in order.
  ///
  /// Used when the editor has the whole set in hand — which it does whenever
  /// a document is opened — so reordering, deleting and adding are all just
  /// this one operation.
  Future<void> setImages(
    domain.TrackedDocument doc,
    List<Uint8List> images,
  ) async {
    final path = await _images.saveAll(doc.id, images);
    await save(doc.copyWith(imagePath: path, imageCount: images.length));
  }

  /// The chosen documents, pictures included, ready to be written to a file.
  ///
  /// Takes ids rather than documents so the pictures — the expensive part, and
  /// the part that has to be decrypted one file at a time — are only loaded
  /// for what is actually being sent.
  Future<List<ArchivedDocument>> exportDocuments(
    Set<String> ids, {
    List<CustomType> knownTypes = const [],
  }) async {
    final byName = {for (final type in knownTypes) type.name: type};
    final documents = await getAll();

    return [
      for (final doc in documents)
        if (ids.contains(doc.id))
          ArchivedDocument(
            doc,
            await _images.loadAll(doc.id, doc.imageCount),
            // Sent with the document, not looked up at the far end.
            customType: byName[doc.customType],
          ),
    ];
  }

  /// Writes archived documents back in.
  ///
  /// Identity is kept, so importing the same archive twice updates the same
  /// records instead of doubling them — which is what makes this safe to run
  /// when you are not quite sure whether the last attempt worked.
  ///
  /// [replace] clears what is here first. The default merges, because merging
  /// is the recoverable mistake: an unwanted document can be deleted one at a
  /// time, while a wrongly replaced library is gone.
  Future<int> importAll(
    List<ArchivedDocument> archived, {
    bool replace = false,
  }) async {
    if (replace) {
      for (final existing in await getAll()) {
        await _db.deleteById(existing.id);
        await _images.deleteAll(existing.id);
      }
    }

    for (final entry in archived) {
      final path = await _images.saveAll(entry.document.id, entry.images);
      await _db.upsert(
        _toCompanion(
          entry.document.copyWith(
            imagePath: path,
            imageCount: entry.images.length,
          ),
        ),
      );
    }

    await _resync();
    return archived.length;
  }

  /// Rebuilds the scheduled reminders from what is currently stored.
  ///
  /// Worth doing on every app resume, not just on edit: it picks up permission
  /// the user granted in Settings after first declining, and it refreshes the
  /// rolling window of pending notifications as older ones fire and fall off.
  Future<void> resync() => _resync();

  Future<void> _resync() async =>
      _notifications.rescheduleAll(await getAll(), _l);

  /// Reads the user's own fields back, dropping anything malformed rather
  /// than letting one bad record take the whole list down with it.
  static Map<String, String> _decodeExtras(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      final raw = jsonDecode(json);
      if (raw is! Map) return const {};
      return {
        for (final entry in raw.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    } catch (_) {
      return const {};
    }
  }

  static domain.TrackedDocument _toDomain(Document row) {
    return domain.TrackedDocument(
      id: row.id,
      type: row.type,
      label: row.label,
      holder: row.holder,
      documentNumber: row.documentNumber,
      issuingCountry: row.issuingCountry,
      issueDate: row.issueDate,
      expiryDate: row.expiryDate,
      renewalLeadDays: row.renewalLeadDays,
      imagePath: row.imagePath,
      imageCount: row.imageCount,
      details: domain.DocumentDetails.decode(row.details),
      reminderOffsets: _decodeOffsets(row.reminderOffsets),
      customType: row.typeName,
      scanText: row.scanText,
      extras: _decodeExtras(row.extras),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Parses the stored comma-separated offsets, ignoring anything that is not
  /// a positive whole number of days.
  static List<int>? _decodeOffsets(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    final days = stored
        .split(',')
        .map((part) => int.tryParse(part.trim()))
        .whereType<int>()
        .where((d) => d > 0)
        .toList();
    return days.isEmpty ? null : days;
  }

  static DocumentsCompanion _toCompanion(domain.TrackedDocument doc) {
    return DocumentsCompanion(
      id: Value(doc.id),
      type: Value(doc.type),
      label: Value(doc.label),
      holder: Value(doc.holder),
      documentNumber: Value(doc.documentNumber),
      issuingCountry: Value(doc.issuingCountry),
      issueDate: Value(doc.issueDate),
      expiryDate: Value(doc.expiryDate),
      renewalLeadDays: Value(doc.renewalLeadDays),
      imagePath: Value(doc.imagePath),
      imageCount: Value(doc.imageCount),
      details: Value(domain.DocumentDetails.encode(doc.details)),
      typeName: Value(doc.customType),
      scanText: Value(doc.scanText),
      extras: Value(doc.extras.isEmpty ? null : jsonEncode(doc.extras)),
      reminderOffsets: Value(
        doc.hasChosenReminders ? doc.reminderOffsetDays.join(',') : null,
      ),
      createdAt: Value(doc.createdAt),
      updatedAt: Value(doc.updatedAt),
    );
  }
}

// ------------------------------------------------------------------ providers

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final documentImageStoreProvider = Provider<DocumentImageStore>((ref) {
  return DocumentImageStore(ref.watch(secureStoreProvider));
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(ref.watch(secureStoreProvider));
  ref.onDispose(db.close);
  return db;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(documentImageStoreProvider),
    lookupL(ref.watch(activeLocaleProvider)),
  );
});

/// The locale the app is actually running in — the user's explicit choice, or
/// the device's if they have not made one.
final activeLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(languageProvider).locale ??
      _firstSupported(PlatformDispatcher.instance.locales);
});

Locale _firstSupported(List<Locale> candidates) {
  for (final candidate in candidates) {
    for (final supported in L.supportedLocales) {
      if (supported.languageCode == candidate.languageCode) return candidate;
    }
  }
  return const Locale('en');
}

final documentsProvider = StreamProvider<List<domain.TrackedDocument>>((ref) {
  return ref.watch(documentRepositoryProvider).watchAll();
});
