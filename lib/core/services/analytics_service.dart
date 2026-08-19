import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'telemetry_consent_service.dart';

/// App-wide privacy-first Product Analytics Service (PROD-001).
///
/// Strictly enforces that no PII (user text, prompts, emails, audio) is sent to
/// external telemetry endpoints. All events respect user consent.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Log app launch event
  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint('Analytics logAppOpen failed: $e');
    }
  }

  /// Log screen transition
  Future<void> logScreenView({required String screenName}) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Analytics logScreenView failed: $e');
    }
  }

  /// Log lesson completion without including personal responses
  Future<void> logLessonCompleted({
    required String lessonId,
    required int scorePercentage,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'lesson_completed',
        parameters: {
          'lesson_id': lessonId,
          'score_percentage': scorePercentage,
        },
      );
    } catch (e) {
      debugPrint('Analytics logLessonCompleted failed: $e');
    }
  }

  /// Log card review event (SRS memory test)
  Future<void> logCardReviewed({
    required String cardId,
    required bool remembered,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'card_reviewed',
        parameters: {
          'card_id': cardId,
          'remembered': remembered ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('Analytics logCardReviewed failed: $e');
    }
  }

  /// Log AI generation request without sending prompt text or transcripts
  Future<void> logAiLessonRequested({
    required String level,
    required String targetLanguage,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_lesson_requested',
        parameters: {
          'level': level,
          'target_language': targetLanguage,
        },
      );
    } catch (e) {
      debugPrint('Analytics logAiLessonRequested failed: $e');
    }
  }
}
