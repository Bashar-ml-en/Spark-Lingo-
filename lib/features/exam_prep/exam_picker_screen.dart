import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

import '../../core/constants/language_catalog.dart';
import '../../core/design/getwidget_theme.dart';
import 'exam_format_registry.dart';

/// Exam preparation entry point — language-aware, fact-based, built on
/// GetWidget components (GFCard / GFAccordion / GFBadge) themed globally
/// via SparkGF for cross-screen consistency.
///
/// Honesty contract: every displayed fact was sourced from the official
/// exam body (see ExamFormatRegistry). Nothing here is a readiness score,
/// a predicted result, or an invented format detail.
class ExamPrepScreen extends StatelessWidget {
  final String languageKey;

  const ExamPrepScreen({super.key, required this.languageKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = officialExamFormats[languageKey];
    final languageName = LanguageCatalog.displayName(languageKey);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Exam preparation · $languageName')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (format == null)
            _UnmappedLanguageCard(languageName: languageName)
          else ...[
            _FormatHeaderCard(format: format),
            const SizedBox(height: 12),
            _ExamSectionAccordions(format: format),
            const SizedBox(height: 12),
            _HonestyNoticeCard(theme: theme),
          ],
        ],
      ),
    );
  }
}

class _UnmappedLanguageCard extends StatelessWidget {
  final String languageName;

  const _UnmappedLanguageCard({required this.languageName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SparkGF.card(
      margin: EdgeInsets.zero,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Building the exam module',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'No official exam mapping has been verified for $languageName '
            'yet. We refuse to show fabricated scores: mock exams ship only '
            'after every format detail is sourced from the official body '
            'for that exam.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FormatHeaderCard extends StatelessWidget {
  final OfficialExamFormat format;

  const _FormatHeaderCard({required this.format});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SparkGF.card(
      margin: EdgeInsets.zero,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  format.examName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SparkGF.badge('Verified format'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Official organizer: ${format.organizer}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            format.scoringScale ?? format.formatNotes ?? '',
            style: theme.textTheme.bodyMedium,
          ),
          if (format.passingRule != null) ...[
            const SizedBox(height: 4),
            Text(
              'Passing: ${format.passingRule}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final level in format.levels)
                SparkGF.badge(level),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamSectionAccordions extends StatelessWidget {
  final OfficialExamFormat format;

  const _ExamSectionAccordions({required this.format});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final section in format.sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GFAccordion(
              title: section.name,
              titleBorderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              contentBorderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              collapsedTitleBackgroundColor: theme.cardColor,
              expandedTitleBackgroundColor: theme.cardColor,
              contentBackgroundColor: theme.cardColor,
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ) ?? const TextStyle(),
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              contentChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.minutes != null)
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      text: 'Time allotted: ${section.minutes}',
                    ),
                  if (section.code != null)
                    _InfoRow(
                      icon: Icons.confirmation_num_outlined,
                      text: 'Official paper: ${section.code}',
                    ),
                  if (section.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      section.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _HonestyNoticeCard extends StatelessWidget {
  final ThemeData theme;

  const _HonestyNoticeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return SparkGF.card(
      margin: EdgeInsets.zero,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Practice sections under real exam conditions come next. '
              'Until a question bank is licensed or written from official '
              'specs, this page shows the verified format only — no '
              'fabricated scores.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
