import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_detail.dart';
import 'package:elapsa/domain/document_type.dart';

/// The passphrase was wrong, or the file is not what it says it is.
class ArchiveException implements Exception {
  const ArchiveException(this.reason);

  final ArchiveFailure reason;

  @override
  String toString() => 'ArchiveException(${reason.name})';
}

enum ArchiveFailure {
  /// Not an Elapsa archive at all.
  notAnArchive,

  /// Written by a newer version of the app than this one.
  tooNew,

  /// The passphrase does not open it, or the file has been altered since.
  ///
  /// These are one failure, not two: the authentication tag cannot tell a
  /// wrong key from tampered bytes, and it would be a poor idea if it could.
  cannotOpen,
}

/// One document as it travels, pictures and all.
class ArchivedDocument {
  final TrackedDocument document;
  final List<Uint8List> images;

  const ArchivedDocument(this.document, this.images);
}

/// Every document in one encrypted file.
///
/// Elapsa keeps everything on the device and nothing on a server, which is the
/// point of it — and which means a lost phone is a lost passport record, and
/// moving to a new phone has until now meant photographing everything again.
/// An archive is the answer to both.
///
/// It is encrypted with a passphrase the user chooses rather than with the
/// device key, for the obvious reason: a file sealed with a key that never
/// leaves this phone's Keychain cannot be opened on the next phone, which is
/// the only thing anyone wants to do with it.
class DocumentArchive {
  const DocumentArchive();

  static const _magic = 'elapsa.archive';

  /// Bumped only for a change this reader cannot handle. A file from a newer
  /// version is refused by name rather than misread.
  static const _version = 1;

  /// PBKDF2 is not the strongest choice available — Argon2 is — but it is the
  /// one this app already has, and the number of rounds is what actually
  /// decides how long a weak passphrase survives. This costs about a second on
  /// a modern phone, which is a second the user pays once per transfer and an
  /// attacker pays for every guess.
  static const _rounds = 210000;

  static final _cipher = AesGcm.with256bits();

  /// Packs [documents] into a single encrypted file.
  Future<Uint8List> pack(
    List<ArchivedDocument> documents, {
    required String passphrase,
  }) async {
    final salt = _randomBytes(16);
    final key = await _deriveKey(passphrase, salt);

    final payload = utf8.encode(
      jsonEncode({
        'exported': DateTime.now().toIso8601String(),
        'documents': [for (final entry in documents) _encodeDocument(entry)],
      }),
    );

    final box = await _cipher.encrypt(payload, secretKey: key);

    // The envelope is plain JSON on purpose. Anyone finding this file years
    // from now can see what it is and what it would take to open it, without
    // having to have kept a copy of this app.
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': _magic,
          'version': _version,
          'kdf': {
            'name': 'pbkdf2-hmac-sha256',
            'rounds': _rounds,
            'salt': base64Encode(salt),
          },
          'cipher': 'aes-256-gcm',
          'nonce': base64Encode(box.nonce),
          'mac': base64Encode(box.mac.bytes),
          'body': base64Encode(box.cipherText),
        }),
      ),
    );
  }

  /// Opens a file produced by [pack].
  ///
  /// Throws [ArchiveException] rather than returning null, because every way
  /// this fails is something the user needs told about in different words.
  Future<List<ArchivedDocument>> unpack(
    Uint8List file, {
    required String passphrase,
  }) async {
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
    } catch (_) {
      throw const ArchiveException(ArchiveFailure.notAnArchive);
    }

    if (envelope['format'] != _magic) {
      throw const ArchiveException(ArchiveFailure.notAnArchive);
    }
    if ((envelope['version'] as num?) != null &&
        (envelope['version'] as num) > _version) {
      throw const ArchiveException(ArchiveFailure.tooNew);
    }

    final Uint8List plain;
    try {
      final kdf = envelope['kdf'] as Map<String, dynamic>;
      final key = await _deriveKey(
        passphrase,
        base64Decode(kdf['salt'] as String),
        rounds: (kdf['rounds'] as num?)?.toInt() ?? _rounds,
      );

      plain = Uint8List.fromList(
        await _cipher.decrypt(
          SecretBox(
            base64Decode(envelope['body'] as String),
            nonce: base64Decode(envelope['nonce'] as String),
            mac: Mac(base64Decode(envelope['mac'] as String)),
          ),
          secretKey: key,
        ),
      );
    } catch (_) {
      throw const ArchiveException(ArchiveFailure.cannotOpen);
    }

    try {
      final body = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      return [
        for (final raw in body['documents'] as List)
          _decodeDocument(raw as Map<String, dynamic>),
      ];
    } catch (_) {
      // Decryption succeeded, so the passphrase was right and the file is
      // intact; it is the contents that make no sense.
      throw const ArchiveException(ArchiveFailure.notAnArchive);
    }
  }

  static Map<String, dynamic> _encodeDocument(ArchivedDocument entry) {
    final doc = entry.document;
    return {
      'id': doc.id,
      'type': doc.type.name,
      'label': doc.label,
      'holder': doc.holder,
      'documentNumber': doc.documentNumber,
      'issuingCountry': doc.issuingCountry,
      'issueDate': doc.issueDate?.toIso8601String(),
      'expiryDate': doc.expiryDate.toIso8601String(),
      'renewalLeadDays': doc.renewalLeadDays,
      // The chosen set only, not the conventional fallback: an archive should
      // carry the user's decisions, and let the app of the day supply its own
      // defaults for everything they never decided.
      'reminderOffsets': doc.hasChosenReminders ? doc.reminderOffsetDays : null,
      'details': {
        for (final entry in doc.details.entries) entry.key.name: entry.value,
      },
      'createdAt': doc.createdAt.toIso8601String(),
      'updatedAt': doc.updatedAt.toIso8601String(),
      'images': [for (final image in entry.images) base64Encode(image)],
    };
  }

  static ArchivedDocument _decodeDocument(Map<String, dynamic> raw) {
    final images = [
      for (final image in (raw['images'] as List? ?? const []))
        base64Decode(image as String),
    ];

    return ArchivedDocument(
      TrackedDocument(
        id: raw['id'] as String,
        type: DocumentType.values.firstWhere(
          (t) => t.name == raw['type'],
          orElse: () => DocumentType.other,
        ),
        label: raw['label'] as String,
        holder: raw['holder'] as String?,
        documentNumber: raw['documentNumber'] as String?,
        issuingCountry: raw['issuingCountry'] as String?,
        issueDate: _date(raw['issueDate']),
        expiryDate: _date(raw['expiryDate'])!,
        renewalLeadDays: (raw['renewalLeadDays'] as num).toInt(),
        reminderOffsets: (raw['reminderOffsets'] as List?)
            ?.map((d) => (d as num).toInt())
            .toList(),
        details: {
          for (final entry in (raw['details'] as Map? ?? const {}).entries)
            for (final detail in DocumentDetail.values)
              if (detail.name == entry.key) detail: entry.value as String,
        },
        imageCount: images.length,
        createdAt: _date(raw['createdAt']) ?? DateTime.now(),
        updatedAt: _date(raw['updatedAt']) ?? DateTime.now(),
      ),
      images,
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt, {
    int rounds = _rounds,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: rounds,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
