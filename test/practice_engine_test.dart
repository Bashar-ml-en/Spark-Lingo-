import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/features/practice/practice_engine.dart';

PracticeCard card(String id, String front, String back, {String? context}) =>
    PracticeCard(id: id, front: front, back: back, context: context);

void main() {
  group('PracticeCard.complexity', () {
    test('single word ranks below multi-word phrase', () {
      final word = card('a', 'Hallo', 'Hello');
      final phrase = card('b', 'Wie geht es dir?', 'How are you?');
      expect(word.complexity < phrase.complexity, isTrue);
    });

    test('equal-length phrases ordered by character count', () {
      final short = card('a', 'Hola', 'Hi');
      final long = card('b', 'Buenos dias', 'Good morning');
      expect(short.complexity < long.complexity, isTrue);
    });

    test('context marks a richer item (later ordering)', () {
      final plain = card('a', 'Casa', 'House');
      final rich = card('b', 'Casa', 'House', context: 'Mi casa es tu casa');
      expect(plain.complexity < rich.complexity, isTrue);
    });
  });

  group('PracticeEngine.buildSession', () {
    final engine = PracticeEngine(random: Random(42));
    final cards = [
      card('c1', 'Bonjour', 'Hello'),
      card('c2', 'Merci', 'Thank you'),
      card('c3', 'Comment allez-vous?', 'How are you?'),
      card('c4', 'Au revoir', 'Goodbye'),
    ];

    test('empty input yields empty queue', () {
      expect(engine.buildSession([]), isEmpty);
    });

    test('queue length = 3x cards (learn + recognize + produce)', () {
      final queue = engine.buildSession(cards);
      expect(queue.length, cards.length * 3);
    });

    test('phases appear in escalation order', () {
      final queue = engine.buildSession(cards);
      final types = queue.map((e) => e.type).toList();
      final firstRecognize = types.indexOf(ExerciseType.recognize);
      final firstProduce = types.indexOf(ExerciseType.produce);
      expect(types.take(cards.length).every((t) => t == ExerciseType.learn),
          isTrue);
      expect(firstRecognize, cards.length);
      expect(firstProduce, greaterThan(firstRecognize));
    });

    test('learn phase escalates: bands non-decreasing, complexity '
        'non-decreasing within each band', () {
      final queue = engine.buildSession(cards);
      final learn = queue.where((e) => e.type == ExerciseType.learn).toList();
      final n = cards.length;
      int bandOf(PracticeCard c) {
        final idx = cards.indexWhere((x) => x.id == c.id);
        return (idx * 3) ~/ n;
      }

      for (var i = 1; i < learn.length; i++) {
        final prevBand = bandOf(learn[i - 1].card);
        final currBand = bandOf(learn[i].card);
        expect(currBand >= prevBand, isTrue,
            reason: 'unit band must not regress');
        if (currBand == prevBand) {
          expect(
            learn[i - 1].card.complexity <= learn[i].card.complexity,
            isTrue,
            reason: 'within a band, complexity must escalate',
          );
        }
      }
    });

    test('recognition exercises carry 3 distinct distractors from the pool',
        () {
      final queue = engine.buildSession(cards);
      final rec = queue.where((e) => e.type == ExerciseType.recognize).toList();
      for (final ex in rec) {
        expect(ex.distractors.length, 3);
        expect(ex.distractors.toSet().length, 3, reason: 'no dup distractors');
        expect(ex.distractors.contains(ex.answer), isFalse);
      }
    });

    test('recognition direction alternates', () {
      final queue = engine.buildSession(cards);
      final rec = queue.where((e) => e.type == ExerciseType.recognize).toList();
      expect(rec[0].frontToBack, isNot(rec[1].frontToBack));
    });

    test('production phase produces target-language answers mostly', () {
      final queue = engine.buildSession(cards);
      final prod = queue.where((e) => e.type == ExerciseType.produce).toList();
      final targetProduction =
          prod.where((e) => !e.frontToBack).length; // back→front = target
      expect(targetProduction, greaterThanOrEqualTo(prod.length ~/ 2));
    });
  });

  group('answersMatch (fuzzy production grading)', () {
    test('exact match', () {
      expect(answersMatch('Merci', 'Merci'), isTrue);
    });

    test('case-insensitive', () {
      expect(answersMatch('Bonjour', 'bonjour'), isTrue);
    });

    test('diacritics forgiven', () {
      expect(answersMatch('élève', 'eleve'), isTrue);
    });

    test('punctuation forgiven', () {
      expect(answersMatch('Comment allez-vous?', 'comment allez vous'),
          isTrue);
    });

    test('wrong answer rejected', () {
      expect(answersMatch('Merci', 'Bonjour'), isFalse);
    });

    test('empty given rejected', () {
      expect(answersMatch('Merci', ''), isFalse);
    });

    test('leading article optional', () {
      expect(answersMatch('the house', 'house'), isTrue);
      expect(answersMatch('la casa', 'casa'), isTrue);
    });
  });

  group('srsQualityFor', () {
    test('passed production scores highest (5)', () {
      expect(
        srsQualityFor(type: ExerciseType.produce, passed: true),
        5,
      );
    });

    test('passed recall after failure scores 3', () {
      expect(
        srsQualityFor(type: ExerciseType.recall, passed: true),
        3,
      );
    });

    test('failed exercises score 1', () {
      expect(
        srsQualityFor(type: ExerciseType.recognize, passed: false),
        1,
      );
    });

    test('learn exposure scores 4', () {
      expect(srsQualityFor(type: ExerciseType.learn, passed: true), 4);
    });
  });

  group('recall re-queue', () {
    test('recallExercise builds a produce-style re-test', () {
      final engine = PracticeEngine();
      final c = card('x', 'Danke', 'Thanks');
      final ex = engine.recallExercise(c);
      expect(ex.type, ExerciseType.recall);
      expect(ex.card.id, 'x');
      expect(ex.frontToBack, isFalse, reason: 'recall targets production');
    });

    test('unit band dominates: early-course card precedes late-course card '
        'even when complexity says otherwise', () {
      final engine = PracticeEngine();
      // 6 cards in syllabus order. The LAST card is a short simple word
      // (lowest complexity), but it belongs to the late band, so the first
      // card (early band, longer phrase) must still come first.
      final orderedCards = [
        card('c0', 'a long early phrase here', 'x0'),
        card('c1', 'early item two', 'x1'),
        card('c2', 'mid item one', 'x2'),
        card('c3', 'mid item two now', 'x3'),
        card('c4', 'late item one', 'x4'),
        card('c5', 'hi', 'x5'), // shortest, but last in syllabus order
      ];
      final queue = engine.buildSession(orderedCards);
      final learnOrder = queue
          .where((e) => e.type == ExerciseType.learn)
          .map((e) => e.card.id)
          .toList();
      expect(learnOrder.first, anyOf('c0', 'c1'),
          reason: 'an early-band card comes first despite complexity');
      expect(learnOrder.last, 'c4',
          reason: 'highest-complexity card of the late band comes last; '
              'c5 is in the same late band but simpler, so it precedes c4');
      // Bands must be non-decreasing across the session.
      final bandOf = {
        for (var i = 0; i < orderedCards.length; i++)
          orderedCards[i].id: (i * 3) ~/ orderedCards.length,
      };
      final bands = learnOrder.map((id) => bandOf[id]!).toList();
      for (var i = 1; i < bands.length; i++) {
        expect(bands[i] >= bands[i - 1], isTrue,
            reason: 'band progression must not regress');
      }
    });
  });
}
