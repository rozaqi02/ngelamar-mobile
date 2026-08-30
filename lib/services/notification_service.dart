import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/job_application.dart';

/// Local notification service for interview reminders & follow-up alerts.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static const _channelId = 'ngelamar_interview_reminders';
  static const _notificationIdPrefix = 100000000;
  static const _nextActionNotificationIdPrefix = 900000000;
  static final StreamController<NotificationActionEvent> _actionController =
      StreamController<NotificationActionEvent>.broadcast();
  static final List<NotificationActionEvent> _pendingActions = [];

  static Stream<NotificationActionEvent> get actionEvents =>
      _actionController.stream;

  static List<NotificationActionEvent> drainPendingActions() {
    final result = List<NotificationActionEvent>.from(_pendingActions);
    _pendingActions.clear();
    return result;
  }

  static void acknowledgeAction(NotificationActionEvent event) {
    _pendingActions.removeWhere(
      (pending) =>
          pending.jobId == event.jobId && pending.actionId == event.actionId,
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final jobId = response.payload?.trim() ?? '';
    if (jobId.isEmpty || response.actionId?.isEmpty != false) return;
    final event = NotificationActionEvent(
      jobId: jobId,
      actionId: response.actionId!,
    );
    _pendingActions.add(event);
    _actionController.add(event);
  }

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      tz_data.initializeTimeZones();
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          _channelId,
          'Pengingat & Kabar Loker',
          description:
              'Notifikasi jadwal interview, tes, pengumuman dan kabar lamaran',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      _initialized = true;
    } catch (error) {
      debugPrint('Inisialisasi notifikasi gagal: $error');
    }
  }

  static int notificationIdFor(String jobId) {
    var hash = 2166136261;
    for (final codeUnit in jobId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    // Reserve two consecutive IDs per job: event time and H-1 reminder.
    return _notificationIdPrefix + ((hash % 400000000) * 2);
  }

  /// Uses a separate high range so the next-action reminder cannot collide
  /// with the paired H and H-1 selection reminders above.
  static int nextActionNotificationIdFor(String jobId) {
    var hash = 2166136261;
    for (final codeUnit in jobId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return _nextActionNotificationIdPrefix + (hash % 100000000);
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    if (!_initialized) await init();
    if (!_initialized) return false;

    try {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final androidGranted = await android?.requestNotificationsPermission();
      final ios = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return androidGranted ?? iosGranted ?? true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Returns the current OS-level notification permission without prompting.
  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;
    if (!_initialized) await init();
    if (!_initialized) return false;

    try {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }

      final ios = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios == null) return true;
      final permissions = await ios.checkPermissions();
      return permissions?.isEnabled ??
          permissions?.isProvisionalEnabled ??
          false;
    } catch (error) {
      debugPrint('Gagal membaca status izin notifikasi: $error');
      return false;
    }
  }

  /// Edu-sheet untuk izin notifikasi di Android 13+ (POST_NOTIFICATIONS)
  static Future<bool> promptPermissionIfNeeded(BuildContext context) async {
    if (await areNotificationsEnabled()) {
      return true;
    }

    if (!context.mounted) return false;
    final granted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5C44E4).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF5C44E4),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Aktifkan Pengingat Seleksi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF121214),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi Ngelamar akan mengirimkan alarm jadwal tepat waktu pada hari H dan H-1 sebelum interview agar Anda siap 100%.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFDCD8CE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Nanti Saja',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF555558),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C44E4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Izinkan Notifikasi',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (granted == true) {
      return await requestPermission();
    }
    return false;
  }

  static Future<NotificationScheduleResult> syncInterviewReminder(
    JobApplication job,
  ) async {
    if (kIsWeb) {
      return const NotificationScheduleResult(
        state: ScheduleState.unsupported,
        message: 'Notifikasi lokal belum didukung di platform Web.',
      );
    }
    if (job.isSampleData ||
        job.status == 'Diterima' ||
        job.status == 'Ditolak' ||
        job.status == 'Dibatalkan') {
      return const NotificationScheduleResult(
        state: ScheduleState.skippedClosedOrSample,
        message: 'Lamaran berstatus ditutup atau data contoh diabaikan.',
      );
    }
    if (!_initialized) await init();
    if (!_initialized) {
      return const NotificationScheduleResult(
        state: ScheduleState.failed,
        message: 'Inisialisasi notifikasi lokal gagal.',
      );
    }

    try {
      final id = notificationIdFor(job.id);
      final idH1 = id + 1;
      await _notificationsPlugin.cancel(id);
      await _notificationsPlugin.cancel(idH1);

      final interviewDate = job.interviewDate ?? job.testDate;
      final isSelectionStage =
          job.status == 'Tes / Psikotes' || job.status.startsWith('Interview');
      final hasExplicitTime =
          interviewDate == null ||
          interviewDate.hour != 0 ||
          interviewDate.minute != 0;
      if (interviewDate == null || !interviewDate.isAfter(DateTime.now())) {
        return const NotificationScheduleResult(
          state: ScheduleState.skippedPastDate,
          message: 'Tanggal wawancara sudah lewat atau belum ditentukan.',
        );
      }
      if (!isSelectionStage || !hasExplicitTime) {
        return const NotificationScheduleResult(
          state: ScheduleState.cancelled,
          message: 'Bukan tahap seleksi aktif atau jam belum diisi.',
        );
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        'Pengingat Interview',
        channelDescription: 'Pengingat jadwal interview & tes lamaran kerja',
        importance: Importance.high,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'complete',
            'Tandai selesai',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'snooze_tomorrow',
            'Tunda besok',
            showsUserInterface: true,
          ),
        ],
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      // 1. Notifikasi Tepat Waktu
      await _notificationsPlugin.zonedSchedule(
        id,
        'Wawancara ${job.position}',
        'Jadwal seleksi dengan ${job.companyName} dimulai sekarang. Semoga sukses!',
        tz.TZDateTime.from(interviewDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: job.id,
      );

      // 2. Notifikasi Persiapan H-1 (Pukul 09:00 Pagi)
      final h1Date = interviewDate.subtract(const Duration(days: 1));
      final h1Morning = DateTime(h1Date.year, h1Date.month, h1Date.day, 9, 0);
      if (h1Morning.isAfter(DateTime.now())) {
        await _notificationsPlugin.zonedSchedule(
          idH1,
          'H-1 Interview ${job.companyName}',
          'Besok ada jadwal ${job.status} untuk posisi ${job.position}. Siapkan berkas dan istirahat yang cukup!',
          tz.TZDateTime.from(h1Morning, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: job.id,
        );
      }

      return NotificationScheduleResult(
        state: ScheduleState.scheduled,
        message: 'Pengingat berhasil dijadwalkan.',
        scheduledTime: interviewDate,
      );
    } catch (error) {
      debugPrint('Gagal menjadwalkan pengingat ${job.id}: $error');
      return NotificationScheduleResult(
        state: ScheduleState.failed,
        message: 'Gagal menjadwalkan pengingat: $error',
      );
    }
  }

  static Future<NotificationScheduleResult> syncNextActionReminder(
    JobApplication job,
  ) async {
    if (kIsWeb) {
      return const NotificationScheduleResult(
        state: ScheduleState.unsupported,
        message: 'Notifikasi lokal belum didukung di platform Web.',
      );
    }
    if (job.isSampleData ||
        job.status == 'Diterima' ||
        job.status == 'Ditolak' ||
        job.status == 'Dibatalkan') {
      return const NotificationScheduleResult(
        state: ScheduleState.skippedClosedOrSample,
        message: 'Lamaran berstatus ditutup atau data contoh diabaikan.',
      );
    }
    if (!_initialized) await init();
    if (!_initialized) {
      return const NotificationScheduleResult(
        state: ScheduleState.failed,
        message: 'Inisialisasi notifikasi lokal gagal.',
      );
    }

    final id = nextActionNotificationIdFor(job.id);
    try {
      await _notificationsPlugin.cancel(id);
      final dueAt = job.nextActionAt;
      if (dueAt == null ||
          !dueAt.isAfter(DateTime.now()) ||
          job.nextActionType == null) {
        return const NotificationScheduleResult(
          state: ScheduleState.skippedPastDate,
          message: 'Tindakan lanjutan belum ditentukan atau sudah lewat.',
        );
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Pengingat Interview',
          channelDescription: 'Pengingat tindakan dan jadwal lamaran kerja',
          importance: Importance.high,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'complete',
              'Tandai selesai',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'snooze_tomorrow',
              'Tunda besok',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );
      await _notificationsPlugin.zonedSchedule(
        id,
        '${job.nextActionType}: ${job.companyName}',
        job.nextActionNote?.trim().isNotEmpty == true
            ? job.nextActionNote!.trim()
            : 'Ada tindakan lanjutan untuk posisi ${job.position}.',
        tz.TZDateTime.from(dueAt, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: job.id,
      );

      return NotificationScheduleResult(
        state: ScheduleState.scheduled,
        message: 'Pengingat tindakan lanjutan berhasil dijadwalkan.',
        scheduledTime: dueAt,
      );
    } catch (error) {
      debugPrint('Gagal menjadwalkan tindakan berikutnya ${job.id}: $error');
      return NotificationScheduleResult(
        state: ScheduleState.failed,
        message: 'Gagal menjadwalkan tindakan lanjutan: $error',
      );
    }
  }

  static Future<void> syncJobReminders(JobApplication job) async {
    await Future.wait([
      syncInterviewReminder(job),
      syncNextActionReminder(job),
    ]);
  }

  static Future<void> cancelInterviewReminder(String jobId) async {
    if (kIsWeb) return;
    try {
      if (!_initialized) await init();
      if (_initialized) {
        final id = notificationIdFor(jobId);
        await _notificationsPlugin.cancel(id);
        await _notificationsPlugin.cancel(id + 1);
        await _notificationsPlugin.cancel(nextActionNotificationIdFor(jobId));
      }
    } catch (e) {
      debugPrint('Gagal membatalkan pengingat $jobId: $e');
    }
  }

  static Future<void> syncAll(Iterable<JobApplication> jobs) async {
    if (kIsWeb) return;
    for (final job in jobs) {
      await syncJobReminders(job);
    }
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    try {
      if (!_initialized) await init();
      // An FCM data message may be handled while Flutter has no foreground
      // activity. Never try to show Android's permission dialog from that
      // background isolate; the foreground setup already asks for it.
      if (!await areNotificationsEnabled()) return;

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        'Pengingat Interview & Notifikasi Loker',
        channelDescription: 'Pengingat jadwal seleksi dan update lamaran kerja',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (error) {
      debugPrint('Gagal menampilkan notifikasi instan: $error');
    }
  }

  static Future<void> cancelAllInterviewReminders() async {
    if (kIsWeb) return;
    try {
      if (!_initialized) await init();
      if (!_initialized) return;
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      for (final reminder in pending) {
        if (reminder.id >= _notificationIdPrefix) {
          await _notificationsPlugin.cancel(reminder.id);
        }
      }
    } catch (e) {
      debugPrint('Gagal membatalkan seluruh pengingat: $e');
    }
  }
}

enum ScheduleState {
  scheduled,
  failed,
  skippedPastDate,
  skippedClosedOrSample,
  permissionDenied,
  unsupported,
  cancelled,
}

class NotificationScheduleResult {
  final ScheduleState state;
  final String message;
  final DateTime? scheduledTime;

  const NotificationScheduleResult({
    required this.state,
    required this.message,
    this.scheduledTime,
  });

  bool get isSuccess => state == ScheduleState.scheduled;
}

class NotificationActionEvent {
  final String jobId;
  final String actionId;

  const NotificationActionEvent({required this.jobId, required this.actionId});
}
