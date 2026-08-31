import 'dart:convert';

import 'package:elapsa/domain/document_detail.dart';
import 'package:elapsa/domain/document_type.dart';

/// How urgently a document needs attention.
enum DocumentStatus {
  /// Past its expiry date.
  expired,

  /// Expiring within a month. Whatever the renewal takes, it is late.
  critical,

  /// Inside the window where renewal should already have started.
  actionNeeded,

  /// Nothing to do yet.
  valid,
}

/// Most destinations require a passport to remain valid for six months beyond
/// the date of entry, so a passport stops being useful well before it expires.
const kSixMonthRuleDays = 183;

/// A tracked document. Immutable; edits go through [copyWith].
class TrackedDocument {
  final String id;
  final DocumentType type;

  /// What the user calls it — "My passport", "Mum's residence permit".
  final String label;

  /// Which family member it belongs to. Null means the account owner.
  final String? holder;

  final String? documentNumber;
  final String? issuingCountry;
  final DateTime? issueDate;
  final DateTime expiryDate;

  /// Days before expiry at which renewal should begin. Defaults from the
  /// document type but the user can override — processing times differ by
  /// country, and they know their own situation better than we do.
  ///
  /// Always the earliest of [reminderOffsetDays]: the first nudge is the one
  /// that says "start now", and the status on the list follows it.
  final int renewalLeadDays;

  /// The user's chosen reminder times, in days before expiry.
  ///
  /// Null means they never chose, and the conventional set below is used.
  final List<int>? _chosenOffsets;

  /// Relative path to the first encrypted scan, if one was captured.
  final String? imagePath;

  /// How many pictures this document has — a card has two sides, and some
  /// documents run to several pages.
  final int imageCount;

  /// The type-specific fields the user filled in: a security code on a bank
  /// card, a plate number on a vehicle registration.
  final Map<DocumentDetail, String> details;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TrackedDocument({
    required this.id,
    required this.type,
    required this.label,
    required this.expiryDate,
    required this.renewalLeadDays,
    required this.createdAt,
    required this.updatedAt,
    this.holder,
    this.documentNumber,
    this.issuingCountry,
    this.issueDate,
    this.imagePath,
    this.imageCount = 0,
    this.details = const {},
    List<int>? reminderOffsets,
  }) : _chosenOffsets = reminderOffsets;

  /// Days until expiry, measured in whole calendar days from today.
  ///
  /// Calendar days rather than elapsed hours: a document expiring tomorrow
  /// should read "1 day" all day today, not flip to 0 after lunch.
  int daysRemaining({DateTime? now}) {
    final today = _startOfDay(now ?? DateTime.now());
    final expiry = _startOfDay(expiryDate);
    return expiry.difference(today).inDays;
  }

  DocumentStatus status({DateTime? now}) {
    final days = daysRemaining(now: now);
    if (days < 0) return DocumentStatus.expired;
    if (days <= 30) return DocumentStatus.critical;
    if (days <= renewalLeadDays) return DocumentStatus.actionNeeded;
    return DocumentStatus.valid;
  }

  /// The date this document stops being accepted for international travel.
  ///
  /// Null for types the six-month rule does not apply to. For a passport this
  /// is six months before the printed expiry — the date that actually matters
  /// when booking a trip.
  DateTime? get travelValidUntil {
    if (!type.hasSixMonthTravelRule) return null;
    return expiryDate.subtract(const Duration(days: kSixMonthRuleDays));
  }

  /// True when the document is still valid on paper but can no longer be used
  /// to enter countries that enforce the six-month rule.
  bool isTravelRestricted({DateTime? now}) {
    final cutoff = travelValidUntil;
    if (cutoff == null) return false;
    final today = _startOfDay(now ?? DateTime.now());
    return !today.isBefore(_startOfDay(cutoff)) &&
        daysRemaining(now: now) >= 0;
  }

  /// Days before expiry at which to fire reminders, longest first.
  ///
  /// Whatever the user picked, or a conventional set when they picked nothing:
  /// the renewal lead time itself, then a tail so they are nudged again as the
  /// date closes in.
  List<int> get reminderOffsetDays {
    final chosen = _chosenOffsets;
    if (chosen != null && chosen.isNotEmpty) {
      return chosen.toSet().toList()..sort((a, b) => b.compareTo(a));
    }
    return <int>{renewalLeadDays, 90, 30, 7, 1}
        .where((d) => d > 0 && d <= renewalLeadDays)
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  /// True when the user chose these times rather than taking the default.
  bool get hasChosenReminders =>
      _chosenOffsets != null && _chosenOffsets.isNotEmpty;

  /// Concrete dates on which to notify, discarding any already in the past.
  List<DateTime> reminderDates({DateTime? now}) {
    final today = _startOfDay(now ?? DateTime.now());
    return reminderOffsetDays
        .map((d) => _startOfDay(expiryDate).subtract(Duration(days: d)))
        .where((d) => d.isAfter(today))
        .toList();
  }

  TrackedDocument copyWith({
    DocumentType? type,
    String? label,
    String? holder,
    String? documentNumber,
    String? issuingCountry,
    DateTime? issueDate,
    DateTime? expiryDate,
    int? renewalLeadDays,
    String? imagePath,
    int? imageCount,
    Map<DocumentDetail, String>? details,
    List<int>? reminderOffsets,
    DateTime? updatedAt,
  }) {
    return TrackedDocument(
      id: id,
      type: type ?? this.type,
      label: label ?? this.label,
      holder: holder ?? this.holder,
      documentNumber: documentNumber ?? this.documentNumber,
      issuingCountry: issuingCountry ?? this.issuingCountry,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      renewalLeadDays: renewalLeadDays ?? this.renewalLeadDays,
      imagePath: imagePath ?? this.imagePath,
      imageCount: imageCount ?? this.imageCount,
      details: details ?? this.details,
      reminderOffsets: reminderOffsets ?? _chosenOffsets,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Reads and writes the detail map as JSON for storage.
///
/// Unknown keys are dropped rather than carried: they can only come from a
/// newer build, and silently keeping a field the app no longer understands is
/// how stale data outlives the code that made sense of it.
class DocumentDetails {
  const DocumentDetails._();

  static Map<DocumentDetail, String> decode(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      final raw = jsonDecode(json);
      if (raw is! Map) return const {};
      return {
        for (final detail in DocumentDetail.values)
          if (raw[detail.name] is String && (raw[detail.name] as String).isNotEmpty)
            detail: raw[detail.name] as String,
      };
    } on FormatException {
      return const {};
    }
  }

  static String? encode(Map<DocumentDetail, String> details) {
    final populated = {
      for (final entry in details.entries)
        if (entry.value.trim().isNotEmpty) entry.key.name: entry.value.trim(),
    };
    return populated.isEmpty ? null : jsonEncode(populated);
  }
}

/// Orders documents by urgency: expired first, then soonest to expire.
int byUrgency(TrackedDocument a, TrackedDocument b) =>
    a.expiryDate.compareTo(b.expiryDate);
