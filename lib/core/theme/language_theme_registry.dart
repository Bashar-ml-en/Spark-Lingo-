import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/language_theme.dart';
import 'theme.dart';

class LanguageThemeRegistry {
  static Map<String, LanguageTheme> _themes = {};
  static LanguageTheme? _fallbackTheme;

  /// Expose the list of all configured language codes.
  static List<String> get availableLanguageCodes => _themes.keys.toList();

  /// Initialize the registry with the JSON string content.
  static void initialize(String jsonContent) {
    final data = json.decode(jsonContent) as Map<String, dynamic>;
    final languages = data['languages'] as Map<String, dynamic>;

    _themes = languages.map((key, value) {
      return MapEntry(
        key.toLowerCase(),
        LanguageTheme.fromJson(value as Map<String, dynamic>),
      );
    });

    final fallback = data['fallback_theme'] as Map<String, dynamic>;
    _fallbackTheme = LanguageTheme(
      displayName: fallback['display_name'] as String? ?? 'Default',
      flags: fallback['flags'] != null
          ? (fallback['flags'] as List<dynamic>)
                .map((item) => FlagInfo.fromJson(item as Map<String, dynamic>))
                .toList()
          : const [],
      primaryColor: LanguageTheme.parseHexColor(
        fallback['primary_color'] as String,
      ),
      accentColor: LanguageTheme.parseHexColor(
        fallback['accent_color'] as String,
      ),
      fontFamily: fallback['font_family'] as String? ?? 'Inter',
      textDirection: (fallback['text_direction'] as String? ?? 'ltr') == 'rtl'
          ? LanguageTextDirection.rtl
          : LanguageTextDirection.ltr,
      motif: fallback['motif'] as String? ?? 'generic-globe-lines',
      motifAsset:
          fallback['motif_asset'] as String? ??
          'assets/symbols/en_symbol.svg', // default fallback
    );
  }

  /// Get the language theme for the specified language code.
  static LanguageTheme themeFor(String langCode) {
    if (_fallbackTheme == null) {
      throw StateError(
        "LanguageThemeRegistry is not initialized. Call initialize() first.",
      );
    }

    // Clean code (e.g. 'es-ES' -> 'es')
    final cleanCode = langCode.split('-').first.toLowerCase();
    final theme = _themes[cleanCode] ?? _themes[langCode.toLowerCase()];
    return theme ?? _fallbackTheme!;
  }

  static double _contrastRatio(Color first, Color second) {
    final lighter = first.computeLuminance() > second.computeLuminance()
        ? first.computeLuminance()
        : second.computeLuminance();
    final darker = first.computeLuminance() > second.computeLuminance()
        ? second.computeLuminance()
        : first.computeLuminance();
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Language identity colors are often designed for a flag, not a white UI.
  /// Darken them only when necessary to meet the normal-text 4.5:1 target.
  static Color _accessibleOnLightSurface(Color color) {
    for (var step = 0; step <= 20; step++) {
      final candidate = Color.lerp(color, Colors.black, step / 20)!;
      if (_contrastRatio(candidate, Colors.white) >= 4.5) return candidate;
    }
    return Colors.black;
  }

  static Color _bestForeground(Color background) =>
      _contrastRatio(background, Colors.white) >=
          _contrastRatio(background, Colors.black)
      ? Colors.white
      : Colors.black;

  /// Build a ThemeData extending SparkTheme.lightTheme for a given LanguageTheme.
  static ThemeData buildTheme(LanguageTheme langTheme) {
    final baseTheme = SparkTheme.lightTheme;
    final primary = _accessibleOnLightSurface(langTheme.primaryColor);
    final secondary = _accessibleOnLightSurface(langTheme.accentColor);
    final onPrimary = _bestForeground(primary);
    final onSecondary = _bestForeground(secondary);

    // Create new color scheme overriding primary and secondary colors
    final colorScheme = baseTheme.colorScheme.copyWith(
      primary: primary,
      secondary: secondary,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
    );

    // Apply the language-specific font family to the base text theme
    final textTheme = baseTheme.textTheme.copyWith(
      displayLarge: baseTheme.textTheme.displayLarge?.copyWith(
        fontFamily: langTheme.fontThemeName,
      ),
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
        fontFamily: langTheme.fontThemeName,
      ),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
        fontFamily: langTheme.fontThemeName,
      ),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
        fontFamily: langTheme.fontThemeName,
      ),
      labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
        fontFamily: langTheme.fontThemeName,
      ),
    );

    return baseTheme.copyWith(
      primaryColor: primary,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        iconTheme: baseTheme.appBarTheme.iconTheme?.copyWith(color: primary),
        titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: langTheme.fontThemeName,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(primary),
          foregroundColor: WidgetStateProperty.all(onPrimary),
          textStyle: WidgetStateProperty.all(
            baseTheme.elevatedButtonTheme.style?.textStyle
                ?.resolve({})
                ?.copyWith(fontFamily: langTheme.fontThemeName),
          ),
        ),
      ),
    );
  }
}

extension on LanguageTheme {
  /// Resolves the actual font family name or returns null if it is Inter (the base default).
  String? get fontThemeName {
    // If it is 'Inter', we let it fallback to base typography which already resolves 'Inter' or GoogleFonts.inter/lexend.
    // Otherwise we return the Noto font family string.
    return fontFamily == 'Inter' ? null : fontFamily;
  }
}

final localActiveLanguageProvider = StateProvider<String?>((ref) => null);
