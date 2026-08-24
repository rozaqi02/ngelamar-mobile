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
      // DateTime values from the form use the device's local clock. Keeping
      // tz.local at its default prevents a schedule entered while travelling
      // from being reinterpreted as Asia/Jakarta time.
      await _notificationsPlugin.initialize(initSettings);
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

  static Future<void> syncInterviewReminder(JobApplication job) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!_initialized) return;

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
      if (interviewDate == null ||
          !interviewDate.isAfter(DateTime.now()) ||
          !isSelectionStage ||
          !hasExplicitTime ||
          job.status == 'Diterima' ||
          job.status == 'Ditolak') {
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        'Pengingat Interview',
        channelDescription: 'Pengingat jadwal interview & tes lamaran kerja',
        importance: Importance.high,
        priority: Priority.high,
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
    } catch (error) {
      debugPrint('Gagal menjadwalkan pengingat ${job.id}: $error');
    }
  }

  static Future<void> cancelInterviewReminder(String jobId) async {
    if (kIsWeb) return;
    try {
      if (!_initialized) await init();
      if (_initialized) {
        final id = notificationIdFor(jobId);
        await _notificationsPlugin.cancel(id);
        await _notificationsPlugin.cancel(id + 1);
      }
    } catch (e) {
      debugPrint('Gagal membatalkan pengingat $jobId: $e');
    }
  }

  static Future<void> syncAll(Iterable<JobApplication> jobs) async {
    if (kIsWeb) return;
    for (final job in jobs) {
      await syncInterviewReminder(job);
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
      await requestPermission();

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
