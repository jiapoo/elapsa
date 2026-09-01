import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_detail.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/services/document_archive.dart';

const archive = DocumentArchive();

ArchivedDocument _passport() => ArchivedDocument(
      TrackedDocument(
        id: 'a1b2',
        type: DocumentType.passport,
        label: 'Passport',
        holder: 'LIU JIA',
        documentNumber: 'EM1234567',
        issuingCountry: 'CHN',
        issueDate: DateTime(2024, 5, 21),
        expiryDate: DateTime(2034, 5, 20),
        renewalLeadDays: 180,
        reminderOffsets: const [180, 90, 30],
        details: const {DocumentDetail.nationality: 'CHINESE'},
        imageCount: 2,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 2, 2),
      ),
      [
        Uint8List.fromList(List.generate(64, (i) => i)),
        Uint8List.fromList(List.generate(32, (i) => 255 - i)),
      ],
    );

void main() {
  group('round trip', () {
    test('everything that went in comes back out', () async {
      final packed = await archive.pack([_passport()], passphrase: 'open sesame');
      final out = await archive.unpack(packed, passphrase: 'open sesame');

      expect(out, hasLength(1));
      final doc = out.single.document;
      final original = _passport().document;

      // Identity survives, which is what makes importing the same file twice
      // update the records rather than double them.
      expect(doc.id, original.id);
      expect(doc.type, original.type);
      expect(doc.label, original.label);
      expect(doc.holder, original.holder);
      expect(doc.documentNumber, original.documentNumber);
      expect(doc.issuingCountry, original.issuingCountry);
      expect(doc.issueDate, original.issueDate);
      expect(doc.expiryDate, original.expiryDate);
      expect(doc.renewalLeadDays, original.renewalLeadDays);
      expect(doc.reminderOffsetDays, original.reminderOffsetDays);
      expect(doc.details, original.details);
      expect(doc.createdAt, original.createdAt);
    });

    test('the pictures come back byte for byte', () async {
      final packed = await archive.pack([_passport()], passphrase: 'hunter2!!');
      final out = await archive.unpack(packed, passphrase: 'hunter2!!');

      expect(out.single.images, hasLength(2));
      expect(out.single.images.first, _passport().images.first);
      expect(out.single.images.last, _passport().images.last);
    });

    test('an empty library is still a valid archive', () async {
      final packed = await archive.pack([], passphrase: 'nothing here');
      expect(await archive.unpack(packed, passphrase: 'nothing here'), isEmpty);
    });

    test('a document that chose no reminders keeps choosing none', () async {
      // The archive carries the user's decisions, not the app's defaults, so
      // an untouched document stays untouched on the other phone.
      final doc = ArchivedDocument(
        TrackedDocument(
          id: 'x',
          type: DocumentType.bankCard,
          label: 'Card',
          expiryDate: DateTime(2030, 1, 31),
          renewalLeadDays: 60,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        const [],
      );

      final out = await archive.unpack(
        await archive.pack([doc], passphrase: 'passphrase'),
        passphrase: 'passphrase',
      );
      expect(out.single.document.hasChosenReminders, isFalse);
    });
  });

  group('refuses what it should', () {
    test('the wrong passphrase opens nothing', () async {
      final packed = await archive.pack([_passport()], passphrase: 'correct one');
      expect(
        () => archive.unpack(packed, passphrase: 'correct onf'),
        throwsA(
          isA<ArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveFailure.cannotOpen,
          ),
        ),
      );
    });

    test('a tampered body is refused, not silently accepted', () async {
      // AES-GCM authenticates; without that check an altered archive would
      // decrypt to rubbish and be imported as if it were real.
      final packed = await archive.pack([_passport()], passphrase: 'a good key');
      final envelope =
          jsonDecode(utf8.decode(packed)) as Map<String, dynamic>;
      final body = base64Decode(envelope['body'] as String);
      body[0] ^= 0xFF;
      envelope['body'] = base64Encode(body);

      expect(
        () => archive.unpack(
          Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
          passphrase: 'a good key',
        ),
        throwsA(
          isA<ArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveFailure.cannotOpen,
          ),
        ),
      );
    });

    test('some other file is not an archive', () async {
      expect(
        () => archive.unpack(
          Uint8List.fromList(utf8.encode('{"hello":"world"}')),
          passphrase: 'x',
        ),
        throwsA(
          isA<ArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveFailure.notAnArchive,
          ),
        ),
      );
      expect(
        () => archive.unpack(
          Uint8List.fromList([0, 1, 2, 3, 200, 201]),
          passphrase: 'x',
        ),
        throwsA(isA<ArchiveException>()),
      );
    });

    test('an archive from a newer Elapsa is refused by name', () async {
      final packed = await archive.pack([], passphrase: 'key');
      final envelope =
          jsonDecode(utf8.decode(packed)) as Map<String, dynamic>;
      envelope['version'] = 99;

      expect(
        () => archive.unpack(
          Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
          passphrase: 'key',
        ),
        throwsA(
          isA<ArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveFailure.tooNew,
          ),
        ),
      );
    });
  });

  test('nothing readable is left in the clear', () async {
    final packed = await archive.pack([_passport()], passphrase: 'a passphrase');
    final text = utf8.decode(packed);

    // The envelope names the algorithms so the file can be understood years
    // from now. It must not name the holder.
    expect(text, contains('elapsa.archive'));
    expect(text, contains('pbkdf2-hmac-sha256'));
    expect(text, isNot(contains('LIU JIA')));
    expect(text, isNot(contains('EM1234567')));
    expect(text, isNot(contains('a passphrase')));
  });
}
