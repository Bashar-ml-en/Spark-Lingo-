import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/curriculum.dart';

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

  // Fetch user profile from public.profiles table safely without realtime requirements
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res == null) return null;
      return UserProfile.fromMap(res);
    } catch (e) {
      debugPrint("Supabase DB Error (getProfile): $e");
      rethrow;
    }
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

// Auto-dispose Future Provider that exposes the profile model
final userProfileProvider = FutureProvider.autoDispose.family<UserProfile?, String>((ref, userId) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getProfile(userId);
});

// Future Provider that parses the syllabus JSON database
final masterSyllabusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/curriculum/syllabus_master.json');
  return json.decode(jsonString) as Map<String, dynamic>;
});

// Family Provider exposing specific language syllabus
final languageSyllabusProvider = FutureProvider.autoDispose.family<LanguageSyllabus?, String>((ref, languageKey) async {
  final masterSyllabus = await ref.watch(masterSyllabusProvider.future);
  final languageData = masterSyllabus[languageKey.toLowerCase()];
  if (languageData == null) return null;
  return LanguageSyllabus.fromJson(languageKey, languageData as Map<String, dynamic>);
});

