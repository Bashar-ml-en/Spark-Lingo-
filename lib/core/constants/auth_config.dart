/// Build-time switches for third-party OAuth entry points.
///
/// Provider configuration lives in Supabase and the identity providers, not in
/// the client. The buttons are hidden by default so a release cannot send a
/// learner into an unconfigured redirect flow. Enable each switch only after
/// its production callback and provider have been tested on the target build.
class AuthConfig {
  AuthConfig._();

  static const environment = String.fromEnvironment(
    'SPARK_LINGO_ENV',
    defaultValue: 'development',
  );

  static const googleOAuthEnabled = bool.fromEnvironment(
    'ENABLE_GOOGLE_OAUTH',
    defaultValue: false,
  );
  static const appleOAuthEnabled = bool.fromEnvironment(
    'ENABLE_APPLE_OAUTH',
    defaultValue: false,
  );

  /// Test-deployment escape hatch for the consent gate.
  ///
  /// Sparky AI chat/score/voice is normally locked behind a server-recorded,
  /// versioned consent document (LEG-001). Pre-store web test deployments do
  /// not have approved HTTPS policy URLs yet, so compiling with
  /// A local draft-consent path is permitted only for an explicitly compiled
  /// development build. Staging and production ignore the flag even if it is
  /// mistakenly supplied, so a release cannot weaken consent by configuration.
  static const _testConsentRequested = bool.fromEnvironment(
    'ENABLE_TEST_CONSENT',
    defaultValue: false,
  );
  static const testConsentEnabled =
      environment == 'development' && _testConsentRequested;
}
