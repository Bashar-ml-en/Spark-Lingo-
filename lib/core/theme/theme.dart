import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SparkTheme {
  // Brand Color Tokens
  static const Color obsidianBlack = Color(0xFF0D0D0F);
  static const Color deepCharcoal = Color(0xFF1A1A2E);
  static const Color elevatedSurface = Color(0xFF252540);
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color vividOrange = Color(0xFFFF6B00);
  static const Color successGreen = Color(0xFF00E676);
  static const Color errorRed = Color(0xFFFF1744);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);

  // System Typography Fallbacks (Preventing FOIT/CLS)
  static const List<String> fontFallbacks = [
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  /// Dark theme — dark-mode equivalent of the ui-ux-pro-max indigo
  /// palette (same hue family, contrast-checked for dark surfaces):
  /// light indigo #A5B4FC on #0F1024 ≈ 8.6:1; body #CBD5E1 ≈ 12:1.
  static ThemeData get darkTheme {
    const Color nightCanvas = Color(0xFF0F1024);
    const Color nightSurface = Color(0xFF1B1D3A);
    const Color primaryIndigo = Color(0xFFA5B4FC);
    const Color accentGreen = Color(0xFF4ADE80);
    const Color bodyInk = Color(0xFFCBD5E1);
    const Color mutedInk = Color(0xFF94A3B8);
    const Color borderIndigo = Color(0xFF373A63);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryIndigo,
      scaffoldBackgroundColor: nightCanvas,
      cardColor: nightSurface,

      colorScheme: const ColorScheme.dark(
        primary: primaryIndigo,
        secondary: accentGreen,
        tertiary: Color(0xFF818CF8),
        surface: nightSurface,
        error: errorRed,
        onPrimary: Color(0xFF0F1024),
        onSecondary: Color(0xFF0F1024),
        onSurface: bodyInk,
        onSurfaceVariant: mutedInk,
        outline: borderIndigo,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: nightCanvas,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryIndigo),
        titleTextStyle: TextStyle(
          color: bodyInk,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamilyFallback: fontFallbacks,
        ),
      ),

      cardTheme: CardThemeData(
        color: nightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderIndigo, width: 1),
        ),
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigo,
          foregroundColor: const Color(0xFF0F1024),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamilyFallback: fontFallbacks,
          ),
        ),
      ),

      // Typography: Nunito (display) + DM Sans (body), lineHeight tokens
      // per ux rule #72 (1.5-1.75 for body text).
      textTheme: TextTheme(
        displayLarge: GoogleFonts.nunito(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: bodyInk,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: bodyInk,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: bodyInk,
          textStyle: const TextStyle(
            fontFamilyFallback: fontFallbacks,
            height: 1.55,
          ),
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: mutedInk,
          textStyle: const TextStyle(
            fontFamilyFallback: fontFallbacks,
            height: 1.55,
          ),
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primaryIndigo,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
      ),
    );
  }

  /// Light theme — SparkLingo design system (ui-ux-pro-max generated,
  /// 2026-08): learning-indigo primary, progress-green success accent,
  /// soft indigo-tinted canvas, Nunito display + DM Sans body.
  /// Contrast checked: #4F46E5 on #EEF2FF ≈ 5.3:1, #312E81 body ≈ 10.5:1.
  static ThemeData get lightTheme {
    const Color learningIndigo = Color(0xFF4F46E5);
    const Color indigoLight = Color(0xFF818CF8);
    const Color progressGreen = Color(0xFF16A34A);
    const Color canvas = Color(0xFFEEF2FF);
    const Color cardSurface = Color(0xFFFFFFFF);
    const Color ink = Color(0xFF312E81);
    const Color mutedInk = Color(0xFF475569);
    const Color borderIndigo = Color(0xFFC7D2FE);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: learningIndigo,
      scaffoldBackgroundColor: canvas,
      cardColor: cardSurface,

      colorScheme: const ColorScheme.light(
        primary: learningIndigo,
        secondary: progressGreen,
        tertiary: indigoLight,
        surface: cardSurface,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: ink,
        onSurfaceVariant: mutedInk,
        outline: borderIndigo,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: learningIndigo),
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamilyFallback: fontFallbacks,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderIndigo, width: 1),
        ),
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: learningIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamilyFallback: fontFallbacks,
          ),
        ),
      ),

      // Typography: Nunito (rounded display) + DM Sans (geometric body) —
      // the ui-ux-pro-max pairing for gamified education apps.
      textTheme: TextTheme(
        displayLarge: GoogleFonts.nunito(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: ink,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: ink,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ink,
          textStyle: const TextStyle(
            fontFamilyFallback: fontFallbacks,
            height: 1.55,
          ),
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: mutedInk,
          textStyle: const TextStyle(
            fontFamilyFallback: fontFallbacks,
            height: 1.55,
          ),
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: learningIndigo,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
      ),
    );
  }
}
