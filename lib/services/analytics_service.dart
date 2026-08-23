import 'supabase_service.dart';

/// Privacy-first product analytics. Never send job descriptions, CV contents,
/// employer names, contact details, or free-form notes through this service.
class AnalyticsService {
  static Future<void> track(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    final validName = RegExp(r'^[a-z0-9_]{1,64}$');
    if (!validName.hasMatch(name)) return;
    try {
      final user = await SupabaseService.ensureAuthenticated();
      final safeProperties = <String, Object?>{};
      for (final entry in properties.entries) {
        if (entry.key.length > 40) continue;
        final value = entry.value;
        if (value is String && value.length <= 120) {
          safeProperties[entry.key] = value;
        } else if (value is num || value is bool) {
          safeProperties[entry.key] = value;
        }
      }
      await SupabaseService.client.from('app_events').insert({
        'user_id': user.id,
        'name': name,
        'properties': safeProperties,
      });
    } catch (_) {
      // Product analytics must never disrupt the local workflow.
    }
  }
}
