import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spark_lingo/core/services/ai_service.dart';
import 'package:spark_lingo/core/services/correction_review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionReport.fromMap', () {
    test('parses focus areas and corrections defensively', () {
      final report = SessionReport.fromMap({
        'language': 'ms',
        'focus_areas': [
          {'error_class': 'grammar_accuracy', 'occurrences': 3},
          {'error_class': '', 'occurrences': 1}, // dropped: empty class
          {'occurrences': 2}, // dropped: no class
          'not-a-map', // dropped
        ],
        'corrections': [
          {
            'error_class': 'grammar_accuracy',
            'criterion_name': 'Grammar',
            'corrected_form': "Use 'went' instead of 'goed'.",
            'occurrences': 2,
            'last_seen_at': '2026-09-09T00:00:00Z',
          },
          {
            'error_class': 'pronunciation',
            'corrected_form': '   ', // dropped: blank form
          },
          {
            'error_class': 'vocabulary_range',
            'corrected_form': 'Prefer "big" over "very big".',
            'occurrences': 'two', // non-int occurrences defaults to 1
          },
        ],
      });

      expect(report.focusAreas.length, 1);
      expect(report.focusAreas.first.errorClass, 'grammar_accuracy');
      expect(report.focusAreas.first.occurrences, 3);

      expect(report.corrections.length, 2);
      expect(report.corrections[0].correctedForm, "Use 'went' instead of 'goed'.");
      expect(report.corrections[1].occurrences, 1);
      expect(report.isEmpty, isFalse);
    });

    test('empty payload yields empty report', () {
      const report = SessionReport();
      expect(report.isEmpty, isTrue);
      expect(SessionReport.fromMap({}).isEmpty, isTrue);
      expect(SessionReport.fromMap({'focus_areas': null, 'corrections': 42}).isEmpty, isTrue);
    });
  });

  group('CorrectionReviewService', () {
    late CorrectionReviewService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = CorrectionReviewService();
    });

    const item = CorrectionItem(
      errorClass: 'grammar_accuracy',
      criterionName: 'Grammar',
      correctedForm: "Use 'went' instead of 'goed'.",
      occurrences: 1,
    );

    test('saveCorrection stores card with fresh SM-2 state due now', () async {
      final saved = await service.saveCorrection(languageCode: 'ms', item: item);
      expect(saved, isTrue);

      final deck = await service.loadDeck(languageCode: 'ms');
      expect(deck.length, 1);
      expect(deck.first.correctedForm, item.correctedForm);
      expect(deck.first.srs.repetitions, 0);
      expect(deck.first.srs.efactor, 2.5);

      final due = await service.dueCards('ms');
      expect(due.length, 1);
    });

    test('saveCorrection dedupes by language + corrected form', () async {
      await service.saveCorrection(languageCode: 'ms', item: item);
      final again = await service.saveCorrection(languageCode: 'ms', item: item);
      expect(again, isFalse);

      final deck = await service.loadDeck(languageCode: 'ms');
      expect(deck.length, 1);
    });

    test('blank corrections are never saved', () async {
      const blank = CorrectionItem(
        errorClass: 'grammar_accuracy',
        criterionName: '',
        correctedForm: '   ',
        occurrences: 1,
      );
      final saved = await service.saveCorrection(languageCode: 'ms', item: blank);
      expect(saved, isFalse);
      expect(await service.loadDeck(languageCode: 'ms'), isEmpty);
    });

    test('reviewCard applies SM-2 scheduling', () async {
      await service.saveCorrection(languageCode: 'ms', item: item);
      final card = (await service.loadDeck(languageCode: 'ms')).first;

      // Perfect recall → repetitions 1, interval 1 day.
      await service.reviewCard(card: card, quality: 5);
      final after = (await service.loadDeck(languageCode: 'ms')).first;
      expect(after.srs.repetitions, 1);
      expect(after.srs.interval, 1);
      expect(after.srs.nextReviewAt.isAfter(DateTime.now()), isTrue);

      // No longer due.
      expect(await service.dueCards('ms'), isEmpty);

      // Failed recall resets to due tomorrow-ish (interval 1, reps 0).
      await service.reviewCard(card: after, quality: 1);
      final reset = (await service.loadDeck(languageCode: 'ms')).first;
      expect(reset.srs.repetitions, 0);
      expect(reset.srs.interval, 1);
    });

    test('removeCard deletes only the target card', () async {
      await service.saveCorrection(languageCode: 'ms', item: item);
      const other = CorrectionItem(
        errorClass: 'spelling_orthography',
        criterionName: 'Spelling',
        correctedForm: 'Their vs There',
        occurrences: 1,
      );
      await service.saveCorrection(languageCode: 'ms', item: other);
      expect((await service.loadDeck(languageCode: 'ms')).length, 2);

      final target = (await service.loadDeck(languageCode: 'ms'))
          .firstWhere((c) => c.correctedForm == 'Their vs There');
      await service.removeCard(target.id);

      final deck = await service.loadDeck(languageCode: 'ms');
      expect(deck.length, 1);
      expect(deck.first.correctedForm, item.correctedForm);
    });

    test('deck is isolated per language', () async {
      await service.saveCorrection(languageCode: 'ms', item: item);
      await service.saveCorrection(languageCode: 'en', item: item);
      expect((await service.loadDeck(languageCode: 'ms')).length, 1);
      expect((await service.loadDeck(languageCode: 'en')).length, 1);
      expect((await service.loadDeck()).length, 2);
    });

    test('corrupt storage degrades to empty deck', () async {
      SharedPreferences.setMockInitialValues({
        'spark_correction_deck_v1': '{{{not json',
      });
      final fresh = CorrectionReviewService();
      expect(await fresh.loadDeck(), isEmpty);
    });
  });
}
