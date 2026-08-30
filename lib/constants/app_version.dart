import '../services/app_version_service.dart';

/// Single source of truth for Ngelamar application versioning.
class AppVersion {
  static String get version => AppVersionService.version;
  static String get buildNumber => AppVersionService.buildNumber;
  static String get fullDisplay => AppVersionService.fullDisplay;
  static String get releaseFormat => AppVersionService.releaseFormat;
}
