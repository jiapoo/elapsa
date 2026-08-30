import 'package:flutter_test/flutter_test.dart';
import 'package:elapsa/domain/mrz.dart';

/// Specimen MRZs from ICAO Doc 9303. These are the published example
/// documents for "Anna Maria Eriksson" of Utopia and are the standard
/// conformance fixtures for an MRZ implementation.
String td3Line1 = 'P<UTOERIKSSON<<ANNA<MARIA'.padRight(44, '<');
const td3Line2 = 'L898902C36UTO7408122F1204159ZE184226B<<<<<10';

const td1Line1 = 'I<UTOD231458907<<<<<<<<<<<<<<<';
const td1Line2 = '7408122F1204159UTO<<<<<<<<<<<6';
String td1Line3 = 'ERIKSSON<<ANNA<MARIA'.padRight(30, '<');

void main() {
  group('check digit', () {
    test('matches the worked example in the standard', () {
      // ICAO 9303 Part 3, Section 4.9 walks through this exact computation.
      expect(MrzParser.computeCheckDigit('L898902C3'), 6);
      expect(MrzParser.computeCheckDigit('740812'), 2);
      expect(MrzParser.computeCheckDigit('120415'), 9);
    });

    test('treats filler as zero', () {
      expect(MrzParser.computeCheckDigit('<<<<<<'), 0);
    });

    test('weights letters by A=10 through Z=35', () {
      // Z scores 35, weighted by 7 => 245, so the digit is 5.
      expect(MrzParser.computeCheckDigit('Z'), 5);
    });
  });

  group('TD3 passport', () {
    late MrzResult result;

    setUp(() {
      result = MrzParser.parse('$td3Line1\n$td3Line2');
    });

    test('validates every check digit', () {
      expect(result.isValid, isTrue, reason: result.failedChecks.join(', '));
      expect(result.format, MrzFormat.td3);
    });

    test('extracts identity fields', () {
      expect(result.documentCode, 'P');
      expect(result.issuingState, 'UTO');
      expect(result.surname, 'ERIKSSON');
      expect(result.givenNames, 'ANNA MARIA');
      expect(result.fullName, 'ANNA MARIA ERIKSSON');
      expect(result.documentNumber, 'L898902C3');
      expect(result.nationality, 'UTO');
      expect(result.sex, 'F');
    });

    test('resolves the expiry date to this century', () {
      expect(result.expiryDate, DateTime(2012, 4, 15));
    });

    test('resolves a birth date in the past century', () {
      expect(result.dateOfBirth, DateTime(1974, 8, 12));
    });

    test('ignores surrounding noise from the OCR pass', () {
      final noisy = '''
        PASSPORT
        REPUBLIC OF UTOPIA
        $td3Line1
        $td3Line2
        Signature of bearer
      ''';
      final parsed = MrzParser.parse(noisy);
      expect(parsed.isValid, isTrue);
      expect(parsed.documentNumber, 'L898902C3');
    });
  });

  group('TD1 identity card', () {
    late MrzResult result;

    setUp(() {
      result = MrzParser.parse('$td1Line1\n$td1Line2\n$td1Line3');
    });

    test('validates every check digit', () {
      expect(result.isValid, isTrue, reason: result.failedChecks.join(', '));
      expect(result.format, MrzFormat.td1);
    });

    test('extracts identity fields', () {
      expect(result.documentNumber, 'D23145890');
      expect(result.surname, 'ERIKSSON');
      expect(result.givenNames, 'ANNA MARIA');
      expect(result.nationality, 'UTO');
      expect(result.expiryDate, DateTime(2012, 4, 15));
      expect(result.dateOfBirth, DateTime(1974, 8, 12));
    });
  });

  group('OCR repair', () {
    test('recovers from digit/letter confusion inside numeric runs', () {
      // The scanner misread the 0 in the expiry date 120415 as a letter O.
      final damaged = td3Line2.replaceRange(21, 27, '12O415');
      final result = MrzParser.parse('$td3Line1\n$damaged');

      expect(result.isValid, isTrue, reason: result.failedChecks.join(', '));
      expect(result.wasRepaired, isTrue);
      expect(result.expiryDate, DateTime(2012, 4, 15));
    });

    test('does not claim validity when the damage is unrecoverable', () {
      // A wrong digit — not a letter confusion — cannot be repaired, and must
      // not be silently accepted.
      final damaged = td3Line2.replaceRange(21, 27, '129415');
      final result = MrzParser.parse('$td3Line1\n$damaged');

      expect(result.isValid, isFalse);
      expect(result.failedChecks, contains('expiryDate'));
    });
  });

  group('malformed input', () {
    test('throws when no MRZ is present', () {
      expect(
        () => MrzParser.parse('just some ordinary text\nwith no MRZ at all'),
        throwsA(isA<MrzException>()),
      );
    });

    test('rejects an impossible calendar date', () {
      // 30 February — the parser must return null rather than roll over.
      final bad = td3Line2.replaceRange(21, 27, '120230');
      final result = MrzParser.parse('$td3Line1\n$bad');
      expect(result.expiryDate, isNull);
    });
  });
}
