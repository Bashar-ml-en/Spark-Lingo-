/// Explicit deployment target compiled into a Spark Lingo client.
///
/// The value comes from `--dart-define=SPARK_LINGO_ENV=...`; it intentionally
/// has no default. A build with an omitted or unknown environment is unusable
/// rather than falling back to a hosted project.
enum SparkLingoEnvironment {
  development,
  staging,
  production;

  static SparkLingoEnvironment? parse(String value) {
    return switch (value) {
      'development' => SparkLingoEnvironment.development,
      'staging' => SparkLingoEnvironment.staging,
      'production' => SparkLingoEnvironment.production,
      _ => null,
    };
  }
}

/// Whether the client is intentionally configured for a local or hosted
/// Supabase instance. Staging and production are hosted-only.
enum SupabaseDeployment {
  local,
  hosted;

  static SupabaseDeployment? parse(String value) {
    return switch (value) {
      'local' => SupabaseDeployment.local,
      'hosted' => SupabaseDeployment.hosted,
      _ => null,
    };
  }
}

/// A parsed, non-secret mobile build configuration.
///
/// A Supabase publishable key is necessarily distributed in the client, but it
/// is not a server credential and must remain constrained by Auth, RLS, and
/// Edge Function authorization. Service-role, management, OpenAI, signing,
/// and RevenueCat secret keys never belong in this configuration.
class SupabaseBuildConfiguration {
  const SupabaseBuildConfiguration({
    required this.environment,
    required this.deployment,
    required this.url,
    required this.publishableKey,
    required this.projectRef,
    required this.productionProjectRef,
  });

  final String environment;
  final String deployment;
  final String url;
  final String publishableKey;
  final String projectRef;
  final String productionProjectRef;

  static final RegExp _projectRefPattern = RegExp(r'^[a-z0-9]{20}$');
  static final RegExp _publishableKeyPattern = RegExp(
    r'^sb_publishable_[A-Za-z0-9_-]{20,}$',
  );

  SparkLingoEnvironment? get parsedEnvironment =>
      SparkLingoEnvironment.parse(environment);

  SupabaseDeployment? get parsedDeployment =>
      SupabaseDeployment.parse(deployment);

  /// Returns a non-sensitive reason when the configuration must not be used.
  /// Do not include values in this message: build logs can be retained.
  String? get validationError {
    final appEnvironment = parsedEnvironment;
    final targetDeployment = parsedDeployment;

    if (appEnvironment == null) {
      return 'A recognized Spark Lingo environment is required.';
    }
    if (targetDeployment == null) {
      return 'A recognized Supabase deployment type is required.';
    }
    if (_hasWhitespaceOrIsEmpty(url) ||
        _hasWhitespaceOrIsEmpty(publishableKey)) {
      return 'Supabase URL and public key are required without whitespace.';
    }

    final endpoint = Uri.tryParse(url);
    if (endpoint == null ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        endpoint.userInfo.isNotEmpty ||
        (endpoint.path.isNotEmpty && endpoint.path != '/')) {
      return 'Supabase URL is malformed.';
    }

    if (targetDeployment == SupabaseDeployment.local) {
      if (appEnvironment != SparkLingoEnvironment.development) {
        return 'Only development builds may use a local Supabase instance.';
      }
      if (endpoint.scheme != 'http' || !_isAllowedLocalHost(endpoint.host)) {
        return 'Local Supabase must use an approved local HTTP endpoint.';
      }
      if (projectRef.isNotEmpty && !_isProjectRef(projectRef)) {
        return 'The optional local project reference is malformed.';
      }
      if (productionProjectRef.isNotEmpty &&
          !_isProjectRef(productionProjectRef)) {
        return 'The production project reference is malformed.';
      }
      return null;
    }

    if (endpoint.scheme != 'https' || endpoint.host.isEmpty) {
      return 'Hosted Supabase must use an HTTPS endpoint.';
    }
    if (!_isProjectRef(projectRef) || !_isProjectRef(productionProjectRef)) {
      return 'Hosted builds require valid project references.';
    }
    if (endpoint.host.toLowerCase() != '$projectRef.supabase.co') {
      return 'Hosted Supabase URL does not match its configured project.';
    }
    if (!_publishableKeyPattern.hasMatch(publishableKey)) {
      return 'Hosted builds require a Supabase publishable key.';
    }

    final pointsAtProduction = projectRef == productionProjectRef;
    if (appEnvironment == SparkLingoEnvironment.production &&
        !pointsAtProduction) {
      return 'Production builds must use the approved production project.';
    }
    if (appEnvironment != SparkLingoEnvironment.production &&
        pointsAtProduction) {
      return 'Non-production builds may not use the production project.';
    }

    return null;
  }

  bool get isValid => validationError == null;

  static bool _hasWhitespaceOrIsEmpty(String value) =>
      value.isEmpty || value.trim() != value;

  static bool _isProjectRef(String value) => _projectRefPattern.hasMatch(value);

  static bool _isAllowedLocalHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1' ||
        normalized == '10.0.2.2' ||
        normalized == '10.0.3.2') {
      return true;
    }

    // Permit physical-device development against a private IPv4 address only.
    final octets = normalized.split('.');
    if (octets.length != 4) return false;
    final values = octets.map(int.tryParse).toList();
    if (values.any((value) => value == null || value < 0 || value > 255)) {
      return false;
    }

    final first = values[0]!;
    final second = values[1]!;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }
}

/// Compile-time Supabase configuration for the mobile client.
///
/// Do not add a default URL, key, or production reference here. Omitting any
/// hosted build value causes `main` to show the unavailable screen, which is a
/// safer failure mode than accidentally calling production.
class SupabaseConfig {
  static const String _environment = String.fromEnvironment('SPARK_LINGO_ENV');
  static const String _deployment = String.fromEnvironment(
    'SUPABASE_DEPLOYMENT',
  );
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String _projectRef = String.fromEnvironment(
    'SUPABASE_PROJECT_REF',
  );
  static const String _productionProjectRef = String.fromEnvironment(
    'SPARK_LINGO_PRODUCTION_PROJECT_REF',
  );

  static const SupabaseBuildConfiguration configuration =
      SupabaseBuildConfiguration(
        environment: _environment,
        deployment: _deployment,
        url: _url,
        publishableKey: _publishableKey,
        projectRef: _projectRef,
        productionProjectRef: _productionProjectRef,
      );

  static bool get isConfigured => configuration.isValid;

  static SparkLingoEnvironment? get environment =>
      configuration.parsedEnvironment;

  static String get url => _requireConfigured().url;

  static String get publishableKey => _requireConfigured().publishableKey;

  /// Compatibility alias for existing Supabase client call sites. New code
  /// should use [publishableKey] to make the key's intended scope clear.
  static String get anonKey => publishableKey;

  static SupabaseBuildConfiguration _requireConfigured() {
    if (!isConfigured) {
      throw StateError('Supabase build configuration is unavailable.');
    }
    return configuration;
  }
}
