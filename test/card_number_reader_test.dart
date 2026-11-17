import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/core/card_number.dart';
import 'package:elapsa/domain/printed_fields.dart';
import 'package:elapsa/services/card_number_reader.dart';
import 'package:elapsa/services/vision_channel.dart';

const reader = CardNumberReader();

// Published test numbers, never a real card.
const visa = '4539148803436467';
const unionPay = '6217003320002856600';

/// One group of a card number, read as its own observation, at the [slot]th
/// position along a row at height [y].
RecognisedLine at(
  int slot,
  List<String> readings, {
  double y = 0.6,
  int of = 4,
}) {
  final width = 0.8 / of;
  return RecognisedLine(
    readings.first,
    Rect.fromLTWH(
      0.08 + slot * width + width * 0.1,
      y - 0.03,
      width * 0.8,
      0.06,
    ),
    candidates: readings,
  );
}

/// Every four-digit group that, put in place of group [slot] of [number],
/// still passes the checksum — the decoys a reckless reader would fall for.
List<String> luhnDecoys(String number, int slot) => [
  for (var i = 0; i < 10000; i++)
    if (i.toString().padLeft(4, '0') case final g
        when g != number.substring(slot * 4, slot * 4 + 4) &&
            passesLuhn(number.replaceRange(slot * 4, slot * 4 + 4, g)))
      g,
];

void main() {
  test('the published test numbers are valid to begin with', () {
    expect(passesLuhn(visa) && isPlausibleCardNumber(visa), isTrue);
    expect(passesLuhn(unionPay) && isPlausibleCardNumber(unionPay), isTrue);
  });

  group('one pass, with its runners-up', () {
    test('a group misread first and read right second is repaired', () {
      // 1488 came back as 1468 — a real failure on embossed figures — with
      // the right digits one place down the list.
      final lines = [
        at(0, ['4539']),
        at(1, ['1468', '1488']),
        at(2, ['0343']),
        at(3, ['6467']),
      ];
      expect(reader.read([lines]), visa);
    });

    test('a group read as letters is folded back', () {
      final lines = [
        at(0, ['4539']),
        at(1, ['l4B8', '1A88']),
        at(2, ['O343']),
        at(3, ['6467']),
      ];
      expect(reader.read([lines]), visa);
    });

    test('the whole row as one observation', () {
      final row = RecognisedLine(
        '4539 1488 0343 6461',
        const Rect.fromLTWH(0.08, 0.57, 0.84, 0.06),
        candidates: const ['4539 1488 0343 6461', '4539 1488 0343 6467'],
      );
      expect(
        reader.read([
          [row],
        ]),
        visa,
      );
    });
  });

  group('many passes, each losing a different part', () {
    test('are put together into the number none of them had', () {
      final passes = [
        // The artwork took the first group from one treatment...
        [
          at(1, ['1488']),
          at(2, ['0343']),
          at(3, ['6467']),
        ],
        // ...the third from another...
        [
          at(0, ['4539']),
          at(1, ['1488']),
          at(3, ['6467']),
        ],
        // ...and misread the last in a third.
        [
          at(0, ['4539']),
          at(2, ['0343']),
          at(3, ['6487']),
        ],
      ];
      expect(reader.read(passes), visa);
    });

    test('a wrong reading outvoted by the right one loses', () {
      final decoy = luhnDecoys(visa, 1).first;
      final right = [
        at(0, ['4539']),
        at(1, ['1488']),
        at(2, ['0343']),
        at(3, ['6467']),
      ];
      final wrong = [
        at(0, ['4539']),
        at(1, [decoy]),
        at(2, ['0343']),
        at(3, ['6467']),
      ];
      expect(reader.read([right, right, wrong]), visa);
    });

    test('two numbers the evidence supports equally are no answer', () {
      // Better an empty field the user fills in than a wrong one they have
      // no reason to check.
      final decoy = luhnDecoys(visa, 1).first;
      final right = [
        at(0, ['4539']),
        at(1, ['1488']),
        at(2, ['0343']),
        at(3, ['6467']),
      ];
      final wrong = [
        at(0, ['4539']),
        at(1, [decoy]),
        at(2, ['0343']),
        at(3, ['6467']),
      ];
      expect(reader.read([right, wrong]), isNull);
    });

    test('a whole-row reading and a grouped one are not spliced together', () {
      final row = RecognisedLine(
        '4539148803436467',
        const Rect.fromLTWH(0.08, 0.57, 0.84, 0.06),
      );
      final grouped = [
        at(0, ['4539']),
        at(1, ['1488']),
        at(2, ['0343']),
        at(3, ['6467']),
      ];
      expect(
        reader.read([
          [row],
          grouped,
        ]),
        visa,
      );
    });
  });

  test('groups joined by a hyphen are still placed one by one', () {
    // Silver foil over a painted card came back as "#### ####-#### ####"
    // from one pass, with the last group wrong, and right from others.
    final joined = RecognisedLine(
      '4539 1488-0343 6461',
      const Rect.fromLTWH(0.08, 0.57, 0.84, 0.06),
    );
    final last = [at(3, ['6467'])];
    expect(reader.read([[joined], last, last]), visa);
  });

  test('a nineteen-digit UnionPay number is not cut short', () {
    final lines = [
      for (final (i, g) in ['6217', '0033', '2000', '2856', '600'].indexed)
        at(i, [g], of: 5),
    ];
    expect(reader.read([lines, lines]), unionPay);
  });

  test('digits elsewhere on the card are not a number', () {
    final lines = [
      at(0, ['09/26']),
      at(1, ['95555'], y: 0.9),
      at(0, ['400'], y: 0.2),
    ];
    expect(reader.read([lines]), isNull);
  });

  group('where to look for the number', () {
    test('the row with the most digits, when something was read', () {
      final bands = numberBands([
        RecognisedLine(
          'CHINA MERCHANTS BANK',
          const Rect.fromLTWH(0.1, 0.1, 0.5, 0.05),
        ),
        RecognisedLine('4539 1488', const Rect.fromLTWH(0.1, 0.53, 0.4, 0.07)),
        RecognisedLine('09/26', const Rect.fromLTWH(0.5, 0.75, 0.1, 0.04)),
      ]);
      expect(bands.first.top, lessThan(0.53));
      expect(bands.first.bottom, greaterThan(0.6));
      expect(bands.first.width, 1);
    });

    test('just below the middle of the card, when nothing was', () {
      final bands = numberBands(const []);
      expect(bands, hasLength(1));
      expect(bands.single.contains(const Offset(0.5, 0.6)), isTrue);
    });
  });

  test('figures returned as Cyrillic letters are folded back', () {
    // 6467 as "б4б7" — the shapes are the same, the code points are not.
    expect(digitGroup('б4б7')?.digits, '6467');
    expect(digitGroup('О343')?.digits, '0343');
  });

  test('full-width figures from a Chinese model are read as figures', () {
    const parser = PrintedFieldParser();
    final fields = parser.parse('招商银行\n４５３９ １４８８ ０３４３ ６４６７\n０９／２６');
    expect(fields.documentNumber, visa);
    expect(fields.expiryDate, DateTime(2026, 8, 31));
  });
}
