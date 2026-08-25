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
    final actionUri = action == null ? null : Uri.tryParse(action);
    return RemoteAnnouncement(
      title: title,
      message: message,
      actionUrl: actionUri != null && actionUri.scheme == 'https'
          ? actionUri.toString()
          : null,
    );
  }

  static String? get minimumSupportedVersion {
    final raw = _values['minimum_supported_version'];
    return raw is Map ? raw['version']?.toString() : null;
  }

  static String? get minimumSupportedStoreUrl {
    final raw = _values['minimum_supported_version'];
    final url = raw is Map ? raw['store_url']?.toString().trim() : null;
    final uri = url == null ? null : Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' ? uri.toString() : null;
  }

  static bool requiresUpdate(String installedVersion) {
    final minimum = minimumSupportedVersion?.trim();
    if (minimum == null ||
        minimum.isEmpty ||
        minimumSupportedStoreUrl == null) {
      return false;
    }
    return _compareVersions(installedVersion, minimum) < 0;
  }

  static int _compareVersions(String first, String second) {
    List<int> parse(String value) => value
        .split(RegExp(r'[.+-]'))
        .take(3)
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final a = parse(first);
    final b = parse(second);
    for (var index = 0; index < 3; index++) {
      final comparison = (index < a.length ? a[index] : 0).compareTo(
        index < b.length ? b[index] : 0,
      );
      if (comparison != 0) return comparison;
    }
    return 0;
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
