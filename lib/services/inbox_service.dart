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

      await prefs.setStringList(_notifiedIdsKey, newNotified.toList());
    } catch (e) {
      debugPrint('Error triggering inbox device notification: $e');
    }
  }

  /// Inisialisasi listener realtime untuk menerima pesan inbox dari admin secara instan
  static void initRealtimeListener() {
    if (kIsWeb || _realtimeSubscription != null) return;
    try {
      _realtimeSubscription = SupabaseService.client
          .from('notification_inbox')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> rows) {
            final messages = rows
                .map((r) => InboxMessage.fromMap(r))
                .toList(growable: false);
            _notifyNewMessages(messages);
          }, onError: (err) {
            debugPrint('Realtime inbox stream error: $err');
          });
    } catch (e) {
      debugPrint('Gagal menginisialisasi realtime inbox listener: $e');
    }
  }
}

class InboxFetchException implements Exception {
  final String message;

  const InboxFetchException(this.message);

  @override
  String toString() => message;
}
