import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AuthNotifier extends StateNotifier<sb.User?> {
  final sb.SupabaseClient _client = sb.Supabase.instance.client;

  AuthNotifier() : super(sb.Supabase.instance.client.auth.currentUser) {
    // 1. Listen to authentication state changes reactively
    _client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      state = user;
      
      // 2. Synchronize active user ID profile to Firebase Operations (Hybrid sync)
      if (user != null) {
        _syncUserIdentityToFirebase(user.id);
      } else {
        _clearFirebaseIdentity();
      }
    });
  }

  void _syncUserIdentityToFirebase(String uid) {
    try {
      FirebaseAnalytics.instance.setUserId(id: uid);
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.setUserIdentifier(uid);
      }
      debugPrint("Hybrid Auth Sync: Unified User ID ($uid) synced to Firebase Ops.");
    } catch (e) {
      debugPrint("Hybrid Auth Sync Warning: Firebase ops ID sync failed: $e");
    }
  }

  void _clearFirebaseIdentity() {
    try {
      FirebaseAnalytics.instance.setUserId(id: null);
      debugPrint("Hybrid Auth Sync: Cleared user identity.");
    } catch (e) {
      debugPrint("Hybrid Auth Sync Warning: Firebase identity clear failed: $e");
    }
  }

  // Sign in anonymously (Used for onboarding / free trials)
  Future<void> signInAnonymously() async {
    try {
      await _client.auth.signInAnonymously();
    } catch (e) {
      debugPrint("Supabase Auth Error (Anonymous): $e");
      rethrow;
    }
  }

  // Sign in with Email / Password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Supabase Auth Error (Email Signin): $e");
      rethrow;
    }
  }

  // Sign up with Email / Password
  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
    } catch (e) {
      debugPrint("Supabase Auth Error (Email Signup): $e");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint("Supabase Auth Error (Signout): $e");
      rethrow;
    }
  }

  // Sign in with Google Account (OAuth redirect)
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.sparklingo://login-callback',
      );
    } catch (e) {
      debugPrint("Supabase Auth Error (Google OAuth): $e");
      rethrow;
    }
  }
}

// Global Provider exposing the Auth state notifier
final authProvider = StateNotifierProvider<AuthNotifier, sb.User?>((ref) {
  return AuthNotifier();
});
