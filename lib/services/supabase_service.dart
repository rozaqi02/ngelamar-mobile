import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client configuration for this privately distributed APK.
/// The anon/publishable key is intentionally a client-side identifier; data
/// security is enforced by Postgres grants, RLS, and authenticated RPCs.
class SupabaseService {
  static const String projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jfmmfnfxofodmallkmsq.supabase.co',
  );
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmbW1mbmZ4b2ZvZG1hbGxrbXNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc0MTUwNzAsImV4cCI6MjEwMjk5MTA3MH0.yz5gUG-XMXzh33f88uTXlsMmGEzVBL1DKXznsukIP3I',
  );

  static bool _isInitialized = false;
  static Future<User>? _pendingAnonymousSignIn;
  static DateTime? _lastActivitySentAt;
  static const _activityInterval = Duration(minutes: 5);

  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(url: projectUrl, publishableKey: publishableKey);
    _isInitialized = true;
  }

  /// Creates a persisted anonymous Supabase session when the installation does
  /// not have one yet. The resulting auth.uid() is used by all PRO RLS rules.
  static Future<User> ensureAuthenticated() async {
    if (!_isInitialized) {
      throw StateError('Supabase belum diinisialisasi.');
    }

    final currentUser = client.auth.currentUser;
    if (currentUser != null) return currentUser;

    final pending = _pendingAnonymousSignIn;
    if (pending != null) return pending;

    final request = () async {
      final response = await client.auth.signInAnonymously();
      final user = response.user;
      if (user == null) {
        throw StateError('Sesi anonim Supabase gagal dibuat.');
      }
      return user;
    }();
    _pendingAnonymousSignIn = request;
    try {
      return await request;
    } finally {
      _pendingAnonymousSignIn = null;
    }
  }

  /// Marks this installation as active at most once every five minutes.
  /// Failing to report analytics must never block the local app experience.
  static Future<void> markUserActive({bool force = false}) async {
    final now = DateTime.now();
    final lastSent = _lastActivitySentAt;
    if (!force &&
        lastSent != null &&
        now.difference(lastSent) < _activityInterval) {
      return;
    }

    try {
      await ensureAuthenticated();
      await client.rpc('mark_user_active');
      _lastActivitySentAt = now;
    } catch (_) {
      // Analytics is best-effort: e.g. the user may be offline on first open.
    }
  }
}
