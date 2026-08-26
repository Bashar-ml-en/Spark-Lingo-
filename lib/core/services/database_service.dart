import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/curriculum.dart';
import '../../shared/models/exam.dart';
import '../constants/language_catalog.dart';
import '../constants/supabase_config.dart';
import 'spaced_repetition_service.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  Map<String, dynamic>? _localCurriculumCache;

  Future<Map<String, dynamic>> _getLocalCurriculum() async {
    if (_localCurriculumCache != null) return _localCurriculumCache!;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/curriculum/syllabus_master.json',
      );
      _localCurriculumCache = jsonDecode(jsonString) as Map<String, dynamic>;
      return _localCurriculumCache!;
    } catch (_) {
      debugPrint('Local curriculum could not be loaded.');
      return {};
    }
  }

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
    } catch (_) {
      debugPrint('Profile lookup failed.');
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
    } catch (_) {
      debugPrint('Display-name update failed.');
      rethrow;
    }
  }

  // Upsert profile if missing
  Future<void> upsertProfile(String userId, String languageCode) async {
    final code = LanguageCatalog.tryCanonicalCode(languageCode);
    if (code == null) {
      throw ArgumentError.value(
        languageCode,
        'languageCode',
        'Unsupported language',
      );
    }
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'display_name': 'Guest User',
        'target_languages': [code],
        'active_language': code,
      });
    } catch (_) {
      debugPrint('Profile creation failed.');
      rethrow;
    }
  }

  // Update Target Languages
  Future<void> updateTargetLanguages(
    String userId,
    List<String> languages,
  ) async {
    final canonicalLanguages = LanguageCatalog.canonicalizeAll(languages);
    try {
      await _client
          .from('profiles')
          // Keep the profile internally consistent: an empty language list
          // must never leave an empty-string active language that bypasses the
          // onboarding redirect.  For a non-empty list the first entry is the
          // selected active language, which callers deliberately place first.
          .update({
            'target_languages': canonicalLanguages,
            'active_language': canonicalLanguages.isEmpty
                ? null
                : canonicalLanguages.first,
          })
          .eq('id', userId);
    } catch (_) {
      debugPrint('Target-language update failed.');
      rethrow;
    }
  }

  // Update Active Language
  Future<void> updateActiveLanguage(String userId, String languageCode) async {
    final code = LanguageCatalog.tryCanonicalCode(languageCode);
    if (code == null) {
      throw ArgumentError.value(
        languageCode,
        'languageCode',
        'Unsupported language',
      );
    }
    try {
      await _client
          .from('profiles')
          .update({'active_language': code})
          .eq('id', userId);
    } catch (_) {
      debugPrint('Active-language update failed.');
      rethrow;
    }
  }

  /// Deletes the currently authenticated Spark Lingo account through the
  /// server-side function. The function derives identity from the access token;
  /// callers must never send an arbitrary user id for deletion.
  Future<bool> deleteCurrentAccount() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('An authenticated session is required.');
    }

    try {
      final response = await _client.functions.invoke(
        'delete-account',
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': SupabaseConfig.publishableKey,
        },
        body: const {'confirmation': 'DELETE'},
      );
      final data = response.data;
      return data is Map && data['deleted'] == true;
    } catch (_) {
      debugPrint('Account deletion request failed.');
      rethrow;
    }
  }

  // Record a completed lesson through the security-definer RPC
  // (migration 015). Completion can only be written server-side.
  Future<void> completeLesson(String lessonId, String languageCode) async {
    try {
      await _client.rpc('complete_lesson', params: {
        'p_lesson_id': lessonId,
        'p_language_code': LanguageCatalog.canonicalCode(languageCode),
      });
    } catch (_) {
      debugPrint('Lesson-completion record failed.');
      rethrow;
    }
  }

  // Fetch the learner's completed lesson ids for one language.
  Future<Map<String, int>> fetchLessonAttempts(
    String userId,
    String languageKey,
  ) async {
    try {
      final res = await _client
          .from('lesson_progress')
          .select('lesson_id,attempts')
          .eq('user_id', userId)
          .eq('language_code', LanguageCatalog.canonicalCode(languageKey));
      final map = <String, int>{};
      for (final row in res as List<dynamic>) {
        final lessonId = row['lesson_id'] as String?;
        final attempts = row['attempts'] as int?;
        if (lessonId != null && attempts != null) {
          map[lessonId] = attempts;
        }
      }
      return map;
    } catch (_) {
      debugPrint('Lesson-progress lookup failed.');
      rethrow;
    }
  }

  // Persist spaced repetition stats inside public.card_reviews table
  Future<void> upsertCardReview({
    required String userId,
    required String cardId,
    required String languageKey,
    required int interval,
    required int repetitions,
    required double efactor,
    required DateTime nextReview,
  }) async {
    try {
      await _client.from('card_reviews').upsert(
        {
          'user_id': userId,
          'card_id': cardId,
          'language_key': LanguageCatalog.canonicalCode(languageKey),
          'interval': interval,
          'repetitions': repetitions,
          'efactor': efactor,
          'next_review_at': nextReview.toUtc().toIso8601String(),
        },
        // `id` is generated server-side. Target the learner/card/language
        // uniqueness constraint so another review updates SRS state instead of
        // failing with a duplicate-key error.
        onConflict: 'user_id,card_id,language_key',
      );
    } catch (_) {
      debugPrint('Card-review update failed.');
      rethrow;
    }
  }

  // Fetch SRS progress for a user and language
  Future<Map<String, SRSState>> fetchCardReviews(
    String userId,
    String languageKey,
  ) async {
    try {
      final res = await _client
          .from('card_reviews')
          .select()
          .eq('user_id', userId)
          .eq('language_key', LanguageCatalog.canonicalCode(languageKey));

      final Map<String, SRSState> reviews = {};
      for (var row in (res as List<dynamic>)) {
        reviews[row['card_id'] as String] = SRSState.fromMap(row);
      }
      return reviews;
    } catch (_) {
      debugPrint('Card-review lookup failed.');
      return {};
    }
  }

  // Curriculum Cloud Fetches

  Future<List<Unit>> fetchUnits(String languageId) async {
    final languageCode = LanguageCatalog.tryCanonicalCode(languageId);
    if (languageCode == null) return [];
    try {
      final res = await _client
          .from('units')
          .select()
          .eq('language_id', languageCode)
          .eq('is_reviewed', true)
          .order('order_index', ascending: true);

      final units = (res as List<dynamic>)
          .map((map) => Unit.fromMap(map))
          .toList();
      if (units.isNotEmpty) return units;
    } catch (_) {
      debugPrint('Cloud curriculum lookup failed; using local curriculum.');
    }

    // Fallback to local JSON
    final localData = await _getLocalCurriculum();
    final langData = localData[LanguageCatalog.curriculumKey(languageCode)];
    if (langData != null && langData['units'] != null) {
      return (langData['units'] as List<dynamic>).map((u) {
        return Unit(
          id: u['id'],
          title: u['title'],
          description: u['description'],
          sourceAttribution: u['source_attribution'],
          isReviewed: u['is_reviewed'] ?? true,
        );
      }).toList();
    }
    return [];
  }

  Future<List<Lesson>> fetchLessons(String unitId) async {
    try {
      final res = await _client
          .from('lessons')
          .select()
          .eq('unit_id', unitId)
          .order('order_index', ascending: true);

      final lessons = (res as List<dynamic>)
          .map((map) => Lesson.fromMap(map))
          .toList();
      if (lessons.isNotEmpty) return lessons;
    } catch (_) {
      debugPrint('Cloud lesson lookup failed; using local curriculum.');
    }

    // Fallback to local JSON
    final localData = await _getLocalCurriculum();
    for (var lang in localData.values) {
      if (lang['units'] != null) {
        for (var unit in lang['units']) {
          if (unit['id'] == unitId && unit['lessons'] != null) {
            return (unit['lessons'] as List<dynamic>).map((l) {
              return Lesson(
                id: l['id'],
                title: l['title'],
                description: l['description'],
              );
            }).toList();
          }
        }
      }
    }
    return [];
  }

  Future<List<Flashcard>> fetchFlashcards(String lessonId) async {
    try {
      final res = await _client
          .from('flashcards')
          .select()
          .eq('lesson_id', lessonId);

      final flashcards = (res as List<dynamic>)
          .map((map) => Flashcard.fromMap(map))
          .toList();
      if (flashcards.isNotEmpty) return flashcards;
    } catch (_) {
      debugPrint('Cloud flashcard lookup failed; using local curriculum.');
    }

    // Fallback to local JSON
    final localData = await _getLocalCurriculum();
    for (var lang in localData.values) {
      if (lang['units'] != null) {
        for (var unit in lang['units']) {
          if (unit['lessons'] != null) {
            for (var lesson in unit['lessons']) {
              if (lesson['id'] == lessonId && lesson['flashcards'] != null) {
                return (lesson['flashcards'] as List<dynamic>).map((f) {
                  return Flashcard(
                    id: f['id'],
                    front: f['front'],
                    back: f['back'],
                    context: f['context'],
                  );
                }).toList();
              }
            }
          }
        }
      }
    }
    return [];
  }

  // --- Exam Certification Module ---

  Future<List<ExamDefinition>> fetchExamDefinitions(String languageCode) async {
    try {
      final res = await _client
          .from('exam_definitions')
          .select()
          .eq('language_code', languageCode);
      return (res as List<dynamic>)
          .map((map) => ExamDefinition.fromJson(map))
          .toList();
    } catch (_) {
      debugPrint('Exam-definition lookup failed.');
      return [];
    }
  }

  Future<List<MockExam>> fetchMockExams(String examId) async {
    try {
      final res = await _client
          .from('mock_exams')
          .select()
          .eq('exam_id', examId)
          .order('created_at', ascending: false);
      return (res as List<dynamic>)
          .map((map) => MockExam.fromJson(map))
          .toList();
    } catch (_) {
      debugPrint('Mock-exam lookup failed.');
      return [];
    }
  }

  Future<List<MockExamSection>> fetchMockExamSections(String mockExamId) async {
    try {
      final res = await _client
          .from('mock_exam_sections')
          .select()
          .eq('mock_exam_id', mockExamId)
          .order('section_order', ascending: true);
      return (res as List<dynamic>)
          .map((map) => MockExamSection.fromJson(map))
          .toList();
    } catch (_) {
      debugPrint('Mock-exam section lookup failed.');
      return [];
    }
  }

  Future<UserExamReadiness?> fetchUserExamReadiness(
    String userId,
    String examId,
  ) async {
    try {
      final res = await _client
          .from('user_exam_readiness')
          .select()
          .eq('user_id', userId)
          .eq('exam_id', examId)
          .maybeSingle();
      if (res == null) return null;
      return UserExamReadiness.fromJson(res);
    } catch (_) {
      debugPrint('Exam-readiness lookup failed.');
      return null;
    }
  }

  Future<void> upsertUserExamReadiness(UserExamReadiness readiness) async {
    try {
      await _client.from('user_exam_readiness').upsert({
        'user_id': readiness.userId,
        'exam_id': readiness.examId,
        'current_estimated_level': readiness.currentEstimatedLevel,
        'target_level': readiness.targetLevel,
        'target_date': readiness.targetDate?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      debugPrint('Exam-readiness update failed.');
      rethrow;
    }
  }

  Future<List<UserMockExamAttempt>> fetchUserMockExamAttempts(
    String userId,
    String examId,
  ) async {
    try {
      // We need to join with mock_exams to filter by examId.
      // Supabase supports embedding/joining.
      final res = await _client
          .from('user_mock_exam_attempts')
          .select('*, mock_exams!inner(exam_id)')
          .eq('user_id', userId)
          .eq('mock_exams.exam_id', examId)
          .order('completed_at', ascending: false);
      return (res as List<dynamic>)
          .map((map) => UserMockExamAttempt.fromJson(map))
          .toList();
    } catch (_) {
      debugPrint('Mock-exam attempt lookup failed.');
      return [];
    }
  }
}

// Global Provider for the Database service instance
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Auto-dispose Future Provider that exposes the profile model
final userProfileProvider = FutureProvider.autoDispose
    .family<UserProfile?, String>((ref, userId) {
      final dbService = ref.watch(databaseServiceProvider);
      return dbService.getProfile(userId);
    });

// Curriculum Providers

final unitsProvider = FutureProvider.autoDispose.family<List<Unit>, String>((
  ref,
  languageId,
) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.fetchUnits(languageId);
});

final lessonsProvider = FutureProvider.autoDispose.family<List<Lesson>, String>(
  (ref, unitId) {
    final dbService = ref.watch(databaseServiceProvider);
    return dbService.fetchLessons(unitId);
  },
);

final flashcardsProvider = FutureProvider.autoDispose
    .family<List<Flashcard>, String>((ref, lessonId) {
      final dbService = ref.watch(databaseServiceProvider);
      return dbService.fetchFlashcards(lessonId);
    });

// A custom provider family parameter class to hold multiple arguments
class CardReviewsParam {
  final String userId;
  final String languageKey;
  CardReviewsParam(this.userId, this.languageKey);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardReviewsParam &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          languageKey == other.languageKey;

  @override
  int get hashCode => userId.hashCode ^ languageKey.hashCode;
}

final cardReviewsProvider = FutureProvider.autoDispose
    .family<Map<String, SRSState>, CardReviewsParam>((ref, param) {
      final dbService = ref.watch(databaseServiceProvider);
      return dbService.fetchCardReviews(param.userId, param.languageKey);
    });

/// Completed-lesson attempt counts for a (user, language) pair. Empty map
/// while the learner has finished nothing yet.
final lessonProgressProvider = FutureProvider.autoDispose
    .family<Map<String, int>, CardReviewsParam>((ref, param) {
      final dbService = ref.watch(databaseServiceProvider);
      return dbService.fetchLessonAttempts(param.userId, param.languageKey);
    });

// --- Exam Providers ---

final examDefinitionsProvider = FutureProvider.autoDispose
    .family<List<ExamDefinition>, String>((ref, languageCode) {
      final dbService = ref.watch(databaseServiceProvider);
      return dbService.fetchExamDefinitions(languageCode);
    });

final mockExamsProvider = FutureProvider.autoDispose
    .family<List<MockExam>, String>((ref, examId) {
      final dbService = ref.watch(databaseServiceProvider);
      return dbService.fetchMockExams(examId);
    });

final mockExamSectionsProvider = FutureProvider.autoDispose
    .family<List<MockExamSection>, String>((ref, mockExamId) {
      final dbService = ref.watch(databaseServiceProvider);
      return dbService.fetchMockExamSections(mockExamId);
    });

class UserExamParam {
  final String userId;
  final String examId;
  UserExamParam(this.userId, this.examId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserExamParam &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          examId == other.examId;

  @override
  int get hashCode => userId.hashCode ^ examId.hashCode;
}

final userExamReadinessProvider = FutureProvider.autoDispose
    .family<UserExamReadiness?, UserExamParam>((ref, param) {
      final dbService = ref.watch(databaseServiceProvider);
      return dbService.fetchUserExamReadiness(param.userId, param.examId);
    });

final userMockExamAttemptsProvider = FutureProvider.autoDispose
    .family<List<UserMockExamAttempt>, UserExamParam>((ref, param) {
      final dbService = ref.watch(databaseServiceProvider);
      return dbService.fetchUserMockExamAttempts(param.userId, param.examId);
    });
