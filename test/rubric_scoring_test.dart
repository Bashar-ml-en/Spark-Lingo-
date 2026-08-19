import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spark_lingo/shared/models/curriculum.dart';
import 'package:spark_lingo/shared/widgets/ai_score_disclaimer.dart';
import 'package:spark_lingo/core/services/monetization_service.dart';
import 'package:spark_lingo/core/services/revenuecat_service.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Lesson Model Extensions Tests', () {
    test('Correctly parses lesson properties from json map', () {
      final map = {
        'id': 'lesson-101',
        'title': 'IELTS Section Practice',
        'description': 'Practice speaking with Sparky',
        'type': 'ai_tutor_session',
        'skill': 'speaking',
        'rubric_ref': 'ielts_speaking_band_descriptors_5_7',
        'honesty_disclaimer': 'Custom IELTS warning notice',
        'sparky_prompt_template': 'Describe this line graph in detail.',
        'source_attribution': 'Mozilla Common Voice CC0',
      };

      final lesson = Lesson.fromMap(map);

      expect(lesson.id, 'lesson-101');
      expect(lesson.type, 'ai_tutor_session');
      expect(lesson.skill, 'speaking');
      expect(lesson.rubricRef, 'ielts_speaking_band_descriptors_5_7');
      expect(lesson.honestyDisclaimer, 'Custom IELTS warning notice');
      expect(
        lesson.sparkyPromptTemplate,
        'Describe this line graph in detail.',
      );
      expect(lesson.sourceAttribution, 'Mozilla Common Voice CC0');
    });
  });

  group('AIScoreDisclaimer Widget Tests', () {
    testWidgets('Renders with default text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AIScoreDisclaimer())),
      );

      expect(
        find.textContaining('AI-scored practice estimate'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('Renders with custom disclaimer text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIScoreDisclaimer(
              customDisclaimer: 'Custom IELTS scoring notice.',
            ),
          ),
        ),
      );

      expect(find.text('Custom IELTS scoring notice.'), findsOneWidget);
    });
  });

  group('MonetizationService Tests', () {
    test('Correctly locks rate limits for free tier', () async {
      final container = ProviderContainer(
        overrides: [
          // Mock isPremiumProvider to return false (free tier)
          isPremiumProvider.overrideWith((ref) => false),
        ],
      );

      final monetizationService = container.read(monetizationServiceProvider);

      // Clean up previous runs
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Verify initial attempts
      expect(await monetizationService.canPerformRubricCall(), true);
      expect(await monetizationService.getRemainingFreeAttempts(), 3);

      // Perform 3 calls
      await monetizationService.incrementRubricCallCount();
      await monetizationService.incrementRubricCallCount();
      await monetizationService.incrementRubricCallCount();

      // Verify limits are reached
      expect(await monetizationService.canPerformRubricCall(), false);
      expect(await monetizationService.getRemainingFreeAttempts(), 0);
    });

    test('Allows unlimited calls for premium tier', () async {
      final container = ProviderContainer(
        overrides: [
          // Mock isPremiumProvider to return true (premium tier)
          isPremiumProvider.overrideWith((ref) => true),
        ],
      );

      final monetizationService = container.read(monetizationServiceProvider);

      // Clean up previous runs
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Perform 5 calls (more than free Daily cap)
      await monetizationService.incrementRubricCallCount();
      await monetizationService.incrementRubricCallCount();
      await monetizationService.incrementRubricCallCount();
      await monetizationService.incrementRubricCallCount();
      await monetizationService.incrementRubricCallCount();

      // Verify attempts are still allowed
      expect(await monetizationService.canPerformRubricCall(), true);
      expect(await monetizationService.getRemainingFreeAttempts(), 999);
    });
  });
}
