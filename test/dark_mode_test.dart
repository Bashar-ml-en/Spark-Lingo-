import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spark_lingo/core/theme/theme_mode_provider.dart';
import 'package:spark_lingo/core/theme/theme.dart';
import 'package:spark_lingo/shared/models/language_theme.dart';
import 'package:spark_lingo/core/theme/language_theme_registry.dart';

void main() {
  // GoogleFonts text styles need an initialized binding. Runtime fetching
  // stays enabled (as in widget_test): failed fetches degrade gracefully,
  // while disabling it throws because fonts are not bundled as assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('themeModeProvider', () {
    test('defaults to light', () {
      final container = ProviderContainer();
      expect(container.read(themeModeProvider), ThemeMode.light);
      container.dispose();
    });

    test('setMode updates state', () async {
      final container = ProviderContainer();
      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      await container
          .read(themeModeProvider.notifier)
          .setMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
      container.dispose();
    });
  });

  group('SparkTheme', () {
    test('light and dark themes are distinct brightnesses', () {
      final light = _silenceFontFetch(() => SparkTheme.lightTheme);
      final dark = _silenceFontFetch(() => SparkTheme.darkTheme);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
    });

    test('dark theme surfaces differ from light', () {
      final light = _silenceFontFetch(() => SparkTheme.lightTheme);
      final dark = _silenceFontFetch(() => SparkTheme.darkTheme);
      expect(
        dark.scaffoldBackgroundColor,
        isNot(light.scaffoldBackgroundColor),
      );
    });
  });

  group('LanguageThemeRegistry dark variant', () {
    test('buildTheme honours brightness parameter', () {
      const sample = LanguageTheme(
        displayName: 'Test',
        flags: [],
        primaryColor: Color(0xFF1D4ED8),
        accentColor: Color(0xFFF59E0B),
        fontFamily: 'Inter',
        textDirection: LanguageTextDirection.ltr,
        motif: '',
        motifAsset: '',
      );
      final light = _silenceFontFetch(
        () => LanguageThemeRegistry.buildTheme(sample),
      );
      final dark = _silenceFontFetch(
        () => LanguageThemeRegistry.buildTheme(
          sample,
          brightness: Brightness.dark,
        ),
      );
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(
        dark.scaffoldBackgroundColor,
        isNot(light.scaffoldBackgroundColor),
      );
    });

    test('dark accent stays readable (>= 4.5:1 vs obsidian)', () {
      // Deep navy fails AA on a dark canvas and must be brightened.
      const sample = LanguageTheme(
        displayName: 'Dark Accent',
        flags: [],
        primaryColor: Color(0xFF0D1B3E),
        accentColor: Color(0xFF0D1B3E),
        fontFamily: 'Inter',
        textDirection: LanguageTextDirection.ltr,
        motif: '',
        motifAsset: '',
      );
      final dark = _silenceFontFetch(
        () => LanguageThemeRegistry.buildTheme(
          sample,
          brightness: Brightness.dark,
        ),
      );
      final primary = dark.colorScheme.primary;
      final ratio = _contrastRatio(primary, SparkTheme.obsidianBlack);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });
}

/// Constructs a theme while swallowing the asynchronous font-fetch errors
/// GoogleFonts raises in the offline test environment. The theme object
/// itself is built synchronously and is valid regardless.
T _silenceFontFetch<T>(T Function() build) {
  late T result;
  runZonedGuarded(
    () {
      result = build();
    },
    (error, stack) {
      // GoogleFonts runtime fetch failures in tests are irrelevant to what
      // is being asserted here (colors, brightness, contrast).
    },
  );
  return result;
}

double _contrastRatio(Color a, Color b) {
  double luminance(Color c) {
    double f(double v) {
      final s = v / 255;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }
    return 0.2126 * f((c.r * 255.0).round().clamp(0, 255).toDouble()) +
        0.7152 * f((c.g * 255.0).round().clamp(0, 255).toDouble()) +
        0.0722 * f((c.b * 255.0).round().clamp(0, 255).toDouble());
  }
  final l1 = luminance(a) + 0.05;
  final l2 = luminance(b) + 0.05;
  return l1 > l2 ? l1 / l2 : l2 / l1;
}
