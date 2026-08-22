import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Opens the application database with an AES key protected by the operating
/// system's secure storage. Existing plain-text data is copied first and the
/// old box is deleted only after the encrypted replacement is flushed.
class SecureHiveService {
  static const jobsBoxName = 'ngelamar_jobs_box_secure_v1';
  static const _legacyJobsBoxName = 'ngelamar_jobs_box';
  static const _encryptionKeyName = 'ngelamar_hive_aes_key_v1';
  static const _migrationMarkerName = 'ngelamar_hive_migrated_v1';

  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<Box<String>> openJobsBox() async {
    final key = await _loadOrCreateEncryptionKey();
    final migrated =
        await _secureStorage.read(key: _migrationMarkerName) == 'complete';

    if (migrated) {
      return Hive.openBox<String>(
        jobsBoxName,
        encryptionCipher: HiveAesCipher(key),
      );
    }

    final legacyExists = await Hive.boxExists(_legacyJobsBoxName);
    final encryptedExists = await Hive.boxExists(jobsBoxName);

    if (legacyExists) {
      // A previous interrupted migration may have left an incomplete encrypted
      // box. The unencrypted source is still authoritative until the marker is
      // written, so it is safe to recreate the destination.
      if (encryptedExists) {
        await Hive.deleteBoxFromDisk(jobsBoxName);
      }

      final legacyBox = await Hive.openBox<String>(_legacyJobsBoxName);
      final legacyEntries = <String, String>{};
      for (final legacyKey in legacyBox.keys) {
        final value = legacyBox.get(legacyKey);
        if (value != null) {
          legacyEntries[legacyKey.toString()] = value;
        }
      }
      await legacyBox.close();

      final encryptedBox = await Hive.openBox<String>(
        jobsBoxName,
        encryptionCipher: HiveAesCipher(key),
      );
      try {
        await encryptedBox.putAll(legacyEntries);
        await encryptedBox.flush();
        await Hive.deleteBoxFromDisk(_legacyJobsBoxName);
      } catch (_) {
        await encryptedBox.close();
        rethrow;
      }

      await _secureStorage.write(key: _migrationMarkerName, value: 'complete');
      return encryptedBox;
    }

    final encryptedBox = await Hive.openBox<String>(
      jobsBoxName,
      encryptionCipher: HiveAesCipher(key),
    );
    await _secureStorage.write(key: _migrationMarkerName, value: 'complete');
    return encryptedBox;
  }

  static Future<List<int>> _loadOrCreateEncryptionKey() async {
    final encodedKey = await _secureStorage.read(key: _encryptionKeyName);
    if (encodedKey != null) {
      final key = base64Url.decode(encodedKey);
      if (key.length == 32) return key;
      throw StateError('Kunci enkripsi data lokal tidak valid.');
    }

    final newKey = Hive.generateSecureKey();
    await _secureStorage.write(
      key: _encryptionKeyName,
      value: base64UrlEncode(newKey),
    );
    return newKey;
  }
}
