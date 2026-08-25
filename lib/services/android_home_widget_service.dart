import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/job_application.dart';

/// The deliberately small data contract exposed to Android's home-screen
/// widget. The encrypted Hive store remains private to Flutter; Android only
/// receives the single most useful reminder and a short, user-visible note.
class AndroidWidgetProjection {
  final String kind;
  final String label;
  final String title;
  final String subtitle;
  final String detail;
  final String jobId;
  final int activeCount;
  final bool hasContent;

  const AndroidWidgetProjection({
    required this.kind,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.jobId,
    required this.activeCount,
    required this.hasContent,
  });

  factory AndroidWidgetProjection.empty() => const AndroidWidgetProjection(
    kind: 'empty',
    label: 'NGELAMAR',
    title: 'Semua pengingat aman',
    subtitle: 'Belum ada interview atau tindakan yang akan datang.',
    detail: 'Buka Ngelamar untuk mencatat lamaran atau catatan baru.',
    jobId: '',
    activeCount: 0,
    hasContent: false,
  );

  Map<String, Object> toMap() => {
    'kind': kind,
    'label': label,
    'title': title,
    'subtitle': subtitle,
    'detail': detail,
    'jobId': jobId,
    'activeCount': activeCount,
    'hasContent': hasContent,
  };
}

/// Keeps the Android widget useful even while the Flutter engine is not alive.
/// Only a compact display projection is written to Android SharedPreferences;
/// the user's encrypted tracker database is never shared with the widget.
class AndroidHomeWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.ngelamar.app.ngelamar/home_widget',
  );

  static Future<void> syncJobs(Iterable<JobApplication> jobs) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final projection = buildProjection(jobs, now: DateTime.now());
      await _channel.invokeMethod<void>('syncWidgetData', projection.toMap());
    } on PlatformException catch (error) {
      debugPrint('Sinkronisasi widget Android gagal: ${error.message}');
    } catch (error) {
      debugPrint('Sinkronisasi widget Android gagal: $error');
    }
  }

  @visibleForTesting
  static AndroidWidgetProjection buildProjection(
    Iterable<JobApplication> source, {
    required DateTime now,
  }) {
    final jobs = source
        .where((job) => job.status != 'Diterima' && job.status != 'Ditolak')
        .toList(growable: false);
    final scheduled = <_WidgetCandidate>[];

    for (final job in jobs) {
      final interviewAt = job.interviewDate ?? job.testDate;
      final isSelection =
          job.status == 'Tes / Psikotes' || job.status.startsWith('Interview');
      if (isSelection && interviewAt != null && interviewAt.isAfter(now)) {
        scheduled.add(
          _WidgetCandidate(
            job: job,
            dueAt: interviewAt,
            kind: 'interview',
            label: job.status == 'Tes / Psikotes'
                ? 'PENGINGAT TES'
                : 'PENGINGAT INTERVIEW',
            title: '${job.status} • ${_formatWhen(interviewAt)}',
            detail: job.notes?.trim().isNotEmpty == true
                ? _shorten(job.notes!)
                : 'Siapkan berkas dan catatan pentingmu.',
          ),
        );
      }
      if (job.hasNextAction && job.nextActionAt!.isAfter(now)) {
        scheduled.add(
          _WidgetCandidate(
            job: job,
            dueAt: job.nextActionAt!,
            kind: 'action',
            label: 'TINDAKAN BERIKUTNYA',
            title: '${job.nextActionType} • ${_formatWhen(job.nextActionAt!)}',
            detail: job.nextActionNote?.trim().isNotEmpty == true
                ? _shorten(job.nextActionNote!)
                : 'Ada langkah lanjutan yang perlu dikerjakan.',
          ),
        );
      }
    }

    scheduled.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    if (scheduled.isNotEmpty) {
      final item = scheduled.first;
      return AndroidWidgetProjection(
        kind: item.kind,
        label: item.label,
        title: _shorten(item.title, limit: 72),
        subtitle: _shorten('${item.job.companyName} · ${item.job.position}'),
        detail: item.detail,
        jobId: item.job.id,
        activeCount: scheduled.length,
        hasContent: true,
      );
    }

    final noteJob = jobs
        .where((job) => job.notes?.trim().isNotEmpty == true)
        .fold<JobApplication?>(null, (latest, job) {
          if (latest == null || job.updatedAt.isAfter(latest.updatedAt)) {
            return job;
          }
          return latest;
        });
    if (noteJob != null) {
      return AndroidWidgetProjection(
        kind: 'note',
        label: 'CATATAN LAMARAN',
        title: _shorten(noteJob.notes!),
        subtitle: _shorten('${noteJob.companyName} · ${noteJob.position}'),
        detail: 'Catatan terakhir disimpan ${_formatWhen(noteJob.updatedAt)}.',
        jobId: noteJob.id,
        activeCount: 1,
        hasContent: true,
      );
    }
    return AndroidWidgetProjection.empty();
  }

  static String _formatWhen(DateTime date) {
    const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _shorten(String value, {int limit = 108}) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= limit) return clean;
    return '${clean.substring(0, limit - 1).trimRight()}…';
  }
}

class _WidgetCandidate {
  final JobApplication job;
  final DateTime dueAt;
  final String kind;
  final String label;
  final String title;
  final String detail;

  const _WidgetCandidate({
    required this.job,
    required this.dueAt,
    required this.kind,
    required this.label,
    required this.title,
    required this.detail,
  });
}
