import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/onboarding/language_selection_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/monetization/paywall_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../constants/language_catalog.dart';

class SparkRouter {
  // Named Route Paths
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String selectLanguage = '/onboarding/select-language';
  static const String home = '/home/:langCode';
  static const String paywall = '/paywall';
  static const String settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  if (authState != null) {
    // Watch profile to reactively trigger redirect rerun when it resolves or changes
    ref.watch(userProfileProvider(authState.id));
  }

  return GoRouter(
    initialLocation: SparkRouter.splash,
    routes: [
      GoRoute(
        path: SparkRouter.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: SparkRouter.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: SparkRouter.selectLanguage,
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: SparkRouter.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: SparkRouter.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: SparkRouter.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      final currentLoc = state.uri.path;
      final isLoggedIn = authState != null;

      // Allow splash screen to complete its lifecycle
      if (currentLoc == SparkRouter.splash) {
        return null;
      }

      // Legal, support, and data-rights links must remain reachable before
      // onboarding and after a user signs out or uninstalls the app.
      if (currentLoc == SparkRouter.settings) {
        return null;
      }

      if (!isLoggedIn) {
        // Guard protected screen access
        if (currentLoc.startsWith('/home') ||
            currentLoc == SparkRouter.selectLanguage) {
          return SparkRouter.welcome;
        }
      } else {
        // Authenticated users
        final profileState = ref.read(userProfileProvider(authState.id));
        final profile = profileState.maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
        final activeLanguage =
            profile?.activeLanguage ??
            (profile?.targetLanguages.isNotEmpty == true
                ? profile!.targetLanguages.first
                : null);
        final requestedLanguage = LanguageCatalog.tryCanonicalCode(
          state.pathParameters['langCode'],
        );

        if (currentLoc.startsWith('/home/') && requestedLanguage != null) {
          // Canonicalise legacy locale/name paths, and do not allow a URL to
          // show a course the signed-in profile has not selected.
          final canonicalPath = '/home/$requestedLanguage';
          if (currentLoc != canonicalPath) return canonicalPath;
          if (profile != null &&
              !profile.targetLanguages.contains(requestedLanguage)) {
            return activeLanguage == null
                ? SparkRouter.selectLanguage
                : '/home/$activeLanguage';
          }
        }

        if (activeLanguage == null) {
          // No active language set, force onboarding select language screen
          if (currentLoc != SparkRouter.selectLanguage) {
            return SparkRouter.selectLanguage;
          }
        } else {
          // User has active language. Redirect away from onboarding/welcome/splash or home base paths
          if (currentLoc == SparkRouter.welcome ||
              currentLoc == SparkRouter.splash ||
              currentLoc == SparkRouter.selectLanguage ||
              currentLoc == '/home') {
            return '/home/$activeLanguage';
          }
        }
      }

      return null;
    },
  );
});
