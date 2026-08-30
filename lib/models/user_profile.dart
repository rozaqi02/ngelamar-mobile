import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Immutable model representing the user's career profile & identity.
class UserProfile {
  final String name;
  final String email;
  final String about;
  final String? avatarPath;
  final List<String> careerInterests;
  final String? cvPdfPath;

  const UserProfile({
    this.name = '',
    this.email = '',
    this.about = '',
    this.avatarPath,
    this.careerInterests = const [],
    this.cvPdfPath,
  });

  /// Factory for clean default profile state.
  factory UserProfile.empty() => const UserProfile(
    name: '',
    email: '',
    about: '',
    avatarPath: null,
    careerInterests: [],
    cvPdfPath: null,
  );

  /// Computes a clean 1-2 letter uppercase monogram for avatar fallback.
  String get initials {
    final clean = name.trim();
    if (clean.isEmpty) return 'N';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      final first = parts[0][0].toUpperCase();
      final second = parts[1][0].toUpperCase();
      return '$first$second';
    }
    if (clean.length >= 2) {
      return clean.substring(0, 2).toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  /// Computes a deterministic vibrant background color based on profile name.
  Color get fallbackColor {
    const palette = [
      Color(0xFF5C44E4), // Indigo / Brand
      Color(0xFF0D9488), // Teal
      Color(0xFFE11D48), // Rose
      Color(0xFFD97706), // Amber
      Color(0xFF2563EB), // Blue
      Color(0xFF7C3AED), // Purple
      Color(0xFF059669), // Emerald
      Color(0xFFEA580C), // Orange
    ];
    if (name.trim().isEmpty) return palette[0];
    final hash = name.trim().toLowerCase().codeUnits.fold(
      0,
      (acc, c) => acc + c,
    );
    return palette[hash % palette.length];
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? about,
    String? avatarPath,
    List<String>? careerInterests,
    String? cvPdfPath,
    bool clearAvatar = false,
    bool clearCv = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      about: about ?? this.about,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      careerInterests: careerInterests ?? this.careerInterests,
      cvPdfPath: clearCv ? null : (cvPdfPath ?? this.cvPdfPath),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'about': about,
    'avatarPath': avatarPath,
    'careerInterests': careerInterests,
    'cvPdfPath': cvPdfPath,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      about: map['about'] as String? ?? '',
      avatarPath: map['avatarPath'] as String?,
      careerInterests:
          (map['careerInterests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      cvPdfPath: map['cvPdfPath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email &&
          about == other.about &&
          avatarPath == other.avatarPath &&
          listEquals(careerInterests, other.careerInterests) &&
          cvPdfPath == other.cvPdfPath;

  @override
  int get hashCode =>
      name.hashCode ^
      email.hashCode ^
      about.hashCode ^
      avatarPath.hashCode ^
      Object.hashAll(careerInterests) ^
      cvPdfPath.hashCode;
}
