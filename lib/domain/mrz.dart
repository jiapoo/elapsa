/// ICAO 9303 Machine Readable Zone parser.
///
/// The MRZ is the block of monospaced `<`-padded text at the bottom of a
/// passport or ID card. Every field it carries is protected by a check digit,
/// so a parse that validates is near-certain to be correct. That is why we
/// read the MRZ rather than running OCR over the printed face of a document:
/// OCR gives us a guess, the MRZ gives us an answer.
///
/// Three layouts are defined by the standard, and we support all of them:
///
///   TD1 — 3 lines x 30 chars — ID cards, residence permits
///   TD2 — 2 lines x 36 chars — older travel documents
///   TD3 — 2 lines x 44 chars — passports
library;

enum MrzFormat { td1, td2, td3 }

/// A single check digit that was verified during parsing.
class MrzCheck {
  final String field;
  final bool valid;

  const MrzCheck(this.field, this.valid);

  @override
  String toString() => '$field: ${valid ? 'ok' : 'FAILED'}';
}

class MrzResult {
  final MrzFormat format;

  /// 'P' for passport, 'I'/'A'/'C' for ID cards, etc.
  final String documentCode;

  /// Issuing state or organisation, as a 3-letter ICAO code.
  final String issuingState;

  final String surname;
  final String givenNames;
  final String documentNumber;
  final String nationality;
  final DateTime? dateOfBirth;

  /// 'M', 'F', or '' when unspecified.
  final String sex;

  final DateTime? expiryDate;
  final String optionalData;

  /// Every check digit we evaluated, in document order.
  final List<MrzCheck> checks;

  /// True when the OCR text had to be repaired (common `0`/`O`, `1`/`I`
  /// confusions) before the check digits agreed. The data is still trustworthy
  /// — the check digits passed — but the UI may want to ask for confirmation.
  final bool wasRepaired;

  const MrzResult({
    required this.format,
    required this.documentCode,
    required this.issuingState,
    required this.surname,
    required this.givenNames,
    required this.documentNumber,
    required this.nationality,
    required this.dateOfBirth,
    required this.sex,
    required this.expiryDate,
    required this.optionalData,
    required this.checks,
    this.wasRepaired = false,
  });

  bool get isValid => checks.every((c) => c.valid);

  List<String> get failedChecks =>
      checks.where((c) => !c.valid).map((c) => c.field).toList();

  String get fullName => [givenNames, surname]
      .where((p) => p.isNotEmpty)
      .join(' ');

  @override
  String toString() =>
      'MrzResult(${format.name}, $documentNumber, $fullName, '
      'expires $expiryDate, valid: $isValid)';
}

class MrzException implements Exception {
  final String message;
  const MrzException(this.message);
  @override
  String toString() => 'MrzException: $message';
}

class MrzParser {
  const MrzParser._();

  /// Parses raw OCR text containing an MRZ.
  ///
  /// Accepts surrounding noise — lines that are not part of the MRZ are
  /// discarded — so the whole text block from an OCR pass can be handed
  /// straight in.
  ///
  /// Throws [MrzException] if no recognisable MRZ is present. A result is
  /// returned even when check digits fail, so the caller can decide whether
  /// to trust it; inspect [MrzResult.isValid] and [MrzResult.failedChecks].
  static MrzResult parse(String raw) {
    final lines = _extractMrzLines(raw);
    if (lines == null) {
      throw const MrzException('No MRZ found in the supplied text');
    }

    final first = _tryParse(lines);
    if (first.isValid) return first;

    // Check digits disagreed. OCR routinely confuses 0/O, 1/I, 5/S and 8/B;
    // retry with those repaired inside the numeric fields before giving up.
    final repaired = _tryParse(lines.map(_repairLine).toList());
    if (repaired.isValid) {
      return MrzResult(
        format: repaired.format,
        documentCode: repaired.documentCode,
        issuingState: repaired.issuingState,
        surname: repaired.surname,
        givenNames: repaired.givenNames,
        documentNumber: repaired.documentNumber,
        nationality: repaired.nationality,
        dateOfBirth: repaired.dateOfBirth,
        sex: repaired.sex,
        expiryDate: repaired.expiryDate,
        optionalData: repaired.optionalData,
        checks: repaired.checks,
        wasRepaired: true,
      );
    }

    // Neither pass validated — hand back the original so the UI can prefill
    // the form and let the user correct it.
    return first;
  }

  /// Computes the ICAO 9303 check digit for [input].
  ///
  /// Each character is weighted 7, 3, 1 repeating; digits score their value,
  /// letters score `A`=10 through `Z`=35, and the filler `<` scores 0.
  static int computeCheckDigit(String input) {
    const weights = [7, 3, 1];
    var sum = 0;
    for (var i = 0; i < input.length; i++) {
      sum += _charValue(input[i]) * weights[i % 3];
    }
    return sum % 10;
  }

  // ---------------------------------------------------------------- internals

  static int _charValue(String c) {
    if (c == '<') return 0;
    final code = c.codeUnitAt(0);
    if (code >= 0x30 && code <= 0x39) return code - 0x30; // '0'-'9'
    if (code >= 0x41 && code <= 0x5A) return code - 0x41 + 10; // 'A'-'Z'
    return 0;
  }

  /// Pulls the MRZ lines out of a larger OCR text block.
  ///
  /// MRZ lines are recognisable by their fixed length and their restricted
  /// alphabet (`A-Z`, `0-9`, `<`), which almost never occurs in ordinary text.
  static List<String>? _extractMrzLines(String raw) {
    final candidates = raw
        .toUpperCase()
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.replaceAll(RegExp(r'[^A-Z0-9<]'), ''))
        .where((l) => l.isNotEmpty)
        .toList();

    // Look for the longest run of consecutive same-length lines matching one
    // of the three layouts. Checking longest-first keeps a TD3 pair from being
    // mistaken for something shorter.
    for (final spec in const [(44, 2), (36, 2), (30, 3)]) {
      final (length, count) = spec;
      final matching = <String>[];
      for (final line in candidates) {
        if (line.length == length) {
          matching.add(line);
          if (matching.length == count) return matching;
        } else if (matching.isNotEmpty) {
          matching.clear();
        }
      }
    }
    return null;
  }

  static MrzResult _tryParse(List<String> lines) {
    if (lines.length == 3 && lines[0].length == 30) return _parseTd1(lines);
    if (lines.length == 2 && lines[0].length == 36) return _parseTd2(lines);
    if (lines.length == 2 && lines[0].length == 44) return _parseTd3(lines);
    throw const MrzException('Unrecognised MRZ layout');
  }

  /// TD3 — passports. Two lines of 44 characters.
  static MrzResult _parseTd3(List<String> lines) {
    final l1 = lines[0];
    final l2 = lines[1];

    final (surname, givenNames) = _parseNames(l1.substring(5));

    final rawDocNumber = l2.substring(0, 9);
    final docCheck = l2[9];
    final dob = l2.substring(13, 19);
    final dobCheck = l2[19];
    final expiry = l2.substring(21, 27);
    final expiryCheck = l2[27];
    final optional = l2.substring(28, 42);
    final optionalCheck = l2[42];
    final compositeCheck = l2[43];

    // A document number longer than 9 characters is carried in the optional
    // data field, with position 9 filled by '<'. Rare, but legal.
    var documentNumber = rawDocNumber;
    var effectiveOptional = optional;
    var docCheckValid = _checkEquals(rawDocNumber, docCheck);
    if (docCheck == '<' && optional.contains('<')) {
      final overflow = optional.substring(0, optional.indexOf('<'));
      if (overflow.isNotEmpty) {
        documentNumber = _strip(rawDocNumber) + _strip(overflow);
        effectiveOptional = '';
        docCheckValid = true; // validated by the composite digit instead
      }
    }

    final composite = rawDocNumber +
        docCheck +
        dob +
        dobCheck +
        expiry +
        expiryCheck +
        optional +
        optionalCheck;

    return MrzResult(
      format: MrzFormat.td3,
      documentCode: _strip(l1.substring(0, 2)),
      issuingState: _strip(l1.substring(2, 5)),
      surname: surname,
      givenNames: givenNames,
      documentNumber: _strip(documentNumber),
      nationality: _strip(l2.substring(10, 13)),
      dateOfBirth: _parseDate(dob, isBirthDate: true),
      sex: _parseSex(l2[20]),
      expiryDate: _parseDate(expiry, isBirthDate: false),
      optionalData: _strip(effectiveOptional),
      checks: [
        MrzCheck('documentNumber', docCheckValid),
        MrzCheck('dateOfBirth', _checkEquals(dob, dobCheck)),
        MrzCheck('expiryDate', _checkEquals(expiry, expiryCheck)),
        MrzCheck('optionalData', _checkEquals(optional, optionalCheck)),
        MrzCheck('composite', _checkEquals(composite, compositeCheck)),
      ],
    );
  }

  /// TD2 — older travel documents. Two lines of 36 characters.
  static MrzResult _parseTd2(List<String> lines) {
    final l1 = lines[0];
    final l2 = lines[1];

    final (surname, givenNames) = _parseNames(l1.substring(5));

    final docNumber = l2.substring(0, 9);
    final docCheck = l2[9];
    final dob = l2.substring(13, 19);
    final dobCheck = l2[19];
    final expiry = l2.substring(21, 27);
    final expiryCheck = l2[27];
    final optional = l2.substring(28, 35);
    final compositeCheck = l2[35];

    final composite =
        docNumber + docCheck + dob + dobCheck + expiry + expiryCheck + optional;

    return MrzResult(
      format: MrzFormat.td2,
      documentCode: _strip(l1.substring(0, 2)),
      issuingState: _strip(l1.substring(2, 5)),
      surname: surname,
      givenNames: givenNames,
      documentNumber: _strip(docNumber),
      nationality: _strip(l2.substring(10, 13)),
      dateOfBirth: _parseDate(dob, isBirthDate: true),
      sex: _parseSex(l2[20]),
      expiryDate: _parseDate(expiry, isBirthDate: false),
      optionalData: _strip(optional),
      checks: [
        MrzCheck('documentNumber', _checkEquals(docNumber, docCheck)),
        MrzCheck('dateOfBirth', _checkEquals(dob, dobCheck)),
        MrzCheck('expiryDate', _checkEquals(expiry, expiryCheck)),
        MrzCheck('composite', _checkEquals(composite, compositeCheck)),
      ],
    );
  }

  /// TD1 — ID cards and residence permits. Three lines of 30 characters.
  static MrzResult _parseTd1(List<String> lines) {
    final l1 = lines[0];
    final l2 = lines[1];
    final l3 = lines[2];

    final (surname, givenNames) = _parseNames(l3);

    final docNumber = l1.substring(5, 14);
    final docCheck = l1[14];
    final optional1 = l1.substring(15, 30);

    final dob = l2.substring(0, 6);
    final dobCheck = l2[6];
    final expiry = l2.substring(8, 14);
    final expiryCheck = l2[14];
    final optional2 = l2.substring(18, 29);
    final compositeCheck = l2[29];

    final composite = docNumber +
        docCheck +
        optional1 +
        dob +
        dobCheck +
        expiry +
        expiryCheck +
        optional2;

    return MrzResult(
      format: MrzFormat.td1,
      documentCode: _strip(l1.substring(0, 2)),
      issuingState: _strip(l1.substring(2, 5)),
      surname: surname,
      givenNames: givenNames,
      documentNumber: _strip(docNumber),
      nationality: _strip(l2.substring(15, 18)),
      dateOfBirth: _parseDate(dob, isBirthDate: true),
      sex: _parseSex(l2[7]),
      expiryDate: _parseDate(expiry, isBirthDate: false),
      optionalData: _strip('$optional1$optional2'),
      checks: [
        MrzCheck('documentNumber', _checkEquals(docNumber, docCheck)),
        MrzCheck('dateOfBirth', _checkEquals(dob, dobCheck)),
        MrzCheck('expiryDate', _checkEquals(expiry, expiryCheck)),
        MrzCheck('composite', _checkEquals(composite, compositeCheck)),
      ],
    );
  }

  static bool _checkEquals(String field, String expected) {
    if (expected == '<') return false;
    final digit = int.tryParse(expected);
    if (digit == null) return false;
    return computeCheckDigit(field) == digit;
  }

  /// Splits an MRZ name field into surname and given names.
  ///
  /// The format is `SURNAME<<GIVEN<NAMES` padded with trailing `<`.
  static (String, String) _parseNames(String field) {
    final trimmed = field.replaceAll(RegExp(r'<+$'), '');
    final split = trimmed.indexOf('<<');
    if (split < 0) {
      return (_humanise(trimmed), '');
    }
    return (
      _humanise(trimmed.substring(0, split)),
      _humanise(trimmed.substring(split + 2)),
    );
  }

  static String _humanise(String s) =>
      s.replaceAll('<', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _strip(String s) => s.replaceAll('<', '').trim();

  static String _parseSex(String c) => (c == 'M' || c == 'F') ? c : '';

  /// Parses a `YYMMDD` MRZ date.
  ///
  /// The century is inferred: a travel document never expires before 2000, so
  /// expiry years always resolve to 20xx. Birth years resolve to 19xx when the
  /// two-digit year is in the future.
  static DateTime? _parseDate(String yymmdd, {required bool isBirthDate}) {
    if (yymmdd.length != 6 || !RegExp(r'^\d{6}$').hasMatch(yymmdd)) return null;

    final yy = int.parse(yymmdd.substring(0, 2));
    final mm = int.parse(yymmdd.substring(2, 4));
    final dd = int.parse(yymmdd.substring(4, 6));
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;

    final int year;
    if (isBirthDate) {
      final currentYy = DateTime.now().year % 100;
      year = yy <= currentYy ? 2000 + yy : 1900 + yy;
    } else {
      year = 2000 + yy;
    }

    final date = DateTime(year, mm, dd);
    // DateTime rolls invalid days over (Feb 31 -> Mar 3); reject those.
    if (date.month != mm || date.day != dd) return null;
    return date;
  }

  /// Repairs the character confusions OCR makes most often.
  ///
  /// Only the numeric regions of a line are touched — letters elsewhere are
  /// legitimate — and the result is re-validated against the check digits, so
  /// a wrong repair simply fails to validate rather than corrupting data.
  static String _repairLine(String line) {
    const toDigit = {'O': '0', 'Q': '0', 'D': '0', 'I': '1', 'L': '1', 'S': '5', 'B': '8', 'G': '6', 'Z': '2'};
    final buffer = StringBuffer();

    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      // Date and check-digit regions differ per format; rather than encode
      // every offset, repair any letter that sits inside a run of digits.
      final prev = i > 0 ? line[i - 1] : '';
      final next = i + 1 < line.length ? line[i + 1] : '';
      final betweenDigits = _isDigit(prev) && _isDigit(next);
      buffer.write(betweenDigits ? (toDigit[c] ?? c) : c);
    }
    return buffer.toString();
  }

  static bool _isDigit(String c) =>
      c.length == 1 && c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;
}
