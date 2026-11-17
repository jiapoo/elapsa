import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/domain/attachment.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/services/document_archive.dart';

void main() {
  final pdf = Attachment(
    id: 'f1',
    kind: AttachmentKind.file,
    name: 'Visa application.PDF',
    size: 4,
    addedAt: DateTime(2026, 3, 1),
  );
  final link = Attachment(
    id: 'l1',
    kind: AttachmentKind.link,
    name: 'Renewal form',
    url: 'https://www.gov.uk/renew-adult-passport',
    addedAt: DateTime(2026, 3, 2),
  );

  group('list encoding', () {
    test('round trips in order', () {
      final out = Attachment.decodeList(Attachment.encodeList([pdf, link]));
      expect(out.map((a) => a.id), ['f1', 'l1']);
      expect(out.first.size, 4);
      expect(out.last.url, link.url);
      expect(out.first.extension, 'pdf');
    });

    test('empty is stored as nothing', () {
      expect(Attachment.encodeList(const []), isNull);
      expect(Attachment.decodeList(null), isEmpty);
    });

    test('a malformed entry is dropped, not fatal', () {
      final out = Attachment.decodeList(
        '[{"id":"x"},{"id":"l","kind":"link","name":"n"},'
        '{"id":"ok","kind":"file","name":"a.txt"}]',
      );
      expect(out.map((a) => a.id), ['ok']);
      expect(Attachment.decodeList('not json'), isEmpty);
    });
  });

  group('links', () {
    test('a missing scheme is supplied', () {
      expect(
        Attachment.normaliseUrl('gov.uk/renew').toString(),
        'https://gov.uk/renew',
      );
    });

    test('only web addresses are accepted', () {
      expect(Attachment.normaliseUrl(''), isNull);
      expect(Attachment.normaliseUrl('hello world'), isNull);
      expect(Attachment.normaliseUrl('javascript:alert(1)'), isNull);
      expect(Attachment.normaliseUrl('tel://123'), isNull);
      expect(Attachment.normaliseUrl('localhost'), isNull);
      expect(Attachment.normaliseUrl('http://example.com'), isNotNull);
    });
  });

  test('attachments travel in an archive, files byte for byte', () async {
    const archive = DocumentArchive();
    final bytes = Uint8List.fromList([37, 80, 68, 70]);
    final doc = ArchivedDocument(
      TrackedDocument(
        id: 'd1',
        type: DocumentType.visa,
        label: 'Visa',
        expiryDate: DateTime(2030, 1, 1),
        renewalLeadDays: 90,
        attachments: [pdf, link],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      const [],
      attachmentFiles: {'f1': bytes},
    );

    final packed = await archive.pack([doc], passphrase: 'pw');
    final out = (await archive.unpack(packed, passphrase: 'pw')).documents;

    expect(out.single.document.attachments.map((a) => a.name), [
      'Visa application.PDF',
      'Renewal form',
    ]);
    expect(out.single.attachmentFiles['f1'], bytes);
  });
}
