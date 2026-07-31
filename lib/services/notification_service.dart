import 'package:flutter/foundation.dart';
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
    if (_initialized) return;

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
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
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
    return _notificationIdPrefix + (hash % 100000000);
  }

  static Future<bool> requestPermission() async {
    if (!_initialized) await init();
    if (!_initialized) return false;

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
  }

  static Future<void> syncInterviewReminder(JobApplication job) async {
    if (!_initialized) await init();
    if (!_initialized) return;

    final id = notificationIdFor(job.id);
    await _notificationsPlugin.cancel(id);
    final interviewDate = job.interviewDate;
    if (interviewDate == null ||
        !interviewDate.isAfter(DateTime.now()) ||
        job.status == 'Diterima' ||
        job.status == 'Ditolak') {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Pengingat Interview',
      channelDescription: 'Pengingat jadwal interview lamaran kerja',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        'Interview ${job.position}',
        'Jadwal interview dengan ${job.companyName} dimulai sekarang.',
        tz.TZDateTime.from(interviewDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: job.id,
      );
    } catch (error) {
      debugPrint('Gagal menjadwalkan pengingat ${job.id}: $error');
    }
  }

  static Future<void> cancelInterviewReminder(String jobId) async {
    if (!_initialized) await init();
    if (_initialized) {
      await _notificationsPlugin.cancel(notificationIdFor(jobId));
    }
  }

  static Future<void> syncAll(Iterable<JobApplication> jobs) async {
    for (final job in jobs) {
      await syncInterviewReminder(job);
    }
  }

  static Future<void> cancelAllInterviewReminders() async {
    if (!_initialized) await init();
    if (!_initialized) return;
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    for (final reminder in pending) {
      if (reminder.id >= _notificationIdPrefix) {
        await _notificationsPlugin.cancel(reminder.id);
      }
    }
  }
}
