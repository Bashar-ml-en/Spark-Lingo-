import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../constants/legal_config.dart';

/// Reasons that a purchase path is intentionally unavailable. These values are
/// user-interface hints only; the server entitlement ledger is the authority.
enum BillingAccessState {
  ready,
  legalLinksMissing,
  recoverableAccountRequired,
  billingDisabled,
  platformUnavailable,
  configurationUnavailable,
}

/// A store transaction is never treated as a premium grant until the server
/// entitlement ledger confirms it.
enum BillingPurchaseResult {
  serverVerified,
  awaitingServerVerification,
  notCompleted,
  unavailable,
}

/// RevenueCat SDK integration with a server-authoritative entitlement boundary.
///
/// The app uses only public RevenueCat SDK keys. It configures the SDK only for
/// a confirmed, recoverable Supabase account after the server billing switch is
/// on. Anonymous accounts cannot buy or restore purchases in this build.
class RevenueCatService {
  factory RevenueCatService() => _instance;
  RevenueCatService._();

  static final RevenueCatService _instance = RevenueCatService._();

  static const String entitlementId = 'spark_premium';
  static const String _appleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
  );
  static const String _googleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
  );

  Future<void>? _initialization;
  bool _isInitialized = false;
  String? _configuredUserId;

  bool get isInitialized => _isInitialized;

  bool get isPlatformConfigured {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _isValidPublicKey(_googleApiKey, 'goog_');
      case TargetPlatform.iOS:
        return _isValidPublicKey(_appleApiKey, 'appl_');
      default:
        return false;
    }
  }

  static bool _isValidPublicKey(String value, String expectedPrefix) =>
      value.trim().startsWith(expectedPrefix) &&
      value.trim().length > expectedPrefix.length;

  /// Returns a fail-closed purchase gate for the authenticated account.
  ///
  /// A green client configuration alone never opens billing: the migration's
  /// service-role-controlled runtime switch must also be enabled.
  Future<BillingAccessState> billingAccessState() async {
    if (!LegalConfig.hasRequiredPurchaseLinks) {
      return BillingAccessState.legalLinksMissing;
    }

    final user = sb.Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      return BillingAccessState.recoverableAccountRequired;
    }

    final customerReady = await _ensureRecoverableBillingCustomer();
    if (!customerReady) {
      return BillingAccessState.recoverableAccountRequired;
    }

    if (!await _isServerBillingEnabled()) {
      return BillingAccessState.billingDisabled;
    }

    if (!isPlatformConfigured) {
      return BillingAccessState.platformUnavailable;
    }

    if (!await _configureForUser(user.id)) {
      return BillingAccessState.configurationUnavailable;
    }
    return BillingAccessState.ready;
  }

  /// Synchronizes a permanent Supabase account to RevenueCat only after the
  /// server's recovery and billing controls allow it. Anonymous sessions are
  /// logged out of a prior SDK identity and cannot become billing customers.
  Future<bool> syncUserIdentity(sb.User user) async {
    if (user.isAnonymous) {
      await clearUserIdentity();
      return false;
    }
    return (await billingAccessState()) == BillingAccessState.ready;
  }

  Future<void> clearUserIdentity() async {
    if (!_isInitialized) return;
    try {
      // RevenueCat creates an SDK-local anonymous identity on logout. This app
      // still keeps purchase/restore unavailable until a permanent account is
      // registered and the server gate is open.
      await Purchases.logOut();
    } catch (_) {
      debugPrint('RevenueCat sign-out synchronization failed.');
    } finally {
      _configuredUserId = null;
    }
  }

  /// Reads only the server-owned entitlement decision. A RevenueCat SDK result,
  /// SharedPreferences value, or Flutter state can never grant premium access.
  Future<bool> checkPremiumStatus() async {
    final user = sb.Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) return false;

    try {
      final result = await sb.Supabase.instance.client.rpc(
        'has_active_billing_entitlement',
        params: {'p_entitlement_id': entitlementId},
      );
      return _readBoolean(result, 'has_active_billing_entitlement');
    } catch (_) {
      debugPrint('Server entitlement lookup failed.');
      return false;
    }
  }

  Future<BillingPurchaseResult> purchasePackage(Package package) async {
    if ((await billingAccessState()) != BillingAccessState.ready) {
      return BillingPurchaseResult.unavailable;
    }
    try {
      await Purchases.purchasePackage(package);
      return await checkPremiumStatus()
          ? BillingPurchaseResult.serverVerified
          : BillingPurchaseResult.awaitingServerVerification;
    } catch (_) {
      // A cancellation is expected and intentionally does not surface SDK or
      // store details to the learner.
      debugPrint('RevenueCat purchase was not completed.');
      return BillingPurchaseResult.notCompleted;
    }
  }

  Future<BillingPurchaseResult> restorePurchases() async {
    if ((await billingAccessState()) != BillingAccessState.ready) {
      return BillingPurchaseResult.unavailable;
    }
    try {
      await Purchases.restorePurchases();
      return await checkPremiumStatus()
          ? BillingPurchaseResult.serverVerified
          : BillingPurchaseResult.awaitingServerVerification;
    } catch (_) {
      debugPrint('RevenueCat restore failed.');
      return BillingPurchaseResult.notCompleted;
    }
  }

  Future<List<Offering>> getOfferings() async {
    if ((await billingAccessState()) != BillingAccessState.ready ||
        !_isInitialized) {
      return const [];
    }
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current == null ? const [] : [offerings.current!];
    } catch (_) {
      debugPrint('RevenueCat offerings lookup failed.');
      return const [];
    }
  }

  Future<bool> _ensureRecoverableBillingCustomer() async {
    try {
      final result = await sb.Supabase.instance.client.rpc(
        'ensure_billing_customer',
      );
      return _readBoolean(result, 'ready');
    } catch (_) {
      // A missing migration, unconfirmed identity, or unavailable server must
      // all leave billing closed instead of falling back to device state.
      debugPrint('Recoverable billing identity check failed.');
      return false;
    }
  }

  Future<bool> _isServerBillingEnabled() async {
    try {
      final result = await sb.Supabase.instance.client.rpc(
        'billing_runtime_status',
      );
      return _readBoolean(result, 'enabled');
    } catch (_) {
      debugPrint('Server billing control lookup failed.');
      return false;
    }
  }

  Future<bool> _configureForUser(String userId) async {
    if (!isPlatformConfigured || userId.trim().isEmpty) return false;

    try {
      if (_isInitialized) {
        if (_configuredUserId == userId) return true;
        await Purchases.logIn(userId);
        _configuredUserId = userId;
        return true;
      }

      _initialization ??= _configure(userId);
      await _initialization;

      // If the user changed while the initial configuration was in flight,
      // hand the initialized SDK to the current verified account.
      if (_isInitialized && _configuredUserId != userId) {
        await Purchases.logIn(userId);
        _configuredUserId = userId;
      }
      return _isInitialized && _configuredUserId == userId;
    } catch (_) {
      debugPrint('RevenueCat initialization failed.');
      _isInitialized = false;
      _configuredUserId = null;
      _initialization = null;
      return false;
    }
  }

  Future<void> _configure(String userId) async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

    final String apiKey;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        apiKey = _googleApiKey;
        break;
      case TargetPlatform.iOS:
        apiKey = _appleApiKey;
        break;
      default:
        return;
    }

    await Purchases.configure(
      PurchasesConfiguration(apiKey)..appUserID = userId,
    );
    _configuredUserId = userId;
    _isInitialized = true;
  }

  static bool _readBoolean(dynamic value, String key) {
    if (value is bool) return value;
    if (value is Map) {
      final field = value[key];
      return field is bool && field;
    }
    if (value is List && value.length == 1) {
      return _readBoolean(value.first, key);
    }
    return false;
  }
}

final revenueCatServiceProvider = Provider<RevenueCatService>(
  (ref) => RevenueCatService(),
);

final isPremiumProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(revenueCatServiceProvider);
  return service.checkPremiumStatus();
});

/// Indicates whether the complete store/legal/server gate is open.  The
/// curriculum must not become accidentally paywalled while billing is still
/// disabled for development or a controlled beta.
final billingAccessProvider = FutureProvider<BillingAccessState>((ref) async {
  final service = ref.watch(revenueCatServiceProvider);
  return service.billingAccessState();
});
