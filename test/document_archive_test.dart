import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:elapsa/data/settings_repository.dart';
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
      final out = (await archive.unpack(packed, passphrase: 'open sesame')).documents;

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
      final out = (await archive.unpack(packed, passphrase: 'hunter2!!')).documents;

      expect(out.single.images, hasLength(2));
      expect(out.single.images.first, _passport().images.first);
      expect(out.single.images.last, _passport().images.last);
    });

    test('an empty library is still a valid archive', () async {
      final packed = await archive.pack([], passphrase: 'nothing here');
      expect(
        (await archive.unpack(packed, passphrase: 'nothing here')).documents,
        isEmpty,
      );
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

      final out = (await archive.unpack(
        await archive.pack([doc], passphrase: 'passphrase'),
        passphrase: 'passphrase',
      )).documents;
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

  group('unprotected archives', () {
    test('a file with no passphrase round-trips', () async {
      // What a nearby transfer will carry: the handover is already guarded by
      // the other device having to accept it, so there is nothing to type.
      final packed = await archive.pack([_passport()]);
      final out = (await archive.unpack(packed)).documents;

      expect(out.single.document.id, 'a1b2');
      expect(out.single.images, hasLength(2));
    });

    test('the file says whether it will ask for anything', () async {
      expect(archive.isProtected(await archive.pack([])), isFalse);
      expect(
        archive.isProtected(await archive.pack([], passphrase: 'a key')),
        isTrue,
      );
    });

    test('an unprotected archive does not pretend to be sealed', () async {
      // Being exact about this is the point: without a passphrase the contents
      // are readable by anything that opens the file, and the app says so
      // rather than implying otherwise.
      final packed = await archive.pack([_passport()]);
      expect(utf8.decode(packed), isNot(contains('pbkdf2')));
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

  group('a document filed under a type the app does not ship', () {
    ArchivedDocument gymPass() => ArchivedDocument(
      TrackedDocument(
        id: 'gym',
        type: DocumentType.other,
        label: 'Gym',
        expiryDate: DateTime(2027, 3, 1),
        renewalLeadDays: 30,
        customType: 'Gym pass',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      const [],
      customType: const CustomType(name: 'Gym pass', leadDays: 21, icon: 8),
    );

    test('the definition travels with it', () async {
      // The point of carrying it rather than referring to it: the receiving
      // phone looks nothing up, so a card cannot land as "Other" for want of a
      // name that was sitting in the same file.
      final out = await archive.unpack(await archive.pack([gymPass()]));

      expect(out.documents.single.document.customType, 'Gym pass');
      expect(out.types.single.name, 'Gym pass');
      expect(out.types.single.leadDays, 21);
      expect(out.types.single.icon, 8);
    });

    test('a type is carried once however many documents use it', () async {
      final out = await archive.unpack(
        await archive.pack([gymPass(), gymPass()]),
      );
      expect(out.types, hasLength(1));
    });

    test('nothing is carried for the built-in types', () async {
      final out = await archive.unpack(await archive.pack([_passport()]));
      expect(out.types, isEmpty);
      expect(out.documents.single.document.customType, isNull);
    });
  });

  group('what the receiver does with an arriving type', () {
    late CustomTypeController receiver;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<CustomTypeController> controller(List<CustomType> existing) async {
      final settings = SettingsRepository(await SharedPreferences.getInstance());
      await settings.setCustomTypes(existing);
      return CustomTypeController(settings);
    }

    test('one it has never seen is added', () async {
      receiver = await controller([]);
      await receiver.adopt(const [CustomType(name: 'Gym pass', icon: 8)]);

      expect(receiver.state.single.name, 'Gym pass');
      expect(receiver.state.single.icon, 8);
    });

    test('one it already has keeps the receiver own settings', () async {
      // The icon and the lead time on this phone are its owner's choice. A
      // card arriving from someone else has no business rewriting them, and
      // the name is what files the document either way.
      receiver = await controller(
        const [CustomType(name: 'Gym pass', leadDays: 90, icon: 3)],
      );
      await receiver.adopt(
        const [CustomType(name: 'Gym pass', leadDays: 7, icon: 8)],
      );

      expect(receiver.state, hasLength(1));
      expect(receiver.state.single.leadDays, 90);
      expect(receiver.state.single.icon, 3);
    });

    test('two arriving, one known: only the new one is added', () async {
      receiver = await controller(const [CustomType(name: 'Gym pass')]);
      await receiver.adopt(const [
        CustomType(name: 'Gym pass'),
        CustomType(name: 'Diving licence'),
      ]);

      expect(receiver.state.map((t) => t.name), ['Diving licence', 'Gym pass']);
    });

    test('adopting nothing new writes nothing', () async {
      receiver = await controller(const [CustomType(name: 'Gym pass')]);
      await receiver.adopt(const [CustomType(name: 'Gym pass')]);
      expect(receiver.state, hasLength(1));
    });
  });
}
