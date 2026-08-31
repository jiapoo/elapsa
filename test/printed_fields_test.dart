import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/domain/printed_fields.dart';

const parser = PrintedFieldParser();

void main() {
  group('Chinese identity card', () {
    // The text Vision returns from the 国徽面 of a 居民身份证 — the exact card
    // that produced an empty expiry before this parser existed.
    const back = '''
中华人民共和国
居民身份证
签发机关  广州市公安局天河分局
有效期限  2024.05.17-2029.05.17
''';

    test('takes the second date of the validity range', () {
      final fields = parser.parse(back);
      expect(fields.expiryDate, DateTime(2029, 5, 17));
      expect(fields.neverExpires, isFalse);
    });

    test('identifies the document type', () {
      expect(parser.parse(back).type, DocumentType.nationalId);
    });

    test('recognises a permanent card rather than calling it expired', () {
      // Issued to someone over 46: the range ends in 长期, not a date.
      final fields = parser.parse('有效期限 2015.01.01-长期');
      expect(fields.neverExpires, isTrue);
      expect(fields.expiryDate, isNull);
    });

    test('handles the traditional form', () {
      expect(parser.parse('有效期限 2015.01.01-長期').neverExpires, isTrue);
    });

    test('reads the 18-character identity number', () {
      final fields = parser.parse('公民身份号码 44010119900307201X');
      expect(fields.documentNumber, '44010119900307201X');
      expect(fields.type, DocumentType.nationalId);
    });

    test('ignores a number of the wrong length', () {
      expect(parser.parse('4401011990030720').documentNumber, isNull);
    });
  });

  group('bank card', () {
    // What Vision reads off a China Construction Bank UnionPay debit card.
    const card = '''
中国建设银行
China Construction Bank
龙卡通(储蓄卡)
6217 0033 2000 2856 600
MONTH/YEAR
DEBIT CCB GD VALID THRU 07/35
UnionPay 银联
''';

    test('reads MM/YY as the last day of that month', () {
      // A card marked 07/35 is good *through* July, so expiring it on the 1st
      // would fire every reminder a month early.
      expect(parser.parse(card).expiryDate, DateTime(2035, 7, 31));
    });

    test('handles February and leap years', () {
      expect(parser.parse('VALID THRU 02/27').expiryDate, DateTime(2027, 2, 28));
      expect(parser.parse('VALID THRU 02/28').expiryDate, DateTime(2028, 2, 29));
    });

    test('identifies the type', () {
      expect(parser.parse(card).type, DocumentType.bankCard);
      expect(parser.parse('UnionPay').type, DocumentType.bankCard);
    });

    test('reads the card number without its spacing', () {
      expect(parser.parse(card).documentNumber, '6217003320002856600');
    });

    test('needs a label — a bare MM/YY is not an expiry', () {
      // "07/35" alone could be part of a number, a sort code, an issue date.
      expect(parser.parse('6217 0033 07/35').expiryDate, isNull);
    });

    test('names the bank that issued it', () {
      // "China Construction Bank" is what someone calls this card. "Bank card"
      // is what a filing cabinet calls it.
      expect(parser.parse(card).issuer, '中国建设银行');
    });

    test('falls back to the English name when there is no Chinese line', () {
      expect(
        parser.parse('China Construction Bank\nVALID THRU 07/35').issuer,
        'China Construction Bank',
      );
      expect(parser.parse('Bank of China\nUnionPay').issuer, 'Bank of China');
    });

    test('an identity number wins over a card number', () {
      // Both patterns can match 18 digits; the ID is the more specific claim.
      final fields = parser.parse('居民身份证 44010119900307201X');
      expect(fields.documentNumber, '44010119900307201X');
      expect(fields.type, DocumentType.nationalId);
    });
  });

  group('a card printing both of its dates', () {
    // A China Merchants Bank Visa, which prints VALID FROM beside VALID THRU,
    // each under its own MONTH/YEAR caption. Recognition returns the captions
    // and the figures as separate lines in layout order, not reading order.
    const front = '''
招商银行
CHINA MERCHANTS BANK
全币种国际信用卡
4539 1488 0343 6467
VALID
MONTH/YEAR
FROM
10/23
VALID
MONTH/YEAR
THRU
10/28
LIU JIA
VISA
Signature
''';

    test('takes the later date as the expiry, never the earlier', () {
      // Anchoring to the MONTH/YEAR caption matched the issue date first and
      // recorded a live card as two years expired.
      expect(parser.parse(front).expiryDate, DateTime(2028, 10, 31));
    });

    test('keeps the earlier date as when it became valid', () {
      expect(parser.parse(front).issueDate, DateTime(2023, 10, 31));
    });

    test('reads the name embossed on it', () {
      expect(parser.parse(front).holderName, 'LIU JIA');
    });

    test('does not mistake the bank or the scheme for the holder', () {
      final holder = parser.parse(front).holderName;
      expect(holder, isNot(contains('BANK')));
      expect(holder, isNot('VISA'));
    });

    test('names the card after the bank', () {
      expect(parser.parse(front).issuer, '招商银行');
    });

    test('a single date is still the expiry', () {
      expect(parser.parse('UnionPay VALID THRU 07/35').expiryDate,
          DateTime(2035, 7, 31));
      expect(parser.parse('UnionPay VALID THRU 07/35').issueDate, isNull);
    });
  });

  group('the grouping is the evidence', () {
    test('a number in fours is a card number without any other wording', () {
      // Requiring the word "bank" meant one bad line of recognition threw the
      // number away. Nothing else on a document is laid out like this.
      final fields = parser.parse('4539 1488 0343 6467');
      expect(fields.documentNumber, '4539148803436467');
      expect(fields.type, DocumentType.bankCard);
    });

    test('the groups may arrive on separate lines', () {
      // Embossed digits are set far apart, so the recogniser hands back each
      // group of four as its own observation. Insisting on a space between
      // them missed the number on every card it was tried against.
      final fields = parser.parse('招商银行\n4539\n1488\n0343\n6467\nLIU JIA');
      expect(fields.documentNumber, '4539148803436467');
    });

    test('a nineteen-digit UnionPay number is read whole', () {
      expect(
        parser.parse('6217 0033 2000 2856 600').documentNumber,
        '6217003320002856600',
      );
    });

    test('a run that fails the checksum still needs the wording', () {
      // Sixteen digits that are not a card number could be anything.
      expect(parser.parse('4539148803436468').documentNumber, isNull);
      expect(
        parser.parse('DEBIT 4539148803436468').documentNumber,
        '4539148803436468',
      );
    });

    test('a checksum-valid run needs no wording at all', () {
      // Every scheme's number satisfies Luhn, so passing it is not a hint
      // about the number — it is the number identifying itself.
      final fields = parser.parse('4539148803436467');
      expect(fields.documentNumber, '4539148803436467');
      expect(fields.type, DocumentType.bankCard);
    });

    test('a misread digit is repaired by the checksum', () {
      // The figures are embossed rather than printed — same colour as the
      // card, read by their shadow — so one character coming back as a letter
      // is ordinary. It used to throw the entire number away.
      expect(
        parser.parse('招商银行\n4539 1488 O343 6467').documentNumber,
        '4539148803436467',
      );
      expect(
        parser.parse('4S39 1488 0343 646T').documentNumber,
        '4539148803436467',
      );
    });

    test('a letter substitution that is really a word is not a number', () {
      // Folding letters to digits everywhere would make GOOD read as 6000.
      expect(parser.parse('GOOD BILBO DIGS OODLES').documentNumber, isNull);
    });

    test('the service numbers on the back are not a card number', () {
      expect(
        parser
            .parse('OVERSEAS CALL +86 400 820 5555\n24 Hours 400-820-5555')
            .documentNumber,
        isNull,
      );
    });

    test('an identity number is not mistaken for a card', () {
      final fields = parser.parse('居民身份证 44010119900307201X');
      expect(fields.documentNumber, '44010119900307201X');
      expect(fields.type, DocumentType.nationalId);
    });
  });

  group('the back of a card', () {
    const back = '''
OVERSEAS CALL: +86 400 820 5555
AUTHORIZED SIGNATURE NOT VALID UNLESS SIGNED
6467 774
24 Hours Hotline 400-820-5555
招商银行 信用卡
http://www.8008205555.com
''';

    test('reads the security code that follows the last four digits', () {
      expect(parser.parse(back).securityCode, '774');
    });

    test('is not fooled by the service numbers around it', () {
      // The panel is surrounded by hotlines; only four digits then three is
      // the signature strip.
      expect(parser.parse(back).securityCode, isNot('555'));
      expect(parser.parse(back).securityCode, isNot('820'));
    });
  });

  group('merging what each side gave', () {
    test('the front and the back together make one card', () {
      // Front has number, dates and name; back has the security code. Keeping
      // only the first page that read anything threw the other half away.
      const front = PrintedFields(
        documentNumber: '4539148803436467',
        holderName: 'LIU JIA',
        type: DocumentType.bankCard,
      );
      const back = PrintedFields(securityCode: '774', issuer: '招商银行');

      final merged = front.mergedWith(back);
      expect(merged.documentNumber, '4539148803436467');
      expect(merged.holderName, 'LIU JIA');
      expect(merged.securityCode, '774');
      expect(merged.issuer, '招商银行');
    });

    test('what is already known is never overwritten', () {
      const first = PrintedFields(securityCode: '111');
      const second = PrintedFields(securityCode: '222');
      expect(first.mergedWith(second).securityCode, '111');
    });

    test('merging with nothing changes nothing', () {
      const fields = PrintedFields(holderName: 'LIU JIA');
      expect(fields.mergedWith(PrintedFields.empty).holderName, 'LIU JIA');
      expect(PrintedFields.empty.mergedWith(fields).holderName, 'LIU JIA');
    });
  });

  group('labelled expiry dates', () {
    test('reads a Chinese label', () {
      expect(
        parser.parse('有效期至 2030年12月31日').expiryDate,
        DateTime(2030, 12, 31),
      );
    });

    test('reads an English label', () {
      expect(
        parser.parse('Date of expiry: 2031-04-09').expiryDate,
        DateTime(2031, 4, 9),
      );
    });

    test('is case insensitive', () {
      expect(
        parser.parse('VALID UNTIL 2028/02/29').expiryDate,
        DateTime(2028, 2, 29),
      );
    });
  });

  group('refuses to guess', () {
    test('an unlabelled date is not an expiry', () {
      // A birth date, an issue date, a printer's code — a document is full of
      // numbers, and claiming one is the expiry produces a reminder on the
      // wrong day with nothing to warn the user.
      expect(parser.parse('出生 1990年03月07日').expiryDate, isNull);
    });

    test('empty text yields nothing', () {
      expect(parser.parse('   ').isEmpty, isTrue);
    });

    test('rejects an impossible calendar date', () {
      expect(parser.parse('有效期至 2027.02.30').expiryDate, isNull);
    });

    test('rejects an out-of-range year', () {
      expect(parser.parse('有效期至 1201.05.17').expiryDate, isNull);
    });
  });

  group('other document types', () {
    test('passport', () {
      expect(parser.parse('PASSPORT / PASSEPORT').type, DocumentType.passport);
      expect(parser.parse('中华人民共和国护照').type, DocumentType.passport);
    });

    test('driving licence, both scripts', () {
      expect(parser.parse('机动车驾驶证').type, DocumentType.driversLicence);
      expect(
        parser.parse("DRIVER'S LICENCE").type,
        DocumentType.driversLicence,
      );
    });

    test('residence permit', () {
      expect(
        parser.parse('Residence Permit').type,
        DocumentType.residencePermit,
      );
    });
  });
}
