import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/auth_config.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/design/neumorph.dart';
import '../../core/router/router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/language_theme_registry.dart';

/// Light-neumorphic onboarding landing screen.
///
/// Design language: soft off-white canvas, surfaces extruded with paired
/// light/dark shadows (SparkNeumorph), staggered entrance motion, and one
/// clear primary action. Replaces the earlier dark glass design per the
/// 2026-08 design review.
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
      backgroundColor: SparkNeumorph.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top header: extruded settings pill.
              _entranceItem(
                delay: 0.0,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      color: SparkNeumorph.surface,
                      borderRadius:
                          BorderRadius.circular(SparkNeumorph.pill),
                      boxShadow: SparkNeumorph.raised(
                        distance: 4,
                        blur: 10,
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
                          color: SparkNeumorph.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Hero: SL monogram in an extruded circle.
              _entranceItem(
                delay: 0.08,
                child: Center(
                  child: Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SparkNeumorph.surface,
                      boxShadow: SparkNeumorph.raised(
                        distance: 8,
                        blur: 18,
                      ),
                    ),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Image.asset(
                        'assets/symbols/sl_logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Wordmark.
              _entranceItem(
                delay: 0.18,
                child: const Text(
                  'Spark Lingo',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: SparkNeumorph.ink,
                    letterSpacing: -0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              _entranceItem(
                delay: 0.26,
                child: const Text(
                  'Learn 15 languages with an AI tutor that talks,\nlistens, and adapts to you.',
                  style: TextStyle(
                    fontSize: 15,
                    color: SparkNeumorph.inkSoft,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Value proposition — three verified facts, one extruded card.
              _entranceItem(
                delay: 0.34,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: SparkNeumorph.surface,
                    borderRadius:
                        BorderRadius.circular(SparkNeumorph.card),
                    boxShadow: SparkNeumorph.raised(),
                  ),
                  child: const Column(
                    children: [
                      _ValueRow(
                        icon: Icons.chat_bubble_outline,
                        title: 'Sparky, your AI tutor',
                        detail:
                            'Conversation practice with streaming replies and corrections',
                      ),
                      SizedBox(height: 14),
                      _ValueRow(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Smart spaced repetition',
                        detail:
                            'Cards resurface right before you forget them',
                      ),
                      SizedBox(height: 14),
                      _ValueRow(
                        icon: Icons.style_outlined,
                        title: '21,600 real cards',
                        detail:
                            '120 lessons in every language — Malay-first',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Primary CTA — moved up: this is the screen's one job.
              if (AuthConfig.googleOAuthEnabled)
                _entranceItem(
                  delay: 0.44,
                  child: _PrimaryActionButton(
                    isLoading: _isLoading,
                    onPressed: _handleGoogleSignIn,
                  ),
                ),
              if (AuthConfig.googleOAuthEnabled)
                const SizedBox(height: 14),
              if (AuthConfig.appleOAuthEnabled &&
                  !kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.iOS) ...[
                _entranceItem(
                  delay: 0.5,
                  child: SparkNeumorphButton(
                    onPressed: _isLoading ? null : _handleAppleSignIn,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apple, color: SparkNeumorph.ink),
                        SizedBox(width: 8),
                        Text(
                          'Continue with Apple',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: SparkNeumorph.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _entranceItem(
                delay: 0.56,
                child: SparkNeumorphButton(
                  onPressed: _isLoading ? null : _handleGetStarted,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        )
                      : const Text(
                          'Explore as Guest',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              // Language catalog — proof section below the CTA.
              _entranceItem(
                delay: 0.64,
                child: Column(
                  children: [
                    const Text(
                      'CHOOSE FROM 15 LANGUAGES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF38BDF8),
                        letterSpacing: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
              const SizedBox(height: 20),
              // Micro trust footer.
              _entranceItem(
                delay: 0.72,
                child: const Text(
                  'Free to start · Progress syncs to your account',
                  style: TextStyle(
                    fontSize: 12,
                    color: SparkNeumorph.inkSoft,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Google sign-in primary action with branded G glyph — extruded on the
/// neumorphic canvas.
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
        boxShadow: SparkNeumorph.raised(distance: 5, blur: 12),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: SparkNeumorph.ink,
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

/// One row of the welcome value-proposition card: icon + title + detail.
class _ValueRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _ValueRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withAlpha(30),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF38BDF8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SparkNeumorph.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 12,
                  color: SparkNeumorph.inkSoft,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
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
        color: SparkNeumorph.surface,
        borderRadius: BorderRadius.circular(19),
        boxShadow: SparkNeumorph.raised(distance: 3, blur: 7),
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
              color: SparkNeumorph.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
