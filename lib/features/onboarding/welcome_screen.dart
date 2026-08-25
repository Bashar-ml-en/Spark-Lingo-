import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/auth_config.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/router/router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/language_theme_registry.dart';

/// Premium dark onboarding landing screen.
///
/// Design language: deep obsidian canvas with a single cyan signature glow,
/// glass surfaces, staggered entrance motion, and one clear primary action.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _handleGetStarted() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInAnonymously();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not sign you in. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in failed. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithApple();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple sign-in is not available for this build.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Staggered entrance wrapper.
  Widget _entranceItem({required Widget child, required double delay}) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entrance,
        curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
      ),
      child: SlideTransition(position: _slide, child: child),
    );
  }

  String _nativeName(String code) {
    try {
      final theme = LanguageThemeRegistry.themeFor(code);
      if (theme.displayName.isNotEmpty) return theme.displayName;
    } catch (_) {
      // Registry unavailable (e.g. token asset failed to load) — fall back.
    }
    return LanguageCatalog.displayName(code);
  }

  Color _nativeAccent(String code) {
    try {
      return LanguageThemeRegistry.themeFor(code).accentColor;
    } catch (_) {
      return const Color(0xFF38BDF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF050B1F), // Near-black indigo
              Color(0xFF0B132B), // Obsidian navy
              Color(0xFF0F172A), // Dark slate canvas
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient signature glow behind the hero emblem.
            Positioned(
              top: -180,
              left: -120,
              right: -120,
              child: IgnorePointer(
                child: Container(
                  height: 520,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withAlpha(46),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top header: glass settings pill.
                    _entranceItem(
                      delay: 0.0,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(30),
                            ),
                          ),
                          child: TextButton.icon(
                            onPressed: () => context.push(SparkRouter.settings),
                            icon: const Icon(
                              Icons.settings_outlined,
                              size: 18,
                              color: Color(0xFF38BDF8),
                            ),
                            label: const Text(
                              'Settings & help',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 44),
                    // Hero: SL monogram emblem.
                    _entranceItem(
                      delay: 0.08,
                      child: Center(
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withAlpha(110),
                                blurRadius: 46,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/symbols/sl_logo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    // Wordmark.
                    _entranceItem(
                      delay: 0.18,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFF38BDF8)],
                        ).createShader(bounds),
                        child: const Text(
                          'Spark Lingo',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _entranceItem(
                      delay: 0.26,
                      child: const Text(
                        'Master 15 languages with AI-guided conversation\nand native audio practice',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF94A3B8),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Proof points.
                    _entranceItem(
                      delay: 0.34,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(value: '15', label: 'languages'),
                          SizedBox(width: 10),
                          _StatChip(value: '9,000+', label: 'real cards'),
                          SizedBox(width: 10),
                          _StatChip(value: 'AI', label: 'tutor inside'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Language strip.
                    _entranceItem(
                      delay: 0.42,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(9),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withAlpha(20)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '15 LANGUAGES · MALAY-FIRST',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF38BDF8),
                                letterSpacing: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 36,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                itemCount:
                                    LanguageCatalog.supportedLanguages.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, i) {
                                  final code =
                                      LanguageCatalog.supportedLanguages[i];
                                  return _LanguageChip(
                                    label: _nativeName(code),
                                    dot: _nativeAccent(code),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Primary CTA stack.
                    if (AuthConfig.googleOAuthEnabled)
                      _entranceItem(
                        delay: 0.52,
                        child: _PrimaryActionButton(
                          isLoading: _isLoading,
                          onPressed: _handleGoogleSignIn,
                        ),
                      ),
                    if (AuthConfig.googleOAuthEnabled)
                      const SizedBox(height: 12),
                    if (AuthConfig.appleOAuthEnabled &&
                        !kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.iOS) ...[
                      _entranceItem(
                        delay: 0.6,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleAppleSignIn,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.apple, color: Colors.white),
                          label: const Text(
                            'Continue with Apple',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _entranceItem(
                      delay: 0.68,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleGetStarted,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          side: const BorderSide(
                            color: Color(0xFF38BDF8),
                            width: 1.5,
                          ),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF38BDF8),
                                ),
                              )
                            : const Text(
                                'Explore as Guest',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google sign-in primary action with branded G glyph.
class _PrimaryActionButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryActionButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withAlpha(26),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.g_mobiledata_rounded, color: Color(0xFF4285F4), size: 28),
            SizedBox(width: 8),
            Text(
              'Continue with Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;

  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(200),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final Color dot;

  const _LanguageChip({required this.label, required this.dot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(180),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF38BDF8).withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFE2E8F0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
