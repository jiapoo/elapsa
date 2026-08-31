import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:elapsa/services/secure_store.dart';

/// Stores the pictures of a document, encrypted, inside the app's own
/// container.
///
/// A document owns an ordered set of images rather than one: a card has two
/// sides, a residence permit has a page of stamps, and a passport data page is
/// useless without the visa page facing it. Index 0 is the face shown in the
/// wallet.
///
/// Two things this deliberately does not do: write to the camera roll, where
/// every other app on the phone could read it, and keep the original capture,
/// which lands in a temporary directory outside our control.
class DocumentImageStore {
  DocumentImageStore(this._secure);

  final SecureStore _secure;

  static const _folder = 'documents';

  Future<Directory> _directory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, _folder));
  }

  File _fileFor(Directory dir, String documentId, int index) =>
      File(p.join(dir.path, '${documentId}_$index.enc'));

  /// Encrypts [bytes] and files them under [documentId] at [index].
  ///
  /// Returns the stored file's name, which is what gets written to the
  /// database — never an absolute path, since the app's container directory
  /// changes between installs and OS upgrades.
  Future<String> save(String documentId, int index, Uint8List bytes) async {
    final dir = await _directory();
    await _secure.writeEncrypted(_fileFor(dir, documentId, index), bytes);
    return '${documentId}_$index.enc';
  }

  /// Saves an ordered set, replacing whatever was there.
  Future<String?> saveAll(String documentId, List<Uint8List> images) async {
    await deleteAll(documentId);
    if (images.isEmpty) return null;

    String? first;
    for (var i = 0; i < images.length; i++) {
      final name = await save(documentId, i, images[i]);
      first ??= name;
    }
    return first;
  }

  /// Decrypted bytes for one picture, or null if there is none.
  Future<Uint8List?> load(String documentId, [int index = 0]) async {
    final dir = await _directory();
    return _secure.readEncrypted(_fileFor(dir, documentId, index));
  }

  Future<List<Uint8List>> loadAll(String documentId, int count) async {
    final images = <Uint8List>[];
    for (var i = 0; i < count; i++) {
      final bytes = await load(documentId, i);
      if (bytes != null) images.add(bytes);
    }
    return images;
  }

  /// Removes every picture belonging to a document.
  ///
  /// Scans the directory rather than trusting a stored count, so a crash
  /// midway through a save can never strand an image of someone's passport
  /// after they deleted the record.
  Future<void> deleteAll(String documentId) async {
    final dir = await _directory();
    if (!await dir.exists()) return;

    await for (final entry in dir.list()) {
      if (entry is File &&
          p.basename(entry.path).startsWith('${documentId}_')) {
        await entry.delete();
      }
    }
  }
}
