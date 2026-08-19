import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/core/constants/supabase_config.dart';

void main() {
  const productionRef = 'aaaaaaaaaaaaaaaaaaaa';
  const stagingRef = 'bbbbbbbbbbbbbbbbbbbb';
  const publishableKey = 'sb_publishable_cccccccccccccccccccc';

  SupabaseBuildConfiguration hosted({
    String environment = 'staging',
    String projectRef = stagingRef,
    String productionProjectRef = productionRef,
    String? url,
    String key = publishableKey,
  }) {
    return SupabaseBuildConfiguration(
      environment: environment,
      deployment: 'hosted',
      url: url ?? 'https://$projectRef.supabase.co',
      publishableKey: key,
      projectRef: projectRef,
      productionProjectRef: productionProjectRef,
    );
  }

  group('SupabaseBuildConfiguration', () {
    test('accepts an explicit hosted staging configuration', () {
      final config = hosted();

      expect(config.isValid, isTrue);
      expect(config.validationError, isNull);
    });

    test('rejects a non-production build targeting the production project', () {
      final config = hosted(projectRef: productionRef);

      expect(config.isValid, isFalse);
      expect(config.validationError, contains('Non-production'));
    });

    test('rejects a production build that targets another project', () {
      final config = hosted(environment: 'production');

      expect(config.isValid, isFalse);
      expect(config.validationError, contains('Production builds'));
    });

    test('requires a hosted URL to match the declared project reference', () {
      final config = hosted(url: 'https://$productionRef.supabase.co');

      expect(config.isValid, isFalse);
      expect(config.validationError, contains('does not match'));
    });

    test('requires explicit values rather than applying a fallback', () {
      const config = SupabaseBuildConfiguration(
        environment: '',
        deployment: '',
        url: '',
        publishableKey: '',
        projectRef: '',
        productionProjectRef: '',
      );

      expect(config.isValid, isFalse);
      expect(config.validationError, contains('environment'));
    });

    test('allows development to use an approved local endpoint', () {
      const config = SupabaseBuildConfiguration(
        environment: 'development',
        deployment: 'local',
        url: 'http://127.0.0.1:54321',
        publishableKey: 'local-development-public-key',
        projectRef: '',
        productionProjectRef: '',
      );

      expect(config.isValid, isTrue);
    });

    test('rejects local deployment outside development', () {
      const config = SupabaseBuildConfiguration(
        environment: 'staging',
        deployment: 'local',
        url: 'http://127.0.0.1:54321',
        publishableKey: 'local-development-public-key',
        projectRef: '',
        productionProjectRef: '',
      );

      expect(config.isValid, isFalse);
      expect(config.validationError, contains('Only development'));
    });

    test('rejects public endpoints in local development mode', () {
      const config = SupabaseBuildConfiguration(
        environment: 'development',
        deployment: 'local',
        url: 'https://example.com',
        publishableKey: 'local-development-public-key',
        projectRef: '',
        productionProjectRef: '',
      );

      expect(config.isValid, isFalse);
      expect(config.validationError, contains('approved local'));
    });

    test('requires the public client-key format for hosted builds', () {
      final config = hosted(key: 'not-a-publishable-client-key');

      expect(config.isValid, isFalse);
      expect(config.validationError, contains('publishable key'));
    });
  });
}
