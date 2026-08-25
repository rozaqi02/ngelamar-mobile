import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class CloudBackupInfo {
  final String id;
  final String objectPath;
  final int bytes;
  final String appVersion;
  final DateTime createdAt;

  const CloudBackupInfo({
    required this.id,
    required this.objectPath,
    required this.bytes,
    required this.appVersion,
    required this.createdAt,
  });

  factory CloudBackupInfo.fromMap(Map<String, dynamic> map) => CloudBackupInfo(
    id: map['id'].toString(),
    objectPath: map['object_path'].toString(),
    bytes: (map['bytes'] as num?)?.toInt() ?? 0,
    appVersion: map['app_version']?.toString() ?? '',
    createdAt:
        DateTime.tryParse(map['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Optional encrypted cloud backup. The app uploads the ZIP produced by
/// BackupService as-is; its password is never sent to Supabase or retained.
class CloudSyncService {
  static const _backupBucket = 'cloud-backups';
  static const _documentsBucket = 'user-documents';

  static Future<CloudBackupInfo> uploadEncryptedBackup(
    File backupFile, {
    required String appVersion,
  }) async {
    final user = await SupabaseService.ensureAuthenticated();
    final bytes = await backupFile.readAsBytes();
    if (bytes.isEmpty || bytes.length > 104857600) {
      throw const FileSystemException('Ukuran backup cloud tidak valid.');
    }
    final objectPath =
        '${user.id}/backups/${DateTime.now().millisecondsSinceEpoch}.zip';
    await SupabaseService.client.storage
        .from(_backupBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/zip',
            upsert: false,
          ),
        );
    try {
      final row = await SupabaseService.client
          .from('cloud_backups')
          .insert({
            'user_id': user.id,
            'object_path': objectPath,
            'bytes': bytes.length,
            'app_version': appVersion,
          })
          .select()
          .single();
      return CloudBackupInfo.fromMap(row);
    } catch (_) {
      await SupabaseService.client.storage.from(_backupBucket).remove([
        objectPath,
      ]);
      rethrow;
    }
  }

  static Future<List<CloudBackupInfo>> listBackups() async {
    final user = await SupabaseService.ensureAuthenticated();
    final rows = await SupabaseService.client
        .from('cloud_backups')
        .select('id, object_path, bytes, app_version, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(20);
    return rows
        .map((row) => CloudBackupInfo.fromMap(row))
        .toList(growable: false);
  }

  static Future<Uint8List> downloadBackup(CloudBackupInfo backup) async {
    await SupabaseService.ensureAuthenticated();
    return SupabaseService.client.storage
        .from(_backupBucket)
        .download(backup.objectPath);
  }

  static Future<void> deleteBackup(CloudBackupInfo backup) async {
    await SupabaseService.ensureAuthenticated();
    await SupabaseService.client.storage.from(_backupBucket).remove([
      backup.objectPath,
    ]);
    await SupabaseService.client
        .from('cloud_backups')
        .delete()
        .eq('id', backup.id);
  }

  static Future<void> uploadCv(File file) async {
    final user = await SupabaseService.ensureAuthenticated();
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 20971520) {
      throw const FileSystemException('Ukuran CV maksimal 20 MB.');
    }
    final objectPath = '${user.id}/cv/cv.pdf';
    await SupabaseService.client.storage
        .from(_documentsBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );
    await SupabaseService.client.from('user_documents').upsert({
      'user_id': user.id,
      'kind': 'cv',
      'object_path': objectPath,
      'file_name': 'cv.pdf',
      'bytes': bytes.length,
    }, onConflict: 'user_id,kind');
  }

  static Future<Uint8List?> downloadCv() async {
    final user = await SupabaseService.ensureAuthenticated();
    final row = await SupabaseService.client
        .from('user_documents')
        .select('object_path')
        .eq('user_id', user.id)
        .eq('kind', 'cv')
        .maybeSingle();
    if (row == null) return null;
    return SupabaseService.client.storage
        .from(_documentsBucket)
        .download(row['object_path'].toString());
  }

  static Future<void> syncPreferences(Map<String, Object?> payload) async {
    final user = await SupabaseService.ensureAuthenticated();
    await SupabaseService.client.from('user_preferences').upsert({
      'user_id': user.id,
      'payload': payload,
    }, onConflict: 'user_id');
  }

  /// Returns only the current user's cloud preferences. Callers decide whether
  /// they want to merge or replace local values, preventing a silent overwrite.
  static Future<Map<String, dynamic>?> fetchPreferences() async {
    final user = await SupabaseService.ensureAuthenticated();
    final row = await SupabaseService.client
        .from('user_preferences')
        .select('payload')
        .eq('user_id', user.id)
        .maybeSingle();
    final payload = row?['payload'];
    if (payload is! Map) return null;
    return Map<String, dynamic>.from(payload);
  }
}
