import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:elapsa/services/secure_store.dart';

/// Stores the picture of a document, encrypted, inside the app's own
/// container.
///
/// Two things this deliberately does not do: write to the camera roll, where
/// every other app on the phone could read it, and keep the original capture
/// from the camera or picker, which lands in a temporary directory outside our
/// control. The plaintext is copied in, encrypted, and the source deleted.
class DocumentImageStore {
  DocumentImageStore(this._secure);

  final SecureStore _secure;

  static const _folder = 'documents';

  Future<Directory> _directory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, _folder));
  }

  File _fileFor(Directory dir, String documentId) =>
      File(p.join(dir.path, '$documentId.enc'));

  /// Encrypts [bytes] and files them under [documentId].
  ///
  /// Returns the stored file's name, which is what gets written to the
  /// database — never an absolute path, since the app's container directory
  /// changes between installs and OS upgrades.
  Future<String> save(String documentId, Uint8List bytes) async {
    final dir = await _directory();
    await _secure.writeEncrypted(_fileFor(dir, documentId), bytes);
    return '$documentId.enc';
  }

  /// Decrypted image bytes, or null if there is no stored image.
  Future<Uint8List?> load(String documentId) async {
    final dir = await _directory();
    return _secure.readEncrypted(_fileFor(dir, documentId));
  }

  Future<void> delete(String documentId) async {
    final dir = await _directory();
    final file = _fileFor(dir, documentId);
    if (await file.exists()) await file.delete();
  }
}
