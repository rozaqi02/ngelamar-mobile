import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─────────────────────────────────────────────────
  // Apple iOS 18 Dark Mode — System Colors
  // ─────────────────────────────────────────────────
  static const Color background       = Color(0xFF000000);
  static const Color surface          = Color(0xFF1C1C1E);
  static const Color surfaceSecondary = Color(0xFF2C2C2E);
  static const Color surfaceLight     = Color(0xFF3A3A3C);
  static const Color border           = Color(0xFF38383A);
  static const Color borderDark       = Color(0xFF38383A);

  static const Color systemBlue    = Color(0xFF0A84FF);
  static const Color systemIndigo  = Color(0xFF5E5CE6);
  static const Color systemGreen   = Color(0xFF30D158);
  static const Color systemOrange  = Color(0xFFFF9F0A);
  static const Color systemRed     = Color(0xFFFF453A);
  static const Color systemPurple  = Color(0xFFBF5AF2);
  static const Color systemTeal    = Color(0xFF64D2FF);
  static const Color systemYellow  = Color(0xFFFFD60A);

  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFF8E8E93);
  static const Color textTertiary   = Color(0xFF636366);
  static const Color textQuaternary = Color(0xFF48484A);

  // ─────────────────────────────────────────────────
  // Apple iOS 18 Light Mode — System Colors
  // ─────────────────────────────────────────────────
  static const Color lBackground       = Color(0xFFF2F2F7);
  static const Color lSurface          = Color(0xFFFFFFFF);
  static const Color lSurfaceSecondary = Color(0xFFE5E5EA);
  static const Color lSurfaceLight     = Color(0xFFD1D1D6);
  static const Color lBorder           = Color(0xFFC6C6C8);

  static const Color lSystemBlue    = Color(0xFF007AFF);
  static const Color lSystemGreen   = Color(0xFF34C759);
  static const Color lSystemOrange  = Color(0xFFFF9500);
  static const Color lSystemRed     = Color(0xFFFF3B30);
  static const Color lSystemPurple  = Color(0xFFAF52DE);
  static const Color lSystemTeal    = Color(0xFF32ADE6);

  static const Color lTextPrimary    = Color(0xFF000000);
  static const Color lTextSecondary  = Color(0xFF6E6E73);
  static const Color lTextTertiary   = Color(0xFF8E8E93);

  // ─────────────────────────────────────────────────
  // Dynamic Context Color Getters (Light/Dark Aware)
  // ─────────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBackground(BuildContext context) =>
      isDark(context) ? background : lBackground;

  static Color getSurface(BuildContext context) =>
      isDark(context) ? surface : lSurface;

  static Color getSurfaceSecondary(BuildContext context) =>
      isDark(context) ? surfaceSecondary : lSurfaceSecondary;

  static Color getSurfaceLight(BuildContext context) =>
      isDark(context) ? surfaceLight : lSurfaceLight;

  static Color getBorder(BuildContext context) =>
      isDark(context) ? border : lBorder;

  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? textPrimary : lTextPrimary;

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? textSecondary : lTextSecondary;

  static Color getTextTertiary(BuildContext context) =>
      isDark(context) ? textTertiary : lTextTertiary;

  // ─────────────────────────────────────────────────
  // Status Color Mapping
  // ─────────────────────────────────────────────────
  static Color getStatusColor(String status, {bool isDark = true}) {
    final blue   = isDark ? systemBlue   : lSystemBlue;
    final teal   = isDark ? systemTeal   : lSystemTeal;
    final orange = isDark ? systemOrange : lSystemOrange;
    final purple = isDark ? systemPurple : lSystemPurple;
    final green  = isDark ? systemGreen  : lSystemGreen;
    final red    = isDark ? systemRed    : lSystemRed;

    switch (status) {
      case 'Dikirim':        return blue;
      case 'HR Screening':   return teal;
      case 'Tes / Psikotes': return orange;
      case 'Interview HR':   return orange;
      case 'Interview User': return orange;
      case 'Offering':       return purple;
      case 'Diterima':       return green;
      case 'Ditolak':        return red;
      default:               return blue;
    }
  }

  // ─────────────────────────────────────────────────
  // Apple iOS 18 Dark Theme
  // ─────────────────────────────────────────────────
  static ThemeData get appleDarkTheme => _buildTheme(Brightness.dark);

  // ─────────────────────────────────────────────────
  // Apple iOS 18 Light Theme
  // ─────────────────────────────────────────────────
  static ThemeData get appleLightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDarkMode = brightness == Brightness.dark;

    final bg       = isDarkMode ? background       : lBackground;
    final surf     = isDarkMode ? surface          : lSurface;
    final surfSec  = isDarkMode ? surfaceSecondary : lSurfaceSecondary;
    final bdr      = isDarkMode ? border           : lBorder;
    final blue     = isDarkMode ? systemBlue       : lSystemBlue;
    final green    = isDarkMode ? systemGreen      : lSystemGreen;
    final red      = isDarkMode ? systemRed        : lSystemRed;
    final txtPri   = isDarkMode ? textPrimary      : lTextPrimary;
    final txtSec   = isDarkMode ? textSecondary    : lTextSecondary;
    final txtTer   = isDarkMode ? textTertiary     : lTextTertiary;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: blue,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: blue,
        secondary: green,
        surface: surf,
        error: red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: txtPri,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme.apply(
              bodyColor: txtPri,
              displayColor: txtPri,
            ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surf,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: txtPri),
        titleTextStyle: GoogleFonts.inter(
          color: txtPri,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: bdr, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfSec,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bdr, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bdr, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: red, width: 0.8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: red, width: 1.5),
        ),
        hintStyle: TextStyle(color: txtTer, fontSize: 15, fontWeight: FontWeight.w400),
        labelStyle: TextStyle(color: txtSec, fontSize: 13, fontWeight: FontWeight.w500),
        floatingLabelStyle: TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        prefixIconColor: txtSec,
        suffixIconColor: txtSec,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: blue,
        unselectedLabelColor: txtSec,
        indicatorColor: blue,
        dividerColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerColor: bdr,
      dividerTheme: DividerThemeData(color: bdr, thickness: 0.5, space: 0),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDarkMode ? surfaceLight : lSurfaceSecondary,
        contentTextStyle: GoogleFonts.inter(color: txtPri, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: IconThemeData(color: txtPri),
      listTileTheme: ListTileThemeData(
        tileColor: surf,
        iconColor: blue,
        textColor: txtPri,
        subtitleTextStyle: TextStyle(color: txtSec, fontSize: 13),
      ),
    );
  }
}
