import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Saturated Vibrant Palette (Pixel-matched with Reference Image)
  static const Color cardPurple = Color(0xFF5C44E4); // Uber card & Stage 1
  static const Color cardYellow = Color(
    0xFFF8BA38,
  ); // Amazon card, Hero Header & Stage 3
  static const Color cardCoral = Color(0xFFE55444); // Stage 2 card
  static const Color cardGreen = Color(
    0xFFC1DE98,
  ); // Google expanded card & Stage 4
  static const Color cardDark = Color(
    0xFF1C1C1E,
  ); // Microsoft card & Action Buttons
  static const Color cardBlue = Color(0xFF3884F5);
  static const Color cardTeal = Color(0xFF32B0B8);

  // Typography Colors
  static const Color textDark = Color(0xFF121214);
  static const Color textMuted = Color(0xFF707074);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textLightMuted = Color(0xD9FFFFFF);

  // Status System Colors
  static const Color systemBlue = Color(0xFF3884F5);
  static const Color systemGreen = Color(0xFF2E7D32);
  static const Color systemOrange = Color(0xFFE65100);
  static const Color systemRed = Color(0xFFD32F2F);
  static const Color systemPurple = Color(0xFF5C44E4);
  static const Color systemTeal = Color(0xFF00838F);

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
  // Assigns vibrant theme color per card index or company name
  // ─────────────────────────────────────────────────
  static Color getCardColor(int index) {
    const colors = [
      cardPurple,
      cardYellow,
      cardDark,
      cardGreen,
      cardCoral,
      cardBlue,
    ];
    return colors[index % colors.length];
  }

  static Color getJobCardColor(String status) {
    switch (status) {
      case 'Contoh':
        return cardPurple;
      case 'Dikirim':
        return cardBlue; // Biru: Tahap Baru Terkirim
      case 'HR Screening':
        return const Color(0xFF00838F); // Toska: Seleksi Dokumen HR
      case 'Tes / Psikotes':
        return cardCoral; // Oranye Merah: Ujian / Tes Kemampuan
      case 'Interview HR':
        return cardYellow; // Kuning Mustard: Wawancara HR
      case 'Interview User':
        return cardPurple; // Ungu Elektrik: Wawancara User / Manager
      case 'Offering':
        return const Color(0xFF9C27B0); // Magenta: Offering & Kontrak
      case 'Diterima':
        return cardGreen; // Hijau Zaitun Muda: Diterima Kerja
      case 'Ditolak':
        return cardDark; // Hitam Arang: Ditolak / Closed
      default:
        return cardBlue;
    }
  }

  static Color getCompanyCardColor(String companyName, [String? status]) {
    if (status != null && status.isNotEmpty) {
      return getJobCardColor(status);
    }
    return getJobCardColor('Dikirim');
  }

  static bool isDarkCard(Color color) {
    return color == cardPurple ||
        color == cardDark ||
        color == cardCoral ||
        color == cardBlue ||
        color == const Color(0xFF00838F) ||
        color == const Color(0xFF9C27B0);
  }

  // ─────────────────────────────────────────────────
  // Status Color Mapping
  // ─────────────────────────────────────────────────
  static Color getStatusColor(String status, {bool isDark = false}) {
    switch (status) {
      case 'Contoh':
        return isDark ? const Color(0xFFB8A7FF) : const Color(0xFF7257D9);
      case 'Dikirim':
        return systemBlue;
      case 'HR Screening':
        return systemTeal;
      case 'Tes / Psikotes':
        return cardCoral;
      case 'Interview HR':
        return cardYellow;
      case 'Interview User':
        return cardPurple;
      case 'Offering':
        return const Color(0xFF9C27B0);
      case 'Diterima':
        return const Color(0xFF2E7D32);
      case 'Ditolak':
        return systemRed;
      default:
        return systemBlue;
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
