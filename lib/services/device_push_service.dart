import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// Persists the FCM token per Supabase identity. The token is only useful to
/// the server-side push function; it is never displayed in the app UI.
class DevicePushService {
  static Future<void> upsertAndroidToken(String rawToken) async {
    if (!SupabaseService.isInitialized) return;
    final token = rawToken.trim();
    if (token.length < 30 || token.length > 4096) return;

    try {
      final user = await SupabaseService.ensureAuthenticated();
      await SupabaseService.client.from('device_push_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': 'android',
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        'enabled': true,
      }, onConflict: 'user_id,token');
    } catch (error) {
      // Push registration must never prevent the tracker from opening.
      debugPrint('Pendaftaran perangkat FCM gagal: $error');
    }
  }
}
