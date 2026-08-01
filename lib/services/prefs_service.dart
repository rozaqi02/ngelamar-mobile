import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for persisting user preferences and settings.
class PrefsService {
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyThemeMode = 'theme_mode'; // 'dark' | 'light'
  static const _keyOnboardingDone = 'onboarding_done';

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

  /// Returns 'dark' or 'light'. Defaults to 'dark'.
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'dark';
  }

  /// Saves theme mode persistently.
  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  /// Returns whether onboarding has been completed.
  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  /// Marks onboarding as completed.
  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }
}
