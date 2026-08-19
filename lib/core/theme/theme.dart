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

  static ThemeData get lightTheme {
    const Color lightScaffold = Color(0xFFFFFFFF);
    const Color lightSurface = Color(0xFFF3F4F6);
    const Color darkText = Color(0xFF111827);
    const Color greyText = Color(0xFF6B7280);
    const Color accessibleCyan = Color(
      0xFF0097A7,
    ); // Darker cyan for legibility on white

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accessibleCyan,
      scaffoldBackgroundColor: lightScaffold,
      cardColor: lightSurface,

      colorScheme: const ColorScheme.light(
        primary: accessibleCyan,
        secondary: vividOrange,
        surface: lightSurface,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightScaffold,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accessibleCyan),
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamilyFallback: fontFallbacks,
        ),
      ),

      cardTheme: CardThemeData(
        color: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withAlpha(30)),
        ),
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accessibleCyan,
          foregroundColor: Colors.white,
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

      textTheme: TextTheme(
        displayLarge: GoogleFonts.lexend(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkText,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        titleLarge: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkText,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkText,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: greyText,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: accessibleCyan,
          textStyle: const TextStyle(fontFamilyFallback: fontFallbacks),
        ),
      ),
    );
  }
}
