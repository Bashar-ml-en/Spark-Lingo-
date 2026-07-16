import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/home/home_screen.dart';
import '../services/auth_service.dart';

class SparkRouter {
  // Named Route Paths
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String home = '/home';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

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
        path: SparkRouter.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final currentLoc = state.uri.path;
      final isLoggedIn = authState != null;

      // Allow splash screen to complete its lifecycle
      if (currentLoc == SparkRouter.splash) {
        return null;
      }

      if (!isLoggedIn) {
        // Guard protected screen access
        if (currentLoc == SparkRouter.home) {
          return SparkRouter.welcome;
        }
      } else {
        // Send authenticated users away from welcome onboarding
        if (currentLoc == SparkRouter.welcome || currentLoc == SparkRouter.splash) {
          return SparkRouter.home;
        }
      }

      return null;
    },
  );
});

