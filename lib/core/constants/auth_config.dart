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
    defaultValue: false,
  );
  static const appleOAuthEnabled = bool.fromEnvironment(
    'ENABLE_APPLE_OAUTH',
    defaultValue: false,
  );
}
