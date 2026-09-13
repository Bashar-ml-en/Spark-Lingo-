import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/ai_service.dart';
import '../../core/services/correction_review_service.dart';
import '../../l10n/app_localizations.dart';

const Map<String, String> _errorClassLabels = {
  'grammar_accuracy': 'Grammar accuracy',
  'vocabulary_range': 'Vocabulary range',
  'fluency_coherence': 'Fluency & coherence',
  'pronunciation': 'Pronunciation',
  'task_response': 'Task response',
  'register_appropriateness': 'Register & tone',
  'spelling_orthography': 'Spelling',
};

String _labelFor(String errorClass) {
  return _errorClassLabels[errorClass] ?? 'Practice feedback';
}

/// Displays only server-provided, allow-listed correction data for the active
/// learner. A request failure stays visibly distinct from an empty report.
class SessionReportScreen extends ConsumerStatefulWidget {
  const SessionReportScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  ConsumerState<SessionReportScreen> createState() =>
      _SessionReportScreenState();
}

class _SessionReportScreenState extends ConsumerState<SessionReportScreen> {
  late Future<SessionReport> _reportFuture;
  final Set<String> _savedForms = <String>{};

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReport();
  }

  Future<SessionReport> _loadReport() {
    return AIService().fetchSessionReport(widget.languageCode);
  }

  void _retry() {
    setState(() {
      _reportFuture = _loadReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.sessionReportTitle)),
      body: FutureBuilder<SessionReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      localizations.sessionReportUnavailable,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retry,
                      child: Text(localizations.retry),
                    ),
                  ],
                ),
              ),
            );
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
                      Icons.insights_outlined,
                      size: 48,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.sessionReportNoDataTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.sessionReportNoDataBody,
                      textAlign: TextAlign.center,
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
                Text(
                  localizations.sessionReportFocusAreas,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: report.focusAreas
                      .map(
                        (area) => Chip(
                          label: Text(
                            '${_labelFor(area.errorClass)} · ${area.occurrences}',
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                localizations.sessionReportCorrections,
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
    final localizations = AppLocalizations.of(context)!;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showMessage(localizations.signInToSaveCorrections);
      return;
    }
    final saved = await ref
        .read(correctionReviewServiceProvider)
        .saveCorrection(
          userId: user.id,
          languageCode: widget.languageCode,
          item: item,
        );
    if (!mounted) return;
    if (saved) {
      setState(() => _savedForms.add(item.correctedForm));
    }
    _showMessage(
      saved ? localizations.addedToReview : localizations.alreadyInReview,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class _CorrectionTile extends StatelessWidget {
  const _CorrectionTile({
    required this.item,
    required this.saved,
    required this.onSave,
  });

  final CorrectionItem item;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _labelFor(item.errorClass),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
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
                      semanticLabel: localizations.alreadyInReview,
                    )
                  : OutlinedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.add),
                      label: Text(localizations.addToReview),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
