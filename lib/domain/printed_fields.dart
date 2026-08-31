import 'package:elapsa/domain/document_type.dart';

/// What could be read off the *printed face* of a document.
///
/// The machine-readable zone is the reliable path, but most of the world's
/// documents do not have one — a Chinese 居民身份证, a driving licence, an
/// insurance card. For those, the expiry date is printed in plain sight and
/// simply needs reading.
class PrintedFields {
  final DateTime? expiryDate;
  final String? documentNumber;
  final DocumentType? type;

  /// True when the document says it never expires — a Chinese ID issued to
  /// someone over 46 reads `2015.01.01-长期`. Recording that as "no expiry" is
  /// right; recording it as "expired" would be badly wrong.
  final bool neverExpires;

  const PrintedFields({
    this.expiryDate,
    this.documentNumber,
    this.type,
    this.neverExpires = false,
  });

  bool get isEmpty =>
      expiryDate == null &&
      documentNumber == null &&
      type == null &&
      !neverExpires;

  static const empty = PrintedFields();
}

/// Reads dates and numbers off recognised text.
///
/// Deliberately conservative. A document photo contains many numbers that look
/// like dates — issue dates, birth dates, a printer's batch code — so this only
/// claims a value when the surrounding text says what it is. Guessing wrong
/// here is worse than returning nothing, because a wrong expiry produces a
/// reminder on the wrong day and the user has no way to know.
class PrintedFieldParser {
  const PrintedFieldParser();

  /// `2024.05.17-2029.05.17`, and the `长期` (permanent) variant.
  ///
  /// This validity *range* is how Chinese identity documents print their
  /// expiry, and the second date is the one that matters.
  static final _validityRange = RegExp(
    r'(\d{4})\s*[.\-/年]\s*(\d{1,2})\s*[.\-/月]\s*(\d{1,2})\s*日?'
    r'\s*[-–—~至]\s*'
    r'(?:(\d{4})\s*[.\-/年]\s*(\d{1,2})\s*[.\-/月]\s*(\d{1,2})\s*日?|(长期|長期))',
  );

  /// A single date introduced by a label that names it as the expiry.
  static final _labelledExpiry = RegExp(
    r'(?:有效期限|有效期至|有效期|到期日|expiry|expires?|valid\s*until|date\s*of\s*expiry)'
    r'[\s:：]*'
    r'(\d{4})\s*[.\-/年]\s*(\d{1,2})\s*[.\-/月]\s*(\d{1,2})',
    caseSensitive: false,
  );

  /// Mainland Chinese national identity number: 17 digits and a check
  /// character.
  static final _chineseIdNumber = RegExp(r'(?<!\d)(\d{17}[\dXx])(?!\d)');

  PrintedFields parse(String text) {
    if (text.trim().isEmpty) return PrintedFields.empty;

    final normalised = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    DateTime? expiry;
    var permanent = false;

    final range = _validityRange.firstMatch(normalised);
    if (range != null) {
      if (range.group(7) != null) {
        permanent = true;
      } else {
        expiry = _date(range.group(4), range.group(5), range.group(6));
      }
    } else {
      // Only when there is no range at all. A range already told us both
      // dates, and falling through to the labelled matcher would find the
      // *start* of that range — putting the reminder years early, or marking a
      // permanent card as long expired.
      final labelled = _labelledExpiry.firstMatch(normalised);
      if (labelled != null) {
        expiry = _date(labelled.group(1), labelled.group(2), labelled.group(3));
      }
    }

    final number = _chineseIdNumber.firstMatch(normalised)?.group(1);

    return PrintedFields(
      expiryDate: expiry,
      documentNumber: number?.toUpperCase(),
      type: _typeFrom(normalised, hasChineseId: number != null),
      neverExpires: permanent,
    );
  }

  /// Identifies the document from words printed on it.
  ///
  /// Only the phrases that appear on the document itself count — the title
  /// line or the issuing authority. A passing mention of a word elsewhere is
  /// not evidence of anything.
  static DocumentType? _typeFrom(String text, {required bool hasChineseId}) {
    if (text.contains('居民身份证') ||
        text.contains('居民身份證') ||
        text.contains('國民身分證') ||
        hasChineseId) {
      return DocumentType.nationalId;
    }
    if (text.contains('驾驶证') || text.contains('駕駛執照') ||
        RegExp(r"driver'?s\s*licen[cs]e", caseSensitive: false).hasMatch(text)) {
      return DocumentType.driversLicence;
    }
    if (text.contains('行驶证') || text.contains('行車執照')) {
      return DocumentType.vehicleRegistration;
    }
    if (text.contains('护照') || text.contains('護照') ||
        RegExp(r'\bpassport\b', caseSensitive: false).hasMatch(text)) {
      return DocumentType.passport;
    }
    if (text.contains('居留许可') || text.contains('居留證') ||
        RegExp(r'residence\s*permit', caseSensitive: false).hasMatch(text)) {
      return DocumentType.residencePermit;
    }
    return null;
  }

  static DateTime? _date(String? year, String? month, String? day) {
    final y = int.tryParse(year ?? '');
    final m = int.tryParse(month ?? '');
    final d = int.tryParse(day ?? '');
    if (y == null || m == null || d == null) return null;
    if (y < 1900 || y > 2200 || m < 1 || m > 12 || d < 1 || d > 31) return null;

    final date = DateTime(y, m, d);
    // DateTime rolls invalid days over (Feb 31 -> Mar 3); reject those.
    if (date.month != m || date.day != d) return null;
    return date;
  }
}
