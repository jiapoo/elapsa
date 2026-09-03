import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/services/vision_channel.dart';

void main() {
  group('which script to read first', () {
    test('the app in simplified Chinese reads simplified first', () {
      expect(
        recognitionLanguagesFor(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ),
        ['zh-Hans', 'zh-Hant', 'en-US'],
      );
    });

    test('the app in traditional Chinese reads traditional first', () {
      expect(
        recognitionLanguagesFor(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
        ['zh-Hant', 'zh-Hans', 'en-US'],
      );
    });

    test('plain Chinese with no script named is treated as simplified', () {
      expect(
        recognitionLanguagesFor(const Locale('zh')),
        ['zh-Hans', 'zh-Hant', 'en-US'],
      );
    });

    test('anything else reads English first', () {
      expect(
        recognitionLanguagesFor(const Locale('en')),
        ['en-US', 'zh-Hans', 'zh-Hant'],
      );
    });

    test('nothing is ever dropped, only reordered', () {
      // Somebody reading the app in Chinese still owns a passport with
      // English on it, and the reverse is just as true.
      for (final locale in [
        const Locale('en'),
        const Locale('zh'),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ]) {
        expect(
          recognitionLanguagesFor(locale).toSet(),
          {'en-US', 'zh-Hans', 'zh-Hant'},
        );
      }
    });
  });
}
