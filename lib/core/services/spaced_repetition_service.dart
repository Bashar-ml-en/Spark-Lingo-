import 'package:flutter/foundation.dart';

@immutable
class SRSState {
  final int repetitions;
  final double efactor;
  final int interval; // in days
  final DateTime nextReviewAt;

  const SRSState({
    required this.repetitions,
    required this.efactor,
    required this.interval,
    required this.nextReviewAt,
  });

  // Convert to JSON-compatible map for Supabase storage
  Map<String, dynamic> toMap() {
    return {
      'repetitions': repetitions,
      'efactor': efactor,
      'interval': interval,
      'next_review_at': nextReviewAt.toIso8601String(),
    };
  }

  // Parse from Supabase database map
  factory SRSState.fromMap(Map<String, dynamic> map) {
    // `next_review` was written by an earlier client build. Read it only as a
    // compatibility fallback while all new writes use `next_review_at`.
    final storedNextReview = map['next_review_at'] ?? map['next_review'];
    return SRSState(
      repetitions: map['repetitions'] as int? ?? 0,
      efactor: (map['efactor'] as num? ?? 2.5).toDouble(),
      interval: map['interval'] as int? ?? 0,
      nextReviewAt: storedNextReview != null
          ? DateTime.parse(storedNextReview as String)
          : DateTime.now(),
    );
  }
}

class SpacedRepetitionService {
  /// Calculate the next learning state of a card according to the SuperMemo-2 (SM-2) algorithm.
  /// [quality] represents user recall response:
  /// - 5: perfect response
  /// - 4: correct response after a hesitation
  /// - 3: correct response recalled with serious difficulty
  /// - 2: incorrect response; where the correct one seemed easy to recall
  /// - 1: incorrect response; the correct one remembered
  /// - 0: complete blackout.
  static SRSState calculateNextState({
    required int quality,
    required int prevRepetitions,
    required double prevEfactor,
    required int prevInterval,
    DateTime? now,
  }) {
    // Quality parameter validation constraints [0, 5]
    final q = quality.clamp(0, 5);

    int repetitions;
    double efactor;
    int interval;

    // 1. Calculate new Easiness Factor (E-factor)
    efactor = prevEfactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (efactor < 1.3) {
      efactor = 1.3; // SM-2 standard absolute minimum floor limit
    }

    // 2. Calculate next review interval in days and update repetition count
    if (q >= 3) {
      if (prevRepetitions == 0) {
        interval = 1;
        repetitions = 1;
      } else if (prevRepetitions == 1) {
        interval = 6;
        repetitions = 2;
      } else {
        interval = (prevInterval * efactor).round();
        repetitions = prevRepetitions + 1;
      }
    } else {
      // Recall failed: reset repetition memory loops, schedule review for tomorrow
      repetitions = 0;
      interval = 1;
    }

    // 3. Schedule next review date
    final nextReviewDate = (now ?? DateTime.now()).add(
      Duration(days: interval),
    );

    return SRSState(
      repetitions: repetitions,
      efactor: efactor,
      interval: interval,
      nextReviewAt: nextReviewDate,
    );
  }
}
