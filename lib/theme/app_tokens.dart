import 'package:flutter/material.dart';

/// Semantic colors shared by every Ngelamar surface.
///
/// Screens should depend on the role of a color instead of repeating a hex
/// value. The light and dark themes can therefore evolve without drifting.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color dockSurface;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color warning;
  final Color danger;
  final List<Color> jobCards;

  const AppColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.dockSurface,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.jobCards,
  });

  static const light = AppColorTokens(
    background: Color(0xFFF5EFE6),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFEDE7DC),
    surfaceElevated: Color(0xFFFFFDF9),
    border: Color(0xFFDCD8CE),
    textPrimary: Color(0xFF121214),
    textSecondary: Color(0xFF66666E),
    textTertiary: Color(0xFF8A8990),
    dockSurface: Color(0xFFF7F1E8),
    accent: Color(0xFF6750E8),
    accentSoft: Color(0xFFE9E3FF),
    success: Color(0xFF087A55),
    warning: Color(0xFF9A5A00),
    danger: Color(0xFFC43838),
    jobCards: <Color>[
      Color(0xFF7651E8),
      Color(0xFFFBBF24),
      Color(0xFF2FA8DF),
      Color(0xFF34C98C),
      Color(0xFFEA477F),
      Color(0xFF11B8C8),
    ],
  );

  static const dark = AppColorTokens(
    background: Color(0xFF121214),
    surface: Color(0xFF1E1E22),
    surfaceSecondary: Color(0xFF2A2A30),
    surfaceElevated: Color(0xFF25252A),
    border: Color(0xFF3A3A42),
    textPrimary: Color(0xFFF8F7FB),
    textSecondary: Color(0xFFA9A8B1),
    textTertiary: Color(0xFF777680),
    dockSurface: Color(0xFF202024),
    accent: Color(0xFFA996FF),
    accentSoft: Color(0xFF332B59),
    success: Color(0xFF55D7A5),
    warning: Color(0xFFFFCB72),
    danger: Color(0xFFFF8A8A),
    jobCards: <Color>[
      Color(0xFF51438A),
      Color(0xFF78652F),
      Color(0xFF345E76),
      Color(0xFF356B5A),
      Color(0xFF7A3E59),
      Color(0xFF31666C),
    ],
  );

  Color jobCard(int index) => jobCards[index.abs() % jobCards.length];

  /// Picks a WCAG-friendly foreground for arbitrary vibrant cards.
  Color onStrongCard(Color background, {double minimumRatio = 4.5}) {
    const lightText = Color(0xFFFFFFFF);
    const darkText = Color(0xFF121214);
    final lightRatio = contrastRatio(background, lightText);
    final darkRatio = contrastRatio(background, darkText);
    if (lightRatio >= minimumRatio && lightRatio >= darkRatio) return lightText;
    return darkText;
  }

  Color onSoftCard(Color background) => onStrongCard(background);

  static double contrastRatio(Color first, Color second) {
    final a = first.computeLuminance();
    final b = second.computeLuminance();
    final lighter = a > b ? a : b;
    final darker = a > b ? b : a;
    return (lighter + 0.05) / (darker + 0.05);
  }

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSecondary,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? dockSurface,
    Color? accent,
    Color? accentSoft,
    Color? success,
    Color? warning,
    Color? danger,
    List<Color>? jobCards,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      dockSurface: dockSurface ?? this.dockSurface,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      jobCards: jobCards ?? this.jobCards,
    );
  }

  @override
  AppColorTokens lerp(covariant AppColorTokens? other, double t) {
    if (other == null) return this;
    return AppColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      dockSurface: Color.lerp(dockSurface, other.dockSurface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      jobCards: List<Color>.generate(
        jobCards.length,
        (index) => Color.lerp(
          jobCards[index],
          other.jobCards[index % other.jobCards.length],
          t,
        )!,
      ),
    );
  }
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double chip = 12;
  static const double input = 16;
  static const double card = 24;
  static const double cardLarge = 28;
  static const double pill = 32;
  static const double sheet = 30;
}

abstract final class AppElevation {
  static List<BoxShadow> low({bool dark = false}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.20 : 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> medium({bool dark = false}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.28 : 0.09),
      blurRadius: 18,
      offset: const Offset(0, 7),
    ),
  ];

  static List<BoxShadow> floating({bool dark = false}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.38 : 0.14),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}

abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double expanded = 840;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < expanded;
  static bool isExpanded(double width) => width >= expanded;
}

extension AppThemeTokensContext on BuildContext {
  AppColorTokens get appColors =>
      Theme.of(this).extension<AppColorTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppColorTokens.dark
          : AppColorTokens.light);
}
