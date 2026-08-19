import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../constants/auth_config.dart';
import 'revenuecat_service.dart';
import 'telemetry_consent_service.dart';

class AuthNotifier extends StateNotifier<sb.User?> {
  final sb.SupabaseClient _client = sb.Supabase.instance.client;
  final Ref _ref;

  AuthNotifier(this._ref)
    : super(sb.Supabase.instance.client.auth.currentUser) {
    final initialUser = state;
    if (initialUser != null) {
      _syncAuthenticatedUserServices(initialUser);
    }

    // 1. Listen to authentication state changes reactively
    _client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      state = user;
      _ref.invalidate(isPremiumProvider);

      // 2. Synchronize active user ID profile to Firebase Operations (Hybrid sync)
      if (user != null) {
        _syncAuthenticatedUserServices(user);
      } else {
        _clearAuthenticatedUserServices();
      }
    });
  }

  void _syncAuthenticatedUserServices(sb.User user) {
    // Analytics and diagnostics are aggregate-only: do not put the Supabase
    // user id in Firebase. Telemetry is enabled only after a server-backed
    // consent check succeeds; a database/configuration error leaves it off.
    unawaited(TelemetryConsentService.syncForCurrentUser());

    // Billing accepts only a confirmed, recoverable account. Anonymous users
    // may use the free experience but cannot create or restore a purchase.
    unawaited(RevenueCatService().syncUserIdentity(user));
  }

  void _clearAuthenticatedUserServices() {
    unawaited(TelemetryConsentService.disable());
    unawaited(RevenueCatService().clearUserIdentity());
  }

  // Sign in anonymously (Used for onboarding / free trials)
  Future<void> signInAnonymously() async {
    try {
      await _client.auth.signInAnonymously();
    } catch (_) {
      debugPrint('Anonymous sign-in failed.');
      rethrow;
    }
  }

  // Sign in with Email / Password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (_) {
      debugPrint('Email sign-in failed.');
      rethrow;
    }
  }

  // Sign up with Email / Password
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
    } catch (_) {
      debugPrint('Email sign-up failed.');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      debugPrint('Sign-out failed.');
      rethrow;
    }
  }

  // Sign in with Google Account (OAuth redirect)
  Future<void> signInWithGoogle() async {
    if (!AuthConfig.googleOAuthEnabled) {
      throw UnsupportedError('Google sign-in is not enabled for this build.');
    }
    try {
      await _client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.sparklingo://login-callback',
      );
    } catch (_) {
      debugPrint('Google OAuth initiation failed.');
      rethrow;
    }
  }

  /// Starts Apple OAuth on iOS. The provider must be configured in Supabase and
  /// Apple Developer before this can succeed; failures are surfaced to the UI
  /// rather than falling back to a different identity provider.
  Future<void> signInWithApple() async {
    if (!AuthConfig.appleOAuthEnabled ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError('Apple sign-in is only available in the iOS app.');
    }
    try {
      await _client.auth.signInWithOAuth(
        sb.OAuthProvider.apple,
        redirectTo: 'io.supabase.sparklingo://login-callback',
      );
    } catch (_) {
      debugPrint('Apple OAuth initiation failed.');
      rethrow;
    }
  }
}

// Global Provider exposing the Auth state notifier
final authProvider = StateNotifierProvider<AuthNotifier, sb.User?>((ref) {
  return AuthNotifier(ref);
});
