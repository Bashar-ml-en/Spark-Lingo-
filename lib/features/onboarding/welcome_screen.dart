import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/auth_config.dart';
import '../../core/router/router.dart';
import '../../core/services/auth_service.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _handleGetStarted() async {
    setState(() {
      _isLoading = true;
    });
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            content: Text(
              'Apple sign-in is not available for this build. Please try another sign-in method.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => context.push(SparkRouter.settings),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Settings & help'),
                ),
              ),
              const Spacer(),
              // Icon representation
              Center(
                child: Icon(
                  Icons.translate,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Welcome to Spark Lingo",
                style: theme.textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Build a foundation with guided conversation practice and reviewed beginner lessons.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Language badges list layout
              Text(
                "Supported Languages:",
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _LanguageBadge(label: "English"),
                  _LanguageBadge(label: "Mandarin"),
                  _LanguageBadge(label: "Spanish"),
                  _LanguageBadge(label: "Hindi"),
                  _LanguageBadge(label: "Russian"),
                  _LanguageBadge(label: "French"),
                  _LanguageBadge(label: "Arabic"),
                ],
              ),
              const Spacer(),
              if (AuthConfig.googleOAuthEnabled) ...[
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.login_outlined,
                    color: Colors.blueAccent,
                    size: 18,
                  ),
                  label: const Text("Continue with Google"),
                ),
                const SizedBox(height: 12),
              ],
              if (AuthConfig.appleOAuthEnabled &&
                  !kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.iOS) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleAppleSignIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFF1F2937)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                ),
              ],
              const SizedBox(height: 12),
              // Secondary Anonymous Button
              OutlinedButton(
                onPressed: _isLoading ? null : _handleGetStarted,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.primary.withAlpha(100),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Explore as Guest"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final String label;
  const _LanguageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(51)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
