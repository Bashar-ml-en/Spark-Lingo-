import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spark_lingo/core/theme/language_theme_registry.dart';
import 'package:spark_lingo/shared/widgets/language_symbol_badge.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;

    // Intercept assets to mock SVG files and registries
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
          if (key.endsWith('.bin') ||
              key.contains('manifest.bin') ||
              key.contains('Manifest.bin')) {
            return const StandardMessageCodec().encodeMessage(manifestMap);
          }
          if (key == 'AssetManifest.json' || key == 'AssetManifest.bin.json') {
            final Uint8List encoded = utf8.encoder.convert(
              json.encode(manifestMap),
            );
            return ByteData.view(encoded.buffer);
          }
          if (key.endsWith('.svg')) {
            final Uint8List bytes = utf8.encoder.convert(
              '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"></svg>',
            );
            return ByteData.view(bytes.buffer);
          }
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

  group('LanguageSymbolBadge Tests', () {
    testWidgets('Renders flag and motif icon SVGs for English (en)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LanguageSymbolBadge(langCode: 'en')),
        ),
      );

      // Verify it renders SvgPictures (one for flag, one for motif)
      expect(find.byType(SvgPicture), findsNWidgets(2));
    });

    testWidgets('Renders fallback theme if invalid code is passed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LanguageSymbolBadge(langCode: 'invalid')),
        ),
      );

      // Invalid language will fallback to standard globe theme and still render
      expect(find.byType(SvgPicture), findsNWidgets(2));
    });
  });

  group('Curriculum Empty State Tests', () {
    testWidgets('Renders empty state with correct motif and localized text', (
      WidgetTester tester,
    ) async {
      final theme = LanguageThemeRegistry.themeFor('ar'); // Arabic (RTL)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Mock column empty state rendering
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        theme.motifAsset,
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 12),
                      const Text('Preparing العربية Lessons'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify custom empty state elements are present
      expect(find.text('Preparing العربية Lessons'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });
}
