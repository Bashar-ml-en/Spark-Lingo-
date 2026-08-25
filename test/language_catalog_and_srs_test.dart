import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/core/constants/language_catalog.dart';
import 'package:spark_lingo/core/services/spaced_repetition_service.dart';

void main() {
  group('LanguageCatalog', () {
    test('normalizes legacy names and regional locales to canonical codes', () {
      expect(LanguageCatalog.tryCanonicalCode('Spanish'), 'es');
      expect(LanguageCatalog.tryCanonicalCode('es-MX'), 'es');
      expect(LanguageCatalog.tryCanonicalCode('bahasa melayu'), 'ms');
      expect(LanguageCatalog.tryCanonicalCode('unknown-language'), isNull);
    });

    test('deduplicates canonical profile languages while preserving order', () {
      expect(
        LanguageCatalog.canonicalizeAll(['Spanish', 'es-MX', 'French', 'fr']),
        ['es', 'fr'],
      );
    });

    test('exposes every catalog language — all 15 ship bundled curriculum', () {
      final codes = LanguageCatalog.supportedLanguages;
      expect(codes, hasLength(15));
      for (final code in codes) {
        expect(
          LanguageCatalog.hasBundledCurriculum(code),
          isTrue,
          reason: code,
        );
      }
      // Includes Malay — the Malay-first home market.
      expect(LanguageCatalog.hasBundledCurriculum('ms'), isTrue);
      // Unknown codes stay excluded.
      expect(LanguageCatalog.hasBundledCurriculum('xx'), isFalse);
    });
  });

  group('SpacedRepetitionService', () {
    test(
      'reads the legacy review timestamp while new maps use next_review_at',
      () {
        final legacy = SRSState.fromMap({
          'repetitions': 2,
          'efactor': 2.5,
          'interval': 6,
          'next_review': '2026-08-20T00:00:00.000Z',
        });

        expect(legacy.nextReviewAt.toUtc(), DateTime.utc(2026, 8, 20));
        expect(legacy.toMap(), containsPair('next_review_at', isNotNull));
        expect(legacy.toMap(), isNot(contains('next_review')));
      },
    );

    test('hard recall remains a successful SM-2 repetition', () {
      final state = SpacedRepetitionService.calculateNextState(
        quality: 3,
        prevRepetitions: 0,
        prevEfactor: 2.5,
        prevInterval: 0,
        now: DateTime.utc(2026, 8, 16),
      );

      expect(state.repetitions, 1);
      expect(state.interval, 1);
      expect(state.nextReviewAt, DateTime.utc(2026, 8, 17));
    });
  });
}
