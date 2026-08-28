import 'package:flutter/material.dart';

import '../../core/constants/language_catalog.dart';
import 'exam_format_registry.dart';

/// Exam preparation entry point — language-aware and fact-based.
///
/// Every format detail shown here comes from [officialExamFormats], which is
/// sourced from official exam bodies (Workstream C, Phase 0 research pass).
/// Languages without a verified official exam get an honest notice instead
/// of invented content. No readiness percentages or score predictions are
/// shown until official scoring rubrics are implemented.
class ExamPrepScreen extends StatelessWidget {
  final String languageCode;

  const ExamPrepScreen({super.key, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageName = LanguageCatalog.displayName(languageCode);
    final format = officialExamFormats[languageCode];

    return Scaffold(
      appBar: AppBar(
        title: Text('Exam preparation — $languageName'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (format != null) ...[
            _OfficialExamCard(format: format, theme: theme),
            const SizedBox(height: 16),
            _BuildStatusCard(theme: theme),
          ] else ...[
            _NoVerifiedExamCard(languageName: languageName, theme: theme),
            const SizedBox(height: 16),
            _BuildStatusCard(theme: theme),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to learning'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A verified official exam: name, organizer, levels, sections with real
/// timings, scoring scale, and passing rule — all from the registry.
class _OfficialExamCard extends StatelessWidget {
  final OfficialExamFormat format;
  final ThemeData theme;

  const _OfficialExamCard({required this.format, required this.theme});

  @override
  Widget build(BuildContext context) {
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );
    final sectionTitle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final body = theme.textTheme.bodyMedium;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(format.examName, style: titleStyle),
            const SizedBox(height: 4),
            Text('Organizer: ${format.organizer}', style: small),
            Text('Verified source: ${format.source}', style: small),
            const SizedBox(height: 16),
            Text('Official levels', style: sectionTitle),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in format.levels)
                  Chip(
                    label: Text(level),
                    backgroundColor:
                        theme.colorScheme.primary.withAlpha(22),
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Exam sections', style: sectionTitle),
            const SizedBox(height: 8),
            for (final section in format.sections)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.code != null
                                ? '${section.name} (paper ${section.code})'
                                : section.name,
                            style: body?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (section.minutes != null)
                            Text('Time: ${section.minutes}', style: small),
                          if (section.note != null)
                            Text(section.note!, style: small),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (format.scoringScale != null) ...[
              const SizedBox(height: 12),
              Text('Scoring', style: sectionTitle),
              const SizedBox(height: 6),
              Text(format.scoringScale!, style: body),
            ],
            if (format.passingRule != null) ...[
              const SizedBox(height: 12),
              Text('Passing requirement', style: sectionTitle),
              const SizedBox(height: 6),
              Text(format.passingRule!, style: body),
            ],
            if (format.formatNotes != null) ...[
              const SizedBox(height: 12),
              Text('Notes', style: sectionTitle),
              const SizedBox(height: 6),
              Text(format.formatNotes!, style: body),
            ],
          ],
        ),
      ),
    );
  }
}

/// Honest notice for languages whose official exam was not verified yet.
class _NoVerifiedExamCard extends StatelessWidget {
  final String languageName;
  final ThemeData theme;

  const _NoVerifiedExamCard({
    required this.languageName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No official exam mapping yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We have not yet verified the official proficiency exam '
              'format for $languageName from its official body. We refuse '
              'to invent exam details, so this page shows real data only. '
              'It will appear here as soon as the official format is '
              'researched and confirmed.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Transparent build status: what exists today vs. what ships next.
class _BuildStatusCard extends StatelessWidget {
  final ThemeData theme;

  const _BuildStatusCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final body = theme.textTheme.bodyMedium;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Building the exam module', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              'We refuse to show fabricated scores. Mock exams ship only '
              'after every format detail is sourced from the official body '
              'for that exam.',
              style: body,
            ),
            const SizedBox(height: 12),
            _statusRow('✅', 'Exam data model — definition, level-mapping, '
                'and mock-exam tables are live.'),
            _statusRow('✅', 'Official format research — verified sections, '
                'timings, and scoring scales above, sourced from official '
                'bodies.'),
            _statusRow('⚪', 'Timed mock exams — section-by-section practice '
                'under real exam conditions.'),
            _statusRow('⚪', 'Readiness scoring — level estimates with '
                'disclosed methodology and sources.'),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String marker, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$marker  ', style: theme.textTheme.bodyMedium),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
