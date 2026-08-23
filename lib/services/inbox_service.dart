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
    type: map['type'].toString(),
    actionUrl: map['action_url']?.toString(),
    createdAt:
        DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
  );
}

class InboxService {
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
      return rows
          .map((row) => InboxMessage.fromMap(row))
          .toList(growable: false);
    } catch (error) {
      throw InboxFetchException(error.toString());
    }
  }
}

class InboxFetchException implements Exception {
  final String message;

  const InboxFetchException(this.message);

  @override
  String toString() => message;
}
