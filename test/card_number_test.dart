import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/core/card_number.dart';

void main() {
  group('grouping', () {
    test('sixteen digits break into fours', () {
      // Sixteen digits in an unbroken row cannot be checked against the card
      // in your hand: the eye loses its place and starts again.
      expect(groupCardNumber('4539148803436467'), '4539 1488 0343 6467');
    });

    test('a nineteen-digit UnionPay number runs 4-4-4-4-3', () {
      expect(
        groupCardNumber('6217003320002856600'),
        '6217 0033 2000 2856 600',
      );
    });

    test('American Express is printed 4-6-5, not in fours', () {
      expect(groupCardNumber('378282246310005'), '3782 822463 10005');
      expect(groupCardNumber('341111111111111'), '3411 111111 11111');
    });

    test('regrouping an already-spaced number changes nothing', () {
      expect(groupCardNumber('4539 1488 0343 6467'), '4539 1488 0343 6467');
    });

    test('leaves alone anything that is not a card number', () {
      // A passport number is not written in fours, and spacing one would be
      // wrong rather than merely unfamiliar.
      expect(groupCardNumber('E12345678'), 'E12345678');
      expect(groupCardNumber(''), '');
      expect(groupCardNumber('44010119900307201X'), '44010119900307201X');
    });

    test('never drops a digit', () {
      for (final number in [
        '4539148803436467',
        '6217003320002856600',
        '378282246310005',
        '123456789012',
      ]) {
        expect(
          groupCardNumber(number).replaceAll(' ', ''),
          number,
          reason: 'grouping must be presentation only',
        );
      }
    });
  });
}
