import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Single source of truth service for application version, build number,
/// and semantic version validation.
class AppVersionService {
  static const String fallbackVersion = '2.32.0';
  static const String fallbackBuildNumber = '250';
  static const String fallbackAppName = 'Ngelamar';

  static PackageInfo? _packageInfo;

  /// Inisialisasi PackageInfo dari platform secara aman saat startup.
  static Future<void> initialize() async {
    if (_packageInfo != null) return;
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('AppVersionService initialize error (using fallback): $e');
    }
  }

  /// Override PackageInfo untuk testing
  @visibleForTesting
  static void setMockPackageInfo(PackageInfo mockInfo) {
    _packageInfo = mockInfo;
  }

  @visibleForTesting
  static void reset() {
    _packageInfo = null;
  }

  /// Versi aplikasi (e.g. "2.28.1")
  static String get version => _packageInfo?.version.isNotEmpty == true
      ? _packageInfo!.version
      : fallbackVersion;

  /// Nomor build aplikasi (e.g. "246")
  static String get buildNumber => _packageInfo?.buildNumber.isNotEmpty == true
      ? _packageInfo!.buildNumber
      : fallbackBuildNumber;

  /// Nama aplikasi
  static String get appName => _packageInfo?.appName.isNotEmpty == true
      ? _packageInfo!.appName
      : fallbackAppName;

  /// Identifier paket (e.g. "com.ngelamar.app")
  static String get packageName => _packageInfo?.packageName ?? '';

  /// Format ringkas: "v2.28.1"
  static String get shortDisplay => 'v$version';

  /// Format lengkap: "v2.28.1 (Build 246)"
  static String get fullDisplay => 'v$version (Build $buildNumber)';

  /// Format standar rilis: "2.28.1+246"
  static String get releaseFormat => '$version+$buildNumber';

  /// Membandingkan dua string versi semantik (e.g., "2.28.1" vs "2.25.0").
  /// Mengembalikan:
  ///   1 jika [v1] > [v2]
  ///  -1 jika [v1] < [v2]
  ///   0 jika [v1] == [v2]
  static int compareVersions(String v1, String v2) {
    final clean1 = v1.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    final clean2 = v2.replaceAll(RegExp(r'[^0-9.]'), '').trim();

    final parts1 = clean1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = clean2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLen = parts1.length > parts2.length
        ? parts1.length
        : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// Mengecek apakah versi saat ini memenuhi versi minimum yang dibutuhkan.
  static bool isVersionSupported(String currentVersion, String minimumVersion) {
    return compareVersions(currentVersion, minimumVersion) >= 0;
  }
}
