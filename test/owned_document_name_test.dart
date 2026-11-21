import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/l10n/app_localizations_de.dart';
import 'package:elapsa/l10n/app_localizations_en.dart';
import 'package:elapsa/l10n/app_localizations_fr.dart';
import 'package:elapsa/l10n/app_localizations_ja.dart';
import 'package:elapsa/l10n/app_localizations_zh.dart';

void main() {
  test('English: the first given name, possessive, type in lower case', () {
    expect(ownedDocumentName(LEn(), 'Passport', 'ALBERT JOHN'),
        "Albert's passport");
  });

  test('no name read: just the type', () {
    expect(ownedDocumentName(LEn(), 'Passport', null), 'Passport');
    expect(ownedDocumentName(LEn(), 'Passport', '  '), 'Passport');
  });

  test("a type the user named keeps its capitals", () {
    expect(
      ownedDocumentName(LEn(), 'Gym Pass', 'ANNA', builtInType: false),
      "Anna's Gym Pass",
    );
  });

  test('French elides before a vowel, not before a consonant', () {
    expect(ownedDocumentName(LFr(), 'Passeport', 'ALBERT'),
        'Passeport d’Albert');
    expect(ownedDocumentName(LFr(), 'Passeport', 'ROBERT'),
        'Passeport de Robert');
  });

  test('German and Japanese put the parts their own way round', () {
    expect(ownedDocumentName(LDe(), 'Reisepass', 'ALBERT'),
        'Reisepass von Albert');
    expect(ownedDocumentName(LJa(), 'パスポート', 'ALBERT'), 'Albertのパスポート');
  });

  test('a name with no spaces is kept whole', () {
    expect(ownedDocumentName(LZh(), '身份证', '刘嘉'), '刘嘉的身份证');
  });
}
