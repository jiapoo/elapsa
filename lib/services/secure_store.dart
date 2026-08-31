import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the single key that protects everything Elapsa stores.
///
/// The key itself lives in the iOS Keychain / Android Keystore — hardware
/// backed where the device offers it — and never touches the filesystem. It is
/// generated once on first launch and reused thereafter.
///
/// One key for both the database and the document photos is deliberate. Two
/// key stores means two chances to get key rotation, backup and deletion
/// wrong, and there is no threat model where a passport scan deserves weaker
/// protection than the passport number typed next to it.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                // Never leaves this device and never goes to iCloud Keychain.
                // A synced key would silently widen the blast radius of the
                // "nothing leaves your device" promise.
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _keyName = 'elapsa_master_key_v1';
  static const _keyLengthBytes = 32; // AES-256

  final _cipher = AesGcm.with256bits();
  Uint8List? _cached;

  /// The master key, generated on first use.
  Future<Uint8List> masterKey() async {
    final cached = _cached;
    if (cached != null) return cached;

    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      return _cached = Uint8List.fromList(base64Decode(existing));
    }

    final random = Random.secure();
    final fresh = Uint8List.fromList(
      List<int>.generate(_keyLengthBytes, (_) => random.nextInt(256)),
    );
    await _storage.write(key: _keyName, value: base64Encode(fresh));
    return _cached = fresh;
  }

  /// The database passphrase, derived from the master key.
  ///
  /// SQLCipher wants a string, so this is the key in base64 rather than a
  /// second independent secret.
  Future<String> databasePassphrase() async =>
      base64Encode(await masterKey());

  /// Encrypts [plaintext] and writes it to [file].
  ///
  /// Layout is `nonce (12 bytes) | ciphertext | MAC (16 bytes)`. The nonce is
  /// random per write, so re-saving the same image never produces the same
  /// bytes on disk.
  Future<void> writeEncrypted(File file, List<int> plaintext) async {
    final key = await _cipher.newSecretKeyFromBytes(await masterKey());
    final box = await _cipher.encrypt(plaintext, secretKey: key);

    await file.parent.create(recursive: true);
    await file.writeAsBytes(
      Uint8List.fromList([...box.nonce, ...box.cipherText, ...box.mac.bytes]),
      flush: true,
    );
  }

  /// Reads and decrypts a file written by [writeEncrypted].
  ///
  /// Returns null when the file is missing or fails authentication — a
  /// tampered or truncated file is treated as absent rather than surfaced as a
  /// crash, because there is nothing the user can do about it either way.
  Future<Uint8List?> readEncrypted(File file) async {
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    const nonceLength = 12;
    const macLength = 16;
    if (bytes.length < nonceLength + macLength) return null;

    final box = SecretBox(
      bytes.sublist(nonceLength, bytes.length - macLength),
      nonce: bytes.sublist(0, nonceLength),
      mac: Mac(bytes.sublist(bytes.length - macLength)),
    );

    try {
      final key = await _cipher.newSecretKeyFromBytes(await masterKey());
      return Uint8List.fromList(await _cipher.decrypt(box, secretKey: key));
    } on SecretBoxAuthenticationError {
      return null;
    }
  }
}
