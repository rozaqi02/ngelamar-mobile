import 'dart:async';
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
  final int offeringCount;
  final String responseRate;
  final String timeBadge;
  final String stageLabel;
  final String companyName;
  final String position;
  final String actionNote;
  final String monthLabel;
  final int agendaCount;
  final String event1Title;
  final String event1When;
  final String event2Title;
  final String event2When;
  final String event3Title;
  final String event3When;

  const AndroidWidgetProjection({
    required this.kind,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.jobId,
    required this.activeCount,
    required this.hasContent,
    this.offeringCount = 0,
    this.responseRate = '0%',
    this.timeBadge = 'Jadwal Seleksi',
    this.stageLabel = '',
    this.companyName = '',
    this.position = '',
    this.actionNote = 'Pantau terus kabar rekrutmen terbaru.',
    this.monthLabel = 'KALENDER',
    this.agendaCount = 0,
    this.event1Title = '',
    this.event1When = '',
    this.event2Title = '',
    this.event2When = '',
    this.event3Title = '',
    this.event3When = '',
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
    offeringCount: 0,
    responseRate: '0%',
    timeBadge: '',
    stageLabel: '',
    companyName: '',
    position: '',
    actionNote: 'Pantau terus kabar rekrutmen terbaru.',
    monthLabel: 'KALENDER',
    agendaCount: 0,
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
    'offeringCount': offeringCount,
    'responseRate': responseRate,
    'timeBadge': timeBadge,
    'stageLabel': stageLabel,
    'companyName': companyName,
    'position': position,
    'actionNote': actionNote,
    'monthLabel': monthLabel,
    'agendaCount': agendaCount,
    'event1Title': event1Title,
    'event1When': event1When,
    'event2Title': event2Title,
    'event2When': event2When,
    'event3Title': event3Title,
    'event3When': event3When,
  };
}

/// Keeps the Android widget useful even while the Flutter engine is not alive.
/// Only a compact display projection is written to Android SharedPreferences;
/// the user's encrypted tracker database is never shared with the widget.
class AndroidHomeWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.ngelamar.app.ngelamar/home_widget',
  );
  static final StreamController<Map<String, dynamic>> _launchController =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _launchHandlerAttached = false;

  static Stream<Map<String, dynamic>> get launchEvents {
    _attachLaunchHandler();
    return _launchController.stream;
  }

  static void _attachLaunchHandler() {
    if (_launchHandlerAttached || kIsWeb || !Platform.isAndroid) return;
    _launchHandlerAttached = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'launchDataChanged') return;
      final args = call.arguments;
      if (args is Map) {
        _launchController.add(Map<String, dynamic>.from(args));
      }
    });
  }

  static Future<Map<String, dynamic>?> getInitialLaunchData() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    _attachLaunchHandler();
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'getInitialLaunchData',
      );
      return res;
    } catch (e) {
      debugPrint('Gagal membaca data peluncuran widget: $e');
      return null;
    }
  }

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
        .where(
          (job) =>
              !job.isSampleData &&
              job.status != 'Diterima' &&
              job.status != 'Ditolak' &&
              job.status != 'Dibatalkan',
        )
        .toList(growable: false);
    final scheduled = <_WidgetCandidate>[];

    final offeringCount = jobs.where((j) => j.status == 'Offering').length;
    final appliedJobs = jobs.where((j) => j.isApplied).toList();
    final respondedCount = appliedJobs
        .where((j) => j.status != 'Dikirim')
        .length;
    final responseRate = appliedJobs.isNotEmpty
        ? '${((respondedCount / appliedJobs.length) * 100).round()}%'
        : '0%';

    for (final job in jobs) {
      final interviewAt = job.interviewDate ?? job.testDate;
      final isSelection =
          job.status == 'Tes / Psikotes' || job.status.startsWith('Interview');
      if (isSelection && interviewAt != null && interviewAt.isAfter(now)) {
        final timeBadge = _formatTimeBadge(interviewAt, now: now);
        final loc = (job.location?.trim().isNotEmpty == true)
            ? job.location!.trim()
            : (job.workType == 'WFH' || job.workType == 'Hybrid'
                  ? 'Google Meet / Online'
                  : 'Lokasi Kantor');
        scheduled.add(
          _WidgetCandidate(
            job: job,
            dueAt: interviewAt,
            kind: 'interview',
            label: job.status == 'Tes / Psikotes'
                ? 'PENGINGAT TES'
                : 'PENGINGAT INTERVIEW',
            title: '${job.status} / ${_formatWhen(interviewAt)}',
            detail: loc,
            timeBadge: timeBadge,
            stageLabel: job.status,
          ),
        );
      }
      if (job.hasNextAction && job.nextActionAt!.isAfter(now)) {
        final timeBadge = _formatTimeBadge(job.nextActionAt!, now: now);
        scheduled.add(
          _WidgetCandidate(
            job: job,
            dueAt: job.nextActionAt!,
            kind: 'action',
            label: 'TINDAKAN BERIKUTNYA',
            title: '${job.nextActionType} / ${_formatWhen(job.nextActionAt!)}',
            detail: job.nextActionNote?.trim().isNotEmpty == true
                ? _shorten(job.nextActionNote!)
                : 'Ada langkah lanjutan yang perlu dikerjakan.',
            timeBadge: timeBadge,
            stageLabel: job.nextActionType ?? 'Tindak Lanjut',
          ),
        );
      }
    }

    // Determine latest actionable note
    String actionNote = 'Pantau terus kabar rekrutmen terbaru.';
    final actionJob = jobs
        .where((j) => j.hasNextAction && j.nextActionAt != null)
        .toList();
    if (actionJob.isNotEmpty) {
      actionJob.sort((a, b) => a.nextActionAt!.compareTo(b.nextActionAt!));
      final next = actionJob.first;
      if (next.nextActionNote?.trim().isNotEmpty == true) {
        actionNote = _shorten(
          '${next.companyName}: ${next.nextActionNote!.trim()}',
          limit: 60,
        );
      }
    }

    scheduled.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final monthLabel = '${_monthName(now.month).toUpperCase()} ${now.year}';
    final agendaCount = scheduled.length;
    String event1Title = '';
    String event1When = '';
    String event2Title = '';
    String event2When = '';
    String event3Title = '';
    String event3When = '';
    if (scheduled.isNotEmpty) {
      event1Title =
          '${scheduled[0].job.companyName} · ${scheduled[0].stageLabel}';
      event1When = scheduled[0].timeBadge;
    }
    if (scheduled.length > 1) {
      event2Title =
          '${scheduled[1].job.companyName} · ${scheduled[1].stageLabel}';
      event2When = scheduled[1].timeBadge;
    }
    if (scheduled.length > 2) {
      event3Title =
          '${scheduled[2].job.companyName} · ${scheduled[2].stageLabel}';
      event3When = scheduled[2].timeBadge;
    }
    if (scheduled.isNotEmpty) {
      final item = scheduled.first;
      return AndroidWidgetProjection(
        kind: item.kind,
        label: item.label,
        title: _shorten(item.title, limit: 72),
        subtitle: _shorten('${item.job.companyName} / ${item.job.position}'),
        detail: item.detail,
        jobId: item.job.id,
        activeCount: scheduled.length,
        hasContent: true,
        offeringCount: offeringCount,
        responseRate: responseRate,
        timeBadge: item.timeBadge,
        stageLabel: item.stageLabel,
        companyName: item.job.companyName,
        position: item.job.position,
        actionNote: actionNote,
        monthLabel: monthLabel,
        agendaCount: agendaCount,
        event1Title: event1Title,
        event1When: event1When,
        event2Title: event2Title,
        event2When: event2When,
        event3Title: event3Title,
        event3When: event3When,
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
        subtitle: _shorten('${noteJob.companyName} / ${noteJob.position}'),
        detail: 'Catatan terakhir disimpan ${_formatWhen(noteJob.updatedAt)}.',
        jobId: noteJob.id,
        activeCount: jobs.length,
        hasContent: true,
        offeringCount: offeringCount,
        responseRate: responseRate,
        timeBadge: 'Catatan',
        stageLabel: noteJob.status,
        companyName: noteJob.companyName,
        position: noteJob.position,
        actionNote: actionNote,
        monthLabel: monthLabel,
        agendaCount: agendaCount,
        event1Title: event1Title,
        event1When: event1When,
        event2Title: event2Title,
        event2When: event2When,
        event3Title: event3Title,
        event3When: event3When,
      );
    }

    if (jobs.isNotEmpty) {
      final latestJob = jobs.reduce(
        (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
      );
      return AndroidWidgetProjection(
        kind: 'active',
        label: 'LAMARAN AKTIF',
        title: _shorten('${latestJob.companyName} - ${latestJob.position}'),
        subtitle: _shorten('${latestJob.companyName} / ${latestJob.position}'),
        detail: 'Status: ${latestJob.status}',
        jobId: latestJob.id,
        activeCount: jobs.length,
        hasContent: true,
        offeringCount: offeringCount,
        responseRate: responseRate,
        timeBadge: latestJob.status,
        stageLabel: latestJob.status,
        companyName: latestJob.companyName,
        position: latestJob.position,
        actionNote: actionNote,
        monthLabel: monthLabel,
        agendaCount: agendaCount,
        event1Title: event1Title,
        event1When: event1When,
        event2Title: event2Title,
        event2When: event2When,
        event3Title: event3Title,
        event3When: event3When,
      );
    }

    return AndroidWidgetProjection.empty();
  }

  static String _formatTimeBadge(DateTime date, {required DateTime now}) {
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;

    final hourStr = date.hour.toString().padLeft(2, '0');
    final minStr = date.minute.toString().padLeft(2, '0');

    if (isToday) return 'Hari ini, $hourStr:$minStr WIB';
    if (isTomorrow) return 'Besok, $hourStr:$minStr WIB';
    return '${_weekdayName(date.weekday)}, ${date.day} ${_monthName(date.month)}';
  }

  static String _weekdayName(int weekday) {
    const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return weekdays[(weekday - 1).clamp(0, 6)];
  }

  static String _monthName(int month) {
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
    return months[(month - 1).clamp(0, 11)];
  }

  static String _formatWhen(DateTime date) {
    final w = _weekdayName(date.weekday);
    final m = _monthName(date.month);
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$w, ${date.day} $m $h:$min';
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
  final String timeBadge;
  final String stageLabel;

  const _WidgetCandidate({
    required this.job,
    required this.dueAt,
    required this.kind,
    required this.label,
    required this.title,
    required this.detail,
    required this.timeBadge,
    required this.stageLabel,
  });
}
