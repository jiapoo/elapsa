import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/l10n/app_localizations.dart';

/// Message keys from one ARB file, ignoring the `@` metadata entries.
Set<String> _keys(String path) {
  final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  group('translation coverage', () {
    final english = _keys('lib/l10n/app_en.arb');

    for (final locale in const ['zh', 'zh_Hant']) {
      test('$locale translates every string', () {
        final translated = _keys('lib/l10n/app_$locale.arb');

        // A missing key silently falls back to English at runtime, which is
        // the kind of half-translated screen nobody notices until a user does.
        expect(
          english.difference(translated),
          isEmpty,
          reason: 'missing from app_$locale.arb',
        );
        expect(
          translated.difference(english),
          isEmpty,
          reason: 'present in app_$locale.arb but not in the template',
        );
      });
    }
  });

  group('localised labels', () {
    /// Every supported locale, so a new one cannot be added without labels.
    for (final locale in L.supportedLocales) {
      test('every document type has a name in $locale', () {
        final l = lookupL(locale);
        for (final type in DocumentType.values) {
          final label = type.label(l);
          expect(label, isNotEmpty, reason: '${type.name} in $locale');
        }
      });

      test('every status has a name in $locale', () {
        final l = lookupL(locale);
        for (final status in DocumentStatus.values) {
          expect(status.label(l), isNotEmpty);
        }
      });

      test('lead times read naturally in $locale', () {
        final l = lookupL(locale);
        // The presets offered in the form, plus the boundary that used to
        // produce "1 months".
        for (final days in [30, 60, 90, 120, 180, 270, 365]) {
          expect(leadTimeLabel(l, days), isNotEmpty);
        }
        expect(leadTimeLabel(l, 365), contains('1'));
      });
    }

    test('English says "1 month", never "1 months"', () {
      final l = lookupL(const Locale('en'));
      expect(leadTimeLabel(l, 30), '1 month');
      expect(leadTimeLabel(l, 60), '2 months');
      expect(leadTimeLabel(l, 365), '1 year');
    });

    test('Simplified and Traditional differ where the terms really differ', () {
      final hans = lookupL(const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
      ));
      final hant = lookupL(const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
      ));

      // These are not character conversions of each other — a mainland reader
      // expects 身份证 and 驾驶证, a Taiwanese reader 身分證 and 駕照. Getting
      // this wrong is the tell that a "translation" was machine-converted.
      expect(DocumentType.nationalId.label(hans), '身份证');
      expect(DocumentType.nationalId.label(hant), '身分證');
      expect(DocumentType.driversLicence.label(hans), '驾驶证');
      expect(DocumentType.driversLicence.label(hant), '駕照');
      expect(DocumentType.vehicleRegistration.label(hans), '行驶证');
      expect(DocumentType.vehicleRegistration.label(hant), '行照');
    });
  });
}
