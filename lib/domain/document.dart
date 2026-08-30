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
  final int renewalLeadDays;

  /// Relative path to the encrypted scan, if one was captured.
  final String? imagePath;

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
  });

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
  /// The renewal lead time is always included — that is the notification that
  /// matters — alongside a conventional tail so the user is nudged again as
  /// the date closes in.
  List<int> get reminderOffsetDays {
    final offsets = <int>{renewalLeadDays, 90, 30, 7, 1}
        .where((d) => d > 0 && d <= renewalLeadDays)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return offsets;
  }

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
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Orders documents by urgency: expired first, then soonest to expire.
int byUrgency(TrackedDocument a, TrackedDocument b) =>
    a.expiryDate.compareTo(b.expiryDate);
