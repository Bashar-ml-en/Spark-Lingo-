import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef SparkLingoTheme = SparkTheme;

/// Riverpod provider for active application ThemeMode (Dark, Light, System)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class SparkTheme {
  // Brand Color Tokens (Stitch World-Class System - Dark Mode)
  static const Color surfaceCanvas = Color(0xFF051424); // Deep Space Navy
  static const Color surfaceContainer = Color(0xFF122131);
  static const Color surfaceContainerHigh = Color(0xFF1C2B3C);
  static const Color surfaceContainerHighest = Color(0xFF273647);
  static const Color surfaceContainerLow = Color(0xFF0D1C2D);
  static const Color surfaceContainerLowest = Color(0xFF010F1F);
  static const Color surfaceBright = Color(0xFF2C3A4C);

  // Light Mode Tokens
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightContainer = Color(0xFFFFFFFF);
  static const Color lightContainerHigh = Color(0xFFF1F5F9);
  static const Color lightContainerHighest = Color(0xFFE2E8F0);
  static const Color lightContainerLow = Color(0xFFFAFAFA);
  static const Color lightContainerLowest = Color(0xFFF8FAFC);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dynamic Theme Helpers
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDarkMode(context) ? surfaceCanvas : lightCanvas;

  static Color cardBg(BuildContext context) =>
      isDarkMode(context) ? surfaceContainer : lightContainer;

  static Color cardHighBg(BuildContext context) =>
      isDarkMode(context) ? surfaceContainerHigh : lightContainerHigh;

  static Color border(BuildContext context) =>
      isDarkMode(context) ? surfaceContainerHighest : lightBorder;

  static Color text(BuildContext context) =>
      isDarkMode(context) ? textPrimary : lightTextPrimary;

  static Color subtext(BuildContext context) =>
      isDarkMode(context) ? textSecondary : lightTextSecondary;

  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color primaryCyan = Color(0xFFC3F5FF);
  static const Color primaryCyanDim = Color(0xFF00DAF3);
  static const Color accessibleCyan = Color(0xFF0097A7);

  static const Color solarGold = Color(0xFFFFB77A);
  static const Color solarGoldContainer = Color(0xFFD37B1D);
  static const Color solarGoldFixed = Color(0xFFFFDCC2);

  static const Color textPrimary = Color(0xFFD4E4FA);
  static const Color textSecondary = Color(0xFFBAC9CC);
  static const Color outlineColor = Color(0xFF849396);
  static const Color outlineVariantColor = Color(0xFF3B494C);

  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  // Backward-compatible aliases
  static const Color obsidianBlack = surfaceCanvas;
  static const Color deepCharcoal = surfaceContainer;
  static const Color elevatedSurface = surfaceContainerHigh;
  static const Color vividOrange = solarGold;

  // System Typography Fallbacks (Preventing FOIT/CLS)
  static const List<String> fontFallbacks = [
    'Plus Jakarta Sans',
    'Inter',
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
      scaffoldBackgroundColor: surfaceCanvas,
      cardColor: surfaceContainer,

      colorScheme: const ColorScheme.dark(
        primary: electricCyan,
        primaryContainer: electricCyan,
        onPrimary: Color(0xFF00363D),
        secondary: solarGold,
        secondaryContainer: solarGoldContainer,
        onSecondary: Color(0xFF4C2700),
        surface: surfaceContainer,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceBright: surfaceBright,
        error: errorRed,
        errorContainer: errorContainer,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: outlineColor,
        outlineVariant: outlineVariantColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceCanvas,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
        iconTheme: IconThemeData(color: electricCyan),
      ),

      cardTheme: CardThemeData(
        color: surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricCyan,
          foregroundColor: const Color(0xFF00363D),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Plus Jakarta Sans',
            fontFamilyFallback: fontFallbacks,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: electricCyan, width: 1.5),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // Text Theme with Plus Jakarta Sans & Inter font fallbacks
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: 'Inter',
          fontFamilyFallback: fontFallbacks,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          fontFamily: 'Inter',
          fontFamilyFallback: fontFallbacks,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: electricCyan,
          fontFamily: 'Inter',
          fontFamilyFallback: fontFallbacks,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const Color lightScaffold = Color(0xFFF8FAFC);
    const Color lightSurface = Color(0xFFFFFFFF);
    const Color lightBorder = Color(0xFFE2E8F0);
    const Color darkText = Color(0xFF0F172A);
    const Color greyText = Color(0xFF64748B);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accessibleCyan,
      scaffoldBackgroundColor: lightScaffold,
      cardColor: lightSurface,

      colorScheme: const ColorScheme.light(
        primary: accessibleCyan,
        secondary: solarGoldContainer,
        surface: lightSurface,
        surfaceContainerHighest: Color(0xFFF1F5F9),
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accessibleCyan),
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
      ),

      cardTheme: CardThemeData(
        color: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accessibleCyan,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Plus Jakarta Sans',
            fontFamilyFallback: fontFallbacks,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accessibleCyan, width: 1.5),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: darkText,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkText,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkText,
          fontFamily: 'Inter',
          fontFamilyFallback: fontFallbacks,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: greyText,
          fontFamily: 'Inter',
          fontFamilyFallback: fontFallbacks,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: accessibleCyan,
          fontFamily: 'Inter',
          fontFamilyFallback: fontFallbacks,
        ),
      ),
    );
  }
}
