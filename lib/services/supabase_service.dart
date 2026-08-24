import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountIdentity {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final bool isAnonymous;

  const AccountIdentity({
    required this.id,
    required this.isAnonymous,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  factory AccountIdentity.fromUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AccountIdentity(
      id: user.id,
      isAnonymous: user.isAnonymous,
      email: user.email,
      displayName:
          metadata['full_name']?.toString() ?? metadata['name']?.toString(),
      avatarUrl: metadata['avatar_url']?.toString(),
    );
  }
}

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
  static const _mobileAuthRedirect = 'ngelamar://auth/callback';

  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client => Supabase.instance.client;

  static AccountIdentity? get currentIdentity {
    final user = client.auth.currentUser;
    return user == null ? null : AccountIdentity.fromUser(user);
  }

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
    if (currentUser != null) {
      await _ensureProfile();
      return currentUser;
    }

    final pending = _pendingAnonymousSignIn;
    if (pending != null) return pending;

    final request = () async {
      final response = await client.auth.signInAnonymously();
      final user = response.user;
      if (user == null) {
        throw StateError('Sesi anonim Supabase gagal dibuat.');
      }
      await _ensureProfile();
      return user;
    }();
    _pendingAnonymousSignIn = request;
    try {
      return await request;
    } finally {
      _pendingAnonymousSignIn = null;
    }
  }

  /// Links the current anonymous identity to Google whenever possible. This
  /// preserves the existing UID, entitlement PRO, and cloud files.
  static Future<bool> connectGoogle() async {
    try {
      final user = await ensureAuthenticated();
      final redirectTo = kIsWeb ? Uri.base.origin : _mobileAuthRedirect;
      if (user.isAnonymous) {
        try {
          return await client.auth.linkIdentity(
            OAuthProvider.google,
            redirectTo: redirectTo,
            authScreenLaunchMode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('linkIdentity failed, falling back to signInWithOAuth: $e');
          return await client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: redirectTo,
            authScreenLaunchMode: LaunchMode.externalApplication,
          );
        }
      }
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('connectGoogle error: $e');
      final redirectTo = kIsWeb ? Uri.base.origin : _mobileAuthRedirect;
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    }
  }

  static Future<void> signOutToAnonymous() async {
    await client.auth.signOut();
    await ensureAuthenticated();
  }

  static Future<void> _ensureProfile() async {
    try {
      await client.rpc('ensure_my_profile');
    } catch (_) {
      // The cloud migration may not have been run yet. Do not block the app.
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
