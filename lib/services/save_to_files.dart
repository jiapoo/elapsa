import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:elapsa/l10n/app_localizations.dart';

/// Hands [bytes] to the system's "save to Files" picker and returns where the
/// user put them, or null if they backed out.
///
/// The picker plugin stages the file in the app's own Documents folder before
/// the system copies it out, and never removes it. Left there it is a plain,
/// unencrypted copy of somebody's passport sitting beside the encrypted
/// database, so it is deleted here however the picker ends.
Future<String?> saveBytesToFiles({
  required String fileName,
  required Uint8List bytes,
  FileType type = FileType.any,
}) async {
  try {
    return await FilePicker.platform.saveFile(
      fileName: fileName,
      type: type,
      bytes: bytes,
    );
  } finally {
    await _removeStagedCopy(fileName);
  }
}

Future<void> _removeStagedCopy(String fileName) async {
  // Never anything but the file just staged: the database lives in the same
  // folder, and a careless name here would be a very bad day.
  if (fileName != p.basename(fileName) || fileName.endsWith('.sqlite')) return;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final staged = File(p.join(dir.path, fileName));
    if (await staged.exists()) await staged.delete();
  } catch (_) {
    // Nothing useful to tell the user; the next save of the same name
    // overwrites it anyway.
  }
}

/// Turns a path the picker returned into the words the Files app uses.
///
/// "/private/var/mobile/…/File Provider Storage/Downloads/x.elapsa" means
/// nothing to anyone holding the phone; "On My iPhone › Downloads" is where
/// they will actually tap.
List<String> filesLocation(String path, L l) {
  const onMyPhone = '/File Provider Storage/';
  const iCloud = '/Mobile Documents/com~apple~CloudDocs/';

  List<String> under(String root, String marker) => [
    root,
    ...path
        .substring(path.indexOf(marker) + marker.length)
        .split('/')
        .where((part) => part.isNotEmpty),
  ];

  if (path.contains(onMyPhone)) return under(l.filesOnMyPhone, onMyPhone);
  if (path.contains(iCloud)) return under(l.filesIcloudDrive, iCloud);

  // Somewhere else — another app's folder, a cloud provider. The folder and
  // the name are still the two things worth knowing.
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  return parts.length >= 2 ? parts.sublist(parts.length - 2) : parts;
}
