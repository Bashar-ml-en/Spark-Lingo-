import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/core/design/components.dart';
import 'package:spark_lingo/core/design/tokens.dart';
import 'package:spark_lingo/core/theme/theme.dart';

void main() {
  group('SparkButton', () {
    testWidgets('renders label and fires onPressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: SparkTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SparkButton(
                label: 'Start',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Start'), findsOneWidget);
      await tester.tap(find.text('Start'));
      expect(tapped, isTrue);
    });

    testWidgets('disabled button does not fire', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: SparkTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: SparkButton(label: 'Nope', onPressed: null),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Nope'), warnIfMissed: false);
      expect(tapped, isFalse);
    });
  });

  group('SparkProgressBar', () {
    testWidgets('clamps progress and exposes semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SparkTheme.lightTheme,
          home: const Scaffold(
            body: SparkProgressBar(progress: 1.5),
          ),
        ),
      );
      final semantics = tester.getSemantics(find.byType(SparkProgressBar));
      expect(semantics.value, '100 percent');
    });
  });

  group('SparkGoalRing', () {
    testWidgets('shows center label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SparkTheme.lightTheme,
          home: const Scaffold(
            body: SparkGoalRing(progress: 0.5, centerLabel: '12'),
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
    });
  });

  group('SparkStreakBadge', () {
    testWidgets('shows day count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SparkTheme.lightTheme,
          home: const Scaffold(
            body: SparkStreakBadge(days: 7, activeToday: true),
          ),
        ),
      );
      expect(find.text('7'), findsOneWidget);
    });
  });

  group('SparkXpBadge', () {
    testWidgets('shows XP value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SparkTheme.lightTheme,
          home: const Scaffold(
            body: SparkXpBadge(xp: 240),
          ),
        ),
      );
      expect(find.text('240 XP'), findsOneWidget);
    });
  });

  group('SparkEmptyState', () {
    testWidgets('renders title, message, and action', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: SparkTheme.lightTheme,
          home: Scaffold(
            body: SparkEmptyState(
              icon: Icons.school_outlined,
              title: 'Nothing here',
              message: 'Try something else.',
              actionLabel: 'Go',
              onAction: () => pressed = true,
            ),
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
      await tester.tap(find.text('Go'));
      expect(pressed, isTrue);
    });
  });

  group('SparkSkeleton', () {
    testWidgets('animates without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SparkTheme.lightTheme,
          home: const Scaffold(
            body: SparkSkeleton(width: 200, height: 20),
          ),
        ),
      );
      // Advance the repeating animation controller.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SparkSkeleton), findsOneWidget);
    });
  });

  group('tokens sanity', () {
    test('touch target meets accessibility minimum', () {
      expect(SparkSize.touchTarget, greaterThanOrEqualTo(48));
    });
  });
}
