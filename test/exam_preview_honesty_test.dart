import 'package:flutter/material.dart';
import 'package:spark_lingo/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/features/exam_prep/exam_readiness_dashboard.dart';
import 'package:spark_lingo/features/exam_prep/mock_exam_screen.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  testWidgets('a new learner never receives a fabricated readiness score', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const ExamReadinessDashboard(
          userId: 'learner-a',
          examId: 'ielts',
          languageCode: 'en',
        ),
      ),
    );

    expect(find.text('Scored exam practice is in development'), findsOneWidget);
    expect(find.textContaining('Band'), findsNothing);
    expect(find.textContaining('CEFR'), findsNothing);
    expect(find.textContaining('7.5'), findsNothing);
    expect(find.textContaining('8.5'), findsNothing);
  });

  testWidgets('a mock exam cannot be started or submitted as scored work', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const MockExamScreen(userId: 'learner-a', mockExamId: 'mock-a')),
    );

    expect(find.text('Mock exams are not available yet'), findsOneWidget);
    expect(find.textContaining('Start exam'), findsNothing);
    expect(find.textContaining('Exam Submitted'), findsNothing);
    expect(
      find.textContaining('Your answers have been submitted'),
      findsNothing,
    );
  });
}
