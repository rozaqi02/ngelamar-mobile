import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for persisting user preferences and settings.
class PrefsService {
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyThemeMode = 'theme_mode'; // 'dark' | 'light'
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyUserInterests = 'user_career_interests';
  static const _keyChecklistDocs = 'fresh_grad_checklist_docs';
  static const _keyProfilePhoto = 'user_profile_photo';

  /// Returns user profile photo file path, or null if not set.
  static Future<String?> getProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfilePhoto);
  }

  /// Persists user profile photo file path.
  static Future<void> setProfilePhoto(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfilePhoto, path);
  }

  /// Returns list of checked document titles from checklist.
  static Future<List<String>?> getChecklistDocs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyChecklistDocs);
  }

  /// Persists checked document titles from checklist.
  static Future<void> setChecklistDocs(List<String> docs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyChecklistDocs, docs);
  }

  /// Returns the stored user name, or null if not set.
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  /// Saves user name persistently.
  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  /// Returns stored user email, or null if not set.
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  /// Saves user email persistently.
  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  /// Returns 'dark' or 'light'. Defaults to 'light'.
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'light';
  }

  /// Saves theme mode persistently.
  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  /// Returns user career interests. Defaults to empty list.
  static Future<List<String>> getUserInterests() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyUserInterests) ?? [];
  }

  /// Saves user career interests.
  static Future<void> setUserInterests(List<String> interests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyUserInterests, interests);
  }

  /// Returns whether user has set at least 3 career interests.
  static Future<bool> hasUserInterests() async {
    final interests = await getUserInterests();
    return interests.length >= 3;
  }

  /// Returns whether onboarding has been completed.
  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  /// Marks onboarding as completed.
  static Future<void> setOnboardingDone([bool done = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, done);
  }

  static const _keyDiscoveryIntroSeen = 'discovery_welcome_intro_seen';
  static const _keyJobListIntroSeen = 'joblist_welcome_intro_seen';
  static const _keyCareerPrepIntroSeen = 'careerprep_welcome_intro_seen';

  /// Returns whether the Discovery Welcome Modal has been seen.
  static Future<bool> isDiscoveryIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDiscoveryIntroSeen) ?? false;
  }

  /// Marks Discovery Welcome Modal as seen.
  static Future<void> setDiscoveryIntroSeen([bool seen = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDiscoveryIntroSeen, seen);
  }

  /// Returns whether the JobList Welcome Screen has been seen.
  static Future<bool> isJobListIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyJobListIntroSeen) ?? false;
  }

  /// Marks JobList Welcome Screen as seen.
  static Future<void> setJobListIntroSeen([bool seen = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyJobListIntroSeen, seen);
  }

  /// Returns whether the Career Prep Welcome Screen has been seen.
  static Future<bool> isCareerPrepIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCareerPrepIntroSeen) ?? false;
  }

  /// Marks Career Prep Welcome Screen as seen.
  static Future<void> setCareerPrepIntroSeen([bool seen = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCareerPrepIntroSeen, seen);
  }

  static Future<bool> isPrepIntroSeen() => isCareerPrepIntroSeen();
  static Future<void> setPrepIntroSeen([bool seen = true]) => setCareerPrepIntroSeen(seen);

  // ── PRO SUBSCRIPTION MANAGEMENT ──
  static const _keyIsPro = 'is_pro_member';
  static const _keyProExpiry = 'pro_expiry_timestamp';
  static const _keyProPlan = 'pro_plan_period';

  /// Returns whether current user is active PRO subscriber.
  static Future<bool> isProSubscriber() async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool(_keyIsPro) ?? false;
    if (!isPro) return false;

    final expiryMs = prefs.getInt(_keyProExpiry);
    if (expiryMs != null) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryMs);
      if (DateTime.now().isAfter(expiryDate)) {
        // Expired
        await prefs.setBool(_keyIsPro, false);
        return false;
      }
    }
    return true;
  }

  /// Sets user PRO subscription status.
  static Future<void> setProSubscription({
    required bool isPro,
    DateTime? expiry,
    String plan = 'monthly',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPro, isPro);
    if (expiry != null) {
      await prefs.setInt(_keyProExpiry, expiry.millisecondsSinceEpoch);
    } else if (!isPro) {
      await prefs.remove(_keyProExpiry);
    }
    await prefs.setString(_keyProPlan, plan);
  }

  /// Returns PRO subscription expiry date, or null.
  static Future<DateTime?> getProExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyProExpiry);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Returns PRO plan period ('monthly' | 'yearly').
  static Future<String> getProPlanPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProPlan) ?? 'monthly';
  }

  // ── INITIAL SEED FLAG ──
  static const _keyInitialDataSeeded = 'initial_sample_data_seeded_v2';

  /// Returns whether initial sample jobs have been seeded.
  static Future<bool> isInitialDataSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyInitialDataSeeded) ?? false;
  }

  /// Marks initial sample jobs as seeded.
  static Future<void> setInitialDataSeeded([bool seeded = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInitialDataSeeded, seeded);
  }
}
