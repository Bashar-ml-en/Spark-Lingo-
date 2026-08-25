import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/auth_config.dart';

/// Device-local consent fallback for pre-store test deployments only.
///
/// Production and store builds never reach this code path: it is gated on
/// [AuthConfig.testConsentEnabled], which defaults to `false` and is only
/// compiled in for web test deployments (`--dart-define=ENABLE_TEST_CONSENT=true`).
///
/// The real launch flow requires a server-recorded, versioned consent
/// document (LEG-001). Until approved HTTPS policy URLs exist, this fallback
/// presents the same notice-and-choice UI against an in-app draft notice and
/// records the learner's choice on-device so QA can exercise Sparky AI.
class TestConsentService {
  TestConsentService._();

  static const String _keyPrefix = 'spark_test_consent_accepted_';

  /// Versioning the draft notice keeps recorded choices honest: bumping this
  /// after a notice change re-prompts testers, mirroring the server ledger.
  static const String draftNoticeVersion = 'draft-2026.1';

  static bool get active => AuthConfig.testConsentEnabled;

  static String _key(String documentKey) =>
      '$_keyPrefix$documentKey:$draftNoticeVersion';

  static Future<bool> hasCurrentConsent(String documentKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key(documentKey)) ?? false;
    } catch (e) {
      debugPrint('Test consent read failed: $e');
      return false;
    }
  }

  static Future<bool> recordConsent(String documentKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_key(documentKey), true);
    } catch (e) {
      debugPrint('Test consent write failed: $e');
      return false;
    }
  }
}
