import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/domain/script_detection.dart';

const chineseFirst = ['zh-Hans', 'zh-Hant', 'en-US'];

void main() {
  group('reading the language off the document', () {
    test('a traditional-script bank name leads with traditional', () {
      expect(
        languagesForText(
          '招商銀行\nCHINA MERCHANTS BANK\n雙幣信用卡',
          fallback: chineseFirst,
        ),
        ['zh-Hant', 'zh-Hans', 'en-US'],
      );
    });

    test('a simplified one with simplified', () {
      expect(
        languagesForText('中国建设银行\n储蓄卡', fallback: chineseFirst).first,
        'zh-Hans',
      );
    });

    test('kana means Japanese, even with Chinese characters around it', () {
      final languages = languagesForText(
        '在留カード\n氏名 NAME\nこの在留カードは',
        fallback: chineseFirst,
      );
      expect(languages.first, 'ja-JP');
      expect(languages.last, 'en-US');
    });

    test('Hangul means Korean', () {
      expect(
        languagesForText('자동차운전면허증\n서울특별시', fallback: chineseFirst).first,
        'ko-KR',
      );
    });

    test('Cyrillic, and Ukrainian by its own letters', () {
      expect(
        languagesForText(
          'ПАСПОРТ\nРоссийская Федерация',
          fallback: chineseFirst,
        ).first,
        'ru-RU',
      );
      expect(
        languagesForText(
          'ПАСПОРТ\nУкраїна громадянина',
          fallback: chineseFirst,
        ).first,
        'uk-UA',
      );
    });

    test('Thai and Arabic', () {
      expect(
        languagesForText('บัตรประจำตัวประชาชน', fallback: chineseFirst).first,
        'th-TH',
      );
      expect(
        languagesForText('بطاقة الهوية الوطنية', fallback: chineseFirst).first,
        'ar-SA',
      );
    });

    test('Vietnamese by its stacked accents', () {
      expect(
        languagesForText(
          'CĂN CƯỚC CÔNG DÂN\nHọ và tên',
          fallback: chineseFirst,
        ).first,
        'vi-VT',
      );
    });

    test('plenty of writing and nothing but Latin is read in English', () {
      expect(
        languagesForText(
          'BANK OF AMERICA\nDEBIT\nVALID THRU 09/28\nJANE Q PUBLIC',
          fallback: chineseFirst,
        ),
        ['en-US'],
      );
    });

    test('a German card with its umlauts', () {
      expect(
        languagesForText(
          'Führerschein\nBundesrepublik Deutschland\nGültig bis',
          fallback: chineseFirst,
        ).first,
        'de-DE',
      );
    });

    test('almost nothing read is no evidence: the guess stands', () {
      expect(languagesForText('VISA', fallback: chineseFirst), chineseFirst);
      expect(languagesForText('', fallback: chineseFirst), chineseFirst);
    });

    test('one stray glyph does not reorder anything', () {
      expect(
        languagesForText(
          'BANK OF AMERICA DEBIT CARD 가',
          fallback: chineseFirst,
        ),
        ['en-US'],
      );
    });

    test('English always comes last, and only once', () {
      for (final text in ['招商银行', '자동차운전면허증', 'ПАСПОРТ РФ']) {
        final languages = languagesForText(text, fallback: chineseFirst);
        expect(languages.last, 'en-US');
        expect(languages.where((l) => l == 'en-US'), hasLength(1));
      }
    });
  });
}
