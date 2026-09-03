import 'package:elapsa/domain/document_type.dart';

/// What could be read off the *printed face* of a document.
///
/// The machine-readable zone is the reliable path, but most of the world's
/// documents do not have one — a Chinese 居民身份证, a driving licence, an
/// insurance card. For those, the expiry date is printed in plain sight and
/// simply needs reading.
class PrintedFields {
  final DateTime? expiryDate;

  /// When the document became valid. Most cards print it beside the expiry —
  /// `VALID FROM` against `VALID THRU` — and a Chinese identity card prints
  /// both ends of its range.
  final DateTime? issueDate;

  final String? documentNumber;
  final DocumentType? type;

  /// The three-digit code on the signature panel.
  final String? securityCode;

  /// The name embossed on the card.
  final String? holderName;

  /// Who issued it — the bank on a payment card, the authority on an ID.
  ///
  /// Becomes the document's name, because "China Construction Bank" is what
  /// someone calls that card. "Bank card" is what a filing cabinet calls it.
  final String? issuer;

  /// True when the document says it never expires — a Chinese ID issued to
  /// someone over 46 reads `2015.01.01-长期`. Recording that as "no expiry" is
  /// right; recording it as "expired" would be badly wrong.
  final bool neverExpires;

  const PrintedFields({
    this.expiryDate,
    this.issueDate,
    this.documentNumber,
    this.type,
    this.issuer,
    this.securityCode,
    this.holderName,
    this.neverExpires = false,
  });

  /// Fills this in from [other] wherever it has nothing.
  ///
  /// A card is two photographs: the front carries the number, the name and the
  /// dates, the back carries the security code. Keeping only the first page
  /// that yielded anything threw the other half away.
  PrintedFields mergedWith(PrintedFields other) => PrintedFields(
    expiryDate: expiryDate ?? other.expiryDate,
    issueDate: issueDate ?? other.issueDate,
    documentNumber: documentNumber ?? other.documentNumber,
    type: type ?? other.type,
    issuer: issuer ?? other.issuer,
    securityCode: securityCode ?? other.securityCode,
    holderName: holderName ?? other.holderName,
    neverExpires: neverExpires || other.neverExpires,
  );

  bool get isEmpty =>
      expiryDate == null &&
      issueDate == null &&
      documentNumber == null &&
      type == null &&
      issuer == null &&
      securityCode == null &&
      holderName == null &&
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

  /// Every `MM/YY` on a payment card.
  ///
  /// Deliberately *not* anchored to a label. A card carries two of them —
  /// `VALID FROM 10/23` beside `VALID THRU 10/28`, each under its own
  /// `MONTH/YEAR` caption — and a recogniser returns those captions and
  /// figures as separate lines in an order that follows the layout, not the
  /// meaning. Anchoring to the caption matched whichever came first, which on
  /// a card laid out this way is the date it was *issued*: a live card
  /// recorded as two years expired.
  ///
  /// So every one is collected and the latest wins. Between an issue date and
  /// an expiry the expiry is always the later, and that holds whatever order
  /// the lines arrive in and whichever captions the recogniser dropped.
  static final _monthYear = RegExp(
    r'(?<![\d/])(\d{1,2})\s*/\s*(\d{2})(?![\d/])',
  );

  /// A date written with the month in words: `16 JUL 1986`, and the bilingual
  /// `21 5月/MAY 2024` that a Chinese passport prints.
  ///
  /// This is how travel documents write dates, and none of the numeric
  /// patterns above could see them. A passport whose machine-readable zone
  /// failed — a thumb over the line, a worn strip — therefore came back
  /// identified as a passport with every field blank, which is the most
  /// useless result the app can produce: it knew what it was holding and
  /// nothing about it.
  static final _dayMonthYear = RegExp(
    r'(?<![\d])(\d{1,2})\s*(?:\d{1,2}\s*月\s*/?\s*)?'
    r'([A-Za-z]{3})[A-Za-z]*\.?\s*(\d{4})(?![\d])',
  );

  static const _monthNames = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  /// The caption a passport prints over the date it expires.
  static final _expiryLabel = RegExp(
    r'有效期至|有效期限|date\s*of\s*expiry|expiry|expires?|valid\s*until',
    caseSensitive: false,
  );

  /// And over the date it was issued. Deliberately not just "issue": the page
  /// also says *place* of issue, which is a different line with a different
  /// answer under it.
  static final _issueLabel = RegExp(
    r'签发日期|簽發日期|date\s*of\s*issue',
    caseSensitive: false,
  );

  /// A travel document number: a letter or two, then seven or eight digits.
  ///
  /// Bounded on both sides so it cannot match inside a machine-readable zone,
  /// where the same characters run into the check digit that follows them.
  static final _travelNumber = RegExp(
    r'(?<![A-Z0-9])([A-Z]{1,2}\d{7,8})(?![A-Z0-9])',
  );

  /// A three-digit security code, printed after the last four of the card
  /// number on the signature panel.
  ///
  /// That pairing is what makes it findable at all. Three digits on their own
  /// are hopeless — the back of a card is covered in service numbers — but
  /// four digits followed by three is the signature strip and very little
  /// else.
  static final _securityCode = RegExp(r'(?<!\d)\d{4}\s+(\d{3})(?!\d)');

  /// A line that is plausibly the cardholder's name: embossed in capitals,
  /// letters only, a word or three.
  static final _nameLine = RegExp(
    r'^([A-Z][A-Z.\-]{1,20},?(?: [A-Z][A-Z.\-]{0,20}){0,3})$',
    multiLine: true,
  );

  /// Everything else printed on a card in capitals.
  static final _notAName = RegExp(
    r'BANK|VALID|THRU|FROM|MONTH|YEAR|SIGNATURE|AUTHORIZED|AUTHORISED|DEBIT|'
    r'CREDIT|UNIONPAY|VISA|MASTERCARD|EXPRESS|CARD|ATM|CUSTOMER|SERVICE|'
    r'HOTLINE|OVERSEAS|CALL|SIGNED|HTTP|WWW|'
    // Everything else set in capitals on a passport's data page. The holder's
    // name is one line among many that look exactly like it.
    r'PASSPORT|REPUBLIC|CHINA|PEOPLE|NATIONAL|IMMIGRATION|ADMINISTRATION|'
    r'MINISTRY|FOREIGN|AFFAIRS|AUTHORITY|NATIONALITY|COUNTRY|CODE|TYPE|'
    r'PLACE|BIRTH|ISSUE|EXPIRY|SEX|HOLDER|BEARER|CHINESE|PRC',
  );

  /// Mainland Chinese national identity number: 17 digits and a check
  /// character.
  static final _chineseIdNumber = RegExp(r'(?<!\d)(\d{17}[\dXx])(?!\d)');

  /// A payment card number printed the way cards print it: four groups of
  /// four, sometimes with a further group on a nineteen-digit UnionPay card.
  ///
  /// The grouping is itself the evidence. Nothing else on a document is laid
  /// out as `4539 1488 0343 6467`, so this needs no corroborating wording —
  /// which matters, because requiring the word "bank" meant one bad line of
  /// recognition threw the number away.
  ///
  /// Any whitespace separates the groups, newlines included. The digits are
  /// embossed and set far apart, so a recogniser often returns each group of
  /// four as its own observation; joined up they arrive on separate lines, and
  /// insisting on a space between them missed the number entirely.
  static final _groupedCardNumber = RegExp(
    r'(?<![\d/])(\d{4}[\s-]\d{4}[\s-]\d{4}[\s-]\d{4}(?:[\s-]\d{1,3})?)(?![\d/])',
  );

  /// An unbroken run of 13 to 19 digits. Could be a card number, could be an
  /// IMEI or a policy number, so this one does need the wording to back it up.
  static final _cardNumber = RegExp(
    r'(?<![\d/])((?:\d[ -]?){12,18}\d)(?![\d/])',
  );

  /// The line naming the institution that issued the card.
  ///
  /// Chinese banks print their name in full and follow it with the English,
  /// so the Chinese line is matched first and used as-is: it is what the
  /// cardholder actually calls the card.
  static final _issuerLine = RegExp(
    r'([\u4e00-\u9fff]{2,10}(?:银行|銀行|信用社|保险|保險))'
    r'|([A-Z][A-Za-z.\-]*(?:[ ][A-Z][A-Za-z.\-]*){0,4}[ ](?:Bank|BANK))'
    r'|((?:Bank|BANK)[ ]of[ ][A-Z][A-Za-z.\-]*(?:[ ][A-Z][A-Za-z.\-]*){0,3})',
  );

  /// Wording that marks the document as a payment card.
  ///
  /// `VALID THRU` and `MONTH/YEAR` earn their place here: they are captions
  /// printed on payment cards and almost nowhere else, so finding one is
  /// evidence of what the document is even when the bank's own name did not
  /// survive recognition. That matters because the dates are only read once
  /// something here matches — a bare `10/28` on any other piece of paper must
  /// not become an expiry.
  static final _cardWording = RegExp(
    r'银联|銀聯|银行|銀行|储蓄卡|儲蓄卡|信用卡|借记卡|'
    r'unionpay|mastercard|maestro|\bjcb\b|american\s*express|'
    r'\bdebit\b|\bcredit\b|\bbank\b|\bcard\b|'
    r'\bthru\b|valid\s*through|month\s*/?\s*year',
    caseSensitive: false,
  );

  /// Digits that a recogniser hands back as letters.
  ///
  /// The number is *embossed*, not printed: it is the same colour as the card
  /// and is read by its shadow alone. A misread character is ordinary there in
  /// a way it never is on flat print, which is why the dates and the name come
  /// back perfectly from a photo whose number does not.
  static const _lookalikeDigits = {
    'O': '0',
    'D': '0',
    'Q': '0',
    'I': '1',
    'L': '1',
    '|': '1',
    '!': '1',
    'Z': '2',
    'A': '4',
    'S': '5',
    'G': '6',
    'T': '7',
    'B': '8',
  };

  /// The checksum every payment card number carries (ISO/IEC 7812).
  static bool _passesLuhn(String digits) {
    var sum = 0;
    var doubling = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var digit = digits.codeUnitAt(i) - 0x30;
      if (digit < 0 || digit > 9) return false;
      if (doubling) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubling = !doubling;
    }
    return sum % 10 == 0;
  }

  /// One whitespace-separated token read as a group of digits, or null when it
  /// is not one.
  ///
  /// Letters standing in for digits are folded back, but only in a token that
  /// is already mostly digits — otherwise `GOOD` reads as `6000` and every
  /// word on the card becomes a candidate.
  static String? _asDigitGroup(String token) {
    final stripped = token.replaceAll('-', '').toUpperCase();
    if (stripped.length < 3 || stripped.length > 19) return null;

    final digits = StringBuffer();
    var certain = 0;
    for (final char in stripped.split('')) {
      final code = char.codeUnitAt(0);
      if (code >= 0x30 && code <= 0x39) {
        certain++;
        digits.write(char);
        continue;
      }
      final substitute = _lookalikeDigits[char];
      if (substitute == null) return null;
      digits.write(substitute);
    }
    if (certain < 2 || certain * 2 < stripped.length) return null;
    return digits.toString();
  }

  /// The card number, found by its own checksum rather than by its
  /// surroundings.
  ///
  /// This is the one field on a card that proves itself. Every scheme's number
  /// satisfies Luhn, so a run of digits that passes *is* the number — no
  /// wording has to corroborate it, and a single embossed `1488` misread as
  /// `l488` no longer throws the whole number away, because the checksum tells
  /// us which reading was right.
  static String? _luhnCardNumber(String text) => _cardNumberIn(text);

  static String? _cardNumberIn(String text) {
    // Runs of adjacent digit groups. Adjacency matters: the groups are set far
    // apart on the card and come back as separate observations, so the number
    // arrives as four tokens that have to be tried joined.
    final runs = <List<String>>[];
    var run = <String>[];
    for (final token in text.split(RegExp(r'\s+'))) {
      final group = _asDigitGroup(token);
      if (group == null) {
        if (run.isNotEmpty) runs.add(run);
        run = [];
      } else {
        run.add(group);
      }
    }
    if (run.isNotEmpty) runs.add(run);

    String? best;
    for (final groups in runs) {
      for (var i = 0; i < groups.length; i++) {
        final joined = StringBuffer();
        for (var j = i; j < groups.length; j++) {
          joined.write(groups[j]);
          if (joined.length > 19) break;
          final candidate = joined.toString();
          if (candidate.length < 13) continue;
          // Every scheme in circulation begins 2-6. Anchoring here stops an
          // 18-digit identity number passing on a one-in-ten fluke.
          final first = candidate.codeUnitAt(0);
          if (first < 0x32 || first > 0x36) continue;

          if (!_passesLuhn(candidate)) continue;

          if (best == null || candidate.length > best.length) best = candidate;
        }
      }
    }
    return best;
  }

  PrintedFields parse(String text) {
    if (text.trim().isEmpty) return PrintedFields.empty;

    final normalised = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    final lines = normalised.split('\n');

    // Whether this is a payment card at all, judged only on its wording.
    //
    // Dropping the label anchor from the date pattern was necessary — the
    // captions do not survive recognition in a usable order — but it must not
    // become an excuse to read any `10/28` anywhere as an expiry. The wording
    // is the evidence now: a card says bank, or debit, or 银联, somewhere on
    // its face.
    final grouped = _groupedCardNumber
        .firstMatch(normalised)
        ?.group(1)
        ?.replaceAll(RegExp(r'\s+'), ' ');
    // A checksum-valid number is the strongest evidence there is, and it
    // arrives before any of the wording does.
    final luhn = _luhnCardNumber(normalised);
    final looksLikeCard =
        luhn != null || grouped != null || _cardWording.hasMatch(normalised);

    DateTime? expiry;
    var permanent = false;

    DateTime? issued;

    final range = _validityRange.firstMatch(normalised);
    if (range != null) {
      issued = _date(range.group(1), range.group(2), range.group(3));
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
      // A payment card prints MM/YY and nothing else. The later of the pair
      // is when it expires; the earlier is when it was issued.
      if (looksLikeCard) {
        final months = _allMonthYears(normalised);
        if (expiry == null && months.isNotEmpty) expiry = months.last;

        // The same month read the other way round.
        //
        // An expiry naming only a month is read pessimistically — the end of
        // the month before — because it is a date to act before. A start date
        // is not that. A card marked VALID FROM 10/23 became valid on the 1st
        // of October, and recording it as the 30th of September put it in
        // service a day before it existed.
        //
        // These come out of the same reader, so the shift is simply undone:
        // one day past the end of the month before is the first of the month
        // printed, and February, leap years and the turn of the year all take
        // care of themselves.
        if (months.length > 1) {
          issued = months.first.add(const Duration(days: 1));
        }
      }

      // A travel document writes its dates in words, under captions, in a
      // grid. Read under the caption first — that is the only reading that is
      // certain — and fall back to the shape of the page: a data page carries
      // birth, issue and expiry, and of those the expiry is always the last.
      if (expiry == null && _looksLikeTravelDocument(normalised)) {
        expiry = _dateUnder(lines, _expiryLabel);
        issued ??= _dateUnder(lines, _issueLabel);

        if (expiry == null) {
          final written = _allWrittenDates(normalised);
          // Three or more, or nothing. With two there is no telling an expiry
          // from a date of birth, and a passport recorded as expiring on the
          // day its holder was born is worse than one with the field left for
          // them to fill in.
          if (written.length >= 3) {
            expiry = written.last;
            issued ??= written[written.length - 2];
          }
        }
      }
    }

    // A long run of digits is only a card number when something else on the
    // document says "card". Bare, it could as easily be an IMEI, a policy
    // number or a serial — and inventing a document number is the same failure
    // as inventing a date.
    final chineseId = _chineseIdNumber.firstMatch(normalised)?.group(1);
    // A card number has to pass its own checksum. Nothing else counts.
    //
    // The layout — four groups of four — used to be accepted on its own, on
    // the reasoning that two misread characters defeat the checksum and two is
    // not many on embossed figures. A real scan settled that argument: a card
    // reading 6217 0033 2000 2856 600 was stored as 6819 0033 2000 2856 600,
    // taken from a treated image where the first group came out wrong. It was
    // laid out perfectly and it was not the number.
    //
    // Luhn catches every single-digit error and almost every transposition,
    // which is precisely this failure. A field left empty is one the user
    // fills in from the card in their hand; a field filled in wrongly is one
    // they have no reason to check.
    final card = chineseId != null
        ? null
        : luhn ??
              _checked(grouped) ??
              (looksLikeCard
                  ? _checked(_cardNumber.firstMatch(normalised)?.group(1))
                  : null);
    // A passport prints its number in one place and encodes it in another.
    // This is the printed one, for when the machine-readable zone could not be
    // read — which is exactly when the printed face is all there is.
    final travel = _looksLikeTravelDocument(normalised)
        ? _travelNumber.firstMatch(normalised)?.group(1)
        : null;

    final number = chineseId ?? travel ?? card?.replaceAll(RegExp(r'[ -]'), '');

    final issuer = _issuerLine.firstMatch(normalised);

    return PrintedFields(
      expiryDate: expiry,
      issueDate: issued,
      documentNumber: number?.toUpperCase(),
      type: _typeFrom(
        normalised,
        hasChineseId: chineseId != null,
        hasCardNumber: luhn != null,
      ),
      issuer: (issuer?.group(1) ?? issuer?.group(2) ?? issuer?.group(3))
          ?.trim(),
      securityCode: looksLikeCard
          ? _securityCode.firstMatch(normalised)?.group(1)
          : null,
      // A passport prints the holder's name in capitals exactly as a card
      // embosses it, and the same reader finds both.
      holderName: looksLikeCard || _looksLikeTravelDocument(normalised)
          ? _holderName(normalised, issuer)
          : null,
      neverExpires: permanent,
    );
  }

  /// Whether this is the sort of document that prints dates in words under
  /// captions — a passport, a visa, a residence permit.
  static bool _looksLikeTravelDocument(String text) {
    return text.contains('护照') ||
        text.contains('護照') ||
        RegExp(
          r'\bpassport\b|\bvisa\b|residence\s*permit|居留',
          caseSensitive: false,
        ).hasMatch(text);
  }

  /// Identifies the document from words printed on it.
  ///
  /// Only the phrases that appear on the document itself count — the title
  /// line or the issuing authority. A passing mention of a word elsewhere is
  /// not evidence of anything.
  static DocumentType? _typeFrom(
    String text, {
    required bool hasChineseId,
    required bool hasCardNumber,
  }) {
    if (text.contains('居民身份证') ||
        text.contains('居民身份證') ||
        text.contains('國民身分證') ||
        hasChineseId) {
      return DocumentType.nationalId;
    }
    if (text.contains('驾驶证') ||
        text.contains('駕駛執照') ||
        RegExp(
          r"driver'?s\s*licen[cs]e",
          caseSensitive: false,
        ).hasMatch(text)) {
      return DocumentType.driversLicence;
    }
    if (text.contains('行驶证') || text.contains('行車執照')) {
      return DocumentType.vehicleRegistration;
    }
    if (text.contains('护照') ||
        text.contains('護照') ||
        RegExp(r'\bpassport\b', caseSensitive: false).hasMatch(text)) {
      return DocumentType.passport;
    }
    if (text.contains('居留许可') ||
        text.contains('居留證') ||
        RegExp(r'residence\s*permit', caseSensitive: false).hasMatch(text)) {
      return DocumentType.residencePermit;
    }
    if (hasCardNumber ||
        _cardWording.hasMatch(text) ||
        _groupedCardNumber.hasMatch(text)) {
      return DocumentType.bankCard;
    }
    return null;
  }

  /// The first date written with a month name on this line, if any.
  static DateTime? _writtenDate(String line) {
    for (final match in _dayMonthYear.allMatches(line)) {
      final month = _monthNames[match.group(2)!.toLowerCase()];
      if (month == null) continue;
      final date = _date(match.group(3), '$month', match.group(1));
      if (date != null) return date;
    }
    return null;
  }

  /// The date printed under a caption.
  ///
  /// A passport's data page is a grid: the caption sits on one line and its
  /// value on the next, because that is how the page is laid out and not how
  /// it is read. So the caption's own line is searched first and then the two
  /// below it, which is close enough to be the same cell and far enough to
  /// survive a recogniser that split the row.
  static DateTime? _dateUnder(List<String> lines, RegExp label) {
    for (var i = 0; i < lines.length; i++) {
      if (!label.hasMatch(lines[i])) continue;
      for (var j = i; j < lines.length && j <= i + 2; j++) {
        final date = _writtenDate(lines[j]);
        if (date != null) return date;
      }
    }
    return null;
  }

  /// Every date written with a month name, earliest first.
  static List<DateTime> _allWrittenDates(String text) {
    final dates = <DateTime>{};
    for (final match in _dayMonthYear.allMatches(text)) {
      final month = _monthNames[match.group(2)!.toLowerCase()];
      if (month == null) continue;
      final date = _date(match.group(3), '$month', match.group(1));
      if (date != null) dates.add(date);
    }
    return dates.toList()..sort();
  }

  /// A candidate, if it survives its own checksum.
  static String? _checked(String? candidate) {
    if (candidate == null) return null;
    final digits = candidate.replaceAll(RegExp(r'[^0-9]'), '');
    return _passesLuhn(digits) ? candidate : null;
  }

  /// Every `MM/YY` in the text, earliest first, each as the month's last day.
  static List<DateTime> _allMonthYears(String text) {
    final dates = <DateTime>[];
    for (final match in _monthYear.allMatches(text)) {
      final date = _endOfMonth(match.group(1), match.group(2));
      if (date != null && !dates.contains(date)) dates.add(date);
    }
    dates.sort();
    return dates;
  }

  /// The line most likely to be the name embossed on the card.
  static String? _holderName(String text, RegExpMatch? issuer) {
    final issuerText = issuer?.group(0);
    for (final match in _nameLine.allMatches(text)) {
      final candidate = match.group(1)!.trim();
      if (candidate.length < 4) continue;
      if (_notAName.hasMatch(candidate)) continue;
      if (issuerText != null && issuerText.contains(candidate)) continue;
      return candidate;
    }
    return null;
  }

  /// A month with no day in it, recorded a month early.
  ///
  /// `07/35` names a month and nothing finer. Taken at face value that is the
  /// 31st of July — the card really is good through the end of the month — but
  /// an expiry is not a fact to be right about, it is a date to act before,
  /// and every day of slack in it is a day someone is walking around with a
  /// document they believe is valid.
  ///
  /// So an imprecise date is read pessimistically: the last day of the month
  /// *before* the one printed. `07/35` becomes the 30th of June, and everything
  /// downstream — the status, the countdown, every reminder — moves a month
  /// earlier with it. The cost of being a month early is a renewal done in
  /// good time. The cost of being a day late is a cancelled trip.
  static DateTime? _endOfMonth(String? month, String? year) {
    final m = int.tryParse(month ?? '');
    var y = int.tryParse(year ?? '');
    if (m == null || y == null || m < 1 || m > 12) return null;
    if (y < 100) y += 2000;
    if (y < 2000 || y > 2200) return null;

    // Day zero of a month is the last day of the one before it, so this is
    // the end of the *previous* month — and it handles February, leap years
    // and the turn of the year without a table or a special case.
    return DateTime(y, m, 0);
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
