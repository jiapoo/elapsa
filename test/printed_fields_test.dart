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
