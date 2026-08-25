import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'device_push_service.dart';
import 'inbox_service.dart';
import 'notification_service.dart';

/// Required by Firebase when Android receives a data push while Flutter is in
/// the background. Keep this as a top-level entry point so release tree
/// shaking cannot remove it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  await PushNotificationService.handleIncomingMessage(message);
}

/// Handles the Android delivery side of the Supabase -> FCM pipeline. Supabase
/// remains the source of truth; FCM only transports the compact payload to a
/// device that may not currently have a running Flutter UI.
class PushNotificationService {
  static FirebaseMessaging? _messaging;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized || kIsWeb || !Platform.isAndroid) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      _messaging = messaging;
      _isInitialized = true;

      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await _syncCurrentToken();
      messaging.onTokenRefresh.listen(DevicePushService.upsertAndroidToken);
      FirebaseMessaging.onMessage.listen(handleIncomingMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_markOpenedMessage);
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) await _markOpenedMessage(initialMessage);
    } catch (error) {
      // Firebase setup must not block the non-push parts of the application.
      debugPrint('Inisialisasi FCM gagal: $error');
    }
  }

  static Future<void> _syncCurrentToken() async {
    final token = await _messaging?.getToken();
    if (token != null) await DevicePushService.upsertAndroidToken(token);
  }

  static Future<void> _markOpenedMessage(RemoteMessage message) async {
    final inboxId = message.data['inbox_id']?.trim();
    if (inboxId != null && inboxId.isNotEmpty) {
      await InboxService.markAsDeviceNotified(inboxId);
    }
  }

  /// Shows data-only pushes through the existing local notification channel.
  /// Marking the inbox ID first prevents the later inbox fetch from notifying
  /// the same message a second time.
  static Future<void> handleIncomingMessage(RemoteMessage message) async {
    final data = message.data;
    final inboxId = data['inbox_id']?.trim();
    if (inboxId != null && inboxId.isNotEmpty) {
      await InboxService.markAsDeviceNotified(inboxId);
    }

    final title = _shorten(
      data['title']?.trim().isNotEmpty == true
          ? data['title']!
          : (message.notification?.title ?? ''),
      120,
    );
    final body = _shorten(
      data['body']?.trim().isNotEmpty == true
          ? data['body']!
          : (message.notification?.body ?? ''),
      1000,
    );
    if (title.isEmpty || body.isEmpty) return;

    await NotificationService.showInstantNotification(
      title: title,
      body: body,
      payload: data['action_url'],
    );
  }

  static String _shorten(String value, int limit) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= limit) return clean;
    return '${clean.substring(0, limit - 1).trimRight()}…';
  }
}
