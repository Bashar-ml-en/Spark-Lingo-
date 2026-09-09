import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';
import 'spaced_repetition_service.dart';

/// One learner-saved AI correction, reviewed on device with SM-2.
///
/// Stored locally only (SharedPreferences): the server keeps its own
/// service-role ledger for the `report` action; this deck is the learner's
/// personal review queue and never syncs content back to the server.
@immutable
class ReviewCorrection {
  final String id;
  final String languageCode;
  final String errorClass;
  final String correctedForm;
  final SRSState srs;
  final DateTime savedAt;

  const ReviewCorrection({
    required this.id,
    required this.languageCode,
    required this.errorClass,
    required this.correctedForm,
    required this.srs,
    required this.savedAt,
  });

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

/// Local "My Corrections" review deck: saves [CorrectionItem]s from the
/// session report and schedules them with the existing SM-2 service.
class CorrectionReviewService {
  static const _storageKey = 'spark_correction_deck_v1';

  /// Saves a correction into the local deck. Dedupes by
  /// (language, corrected form) so repeated reports don't stack duplicates.
  Future<bool> saveCorrection({
    required String languageCode,
    required CorrectionItem item,
  }) async {
    final deck = await loadDeck();
    final normalized = item.correctedForm.trim();
    if (normalized.isEmpty) return false;
    final exists = deck.any(
      (card) =>
          card.languageCode == languageCode &&
          card.correctedForm == normalized,
    );
    if (exists) return false;

    final now = DateTime.now();
    final card = ReviewCorrection(
      id: 'corr_${now.microsecondsSinceEpoch}',
      languageCode: languageCode,
      errorClass: item.errorClass,
      correctedForm: normalized,
      // Fresh SM-2 state: due immediately so the learner sees it today.
      srs: SRSState(
        repetitions: 0,
        efactor: 2.5,
        interval: 0,
        nextReviewAt: now,
      ),
      savedAt: now,
    );
    await _persist([...deck, card]);
    return true;
  }

  /// All saved corrections for one language.
  Future<List<ReviewCorrection>> loadDeck({String? languageCode}) async {
    final deck = await _readAll();
    if (languageCode == null) return deck;
    return deck
        .where((card) => card.languageCode == languageCode)
        .toList(growable: false);
  }

  /// Cards due for review now (nextReviewAt <= now).
  Future<List<ReviewCorrection>> dueCards(String languageCode) async {
    final now = DateTime.now();
    final deck = await loadDeck(languageCode: languageCode);
    return deck
        .where((card) => !card.srs.nextReviewAt.isAfter(now))
        .toList(growable: false);
  }

  /// Applies an SM-2 recall result and reschedules the card.
  Future<void> reviewCard({
    required ReviewCorrection card,
    required int quality,
  }) async {
    final deck = await _readAll();
    final next = SpacedRepetitionService.calculateNextState(
      quality: quality,
      prevRepetitions: card.srs.repetitions,
      prevEfactor: card.srs.efactor,
      prevInterval: card.srs.interval,
    );
    final updated = deck
        .map(
          (existing) => existing.id == card.id
              ? ReviewCorrection(
                  id: existing.id,
                  languageCode: existing.languageCode,
                  errorClass: existing.errorClass,
                  correctedForm: existing.correctedForm,
                  savedAt: existing.savedAt,
                  srs: next,
                )
              : existing,
        )
        .toList(growable: false);
    await _persist(updated);
  }

  Future<void> removeCard(String id) async {
    final deck = await _readAll();
    await _persist(
      deck.where((card) => card.id != id).toList(growable: false),
    );
  }

  Future<List<ReviewCorrection>> _readAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final cards = <ReviewCorrection>[];
      for (final entry in decoded) {
        // Defensive parse: one corrupt row must not break the whole deck.
        if (entry is Map<String, dynamic>) {
          try {
            cards.add(ReviewCorrection.fromMap(entry));
          } catch (_) {
            continue;
          }
        }
      }
      return cards;
    } catch (_) {
      debugPrint('Correction deck read failed; starting empty.');
      return const [];
    }
  }

  Future<void> _persist(List<ReviewCorrection> deck) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(deck.map((card) => card.toMap()).toList(growable: false)),
      );
    } catch (_) {
      debugPrint('Correction deck save failed.');
    }
  }
}

final correctionReviewServiceProvider =
    Provider<CorrectionReviewService>((ref) => CorrectionReviewService());
