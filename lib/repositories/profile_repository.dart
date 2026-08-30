import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';
import '../services/prefs_service.dart';

/// Centralized repository for managing user profile persistence,
/// avatar caching, and cross-screen reactive synchronization.
class ProfileRepository {
  static final ProfileRepository _instance = ProfileRepository._internal();
  factory ProfileRepository() => _instance;
  ProfileRepository._internal();

  /// Reactive notifier for real-time profile state across Home, Settings, etc.
  final ValueNotifier<UserProfile> profileNotifier = ValueNotifier<UserProfile>(
    UserProfile.empty(),
  );

  ValueListenable<UserProfile> get profileListenable => profileNotifier;
  UserProfile get currentProfile => profileNotifier.value;

  bool _initialized = false;

  /// Initializes and loads profile data from local persistence.
  Future<UserProfile> initialize() async {
    if (_initialized) return profileNotifier.value;
    final profile = await loadProfile();
    profileNotifier.value = profile;
    _initialized = true;
    return profile;
  }

  /// Loads current user profile from persistence layers.
  Future<UserProfile> loadProfile() async {
    try {
      final name = await PrefsService.getUserName() ?? '';
      final email = await PrefsService.getUserEmail() ?? '';
      final about = await PrefsService.getUserAbout() ?? '';
      final avatarPath = await PrefsService.getProfilePhoto();
      final interests = await PrefsService.getUserInterests();
      final cvPdf = await PrefsService.getCvPdf();

      final profile = UserProfile(
        name: name,
        email: email,
        about: about,
        avatarPath: avatarPath,
        careerInterests: interests,
        cvPdfPath: cvPdf,
      );

      profileNotifier.value = profile;
      return profile;
    } catch (e) {
      debugPrint('Error loading UserProfile in ProfileRepository: $e');
      return profileNotifier.value;
    }
  }

  /// Persists updated user profile and broadcasts to all listening widgets.
  Future<void> saveProfile(UserProfile profile) async {
    try {
      await PrefsService.setUserName(profile.name);
      await PrefsService.setUserEmail(profile.email);
      await PrefsService.setUserAbout(profile.about);

      if (profile.avatarPath != null) {
        await PrefsService.setProfilePhoto(profile.avatarPath!);
      }

      await PrefsService.setUserInterests(profile.careerInterests);

      if (profile.cvPdfPath != null) {
        await PrefsService.setCvPdf(profile.cvPdfPath!);
      }

      profileNotifier.value = profile;
    } catch (e) {
      debugPrint('Error saving UserProfile in ProfileRepository: $e');
    }
  }

  /// Saves raw image bytes as the active avatar.
  /// On web: formats as a stable data URI.
  /// On mobile/desktop: saves to the app's persistent documents directory.
  Future<String?> saveAvatarBytes(
    Uint8List bytes, {
    String mimeType = 'image/png',
  }) async {
    try {
      if (bytes.isEmpty) return null;

      String path;
      if (kIsWeb) {
        final base64String = base64Encode(bytes);
        path = 'data:$mimeType;base64,$base64String';
      } else {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final avatarsDir = Directory('${dir.path}/avatars');
          if (!avatarsDir.existsSync()) {
            avatarsDir.createSync(recursive: true);
          }

          final filename =
              'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File('${avatarsDir.path}/$filename');
          await file.writeAsBytes(bytes, flush: true);
          path = file.path;

          // Clean up legacy avatars
          _cleanupOldAvatars(avatarsDir, keepPath: path);
        } catch (_) {
          final base64String = base64Encode(bytes);
          path = 'data:$mimeType;base64,$base64String';
        }
      }

      await PrefsService.setProfilePhoto(path);
      profileNotifier.value = profileNotifier.value.copyWith(avatarPath: path);
      return path;
    } catch (e) {
      debugPrint('Error saving avatar in ProfileRepository: $e');
      return null;
    }
  }

  /// Removes active avatar photo and resets to monogram/initials fallback.
  Future<void> removeAvatar() async {
    try {
      final oldPath = profileNotifier.value.avatarPath;
      if (oldPath != null && !kIsWeb && !oldPath.startsWith('data:')) {
        try {
          final file = File(oldPath);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {}
      }

      await PrefsService.setProfilePhoto('');
      profileNotifier.value = profileNotifier.value.copyWith(clearAvatar: true);
    } catch (e) {
      debugPrint('Error removing avatar in ProfileRepository: $e');
    }
  }

  void _cleanupOldAvatars(Directory avatarsDir, {required String keepPath}) {
    try {
      final list = avatarsDir.listSync();
      for (final entity in list) {
        if (entity is File && entity.path != keepPath) {
          try {
            entity.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
