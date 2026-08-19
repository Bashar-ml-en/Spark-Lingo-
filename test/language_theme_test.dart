import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spark_lingo/shared/models/language_theme.dart';
import 'package:spark_lingo/core/theme/language_theme_registry.dart';

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  setUpAll(() {
    // Disable HTTP runtime fetching of google_fonts during tests
    GoogleFonts.config.allowRuntimeFetching = false;

    // Set up mock asset channel to bypass Google Fonts loading exceptions
    final manifestMap = {
      'google_fonts/Lexend-Bold.ttf': ['google_fonts/Lexend-Bold.ttf'],
      'google_fonts/Inter-Regular.ttf': ['google_fonts/Inter-Regular.ttf'],
      'google_fonts/Inter-Bold.ttf': ['google_fonts/Inter-Bold.ttf'],
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          if (message == null) return null;
          final String key = utf8.decode(
            message.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );

          // Handle binary manifest (used by newer Flutter versions) encoded with StandardMessageCodec
          if (key.endsWith('.bin') ||
              key.contains('manifest.bin') ||
              key.contains('Manifest.bin')) {
            return const StandardMessageCodec().encodeMessage(manifestMap);
          }

          // Handle text JSON manifest (used as fallback or older versions)
          if (key == 'AssetManifest.json' || key == 'AssetManifest.bin.json') {
            final Uint8List encoded = utf8.encoder.convert(
              json.encode(manifestMap),
            );
            return ByteData.view(encoded.buffer);
          }

          // If it's a font, return 0 bytes to simulate successful local loading of empty font data
          if (key.endsWith('.ttf') || key.endsWith('.otf')) {
            return ByteData(0);
          }
          return null;
        });

    // Load tokens synchronously from the assets file for the test environment
    final file = File('assets/language_design_tokens.json');
    final jsonContent = file.readAsStringSync();
    LanguageThemeRegistry.initialize(jsonContent);
  });

  group('LanguageTheme and LanguageThemeRegistry Tests', () {
    test(
      'Registry loads correct properties for English (en) and Arabic (ar)',
      () {
        final enTheme = LanguageThemeRegistry.themeFor('en');
        final arTheme = LanguageThemeRegistry.themeFor('ar');

        // Verify English (en) theme specs
        expect(enTheme.displayName, equals('English'));
        expect(enTheme.textDirection, equals(LanguageTextDirection.ltr));
        expect(enTheme.fontFamily, equals('Inter'));
        expect(enTheme.motif, equals('interlocking-speech-bubbles'));
        expect(enTheme.motifAsset, equals('assets/symbols/en_symbol.svg'));

        // Verify Arabic (ar) theme specs
        expect(arTheme.displayName, equals('العربية'));
        expect(arTheme.textDirection, equals(LanguageTextDirection.rtl));
        expect(arTheme.fontFamily, equals('NotoSansArabic'));
        expect(arTheme.motif, equals('calligraphic-connector-lines'));
        expect(arTheme.motifAsset, equals('assets/symbols/ar_symbol.svg'));

        // Verify color differences
        expect(enTheme.primaryColor, isNot(equals(arTheme.primaryColor)));
        expect(
          enTheme.primaryColor,
          equals(LanguageTheme.parseHexColor('#1F3A93')),
        );
        expect(
          arTheme.primaryColor,
          equals(LanguageTheme.parseHexColor('#006C35')),
        );
      },
    );

    test('Registry falls back gracefully on unknown codes', () {
      final unknownTheme = LanguageThemeRegistry.themeFor('xyz');

      expect(unknownTheme.fontFamily, equals('Inter'));
      expect(unknownTheme.textDirection, equals(LanguageTextDirection.ltr));
      expect(unknownTheme.motif, equals('generic-globe-lines'));
    });

    test('ThemeData is built correctly extending SparkTheme.lightTheme', () {
      final arTheme = LanguageThemeRegistry.themeFor('ar');
      final arThemeData = LanguageThemeRegistry.buildTheme(arTheme);

      expect(
        _contrastRatio(arThemeData.colorScheme.primary, Colors.white),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(
          arThemeData.colorScheme.primary,
          arThemeData.colorScheme.onPrimary,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(
          arThemeData.colorScheme.secondary,
          arThemeData.colorScheme.onSecondary,
        ),
        greaterThanOrEqualTo(4.5),
      );

      expect(
        arThemeData.appBarTheme.titleTextStyle?.fontFamily,
        equals('NotoSansArabic'),
      );
    });

    testWidgets('Directionality is set correctly in widget tree', (
      WidgetTester tester,
    ) async {
      final enTheme = LanguageThemeRegistry.themeFor('en');
      final arTheme = LanguageThemeRegistry.themeFor('ar');

      // Pump widget with English theme directionality
      await tester.pumpWidget(
        MaterialApp(
          theme: LanguageThemeRegistry.buildTheme(enTheme),
          home: Directionality(
            key: const ValueKey('dir_test'),
            textDirection: enTheme.textDirection == LanguageTextDirection.rtl
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: const Text('Direction Test'),
          ),
        ),
      );

      Directionality dirWidget = tester.widget(
        find.byKey(const ValueKey('dir_test')),
      );
      expect(dirWidget.textDirection, equals(TextDirection.ltr));

      // Pump widget with Arabic theme directionality
      await tester.pumpWidget(
        MaterialApp(
          theme: LanguageThemeRegistry.buildTheme(arTheme),
          home: Directionality(
            key: const ValueKey('dir_test'),
            textDirection: arTheme.textDirection == LanguageTextDirection.rtl
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: const Text('Direction Test'),
          ),
        ),
      );

      dirWidget = tester.widget(find.byKey(const ValueKey('dir_test')));
      expect(dirWidget.textDirection, equals(TextDirection.rtl));
    });
  });
}
