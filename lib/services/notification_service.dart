import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notification service for interview reminders & follow-up alerts.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      await _notificationsPlugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      // Graceful fallback on non-supported platforms
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'ngelamar_reminders',
      'Pengingat Lamaran',
      channelDescription: 'Notifikasi pengingat interview dan follow-up',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(id, title, body, details);
    } catch (_) {}
  }
}
