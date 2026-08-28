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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: electricCyan,
      scaffoldBackgroundColor: obsidianBlack,
      cardColor: deepCharcoal,

      colorScheme: const ColorScheme.dark(
        primary: electricCyan,
        secondary: vividOrange,
        surface: deepCharcoal,
        error: errorRed,
        onPrimary: obsidianBlack,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: obsidianBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamilyFallback: fontFallbacks,
        ),
        iconTheme: IconThemeData(color: electricCyan),
      ),

      cardTheme: CardThemeData(
        color: deepCharcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricCyan,
          foregroundColor: obsidianBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamilyFallback: fontFallbacks,
          ),
        ),
      ),

      // Text Theme mapping with Google Fonts + Safe system fallbacks
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lexend(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        titleLarge: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: electricCyan,
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
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: mutedInk,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
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
