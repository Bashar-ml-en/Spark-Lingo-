import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                "Ignite your fluency with AI-driven real-time conversational mentors and professional human accents.",
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
                  _LanguageBadge(label: "Bahasa Melayu"),
                  _LanguageBadge(label: "French"),
                  _LanguageBadge(label: "Arabic"),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  context.go(SparkRouter.home);
                },
                child: const Text("Get Started"),
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
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(51),
        ),
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
