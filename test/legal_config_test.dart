import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/core/constants/legal_config.dart';

void main() {
  group('LegalConfig.parseSecureWebUri', () {
    test('accepts a normal HTTPS policy URL', () {
      expect(
        LegalConfig.parseSecureWebUri(
          'https://legal.example.com/privacy?version=2026-08',
        )?.toString(),
        'https://legal.example.com/privacy?version=2026-08',
      );
    });

    test(
      'fails closed for absent, insecure, malformed, or credential URLs',
      () {
        for (final value in <String?>[
          null,
          '',
          '   ',
          'http://legal.example.com/privacy',
          'mailto:support@example.com',
          'https://',
          'https://user:password@legal.example.com/privacy',
        ]) {
          expect(
            LegalConfig.parseSecureWebUri(value),
            isNull,
            reason: '$value',
          );
        }
      },
    );
  });

  test(
    'purchase links remain unavailable without real build configuration',
    () {
      expect(LegalConfig.hasRequiredPurchaseLinks, isFalse);
      expect(LegalConfig.termsOfServiceUri, isNull);
      expect(LegalConfig.privacyPolicyUri, isNull);
    },
  );

  group('LegalConfig.parseDocument', () {
    test('requires both a secure URL and an immutable version', () {
      final document = LegalConfig.parseDocument(
        'https://legal.example.com/ai-voice-notice',
        '2026-08.1',
      );

      expect(document, isNotNull);
      expect(
        document!.uri.toString(),
        'https://legal.example.com/ai-voice-notice',
      );
      expect(document.version, '2026-08.1');
    });

    test('fails closed for missing or unsafe document metadata', () {
      for (final value in <(String?, String?)>[
        ('https://legal.example.com/notice', null),
        ('https://legal.example.com/notice', ''),
        ('https://legal.example.com/notice', 'version with spaces'),
        ('https://legal.example.com/notice', 'version/with/slashes'),
        ('http://legal.example.com/notice', '2026-08'),
      ]) {
        expect(LegalConfig.parseDocument(value.$1, value.$2), isNull);
      }
    });
  });
}
