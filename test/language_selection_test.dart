import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spark_lingo/shared/models/language_theme.dart';
import 'package:spark_lingo/core/theme/language_theme_registry.dart';
import 'package:spark_lingo/core/constants/language_catalog.dart';
import 'package:spark_lingo/features/onboarding/widgets/flag_tile.dart';
import 'package:spark_lingo/shared/widgets/flag_grid.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;

    // Set up mock asset channel to bypass Google Fonts and SVG loading exceptions
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

          // Handle binary manifest
          if (key.endsWith('.bin') ||
              key.contains('manifest.bin') ||
              key.contains('Manifest.bin')) {
            return const StandardMessageCodec().encodeMessage(manifestMap);
          }
          // Handle text manifest
          if (key == 'AssetManifest.json' || key == 'AssetManifest.bin.json') {
            final Uint8List encoded = utf8.encoder.convert(
              json.encode(manifestMap),
            );
            return ByteData.view(encoded.buffer);
          }
          // Return dummy SVG data to bypass SvgPicture.asset load failures
          if (key.endsWith('.svg')) {
            final Uint8List bytes = utf8.encoder.convert(
              '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"></svg>',
            );
            return ByteData.view(bytes.buffer);
          }
          // Return dummy font data
          if (key.endsWith('.ttf') || key.endsWith('.otf')) {
            return ByteData(0);
          }
          return null;
        });

    // Initialize registry
    final file = File('assets/language_design_tokens.json');
    final jsonContent = file.readAsStringSync();
    LanguageThemeRegistry.initialize(jsonContent);
  });

  group('Launch language availability', () {
    test(
      'only languages with shipped curriculum and visual assets are launch enabled',
      () {
        final launchCodes = LanguageThemeRegistry.availableLanguageCodes
            .where(LanguageCatalog.hasBundledCurriculum)
            .toSet();

        expect(
          launchCodes,
          containsAll(<String>{'en', 'es', 'fr', 'zh', 'hi', 'ru', 'ar'}),
        );
        expect(launchCodes, isNot(contains('de')));
        expect(launchCodes, isNot(contains('ja')));
        expect(launchCodes, isNot(contains('ms')));
      },
    );
  });

  group('FlagTile Widget Tests', () {
    testWidgets('Renders names and triggers onTap immediately', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagTile(
              nativeName: 'Deutsch',
              englishName: 'German',
              flagAsset: 'assets/flags/de_de.svg',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify labels render correctly
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('German'), findsOneWidget);

      // Tap the tile
      await tester.tap(find.byType(FlagTile));
      expect(tapped, isTrue);
    });
  });

  group('FlagGrid Widget Tests', () {
    testWidgets('Filters grid by search query', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagGrid(onLanguageSelected: (langCode, flag) {}),
          ),
        ),
      );

      // Only launch-enabled languages are exposed to a new learner.
      expect(find.byType(FlagTile), findsAtLeastNWidgets(2));
      expect(find.text('Español').first, findsOneWidget);
      expect(find.text('Deutsch'), findsNothing);

      // Future themes remain hidden even when searched for.
      await tester.enterText(find.byType(TextField), 'German');
      await tester.pump();

      expect(find.text('No languages found'), findsOneWidget);

      // Search for "日本語"
      await tester.enterText(find.byType(TextField), '日本語');
      await tester.pump();

      expect(find.text('No languages found'), findsOneWidget);
    });

    testWidgets('French (single flag) invokes callback immediately on tap', (
      WidgetTester tester,
    ) async {
      String? selectedLang;
      FlagInfo? selectedFlag;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagGrid(
              onLanguageSelected: (langCode, flag) {
                selectedLang = langCode;
                selectedFlag = flag;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Français').first);
      await tester.pump();

      expect(selectedLang, equals('fr'));
      expect(selectedFlag?.locale, equals('fr-FR'));
      expect(selectedFlag?.countryName, equals('France'));
    });

    testWidgets('English (multiple flags) triggers bottom sheet choice', (
      WidgetTester tester,
    ) async {
      String? selectedLang;
      FlagInfo? selectedFlag;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagGrid(
              onLanguageSelected: (langCode, flag) {
                selectedLang = langCode;
                selectedFlag = flag;
              },
            ),
          ),
        ),
      );

      // Tap English tile
      await tester.tap(find.text('English').first);
      await tester.pumpAndSettle(); // Wait for bottom sheet slide-in animation

      // Bottom sheet should be visible and showing options
      expect(find.text('Select region for English'), findsOneWidget);
      expect(find.text('United Kingdom'), findsOneWidget);
      expect(find.text('United States'), findsOneWidget);

      // Tap "United States"
      await tester.tap(find.text('United States'));
      await tester.pumpAndSettle(); // Wait for bottom sheet slide-out animation

      expect(selectedLang, equals('en'));
      expect(selectedFlag?.locale, equals('en-US'));
      expect(selectedFlag?.countryName, equals('United States'));
    });
  });
}
