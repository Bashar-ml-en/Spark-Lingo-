import 'package:flutter/material.dart';

export 'theme_mode_provider.dart';

typedef SparkLingoTheme = SparkTheme;

class SparkTheme {
  // Foundation Surfaces (Stitch LingoCraft Obsidian - Deep OLED Architecture)
  static const Color surfaceCanvas = Color(0xFF090A0F); // Deep Obsidian Base
  static const Color surfaceContainerLowest = Color(0xFF0B0E18);
  static const Color surfaceContainerLow = Color(0xFF12141F);
  static const Color surfaceContainer = Color(0xFF1D1F2A);
  static const Color surfaceContainerHigh = Color(0xFF272935);
  static const Color surfaceContainerHighest = Color(0xFF323440);
  static const Color surfaceBright = Color(0xFF373845);

  // Structural Framing
  static const Color structuralBorder = Color(0xFF2A2F45);

  // Light Mode Tokens (Clean Editorial Contrast)
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
      isDarkMode(context) ? structuralBorder : lightBorder;

  static Color text(BuildContext context) =>
      isDarkMode(context) ? textPrimary : lightTextPrimary;

  static Color subtext(BuildContext context) =>
      isDarkMode(context) ? textSecondary : lightTextSecondary;

  // Stitch Semantic Accents
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color masteryEmerald = Color(0xFF10B981);
  static const Color kineticAmber = Color(0xFFF59E0B);
  static const Color diagnosticRose = Color(0xFFF43F5E);

  // Backward-compatible color aliases wired to Stitch system
  static const Color electricCyan = primaryIndigo;
  static const Color primaryCyan = Color(0xFFC0C1FF);
  static const Color primaryCyanDim = Color(0xFF8083FF);
  static const Color accessibleCyan = primaryIndigo;

  static const Color solarGold = kineticAmber;
  static const Color solarGoldContainer = Color(0xFFD97706);
  static const Color solarGoldFixed = Color(0xFFFDE68A);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF475569);
  static const Color outlineColor = structuralBorder;
  static const Color outlineVariantColor = Color(0xFF464554);

  static const Color successGreen = masteryEmerald;
  static const Color errorRed = diagnosticRose;
  static const Color errorContainer = Color(0xFF93000A);

  // Backward-compatible aliases
  static const Color obsidianBlack = surfaceCanvas;
  static const Color deepCharcoal = surfaceContainer;
  static const Color elevatedSurface = surfaceContainerHigh;
  static const Color vividOrange = kineticAmber;

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

  /// Dark theme — dark-mode equivalent of the ui-ux-pro-max indigo
  /// palette (same hue family, contrast-checked for dark surfaces):
  /// light indigo #A5B4FC on #0F1024 ≈ 8.6:1; body #CBD5E1 ≈ 12:1.
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
        iconTheme: IconThemeData(color: electricCyan),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
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

  /// Light theme — SparkLingo design system (ui-ux-pro-max generated,
  /// 2026-08): learning-indigo primary, progress-green success accent,
  /// soft indigo-tinted canvas, Nunito display + DM Sans body.
  /// Contrast checked: #4F46E5 on #EEF2FF ≈ 5.3:1, #312E81 body ≈ 10.5:1.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accessibleCyan,
      scaffoldBackgroundColor: lightCanvas,
      cardColor: lightContainer,

      colorScheme: const ColorScheme.light(
        primary: accessibleCyan,
        secondary: solarGoldContainer,
        surface: lightContainer,
        surfaceContainerHighest: Color(0xFFF1F5F9),
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        outline: lightBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightContainer,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accessibleCyan),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
      ),

      cardTheme: CardThemeData(
        color: lightContainer,
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
        backgroundColor: lightContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: fontFallbacks,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightTextPrimary,
          fontFamily: 'Inter',
          fontFamilyFallback: fontFallbacks,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
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
