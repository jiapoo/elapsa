import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_detail.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/l10n/app_localizations.dart';

void main() {
  group('per-type fields', () {
    test('a bank card asks for a security code, a passport does not', () {
      expect(
        DocumentType.bankCard.details,
        contains(DocumentDetail.securityCode),
      );
      expect(
        DocumentType.passport.details,
        isNot(contains(DocumentDetail.securityCode)),
      );
    });

    test('a vehicle registration asks for a plate and a VIN', () {
      expect(
        DocumentType.vehicleRegistration.details,
        containsAll([
          DocumentDetail.plateNumber,
          DocumentDetail.vehicleIdentification,
        ]),
      );
    });

    test('only the security code is treated as sensitive', () {
      final sensitive =
          DocumentDetail.values.where((d) => d.isSensitive).toList();
      expect(sensitive, [DocumentDetail.securityCode]);
    });

    test('every field is named in every language', () {
      for (final locale in L.supportedLocales) {
        final l = lookupL(locale);
        for (final detail in DocumentDetail.values) {
          expect(detail.label(l), isNotEmpty, reason: '${detail.name} in $locale');
        }
      }
    });
  });

  group('storage', () {
    test('round-trips through JSON', () {
      const original = {
        DocumentDetail.cardholderName: 'ANNA ERIKSSON',
        DocumentDetail.securityCode: '123',
      };
      final encoded = DocumentDetails.encode(original);
      expect(DocumentDetails.decode(encoded), original);
    });

    test('stores nothing when every field is blank', () {
      expect(
        DocumentDetails.encode({
          DocumentDetail.cardholderName: '',
          DocumentDetail.securityCode: '   ',
        }),
        isNull,
      );
    });

    test('trims what it keeps', () {
      final encoded =
          DocumentDetails.encode({DocumentDetail.plateNumber: '  AB 1234  '});
      expect(DocumentDetails.decode(encoded), {
        DocumentDetail.plateNumber: 'AB 1234',
      });
    });

    test('survives absent, empty and malformed values', () {
      // Anything here comes off a device that may have been written by another
      // build; none of it should be able to stop the app opening.
      expect(DocumentDetails.decode(null), isEmpty);
      expect(DocumentDetails.decode(''), isEmpty);
      expect(DocumentDetails.decode('not json'), isEmpty);
      expect(DocumentDetails.decode('[1,2,3]'), isEmpty);
      expect(DocumentDetails.decode('{"securityCode": 42}'), isEmpty);
    });

    test('drops fields it no longer knows about', () {
      // A key from a newer build. Keeping it would let data outlive the code
      // that made sense of it.
      expect(
        DocumentDetails.decode('{"plateNumber":"AB1","retired":"x"}'),
        {DocumentDetail.plateNumber: 'AB1'},
      );
    });
  });

  test('details survive a copyWith', () {
    final doc = TrackedDocument(
      id: 'x',
      type: DocumentType.bankCard,
      label: 'Card',
      expiryDate: DateTime(2030),
      renewalLeadDays: 30,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      details: const {DocumentDetail.securityCode: '999'},
    );

    expect(doc.copyWith(label: 'Renamed').details,
        {DocumentDetail.securityCode: '999'});
    expect(
      doc.copyWith(details: const {DocumentDetail.cardholderName: 'A'}).details,
      {DocumentDetail.cardholderName: 'A'},
    );
  });
}
