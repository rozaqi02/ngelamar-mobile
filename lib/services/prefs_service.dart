import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const _keyUserAbout = 'user_about';
  static const _keyCvPdf = 'user_cv_pdf';
  static const _keyJobListViewMode = 'job_list_view_mode';
  static const _keyJobListSort = 'job_list_sort';
  static const _keyJobListStatusTab = 'job_list_status_tab';
  static const _securePrefix = 'ngelamar_secure_';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<String?> _readSensitiveString(String key) async {
    final secureKey = '$_securePrefix$key';
    final secured = await _secureStorage.read(key: secureKey);
    if (secured != null) return secured;

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(key);
    if (legacyValue != null) {
      await _secureStorage.write(key: secureKey, value: legacyValue);
      await prefs.remove(key);
    }
    return legacyValue;
  }

  static Future<void> _writeSensitiveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: '$_securePrefix$key', value: value);
    await prefs.remove(key);
  }

  static Future<List<String>?> _readSensitiveStringList(String key) async {
    final secureKey = '$_securePrefix$key';
    final secured = await _secureStorage.read(key: secureKey);
    if (secured != null) {
      try {
        final decoded = jsonDecode(secured);
        if (decoded is List) return decoded.map((item) => '$item').toList();
      } on FormatException {
        await _secureStorage.delete(key: secureKey);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getStringList(key);
    if (legacyValue != null) {
      await _secureStorage.write(
        key: secureKey,
        value: jsonEncode(legacyValue),
      );
      await prefs.remove(key);
    }
    return legacyValue;
  }

  static Future<void> _writeSensitiveStringList(
    String key,
    List<String> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(
      key: '$_securePrefix$key',
      value: jsonEncode(values),
    );
    await prefs.remove(key);
  }

  /// Returns user profile photo file path, or null if not set.
  static Future<String?> getProfilePhoto() async {
    return _readSensitiveString(_keyProfilePhoto);
  }

  /// Persists user profile photo file path.
  static Future<void> setProfilePhoto(String path) async {
    await _writeSensitiveString(_keyProfilePhoto, path);
  }

  /// Returns the optional profile bio/about text.
  static Future<String?> getUserAbout() async {
    return _readSensitiveString(_keyUserAbout);
  }

  /// Persists the optional profile bio/about text.
  static Future<void> setUserAbout(String about) async {
    await _writeSensitiveString(_keyUserAbout, about);
  }

  /// Returns the local path to the user's CV PDF, or null when not selected.
  static Future<String?> getCvPdf() async {
    return _readSensitiveString(_keyCvPdf);
  }

  /// Persists the local path to the user's CV PDF.
  static Future<void> setCvPdf(String path) async {
    await _writeSensitiveString(_keyCvPdf, path);
  }

  /// Preferred tracker layout. Grid is the first-use default.
  static Future<String> getJobListViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyJobListViewMode);
    return value == 'list' ? 'list' : 'grid';
  }

  static Future<void> setJobListViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyJobListViewMode,
      mode == 'list' ? 'list' : 'grid',
    );
  }

  static Future<String> getJobListSort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyJobListSort) ?? 'Terbaru';
  }

  static Future<void> setJobListSort(String sort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyJobListSort, sort);
  }

  static Future<String> getJobListStatusTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyJobListStatusTab) ?? 'Semua';
  }

  static Future<void> setJobListStatusTab(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyJobListStatusTab, status);
  }

  /// Returns list of checked document titles from checklist.
  static Future<List<String>?> getChecklistDocs() async {
    return _readSensitiveStringList(_keyChecklistDocs);
  }

  /// Persists checked document titles from checklist.
  static Future<void> setChecklistDocs(List<String> docs) async {
    await _writeSensitiveStringList(_keyChecklistDocs, docs);
  }

  /// Returns the stored user name, or null if not set.
  static Future<String?> getUserName() async {
    return _readSensitiveString(_keyUserName);
  }

  /// Saves user name persistently.
  static Future<void> setUserName(String name) async {
    await _writeSensitiveString(_keyUserName, name);
  }

  /// Returns stored user email, or null if not set.
  static Future<String?> getUserEmail() async {
    return _readSensitiveString(_keyUserEmail);
  }

  /// Saves user email persistently.
  static Future<void> setUserEmail(String email) async {
    await _writeSensitiveString(_keyUserEmail, email);
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
    return await _readSensitiveStringList(_keyUserInterests) ?? [];
  }

  /// Saves user career interests.
  static Future<void> setUserInterests(List<String> interests) async {
    await _writeSensitiveStringList(_keyUserInterests, interests);
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
  static const _keyNotificationIntroSeen = 'notification_welcome_intro_seen';

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
  static Future<void> setPrepIntroSeen([bool seen = true]) =>
      setCareerPrepIntroSeen(seen);

  static Future<bool> isNotificationIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationIntroSeen) ?? false;
  }

  static Future<void> setNotificationIntroSeen([bool seen = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationIntroSeen, seen);
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
