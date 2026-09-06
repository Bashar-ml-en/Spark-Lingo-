import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/auth_config.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/design/motion_tokens.dart';
import '../../core/design/neumorph.dart';
import '../../core/router/router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/language_theme_registry.dart';

/// World-class dark onboarding welcome screen aligned with Stitch specifications.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    // SparkMotion.standard (500ms, easeOutCubic = power2.out per the
    // ui-ux-pro-max motion database). Reduced motion is handled in
    // didChangeDependencies where MediaQuery is available.
    _entrance = AnimationController(
      vsync: this,
      duration: SparkMotion.standard,
    )..forward();
    _fade = CurvedAnimation(parent: _entrance, curve: SparkMotion.arrive);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_fade);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rule #9/#99: if the OS asks for reduced motion, snap to the final
    // readable state instead of animating.
    if (SparkMotion.reduced(context) && !_entrance.isCompleted) {
      _entrance.value = 1.0;
    }
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
    } catch (_) {}
    return LanguageCatalog.displayName(code);
  }

  Color _nativeAccent(String code) {
    try {
      return LanguageThemeRegistry.themeFor(code).accentColor;
    } catch (_) {
      return SparkLingoTheme.electricCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SparkLingoTheme.surfaceCanvas,
      body: Stack(
        children: [
          // Ambient signature cyan glow behind hero
          Positioned(
            top: -160,
            left: -100,
            right: -100,
            child: IgnorePointer(
              child: Container(
                height: 500,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      SparkLingoTheme.electricCyan.withValues(alpha: 0.18),
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
                  // Top header: glass settings pill
                  _entranceItem(
                    delay: 0.0,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Container(
                        decoration: BoxDecoration(
                          color: SparkLingoTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: SparkLingoTheme.surfaceContainerHighest,
                          ),
                        ),
                        child: TextButton.icon(
                          onPressed: () => context.push(SparkRouter.settings),
                          icon: const Icon(
                            Icons.settings_outlined,
                            size: 18,
                            color: SparkLingoTheme.electricCyan,
                          ),
                          label: const Text(
                            'Settings & help',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Hero Monogram Emblem
                  _entranceItem(
                    delay: 0.08,
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: SparkLingoTheme.electricCyan.withValues(alpha: 0.35),
                              blurRadius: 40,
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
                  const SizedBox(height: 24),
                  // Wordmark
                  _entranceItem(
                    delay: 0.18,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, SparkLingoTheme.electricCyan],
                      ).createShader(bounds),
                      child: const Text(
                        'Spark Lingo',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _entranceItem(
                    delay: 0.26,
                    child: Text(
                      'Master 15 languages with AI-guided conversation\nand real native sentence mastery',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Proof point stat chips
                  _entranceItem(
                    delay: 0.34,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _StatChip(value: '15', label: 'languages'),
                        SizedBox(width: 8),
                        _StatChip(value: '21,600', label: 'curated cards'),
                        SizedBox(width: 8),
                        _StatChip(value: 'AI', label: 'voice studio'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Language preview strip
                  _entranceItem(
                    delay: 0.42,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: SparkLingoTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: SparkLingoTheme.surfaceContainerHighest,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '15 LANGUAGES · MALAY-FIRST ARCHITECTURE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: SparkLingoTheme.solarGold,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              itemCount: LanguageCatalog.supportedLanguages.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final code = LanguageCatalog.supportedLanguages[i];
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
                  const SizedBox(height: 32),
                  // Primary CTA Buttons
                  _entranceItem(
                    delay: 0.50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SparkLingoTheme.electricCyan,
                        foregroundColor: SparkLingoTheme.surfaceCanvas,
                        minimumSize: const Size.fromHeight(54),
                        elevation: 4,
                        shadowColor: SparkLingoTheme.electricCyan.withValues(alpha: 0.4),
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
                                color: SparkLingoTheme.surfaceCanvas,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started (Free)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (AuthConfig.googleOAuthEnabled) ...[
                    _entranceItem(
                      delay: 0.58,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: SparkLingoTheme.surfaceContainer,
                          side: BorderSide(
                            color: SparkLingoTheme.surfaceContainerHighest,
                          ),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.g_mobiledata_rounded,
                                color: Color(0xFF4285F4), size: 28),
                            SizedBox(width: 6),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (AuthConfig.appleOAuthEnabled &&
                      !kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.iOS) ...[
                    _entranceItem(
                      delay: 0.66,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleAppleSignIn,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: SparkLingoTheme.surfaceContainer,
                          side: BorderSide(
                            color: SparkLingoTheme.surfaceContainerHighest,
                          ),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.apple, color: Colors.white),
                        label: const Text(
                          'Continue with Apple',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the welcome value-proposition card: icon + title + detail.
class _StatChip extends StatelessWidget {
  final String value;
  final String label;

  const _StatChip({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: SparkLingoTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
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
        color: SparkLingoTheme.surfaceCanvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SparkLingoTheme.surfaceContainerHighest,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: SparkNeumorph.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
