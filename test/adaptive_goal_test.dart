import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/core/services/adaptive_goal.dart';

void main() {
  group('AdaptiveGoal.suggest', () {
    test('thin history yields no suggestion', () {
      expect(AdaptiveGoal.suggest([]), isNull);
      expect(AdaptiveGoal.suggest([30]), isNull);
      expect(AdaptiveGoal.suggest([30, 40]), isNull);
    });

    test('median of 3 active days, rounded to 5', () {
      expect(AdaptiveGoal.suggest([30, 40, 50]), 40);
      expect(AdaptiveGoal.suggest([31, 39, 47]), 40);
    });

    test('uses only the most recent 7 active days', () {
      // Oldest huge values must not inflate the suggestion.
      final history = [500, 500, 500, 500, 500, 20, 20, 20, 20, 20];
      expect(AdaptiveGoal.suggest(history), 20);
    });

    test('even count averages the two middle values', () {
      expect(AdaptiveGoal.suggest([20, 30, 40, 50]), 35);
    });

    test('clamps to server bounds 10..500', () {
      expect(AdaptiveGoal.suggest([500, 500, 500]), 500);
      expect(AdaptiveGoal.suggest([1, 2, 3]), 10);
    });
  });

  group('AdaptiveGoal.shouldOffer', () {
    test('no suggestion means no offer', () {
      expect(AdaptiveGoal.shouldOffer(30, null), isFalse);
    });

    test('trivial deltas are suppressed', () {
      expect(AdaptiveGoal.shouldOffer(30, 35), isFalse);
      expect(AdaptiveGoal.shouldOffer(30, 25), isFalse);
    });

    test('meaningful deltas are offered', () {
      expect(AdaptiveGoal.shouldOffer(30, 45), isTrue);
      expect(AdaptiveGoal.shouldOffer(50, 30), isTrue);
    });
  });
}
