import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/l10n/app_localizations_en.dart';
import 'package:elapsa/services/save_to_files.dart';

void main() {
  final l = LEn();

  test('a folder on the phone reads as the Files app names it', () {
    expect(
      filesLocation(
        '/private/var/mobile/Containers/Shared/AppGroup/ABC/'
        'File Provider Storage/Downloads/elapsa-2026-11-20.elapsa',
        l,
      ),
      ['On My iPhone', 'Downloads', 'elapsa-2026-11-20.elapsa'],
    );
  });

  test('iCloud Drive reads as iCloud Drive', () {
    expect(
      filesLocation(
        '/private/var/mobile/Library/Mobile Documents/com~apple~CloudDocs/'
        'Backups/elapsa.elapsa',
        l,
      ),
      ['iCloud Drive', 'Backups', 'elapsa.elapsa'],
    );
  });

  test('anywhere else keeps the folder and the name', () {
    expect(
      filesLocation('/somewhere/Provider/Shared/elapsa.elapsa', l),
      ['Shared', 'elapsa.elapsa'],
    );
  });
}
