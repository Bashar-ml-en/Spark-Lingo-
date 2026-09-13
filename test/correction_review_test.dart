import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spark_lingo/core/services/ai_service.dart';
import 'package:spark_lingo/core/services/correction_review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const item = CorrectionItem(
    errorClass: 'grammar_accuracy',
    criterionName: 'Grammar',
    correctedForm: "Use 'went' instead of 'goed'.",
    occurrences: 1,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('session reports parse valid corrections defensively', () {
    final report = SessionReport.fromMap({
      'focus_areas': [
        {'error_class': 'grammar_accuracy', 'occurrences': 3},
        {'error_class': ''},
      ],
      'corrections': [
        {
          'error_class': 'grammar_accuracy',
          'criterion_name': 'Grammar',
          'corrected_form': item.correctedForm,
          'occurrences': 2,
        },
        {'error_class': 'pronunciation', 'corrected_form': '   '},
      ],
    });

    expect(report.focusAreas, hasLength(1));
    expect(report.corrections, hasLength(1));
    expect(report.corrections.single.occurrences, 2);
  });

  test('correction decks are isolated by authenticated user', () async {
    final service = CorrectionReviewService();

    expect(
      await service.saveCorrection(
        userId: 'user-a',
        languageCode: 'ms',
        item: item,
      ),
      isTrue,
    );

    expect(await service.loadDeck(userId: 'user-a'), hasLength(1));
    expect(await service.loadDeck(userId: 'user-b'), isEmpty);
  });

  test('duplicate corrections do not stack in one user deck', () async {
    final service = CorrectionReviewService();

    await service.saveCorrection(
      userId: 'user-a',
      languageCode: 'ms',
      item: item,
    );
    expect(
      await service.saveCorrection(
        userId: 'user-a',
        languageCode: 'ms',
        item: item,
      ),
      isFalse,
    );
    expect(await service.loadDeck(userId: 'user-a'), hasLength(1));
  });

  test('account cleanup removes only the deleted user deck', () async {
    final service = CorrectionReviewService();
    await service.saveCorrection(
      userId: 'user-a',
      languageCode: 'ms',
      item: item,
    );
    await service.saveCorrection(
      userId: 'user-b',
      languageCode: 'ms',
      item: item,
    );

    await service.clearDeck('user-a');

    expect(await service.loadDeck(userId: 'user-a'), isEmpty);
    expect(await service.loadDeck(userId: 'user-b'), hasLength(1));
  });

  test('a saved correction is immediately due for review', () async {
    final service = CorrectionReviewService();
    await service.saveCorrection(
      userId: 'user-a',
      languageCode: 'ms',
      item: item,
    );

    expect(
      await service.dueCards(userId: 'user-a', languageCode: 'ms'),
      hasLength(1),
    );
  });
}
