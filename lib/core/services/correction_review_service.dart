import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';
import 'spaced_repetition_service.dart';

/// A learner-saved, server-generated correction scheduled locally with SM-2.
@immutable
class ReviewCorrection {
  const ReviewCorrection({
    required this.id,
    required this.languageCode,
    required this.errorClass,
    required this.correctedForm,
    required this.srs,
    required this.savedAt,
  });

  final String id;
  final String languageCode;
  final String errorClass;
  final String correctedForm;
  final SRSState srs;
  final DateTime savedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'language_code': languageCode,
    'error_class': errorClass,
    'corrected_form': correctedForm,
    'saved_at': savedAt.toIso8601String(),
    ...srs.toMap(),
  };

  factory ReviewCorrection.fromMap(Map<String, dynamic> map) {
    return ReviewCorrection(
      id: map['id'] as String,
      languageCode: map['language_code'] as String,
      errorClass: map['error_class'] as String,
      correctedForm: map['corrected_form'] as String,
      savedAt: DateTime.parse(map['saved_at'] as String),
      srs: SRSState.fromMap(map),
    );
  }
}

/// A user-scoped on-device review deck. Data never crosses account boundaries:
/// callers must pass the currently authenticated user ID for every operation.
class CorrectionReviewService {
  static const _storageKeyPrefix = 'spark_correction_deck_v1.';

  String _keyFor(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'A user ID is required.');
    }
    return '$_storageKeyPrefix$normalized';
  }

  Future<bool> saveCorrection({
    required String userId,
    required String languageCode,
    required CorrectionItem item,
  }) async {
    final deck = await loadDeck(userId: userId);
    final normalizedLanguage = languageCode.trim();
    final normalizedForm = item.correctedForm.trim();
    if (normalizedLanguage.isEmpty || normalizedForm.isEmpty) return false;
    final exists = deck.any(
      (card) =>
          card.languageCode == normalizedLanguage &&
          card.correctedForm == normalizedForm,
    );
    if (exists) return false;

    final now = DateTime.now();
    final card = ReviewCorrection(
      id: 'corr_${now.microsecondsSinceEpoch}',
      languageCode: normalizedLanguage,
      errorClass: item.errorClass,
      correctedForm: normalizedForm,
      srs: SRSState(
        repetitions: 0,
        efactor: 2.5,
        interval: 0,
        nextReviewAt: now,
      ),
      savedAt: now,
    );
    await _persist(userId, [...deck, card]);
    return true;
  }

  Future<List<ReviewCorrection>> loadDeck({
    required String userId,
    String? languageCode,
  }) async {
    final deck = await _readAll(userId);
    if (languageCode == null) return deck;
    return deck
        .where((card) => card.languageCode == languageCode)
        .toList(growable: false);
  }

  Future<List<ReviewCorrection>> dueCards({
    required String userId,
    required String languageCode,
  }) async {
    final now = DateTime.now();
    final deck = await loadDeck(userId: userId, languageCode: languageCode);
    return deck
        .where((card) => !card.srs.nextReviewAt.isAfter(now))
        .toList(growable: false);
  }

  Future<void> reviewCard({
    required String userId,
    required ReviewCorrection card,
    required int quality,
  }) async {
    final deck = await _readAll(userId);
    final next = SpacedRepetitionService.calculateNextState(
      quality: quality,
      prevRepetitions: card.srs.repetitions,
      prevEfactor: card.srs.efactor,
      prevInterval: card.srs.interval,
    );
    await _persist(
      userId,
      deck
          .map(
            (existing) => existing.id == card.id
                ? ReviewCorrection(
                    id: existing.id,
                    languageCode: existing.languageCode,
                    errorClass: existing.errorClass,
                    correctedForm: existing.correctedForm,
                    srs: next,
                    savedAt: existing.savedAt,
                  )
                : existing,
          )
          .toList(growable: false),
    );
  }

  Future<void> removeCard({
    required String userId,
    required String cardId,
  }) async {
    final deck = await _readAll(userId);
    await _persist(
      userId,
      deck.where((card) => card.id != cardId).toList(growable: false),
    );
  }

  Future<void> clearDeck(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_keyFor(userId));
    } catch (_) {
      debugPrint('Correction review cleanup failed.');
    }
  }

  Future<List<ReviewCorrection>> _readAll(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_keyFor(userId));
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final cards = <ReviewCorrection>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        try {
          cards.add(ReviewCorrection.fromMap(Map<String, dynamic>.from(entry)));
        } catch (_) {
          // A corrupt persisted card must not block the rest of the deck.
        }
      }
      return cards;
    } catch (_) {
      debugPrint('Correction review deck could not be read.');
      return const [];
    }
  }

  Future<void> _persist(String userId, List<ReviewCorrection> deck) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _keyFor(userId),
        jsonEncode(deck.map((card) => card.toMap()).toList(growable: false)),
      );
    } catch (_) {
      debugPrint('Correction review deck could not be saved.');
    }
  }
}

final correctionReviewServiceProvider = Provider<CorrectionReviewService>(
  (ref) => CorrectionReviewService(),
);
