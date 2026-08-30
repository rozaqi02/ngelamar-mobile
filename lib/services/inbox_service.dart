import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class InboxMessage {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? actionUrl;
  final DateTime createdAt;

  const InboxMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.actionUrl,
  });

  factory InboxMessage.fromMap(Map<String, dynamic> map) => InboxMessage(
    id: map['id'].toString(),
    title: map['title'].toString(),
    body: map['body'].toString(),
    type: map['type']?.toString() ?? 'announcement',
    actionUrl: map['action_url']?.toString(),
    createdAt:
        DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
  );
}

class InboxService {
  static const String _notifiedIdsKey = 'notified_inbox_message_ids';
  static StreamSubscription? _realtimeSubscription;

  static Future<List<InboxMessage>> fetch() async {
    try {
      await SupabaseService.ensureAuthenticated();
      final rows = await SupabaseService.client
          .from('notification_inbox')
          .select('id, title, body, type, action_url, created_at, expires_at')
          .or(
            'expires_at.is.null,expires_at.gt.${DateTime.now().toUtc().toIso8601String()}',
          )
          .order('created_at', ascending: false)
          .limit(20);
      final messages = rows
          .map((row) => InboxMessage.fromMap(row))
          .toList(growable: false);

      // Trigger OS device tray notification for newly detected messages
      unawaited(_notifyNewMessages(messages));

      return messages;
    } catch (error) {
      throw InboxFetchException(error.toString());
    }
  }

  /// Memeriksa pesan inbox baru secara aman tanpa melempar exception (cocok untuk app lifecycle resume)
  static Future<void> checkNewMessagesSafe() async {
    try {
      await fetch();
    } catch (e) {
      debugPrint('Error checking new inbox messages: $e');
    }
  }

  static Future<void> _notifyNewMessages(List<InboxMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifiedIds = (prefs.getStringList(_notifiedIdsKey) ?? []).toSet();
      final newNotified = Set<String>.from(notifiedIds);

      for (final msg in messages) {
        if (!notifiedIds.contains(msg.id)) {
          newNotified.add(msg.id);
          // Show native OS status-bar / heads-up notification
          await NotificationService.showInstantNotification(
            title: msg.title,
            body: msg.body,
            payload: msg.actionUrl,
          );
        }
      }

      // Keep the local de-duplication store bounded even after years of
      // broadcasts. Order is irrelevant for membership checks.
      // Keep a small, newest-first local deduplication window.  Sorting UUIDs
      // would retain arbitrary records instead of the messages the user saw last.
      final boundedIds = <String>{
        ...messages.map((message) => message.id),
        ...newNotified,
      }.take(300).toList();
      await prefs.setStringList(_notifiedIdsKey, boundedIds);
    } catch (e) {
      debugPrint('Error triggering inbox device notification: $e');
    }
  }

  /// Called by FCM before displaying a device notification. Inbox fetches use
  /// the same de-duplication set, so a push cannot be replayed when the user
  /// opens the in-app notification center afterwards.
  static Future<void> markAsDeviceNotified(String messageId) async {
    final cleanId = messageId.trim();
    if (cleanId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = (prefs.getStringList(_notifiedIdsKey) ?? []).toSet();
      ids.add(cleanId);
      await prefs.setStringList(_notifiedIdsKey, ids.take(300).toList());
    } catch (error) {
      debugPrint('Gagal menyimpan status notifikasi push: $error');
    }
  }

  /// Inisialisasi listener realtime untuk menerima pesan broadcast inbox secara instan
  static void initRealtimeListener() {
    if (kIsWeb) return;
    try {
      // Supabase Realtime Stream for push broadcast
      _realtimeSubscription ??= SupabaseService.client
          .from('notification_inbox')
          .stream(primaryKey: ['id'])
          .listen(
            (List<Map<String, dynamic>> rows) {
              final messages = rows
                  .map((r) => InboxMessage.fromMap(r))
                  .toList(growable: false);
              _notifyNewMessages(messages);
            },
            onError: (err) {
              debugPrint('Realtime inbox stream error: $err');
            },
          );
    } catch (e) {
      debugPrint('Gagal menginisialisasi realtime inbox listener: $e');
    }
  }

  static void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }
}

class InboxFetchException implements Exception {
  final String message;

  const InboxFetchException(this.message);

  @override
  String toString() => message;
}
