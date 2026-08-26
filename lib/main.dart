import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/theme/language_theme_registry.dart';
import 'shared/models/language_theme.dart';
import 'core/services/database_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/telemetry_consent_service.dart';
import 'core/router/router.dart';
import 'core/constants/supabase_config.dart';

void main() async {
  // 1. Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load language design tokens
  try {
    final tokensJson = await rootBundle.loadString(
      'assets/language_design_tokens.json',
    );
    LanguageThemeRegistry.initialize(tokensJson);
  } catch (e) {
    debugPrint("Failed to initialize language design tokens: $e");
  }

  // 2. Initialize Supabase Client (Core Auth & Database)
  var supabaseInitialized = false;
  final configurationAllowsInitialization =
      SupabaseConfig.isConfigured &&
      (SupabaseConfig.environment != SparkLingoEnvironment.production ||
          kReleaseMode);
  if (!configurationAllowsInitialization) {
    // The configuration object deliberately omits values from error messages.
    // A development/debug build must never become a backdoor to production.
    debugPrint('Supabase build configuration is unavailable.');
  } else {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      supabaseInitialized = true;
    } catch (_) {
      debugPrint('Supabase initialization failed.');
    }
  }

  // Auth, profile, and curriculum providers require a real Supabase client.
  // Do not hide a configuration failure and then crash while building them.
  if (!supabaseInitialized) {
    runApp(const SparkLingoUnavailableApp());
    return;
  }

  // 3. Initialize Firebase (Mobile Operations & Analytics)
  var firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // Firebase collection is disabled in native platform metadata before the
  // SDK starts. It remains disabled until a current authenticated user has a
  // server-backed analytics consent record.
  await TelemetryConsentService.initialize(
    firebaseInitialized: firebaseInitialized,
  );

  // 4. Launch App inside Riverpod's ProviderScope
  runApp(const ProviderScope(child: SparkLingoApp()));
}

class SparkLingoUnavailableApp extends StatelessWidget {
  const SparkLingoUnavailableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spark Lingo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.cloud_off_outlined, size: 48),
                SizedBox(height: 16),
                Text(
                  'Spark Lingo is temporarily unavailable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Please check your connection and try again later.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SparkLingoApp extends ConsumerWidget {
  const SparkLingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    ThemeData lightThemeData = SparkTheme.lightTheme;
    ThemeData darkThemeData = SparkTheme.darkTheme;
    LanguageTheme? activeTheme;

    final localLanguage = ref.watch(localActiveLanguageProvider);
    String? activeLanguage = localLanguage;

    if (activeLanguage == null && authState != null) {
      final profileAsync = ref.watch(userProfileProvider(authState.id));
      activeLanguage = profileAsync.maybeWhen(
        data: (profile) =>
            profile?.activeLanguage ??
            (profile?.targetLanguages.isNotEmpty == true
                ? profile!.targetLanguages.first
                : null),
        orElse: () => null,
      );
    }

    if (activeLanguage != null) {
      try {
        activeTheme = LanguageThemeRegistry.themeFor(activeLanguage);
        lightThemeData = LanguageThemeRegistry.buildTheme(activeTheme);
        darkThemeData = LanguageThemeRegistry.buildTheme(
          activeTheme,
          brightness: Brightness.dark,
        );
      } catch (e) {
        debugPrint("Error loading active language theme: $e");
      }
    }

    final textDirection =
        activeTheme != null &&
            activeTheme.textDirection == LanguageTextDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;

    return MaterialApp.router(
      title: 'Spark Lingo',
      debugShowCheckedModeBanner: false,

      // Inject dynamic theme data: light + dark variants with the user's
      // persisted brightness preference.
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: themeMode,

      // Inject GoRouter pathways reactively
      routerConfig: ref.watch(routerProvider),

      // Responsive App Wrapper matching exact user specifications
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          // Outer web background: light grey in light mode, obsidian in dark.
          backgroundColor:
              isDark ? SparkTheme.obsidianBlack : const Color(0xFFF3F4F6),
          body: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep the intended 390px mobile frame without overflowing
                // small phones or split-screen viewports.
                double containerWidth;
                if (constraints.maxWidth <= 600) {
                  containerWidth = constraints.maxWidth
                      .clamp(0.0, 390.0)
                      .toDouble();
                } else if (constraints.maxWidth <= 1000) {
                  containerWidth = constraints.maxWidth
                      .clamp(0.0, 810.0)
                      .toDouble();
                } else {
                  containerWidth = constraints.maxWidth
                      .clamp(0.0, 1200.0)
                      .toDouble();
                }

                return ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: Container(
                    width: containerWidth,
                    height: constraints.maxHeight, // Use full available height
                    decoration: BoxDecoration(
                      // Inner frame background: pure white in light mode
                      // (as originally requested), obsidian in dark mode.
                      color: isDark
                          ? SparkTheme.obsidianBlack
                          : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.zero, // Explicitly 0px radius
                    ),
                    child: Directionality(
                      textDirection: textDirection,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
