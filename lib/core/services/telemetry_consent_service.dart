import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import 'consent_service.dart';

/// Controls Firebase analytics and diagnostics conservatively.
///
/// Native platform metadata starts collection disabled before Flutter runs.
/// This class keeps it disabled unless the current authenticated user has a
/// current, server-backed analytics consent record. It intentionally does not
/// set a Supabase user id in Firebase, preventing cross-service identity
/// linkage that is unnecessary for aggregate release telemetry.
class TelemetryConsentService {
  TelemetryConsentService._();

  static bool _firebaseAvailable = false;
  static bool _collectionEnabled = false;
  static bool _handlersInstalled = false;

  static Future<void> initialize({required bool firebaseInitialized}) async {
    _firebaseAvailable = firebaseInitialized;
    if (!_firebaseAvailable) return;
    await _applyCollectionState(false);
  }

  /// Re-evaluates consent after authentication changes. A database or legal
  /// configuration failure deliberately leaves all optional telemetry off.
  static Future<void> syncForCurrentUser() async {
    if (!_firebaseAvailable) return;

    var isAllowed = false;
    try {
      isAllowed = await ConsentService().hasCurrentConsent(
        ConsentPurpose.analytics,
      );
    } on ConsentServiceException {
      isAllowed = false;
    }
    await _applyCollectionState(isAllowed);
  }

  /// Used after the server has accepted an affirmative in-app consent action.
  static Future<void> enableAfterRecordedConsent() => syncForCurrentUser();

  static Future<void> disable() => _applyCollectionState(false);

  static Future<void> _applyCollectionState(bool enabled) async {
    if (!_firebaseAvailable) return;
    if (!enabled) {
      // Change the in-process error handlers before attempting a provider
      // call, so an opt-out cannot cause this app code to record another
      // report while a provider setting update is in flight.
      _collectionEnabled = false;
      await _setProviderCollectionEnabled(false);
      return;
    }

    // Enable only when every configured provider accepts the change. A failed
    // enable is followed by an explicit disable attempt and never installs a
    // Crashlytics error handler in this process.
    if (!await _setProviderCollectionEnabled(true)) {
      _collectionEnabled = false;
      await _setProviderCollectionEnabled(false);
      return;
    }

    _collectionEnabled = true;
    _installErrorHandlersOnce();
  }

  static Future<bool> _setProviderCollectionEnabled(bool enabled) async {
    var applied = true;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {
      applied = false;
    }

    if (!kIsWeb) {
      try {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          enabled,
        );
      } catch (_) {
        applied = false;
      }
    }
    return applied;
  }

  static void _installErrorHandlersOnce() {
    if (_handlersInstalled || kIsWeb) return;
    _handlersInstalled = true;

    FlutterError.onError = (details) {
      if (_collectionEnabled) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (_collectionEnabled) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      }
      return false;
    };
  }
}
