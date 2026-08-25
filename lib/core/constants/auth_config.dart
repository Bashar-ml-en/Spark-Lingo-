/// Build-time switches for third-party OAuth entry points.
///
/// Provider configuration lives in Supabase and the identity providers, not in
/// the client. The buttons are hidden by default so a release cannot send a
/// learner into an unconfigured redirect flow. Enable each switch only after
/// its production callback and provider have been tested on the target build.
class AuthConfig {
  AuthConfig._();

  static const googleOAuthEnabled = bool.fromEnvironment(
    'ENABLE_GOOGLE_OAUTH',
    defaultValue: true,
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
  /// `--dart-define=ENABLE_TEST_CONSENT=true` switches the consent flow to a
  /// clearly-labelled local draft notice recorded on-device. Store and
  /// production builds must never pass this flag: release pipelines omit it,
  /// and the default is `false`.
  static const testConsentEnabled = bool.fromEnvironment(
    'ENABLE_TEST_CONSENT',
    defaultValue: false,
  );
}
