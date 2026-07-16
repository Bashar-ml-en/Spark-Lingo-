import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/theme.dart';
import 'core/router/router.dart';
import 'core/constants/supabase_config.dart';

void main() async {
  // 1. Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Supabase Client (Core Auth & Database)
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint("Supabase initialization error: $e");
  }

  // 3. Initialize Firebase (Mobile Operations & Analytics)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // 4. Launch App inside Riverpod's ProviderScope
  runApp(
    const ProviderScope(
      child: SparkLingoApp(),
    ),
  );
}

class SparkLingoApp extends ConsumerWidget {
  const SparkLingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Spark Lingo',
      debugShowCheckedModeBanner: false,
      
      // Inject our custom Obsidian/Cyan/Orange theme
      theme: SparkTheme.darkTheme,
      
      // Inject GoRouter pathways reactively
      routerConfig: ref.watch(routerProvider),
    );
  }
}
