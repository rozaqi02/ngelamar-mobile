import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/job_application.dart';

class BackupException implements Exception {
  final String message;

  const BackupException(this.message);

  @override
  String toString() => message;
}

class BackupImportPayload {
  final List<JobApplication> jobs;
  final List<String> extractedAttachmentPaths;

  const BackupImportPayload({
    required this.jobs,
    required this.extractedAttachmentPaths,
  });
}

/// Creates and restores portable ZIP backups. The manifest is validated before
/// any data is returned, and archive paths are never written directly to disk.
class BackupService {
  static const schemaVersion = 3;
  static const _manifestName = 'backup.json';
  static const _maxArchiveBytes = 50 * 1024 * 1024;
  static const _maxAttachmentBytes = 10 * 1024 * 1024;
  static const _maxUncompressedBytes = 80 * 1024 * 1024;
  static const _maxJobs = 5000;

  static Future<File> createBackup(
    List<JobApplication> jobs, {
    required String password,
    Directory? outputDirectory,
  }) async {
    _validatePassword(password);
    final archive = Archive();
    final attachmentNames = <String, String>{};
    var attachmentBytes = 0;
    final serializedJobs = <Map<String, dynamic>>[];

    for (final job in jobs) {
      final record = job.toMap();
      final screenshotWasNew =
          job.screenshotPath != null &&
          !attachmentNames.containsKey(job.screenshotPath);
      record['screenshotPath'] = await _addAttachment(
        archive: archive,
        sourcePath: job.screenshotPath,
        kind: 'screenshots',
        jobId: job.id,
        attachmentNames: attachmentNames,
        attachmentBytes: attachmentBytes,
      );
      if (screenshotWasNew && record['screenshotPath'] != null) {
        attachmentBytes += archive.findFile(record['screenshotPath'])!.size;
      }
      final logoWasNew =
          job.companyLogoPath != null &&
          !attachmentNames.containsKey(job.companyLogoPath);
      record['companyLogoPath'] = await _addAttachment(
        archive: archive,
        sourcePath: job.companyLogoPath,
        kind: 'logos',
        jobId: job.id,
        attachmentNames: attachmentNames,
        attachmentBytes: attachmentBytes,
      );
      if (logoWasNew && record['companyLogoPath'] != null) {
        attachmentBytes += archive.findFile(record['companyLogoPath'])!.size;
      }
      serializedJobs.add(record);
    }

    final manifest = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'app': 'Ngelamar',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'jobs': serializedJobs,
    };
    archive.addFile(ArchiveFile.string(_manifestName, jsonEncode(manifest)));

    final encoded = Uint8List.fromList(
      ZipEncoder(password: password).encode(archive),
    );
    if (encoded.length > _maxArchiveBytes) {
      throw const BackupException(
        'Backup terlalu besar. Hapus atau perkecil lampiran sebelum mengekspor.',
      );
    }

    final temporaryDirectory = outputDirectory ?? await getTemporaryDirectory();
    final file = File(
      '${temporaryDirectory.path}/Ngelamar_Backup_${DateTime.now().millisecondsSinceEpoch}.zip',
    );
    await file.writeAsBytes(encoded, flush: true);
    return file;
  }

  static Future<BackupImportPayload> restoreFromBytes(
    Uint8List bytes, {
    String? password,
    Directory? appDirectory,
  }) async {
    if (bytes.isEmpty || bytes.length > _maxArchiveBytes) {
      throw const BackupException('Ukuran file backup tidak valid.');
    }
    if (isLegacyJsonBackup(bytes)) {
      return _restoreLegacyJson(bytes);
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(
        bytes,
        verify: true,
        password: password,
      );
    } catch (_) {
      throw const BackupException(
        'Backup tidak dapat dibuka. Periksa kata sandi atau pilih file ZIP Ngelamar yang valid.',
      );
    }

    if (archive.length > _maxJobs + 1) {
      throw const BackupException('Backup memuat terlalu banyak file.');
    }
    final totalUncompressed = archive.fold<int>(
      0,
      (total, file) => total + file.size,
    );
    if (totalUncompressed > _maxUncompressedBytes) {
      throw const BackupException('Isi backup terlalu besar untuk dipulihkan.');
    }

    final manifestFile = archive.findFile(_manifestName);
    if (manifestFile == null || !manifestFile.isFile) {
      throw const BackupException('Manifest backup tidak ditemukan.');
    }

    Map<String, dynamic> manifest;
    try {
      final decoded = jsonDecode(utf8.decode(manifestFile.content));
      if (decoded is! Map) throw const FormatException();
      manifest = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw const BackupException(
        'Manifest backup tidak dapat dibaca. Periksa kata sandi backup.',
      );
    }

    final backupSchemaVersion = manifest['schemaVersion'];
    if (backupSchemaVersion != 2 && backupSchemaVersion != schemaVersion) {
      throw const BackupException('Versi backup ini belum didukung.');
    }
    final rawJobs = manifest['jobs'];
    if (rawJobs is! List || rawJobs.length > _maxJobs) {
      throw const BackupException('Daftar lamaran dalam backup tidak valid.');
    }

    final attachments = {
      for (final entry in archive)
        if (entry.isFile && entry.name.startsWith('attachments/'))
          entry.name: entry,
    };
    final restoredPaths = <String>[];
    final jobs = <JobApplication>[];

    try {
      for (final rawJob in rawJobs) {
        final decodedJob = backupSchemaVersion == 2 && rawJob is String
            ? jsonDecode(rawJob)
            : rawJob;
        if (decodedJob is! Map) {
          throw const BackupException('Salah satu data lamaran tidak valid.');
        }
        final record = Map<String, dynamic>.from(decodedJob);
        _validateJobRecord(record);
        record['screenshotPath'] = await _restoreAttachment(
          attachmentReference: record['screenshotPath']?.toString(),
          expectedKind: 'screenshots',
          attachments: attachments,
          restoredPaths: restoredPaths,
          appDirectory: appDirectory,
        );
        record['companyLogoPath'] = await _restoreAttachment(
          attachmentReference: record['companyLogoPath']?.toString(),
          expectedKind: 'logos',
          attachments: attachments,
          restoredPaths: restoredPaths,
          appDirectory: appDirectory,
        );
        jobs.add(JobApplication.fromMap(record));
      }
    } catch (error) {
      for (final path in restoredPaths) {
        try {
          await File(path).delete();
        } catch (_) {
          // Continue cleaning the remaining temporary attachments.
        }
      }
      if (error is BackupException) rethrow;
      throw const BackupException(
        'Isi backup tidak dapat dibaca. Periksa kata sandi backup.',
      );
    }

    return BackupImportPayload(
      jobs: jobs,
      extractedAttachmentPaths: restoredPaths,
    );
  }

  /// Ngelamar 2.1.0 exported its backup as a plain JSON document. This is
  /// retained only for one-way compatibility; new exports are encrypted ZIPs.
  static bool isLegacyJsonBackup(Uint8List bytes) {
    for (final byte in bytes) {
      if (byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D) {
        continue;
      }
      return byte == 0x7B; // {
    }
    return false;
  }

  static BackupImportPayload _restoreLegacyJson(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException();
      final manifest = Map<String, dynamic>.from(decoded);
      if (manifest['schemaVersion'] != 2 || manifest['jobs'] is! List) {
        throw const FormatException();
      }
      final rawJobs = manifest['jobs'] as List;
      if (rawJobs.length > _maxJobs) throw const FormatException();

      final jobs = <JobApplication>[];
      for (final rawJob in rawJobs) {
        final decodedJob = rawJob is String ? jsonDecode(rawJob) : rawJob;
        if (decodedJob is! Map) throw const FormatException();
        final record = Map<String, dynamic>.from(decodedJob);
        _validateJobRecord(record);
        // JSON v2 never contained managed attachments. Ignore arbitrary paths
        // rather than restoring references outside this app's storage.
        record['screenshotPath'] = null;
        record['companyLogoPath'] = null;
        jobs.add(JobApplication.fromMap(record));
      }
      return BackupImportPayload(
        jobs: jobs,
        extractedAttachmentPaths: const [],
      );
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException('Backup JSON lama tidak valid.');
    }
  }

  static Future<String?> _addAttachment({
    required Archive archive,
    required String? sourcePath,
    required String kind,
    required String jobId,
    required Map<String, String> attachmentNames,
    required int attachmentBytes,
  }) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final alreadyAdded = attachmentNames[sourcePath];
    if (alreadyAdded != null) return alreadyAdded;

    final source = File(sourcePath);
    if (!await source.exists()) return null;
    final length = await source.length();
    if (length <= 0 || length > _maxAttachmentBytes) return null;
    if (attachmentBytes + length > _maxArchiveBytes) {
      throw const BackupException('Total ukuran lampiran terlalu besar.');
    }

    final extension = _safeExtension(sourcePath);
    final archiveName =
        'attachments/$kind/${_safeFilePart(jobId)}_${attachmentNames.length}$extension';
    archive.addFile(ArchiveFile.bytes(archiveName, await source.readAsBytes()));
    attachmentNames[sourcePath] = archiveName;
    return archiveName;
  }

  static Future<String?> _restoreAttachment({
    required String? attachmentReference,
    required String expectedKind,
    required Map<String, ArchiveFile> attachments,
    required List<String> restoredPaths,
    Directory? appDirectory,
  }) async {
    if (attachmentReference == null || attachmentReference.isEmpty) {
      return null;
    }
    final prefix = 'attachments/$expectedKind/';
    if (!attachmentReference.startsWith(prefix) ||
        attachmentReference.contains('..')) {
      throw const BackupException('Path lampiran dalam backup tidak aman.');
    }
    final entry = attachments[attachmentReference];
    if (entry == null || entry.size > _maxAttachmentBytes) {
      throw const BackupException(
        'Lampiran backup tidak valid atau terlalu besar.',
      );
    }
    final content = entry.readBytes();
    if (content == null) {
      throw const BackupException('Lampiran backup tidak dapat dibaca.');
    }

    final targetAppDirectory =
        appDirectory ?? await getApplicationDocumentsDirectory();
    final destinationDirectory = Directory(
      '${targetAppDirectory.path}/$expectedKind',
    );
    if (!await destinationDirectory.exists()) {
      await destinationDirectory.create(recursive: true);
    }
    final destination = File(
      '${destinationDirectory.path}/${DateTime.now().microsecondsSinceEpoch}_${_safeFilePart(attachmentReference.split('/').last)}',
    );
    await destination.writeAsBytes(content, flush: true);
    restoredPaths.add(destination.path);
    return destination.path;
  }

  static String _safeExtension(String sourcePath) {
    final match = RegExp(
      r'\.(jpg|jpeg|png|webp)$',
      caseSensitive: false,
    ).firstMatch(sourcePath);
    return match == null ? '.bin' : '.${match.group(1)!.toLowerCase()}';
  }

  static String _safeFilePart(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  static void _validatePassword(String password) {
    if (password.trim().length < 12) {
      throw const BackupException(
        'Gunakan kata sandi backup minimal 12 karakter.',
      );
    }
  }

  static void _validateJobRecord(Map<String, dynamic> record) {
    final id = record['id']?.toString().trim() ?? '';
    final company = record['companyName']?.toString().trim() ?? '';
    final position = record['position']?.toString().trim() ?? '';
    if (id.isEmpty || company.isEmpty || position.isEmpty) {
      throw const BackupException('Backup memiliki lamaran tanpa data wajib.');
    }
    if (id.length > 120 || company.length > 160 || position.length > 160) {
      throw const BackupException('Salah satu data lamaran terlalu panjang.');
    }
  }
}
