import 'supabase_service.dart';

class RemoteAnnouncement {
  final String title;
  final String message;
  final String? actionUrl;

  const RemoteAnnouncement({
    required this.title,
    required this.message,
    this.actionUrl,
  });
}

class RemoteConfigService {
  static Map<String, dynamic> _values = const {};

  static RemoteAnnouncement? get announcement {
    final raw = _values['app_announcement'];
    if (raw is! Map || raw['enabled'] != true) return null;
    final title = raw['title']?.toString().trim() ?? '';
    final message = raw['message']?.toString().trim() ?? '';
    if (title.isEmpty || message.isEmpty) return null;
    final action = raw['action_url']?.toString().trim();
    return RemoteAnnouncement(
      title: title,
      message: message,
      actionUrl: action == null || action.isEmpty ? null : action,
    );
  }

  static String? get minimumSupportedVersion {
    final raw = _values['minimum_supported_version'];
    return raw is Map ? raw['version']?.toString() : null;
  }

  static Future<void> refresh() async {
    try {
      await SupabaseService.ensureAuthenticated();
      final rows = await SupabaseService.client
          .from('remote_config')
          .select('key, value')
          .eq('is_enabled', true);
      _values = {
        for (final row in rows)
          row['key'].toString(): row['value'] is Map
              ? Map<String, dynamic>.from(row['value'] as Map)
              : row['value'],
      };
    } catch (_) {
      // The bundled app remains usable without a network configuration.
    }
  }
}
