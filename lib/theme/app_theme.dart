import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

class AppTheme {
  // ─────────────────────────────────────────────────
  // Neo-Modern Design Tokens & Radii
  // ─────────────────────────────────────────────────
  static const double radiusCard = 24.0;
  static const double radiusCardLarge = 28.0;
  static const double radiusPill = 32.0;
  static const double radiusBadge = 14.0;
  static const double radiusButton = 28.0;
  static const double borderHairline = 1.2;

  // ─────────────────────────────────────────────────
  // Exact Reference Colors
  // ─────────────────────────────────────────────────
  static const Color warmBackground = Color(
    0xFFF5EFE6,
  ); // Exact warm cream tone
  static const Color warmSurface = Color(0xFFFFFFFF);
  static const Color warmSurfaceAlt = Color(0xFFEDE7DC);
  static const Color warmBorder = Color(0xFFDCD8CE);

  // Saturated Vibrant Palette - Bright, Luminous, High Energy
  static const Color cardPurple = Color(0xFF8B5CF6); // Bright Violet
  static const Color cardYellow = Color(0xFFFBBF24); // Bright Sunny Amber
  static const Color cardCoral = Color(0xFFFB923C); // Bright Energetic Orange
  static const Color cardGreen = Color(0xFF34D399); // Bright Fresh Emerald Mint
  static const Color cardDark = Color(0xFFFB7185); // Bright Coral Rose
  static const Color cardBlue = Color(0xFF38BDF8); // Bright Sky Blue
  static const Color cardTeal = Color(0xFF22D3EE); // Bright Cyan Teal

  // Typography Colors
  static const Color textDark = Color(0xFF121214);
  static const Color textMuted = Color(0xFF707074);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textLightMuted = Color(0xD9FFFFFF);

  // Status System Colors - Bright & Vibrant
  static const Color systemBlue = Color(0xFF0284C7);
  static const Color systemGreen = Color(0xFF10B981);
  static const Color systemOrange = Color(0xFFF97316);
  static const Color systemRed = Color(0xFFF43F5E);
  static const Color systemPurple = Color(0xFF8B5CF6);
  static const Color systemTeal = Color(0xFF06B6D4);

  // ─────────────────────────────────────────────────
  // Context-Aware Colors
  // ─────────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBackground(BuildContext context) =>
      isDark(context) ? const Color(0xFF121214) : warmBackground;

  static Color getSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E1E22) : warmSurface;

  static Color getSurfaceSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A2A30) : warmSurfaceAlt;

  static Color getBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF3A3A42) : warmBorder;

  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? textLight : textDark;

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFFA1A1AA) : textMuted;

  static Color getTextTertiary(BuildContext context) =>
      isDark(context) ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);

  // ─────────────────────────────────────────────────
  // Dynamic Card Color Selector
  // Company-card colour is intentionally independent from recruitment status.
  // Status is communicated by [getStatusColor] only, so a purple company card
  // can never be mistaken for an interview stage.
  // ─────────────────────────────────────────────────
  static Color getCardColor(int index) {
    const colors = [
      cardPurple,
      cardYellow,
      cardBlue,
      cardGreen,
      cardCoral,
      cardTeal,
    ];
    return colors[index % colors.length];
  }

  static Color getJobCardColor(String status) {
    switch (status) {
      case 'Contoh':
        return const Color(0xFF8B5CF6);
      case 'Dikirim':
      case 'Tersimpan':
        return const Color(0xFF64748B); // Abu-Abu Slate Elegan
      case 'Tes / Psikotes':
        return const Color(0xFFFBBF24); // Kuning Amber Hangat
      case 'Interview HR':
      case 'HR Screening':
        return const Color(0xFF635BFF); // Ungu Cerah / Violet
      case 'Interview User':
      case 'Interview':
        return const Color(0xFF8B5CF6); // Ungu Indigo / Soft Violet
      case 'Offering':
        return const Color(0xFFEC4899); // Pink Fuchsia Cerah
      case 'Diterima':
        return const Color(0xFF34D399); // Hijau Lime / Fresh Mint
      case 'Ditolak':
        return const Color(0xFFDE4B3E); // Merah Karang / Coral Red
      default:
        return const Color(0xFF64748B);
    }
  }

  static Color getCompanyCardColor(String companyName, [String? status]) {
    if (status != null && status.isNotEmpty) {
      return getJobCardColor(status);
    }
    return getJobCardColor('Dikirim');
  }

  static bool isDarkCard(Color color) {
    return AppColorTokens.contrastRatio(color, Colors.white) >= 4.5;
  }

  static Color getCardForeground(Color color) =>
      AppColorTokens.light.onStrongCard(color);

  // ─────────────────────────────────────────────────
  // Status Color Mapping - Bright Dominant Palette
  // ─────────────────────────────────────────────────
  static Color getStatusColor(String status, {bool isDark = false}) {
    switch (status) {
      case 'Contoh':
        return isDark ? const Color(0xFFC4B5FD) : const Color(0xFF8B5CF6);
      case 'Dikirim':
      case 'Tersimpan':
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
      case 'Tes / Psikotes':
        return isDark ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B);
      case 'Interview HR':
      case 'HR Screening':
        return isDark ? const Color(0xFF818CF8) : const Color(0xFF635BFF);
      case 'Interview User':
      case 'Interview':
        return isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
      case 'Offering':
        return isDark ? const Color(0xFFF472B6) : const Color(0xFFEC4899);
      case 'Diterima':
        return isDark ? const Color(0xFF4ADE80) : const Color(0xFF10B981);
      case 'Ditolak':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFDE4B3E);
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    }
  }

  // ─────────────────────────────────────────────────
  // Theme Data Builder
  // ─────────────────────────────────────────────────
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  // Aliases for compatibility
  static ThemeData get appleLightTheme => lightTheme;
  static ThemeData get appleDarkTheme => darkTheme;
  static const Color lSystemBlue = systemBlue;
  static const Color lSystemGreen = systemGreen;
  static const Color lSystemOrange = systemOrange;
  static const Color lSystemRed = systemRed;
  static const Color lSystemPurple = systemPurple;
  static const Color lSystemTeal = systemTeal;

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121214) : warmBackground;
    final surf = isDark ? const Color(0xFF1E1E22) : warmSurface;
    final bdr = isDark ? const Color(0xFF3A3A42) : warmBorder;
    final txtPri = isDark ? textLight : textDark;
    final txtSec = isDark ? const Color(0xFFA1A1AA) : textMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: cardPurple,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: cardPurple,
        secondary: cardYellow,
        surface: surf,
        error: systemRed,
        onPrimary: Colors.white,
        onSecondary: textDark,
        onSurface: txtPri,
        onError: Colors.white,
      ),
      extensions: <ThemeExtension<dynamic>>[
        isDark ? AppColorTokens.dark : AppColorTokens.light,
      ],
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(
          brightness: brightness,
        ).textTheme.apply(bodyColor: txtPri, displayColor: txtPri),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: txtPri),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: txtPri,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: bdr, width: borderHairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: bdr, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: bdr, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardPurple, width: 2),
        ),
        hintStyle: TextStyle(
          color: txtSec,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: txtSec,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
