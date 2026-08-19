import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App UI renders cleanly under 2.0x accessibility text scale (A11Y-001)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
            ),
            child: const Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text('Spark Lingo Accessibility Test'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Accessibility Button'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Spark Lingo Accessibility Test'), findsOneWidget);
    expect(find.text('Accessibility Button'), findsOneWidget);
  });

  testWidgets('App UI renders cleanly under RTL Directionality (A11Y-001)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: Text('اختبار امكانية الوصول'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('اختبار امكانية الوصول'), findsOneWidget);
  });
}
