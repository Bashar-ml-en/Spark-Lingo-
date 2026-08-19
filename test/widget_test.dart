import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spark_lingo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    // Mock SharedPreferences platform channel
    SharedPreferences.setMockInitialValues({});

    // Initialize Supabase with dummy credentials for headless testing
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      publishableKey: 'placeholder-anon-key',
    );
  });

  testWidgets('App boots up test', (WidgetTester tester) async {
    // Build our app under a ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SparkLingoApp()));

    // Verify that the app starts on the splash loading screen with branding
    expect(find.text('SPARK LINGO'), findsOneWidget);
    expect(find.text('Ignite Your Fluency.'), findsOneWidget);

    // Drain the 2-second splash screen transition timer to avoid "timer pending" failures
    await tester.pump(const Duration(seconds: 3));
  });
}
