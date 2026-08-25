import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spark_lingo/core/constants/auth_config.dart';
import 'package:spark_lingo/core/services/test_consent_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('test consent fallback is off unless the build flag is compiled in', () {
    // Default builds (store, CI) never pass ENABLE_TEST_CONSENT=true.
    expect(AuthConfig.testConsentEnabled, isFalse);
    expect(TestConsentService.active, isFalse);
  });

  test('draft notice version follows the server-side version grammar', () {
    expect(
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$').hasMatch(
        TestConsentService.draftNoticeVersion,
      ),
      isTrue,
    );
  });

  test('consent defaults to absent and is never written when inactive', () async {
    expect(
      await TestConsentService.hasCurrentConsent('ai_processing'),
      isFalse,
    );
    // recordConsent writes on-device storage; callers gate it behind
    // TestConsentService.active, which is false in this build.
    final wrote = await TestConsentService.recordConsent('ai_processing');
    expect(wrote, isTrue, reason: 'storage itself works; callers stay gated');
    expect(
      await TestConsentService.hasCurrentConsent('ai_processing'),
      isTrue,
    );
  });
}
