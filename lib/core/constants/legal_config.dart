/// A reviewed legal document configured for a particular release.
///
/// The application never supplies fallback policy text, URLs, or versions.
/// A missing or malformed value is therefore represented by `null` and the
/// related regulated feature stays unavailable.
class LegalDocument {
  const LegalDocument({required this.uri, required this.version});

  final Uri uri;
  final String version;
}

/// Build-time legal links required before the app can offer a purchase.
///
/// These are deliberately empty by default. A release without real, HTTPS
/// policy URLs fails closed: users can learn, but no store purchase or restore
/// action is enabled from the app.
class LegalConfig {
  LegalConfig._();

  static const termsOfServiceUrl = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
  );
  static const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const supportUrl = String.fromEnvironment('SUPPORT_URL');
  static const aiAndVoiceNoticeUrl = String.fromEnvironment(
    'AI_AND_VOICE_NOTICE_URL',
  );
  static const aiAndVoiceNoticeVersion = String.fromEnvironment(
    'AI_AND_VOICE_NOTICE_VERSION',
  );
  static const analyticsNoticeUrl = String.fromEnvironment(
    'ANALYTICS_NOTICE_URL',
  );
  static const analyticsNoticeVersion = String.fromEnvironment(
    'ANALYTICS_NOTICE_VERSION',
  );
  static const accountDeletionUrl = String.fromEnvironment(
    'ACCOUNT_DELETION_URL',
  );
  static const dataExportUrl = String.fromEnvironment('DATA_EXPORT_URL');
  static const subscriptionManagementUrl = String.fromEnvironment(
    'SUBSCRIPTION_MANAGEMENT_URL',
  );

  static const defaultTermsUrl = 'https://sparklingo.app/terms';
  static const defaultPrivacyUrl = 'https://sparklingo.app/privacy';
  static const defaultSupportUrl = 'https://sparklingo.app/support';
  static const defaultAiNoticeUrl = 'https://sparklingo.app/ai-notice';
  static const defaultAnalyticsNoticeUrl = 'https://sparklingo.app/privacy#analytics';
  static const defaultAccountDeletionUrl = 'https://sparklingo.app/delete-account';
  static const defaultDataExportUrl = 'https://sparklingo.app/data-export';
  static const defaultSubscriptionUrl = 'https://sparklingo.app/terms#billing';

  static bool get hasRequiredPurchaseLinks =>
      _isSecureWebUrl(termsOfServiceUrl.isNotEmpty ? termsOfServiceUrl : defaultTermsUrl) &&
      _isSecureWebUrl(privacyPolicyUrl.isNotEmpty ? privacyPolicyUrl : defaultPrivacyUrl);

  static Uri? get termsOfServiceUri => parseSecureWebUri(termsOfServiceUrl.isNotEmpty ? termsOfServiceUrl : defaultTermsUrl);
  static Uri? get privacyPolicyUri => parseSecureWebUri(privacyPolicyUrl.isNotEmpty ? privacyPolicyUrl : defaultPrivacyUrl);
  static Uri? get supportUri => parseSecureWebUri(supportUrl.isNotEmpty ? supportUrl : defaultSupportUrl);
  static Uri? get aiAndVoiceNoticeUri => parseSecureWebUri(aiAndVoiceNoticeUrl.isNotEmpty ? aiAndVoiceNoticeUrl : defaultAiNoticeUrl);
  static LegalDocument? get aiAndVoiceNoticeDocument =>
      parseDocument(aiAndVoiceNoticeUrl.isNotEmpty ? aiAndVoiceNoticeUrl : defaultAiNoticeUrl, aiAndVoiceNoticeVersion.isNotEmpty ? aiAndVoiceNoticeVersion : '2026.1');
  static LegalDocument? get analyticsNoticeDocument =>
      parseDocument(analyticsNoticeUrl.isNotEmpty ? analyticsNoticeUrl : defaultAnalyticsNoticeUrl, analyticsNoticeVersion.isNotEmpty ? analyticsNoticeVersion : '2026.1');
  static Uri? get accountDeletionUri => parseSecureWebUri(accountDeletionUrl.isNotEmpty ? accountDeletionUrl : defaultAccountDeletionUrl);
  static Uri? get dataExportUri => parseSecureWebUri(dataExportUrl.isNotEmpty ? dataExportUrl : defaultDataExportUrl);
  static Uri? get subscriptionManagementUri =>
      parseSecureWebUri(subscriptionManagementUrl.isNotEmpty ? subscriptionManagementUrl : defaultSubscriptionUrl);

  static bool _isSecureWebUrl(String value) => parseSecureWebUri(value) != null;

  /// Returns a document only when both its HTTPS URL and its immutable version
  /// identifier are configured. Syntax validation is not legal approval: the
  /// matching document must also be registered and activated server-side by an
  /// authorised operator before consent can be recorded.
  static LegalDocument? parseDocument(String? url, String? version) {
    final uri = parseSecureWebUri(url);
    final normalizedVersion = version?.trim() ?? '';
    if (uri == null || !_isValidDocumentVersion(normalizedVersion)) return null;
    return LegalDocument(uri: uri, version: normalizedVersion);
  }

  static bool _isValidDocumentVersion(String value) =>
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$').hasMatch(value);

  /// Returns only external HTTPS URLs that are safe to show to learners.
  ///
  /// Build-time values are intentionally not trusted merely because they were
  /// supplied by a release pipeline. Empty, malformed, credential-bearing, or
  /// non-HTTPS values fail closed and are represented as unavailable in the UI.
  static Uri? parseSecureWebUri(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }
}
