import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/l10n/app_localizations_en.dart';

void main() {
  final l = LEn();

  group('duration', () {
    test('a ten-year passport reads as ten years on the day it is issued', () {
      // Dividing by 365 gives "9 years 362 days", which is arithmetically
      // defensible and obviously wrong to anyone holding the passport.
      expect(
        durationLabel(DateTime(2024, 5, 21), DateTime(2034, 5, 20), l),
        '9 years 364 days',
      );
      expect(
        durationLabel(DateTime(2024, 5, 21), DateTime(2034, 5, 21), l),
        '10 years',
      );
    });

    test('under a year is days alone', () {
      expect(durationLabel(DateTime(2026, 1, 1), DateTime(2026, 1, 2), l),
          '1 day');
      expect(durationLabel(DateTime(2026, 1, 1), DateTime(2026, 3, 1), l),
          '59 days');
    });

    test('years and days together', () {
      expect(
        durationLabel(DateTime(2026, 1, 1), DateTime(2028, 2, 4), l),
        '2 years 34 days',
      );
    });

    test('counts whole years across a leap day', () {
      expect(
        durationLabel(DateTime(2024, 1, 1), DateTime(2025, 1, 1), l),
        '1 year',
      );
    });

    test('a date already past is not negative', () {
      expect(durationLabel(DateTime(2026, 5, 1), DateTime(2026, 4, 1), l),
          '0 days');
    });
  });
}
