import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:elapsa/services/secure_store.dart';

/// Keeps the files attached to a document, encrypted, in the app's container.
///
/// The same protection as the photos, for the same reason: a PDF of a visa
/// application holds everything the passport does and a good deal more.
class AttachmentStore {
  AttachmentStore(this._secure);

  final SecureStore _secure;

  static const _folder = 'attachments';

  /// Where decrypted copies go while another app is showing them.
  static const _openFolder = 'elapsa-open';

  Future<Directory> _directory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, _folder));
  }

  File _fileFor(Directory dir, String documentId, String attachmentId) =>
      File(p.join(dir.path, '${documentId}_$attachmentId.enc'));

  Future<void> save(
    String documentId,
    String attachmentId,
    Uint8List bytes,
  ) async {
    final dir = await _directory();
    await _secure.writeEncrypted(_fileFor(dir, documentId, attachmentId), bytes);
  }

  Future<Uint8List?> load(String documentId, String attachmentId) async {
    final dir = await _directory();
    return _secure.readEncrypted(_fileFor(dir, documentId, attachmentId));
  }

  Future<void> delete(String documentId, String attachmentId) async {
    final file = _fileFor(await _directory(), documentId, attachmentId);
    if (await file.exists()) await file.delete();
  }

  /// Removes every file belonging to a document, found by scanning rather
  /// than from a stored list, so nothing outlives a deleted record.
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

  /// Writes a decrypted copy under its own name, for another app to open.
  ///
  /// The viewer reads the file after this returns, so it cannot be deleted
  /// here; instead every earlier copy is cleared first, and [clearOpened] runs
  /// when the screen that opened it goes away. A decrypted passport scan is
  /// never left behind longer than it is being looked at.
  Future<File?> decryptForViewing(
    String documentId,
    String attachmentId,
    String name,
  ) async {
    final bytes = await load(documentId, attachmentId);
    if (bytes == null) return null;
    await clearOpened();
    final dir = await _openDirectory();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, _safeName(name)));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> clearOpened() async {
    final dir = await _openDirectory();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<Directory> _openDirectory() async {
    final temp = await getTemporaryDirectory();
    return Directory(p.join(temp.path, _openFolder));
  }

  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[/\\:\x00]'), '_').trim();
    return cleaned.isEmpty ? 'attachment' : cleaned;
  }
}
