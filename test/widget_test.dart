import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spark_lingo/main.dart';

void main() {
  testWidgets('App boots up test', (WidgetTester tester) async {
    // Build our app under a ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SparkLingoApp(),
      ),
    );

    // Verify that the app starts on the splash loading screen with branding
    expect(find.text('SPARK LINGO'), findsOneWidget);
    expect(find.text('Ignite Your Fluency.'), findsOneWidget);
  });
}
