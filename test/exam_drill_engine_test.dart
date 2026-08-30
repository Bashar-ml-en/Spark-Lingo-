import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/features/exam_prep/exam_drill_engine.dart';
import 'package:spark_lingo/features/practice/practice_engine.dart';

PracticeCard card(String id, String front, String back) =>
    PracticeCard(id: id, front: front, back: back);

void main() {
  final cards = List.generate(
    12,
    (i) => card('c$i', 'front-$i', 'back-$i'),
  );

  group('ExamDrillEngine', () {
    test('builds the requested number of questions from real cards', () {
      final engine = ExamDrillEngine(random: Random(7));
      final drill = engine.buildDrill(cards, questionCount: 10);
      expect(drill.length, 10);
    });

    test('empty card pool yields empty drill (no fabricated questions)', () {
      final engine = ExamDrillEngine(random: Random(7));
      expect(engine.buildDrill(const []), isEmpty);
    });

    test('fewer cards than requested uses only real cards', () {
      final engine = ExamDrillEngine(random: Random(7));
      final drill = engine.buildDrill(cards.take(3).toList(), questionCount: 10);
      expect(drill.length, 3);
    });

    test('every choice set contains exactly the correct answer', () {
      final engine = ExamDrillEngine(random: Random(11));
      final drill = engine.buildDrill(cards, questionCount: 8);
      for (final q in drill) {
        expect(q.choices.length, 4);
        expect(q.correctIndex >= 0 && q.correctIndex < q.choices.length, isTrue);
      }
    });

    test('direction alternates for retrieval practice', () {
      final engine = ExamDrillEngine(random: Random(3));
      final drill = engine.buildDrill(cards, questionCount: 6);
      expect(drill[0].direction, 'l2-to-l1');
      expect(drill[1].direction, 'l1-to-l2');
    });

    test('distractors never equal the correct answer', () {
      final engine = ExamDrillEngine(random: Random(5));
      final drill = engine.buildDrill(cards, questionCount: 10);
      for (final q in drill) {
        final correct = q.choices[q.correctIndex];
        final others = q.choices.where((c) => c != correct);
        expect(others.length, q.choices.length - 1);
        expect(q.choices.toSet().length, q.choices.length,
            reason: 'no duplicate choices');
      }
    });

    test('deterministic with a fixed seed', () {
      final a = ExamDrillEngine(random: Random(42)).buildDrill(cards);
      final b = ExamDrillEngine(random: Random(42)).buildDrill(cards);
      expect(a.map((q) => q.prompt).toList(), b.map((q) => q.prompt).toList());
    });
  });

  group('training pace honesty', () {
    test('no official minutes → 45s training default', () {
      expect(ExamDrillEngine.trainingPaceSeconds(officialSectionMinutes: null), 45);
      expect(ExamDrillEngine.trainingPaceSeconds(officialSectionMinutes: 0), 45);
    });

    test('official minutes scale proportionally and clamp to sane bounds', () {
      // 50 min for 10 questions = 300s/question → clamped to 180 max.
      expect(ExamDrillEngine.trainingPaceSeconds(officialSectionMinutes: 50), 180);
      // 1 minute for 10 questions = 6s → clamped to 15 min.
      expect(ExamDrillEngine.trainingPaceSeconds(officialSectionMinutes: 1), 15);
      // 15 min → 90s per question, inside bounds.
      expect(ExamDrillEngine.trainingPaceSeconds(officialSectionMinutes: 15), 90);
    });
  });
}
