import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// An honest, non-scored preview of the future exam-preparation experience.
///
/// Do not add estimates, progress, band scores, readiness claims, timers, or
/// assessment entry points here until the product has a persisted attempt,
/// reviewed scoring contract, and provenance that can be shown to the learner.
class ExamReadinessDashboard extends StatelessWidget {
  const ExamReadinessDashboard({
    super.key,
    required this.userId,
    required this.examId,
    required this.languageCode,
  });

  final String userId;
  final String examId;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.examPracticePreview)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Semantics(
                container: true,
                label: l10n.examPreviewSemantics,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.fact_check_outlined,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.scoredExamPracticeInDevelopment,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.examPreviewAvailability),
                        const SizedBox(height: 12),
                        Text(l10n.examPreviewNextStep),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.returnToLearning),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
