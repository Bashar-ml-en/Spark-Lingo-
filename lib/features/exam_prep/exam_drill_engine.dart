import 'dart:math';

import '../practice/practice_engine.dart' show PracticeCard;

/// One question in a timed exam drill.
class TimedDrillQuestion {
  final String prompt;
  final List<String> choices;
  final int correctIndex;
  final String direction; // 'l2-to-l1' or 'l1-to-l2'

  const TimedDrillQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    required this.direction,
  });
}

/// Pure, testable generator for timed exam-section drills.
///
/// Honesty contract: questions are built ONLY from real curriculum cards
/// (syllabus_master.json / reviewed cloud curriculum). The timer is a
/// training pace derived from the official section minutes where the
/// official body publishes them — never a fabricated score, prediction,
/// or official question bank.
class ExamDrillEngine {
  final Random _rng;

  ExamDrillEngine({Random? random}) : _rng = random ?? Random();

  /// Builds a multiple-choice drill from real cards.
  ///
  /// [secondsPerQuestion] is the training pace. Callers derive it from
  /// official section timing when available; the UI labels it as a
  /// training timer, never an official constraint.
  List<TimedDrillQuestion> buildDrill(
    List<PracticeCard> cards, {
    int questionCount = 10,
  }) {
    if (cards.isEmpty) return const [];
    final pool = List<PracticeCard>.from(cards)..shuffle(_rng);
    final picked = pool.take(questionCount).toList();
    final questions = <TimedDrillQuestion>[];

    for (var i = 0; i < picked.length; i++) {
      final card = picked[i];
      // Alternate direction so the drill practices both recognition and
      // translation recall (evidence-based retrieval practice).
      final l2First = i.isEven;
      final prompt = l2First ? card.front : card.back;
      final answer = l2First ? card.back : card.front;

      // Distractors: other cards' answers, never the correct one.
      final distractorPool = pool
          .where((c) => c.id != card.id)
          .map((c) => l2First ? c.back : c.front)
          .where((t) => t != answer)
          .toSet()
          .toList()
        ..shuffle(_rng);
      final distractors = distractorPool.take(3).toList();

      final choices = <String>[answer, ...distractors]..shuffle(_rng);
      questions.add(TimedDrillQuestion(
        prompt: prompt,
        choices: choices,
        correctIndex: choices.indexOf(answer),
        direction: l2First ? 'l2-to-l1' : 'l1-to-l2',
      ));
    }
    return questions;
  }

  /// Training pace in seconds per question.
  ///
  /// If the official body publishes the section length in minutes, pace is
  /// proportional to it (official minutes → seconds per question, scaled
  /// so a full-size section would match the official clock). Otherwise a
  /// conservative 45s training default is used and MUST be labeled as a
  /// training timer in the UI.
  static int trainingPaceSeconds({
    required int? officialSectionMinutes,
    int questionCount = 10,
  }) {
    if (officialSectionMinutes == null || officialSectionMinutes <= 0) {
      return 45;
    }
    // Official minutes per question, applied to the drill length.
    final perQuestion = (officialSectionMinutes * 60) / questionCount;
    return perQuestion.round().clamp(15, 180);
  }
}
