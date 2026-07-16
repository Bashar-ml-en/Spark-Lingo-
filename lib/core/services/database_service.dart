import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/user_profile.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Stream user profile changes reactively from public.profiles table
  Stream<UserProfile?> streamProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((list) {
          if (list.isEmpty) return null;
          return UserProfile.fromMap(list.first);
        });
  }

  // Update User Display Name
  Future<void> updateDisplayName(String userId, String name) async {
    try {
      await _client
          .from('profiles')
          .update({'display_name': name})
          .eq('id', userId);
    } catch (e) {
      debugPrint("Supabase DB Error (updateDisplayName): $e");
      rethrow;
    }
  }

  // Update Target Languages
  Future<void> updateTargetLanguages(String userId, List<String> languages) async {
    try {
      await _client
          .from('profiles')
          .update({'target_languages': languages})
          .eq('id', userId);
    } catch (e) {
      debugPrint("Supabase DB Error (updateTargetLanguages): $e");
      rethrow;
    }
  }
}

// Global Provider for the Database service instance
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Auto-dispose Stream Provider that exposes the profile model
final userProfileProvider = StreamProvider.autoDispose.family<UserProfile?, String>((ref, userId) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.streamProfile(userId);
});
