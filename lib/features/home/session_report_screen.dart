import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai_service.dart';
import '../../core/services/correction_review_service.dart';

/// Human labels for the server's allow-listed error classes. The server
/// only ever sends these seven tokens (error_patterns.ts ERROR_CLASSES),
/// so the map is exhaustive; unknown tokens fall back to a title-cased
/// display of the raw token rather than crashing.
const Map<String, String> _errorClassLabels = {
  'grammar_accuracy': 'Grammar accuracy',
  'vocabulary_range': 'Vocabulary range',
  'fluency_coherence': 'Fluency & coherence',
  'pronunciation': 'Pronunciation',
  'task_response': 'Task response',
  'register_appropriateness': 'Register & tone',
  'spelling_orthography': 'Spelling',
};

String _labelFor(String errorClass) =>
    _errorClassLabels[errorClass] ??
    errorClass
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

/// Post-session error report (Langua-style): what Sparky corrected, which
/// error classes recur, and one-tap "Add to review" into the local SM-2
/// correction deck.
class SessionReportScreen extends ConsumerStatefulWidget {
  final String languageCode;

  const SessionReportScreen({super.key, required this.languageCode});

  @override
  ConsumerState<SessionReportScreen> createState() =>
      _SessionReportScreenState();
}

class _SessionReportScreenState extends ConsumerState<SessionReportScreen> {
  late final Future<SessionReport> _reportFuture;
  final Set<String> _savedForms = {};

  @override
  void initState() {
    super.initState();
    _reportFuture = AIService().fetchSessionReport(widget.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Session report')),
      body: FutureBuilder<SessionReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = snapshot.data ?? const SessionReport();
          if (report.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 48,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No corrections yet',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Finish a graded practice or chat with Sparky — '
                      'your corrections will collect here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (report.focusAreas.isNotEmpty) ...[
                Text('Focus areas', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final area in report.focusAreas)
                      Chip(
                        label: Text(
                          '${_labelFor(area.errorClass)} · ${area.occurrences}',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Sparky’s recent corrections',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final item in report.corrections)
                _CorrectionTile(
                  item: item,
                  saved: _savedForms.contains(item.correctedForm),
                  onSave: () => _save(item),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(CorrectionItem item) async {
    final service = ref.read(correctionReviewServiceProvider);
    final saved = await service.saveCorrection(
      languageCode: widget.languageCode,
      item: item,
    );
    if (!mounted) return;
    setState(() {
      if (saved) _savedForms.add(item.correctedForm);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Added to your correction review deck'
              : 'Already in your review deck',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _CorrectionTile extends StatelessWidget {
  final CorrectionItem item;
  final bool saved;
  final VoidCallback onSave;

  const _CorrectionTile({
    required this.item,
    required this.saved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _labelFor(item.errorClass),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                if (item.occurrences > 1)
                  Text(
                    '×${item.occurrences}',
                    style: theme.textTheme.labelMedium,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.correctedForm, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: saved
                  ? Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    )
                  : TextButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.playlist_add, size: 18),
                      label: const Text('Add to review'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
