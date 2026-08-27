import 'package:flutter/material.dart';

import '../../core/constants/language_catalog.dart';

/// Exam preparation entry point — language-aware.
///
/// Honesty contract: only exam bodies verified for the ACTIVE language are
/// listed; languages without a verified official exam mapping say so
/// explicitly instead of showing unrelated content. No fabricated scores.
class ExamPickerScreen extends StatelessWidget {
  final String userId;
  final String languageCode;

  const ExamPickerScreen({
    super.key,
    required this.userId,
    required this.languageCode,
  });

  /// Official exam bodies verified per language (sourced 2026-08-27 from the
  /// organizers' own sites). Languages absent here have no verified mapping
  /// yet — the UI must say that, never guess.
  static const Map<String, List<_ExamBody>> _examBodiesByLanguage = {
    'zh': [
      _ExamBody('HSK', 'Chinese Testing International (CTI)'),
    ],
    'ja': [
      _ExamBody('JLPT', 'The Japan Foundation & JEES'),
    ],
    'ko': [
      _ExamBody('TOPIK', 'National Institute for International Education (NIIED)'),
    ],
    'fr': [
      _ExamBody('DELF / DALF', 'France Éducation international'),
    ],
    'ms': [
      _ExamBody('MUET', 'Majlis Peperiksaan Malaysia (MPM)'),
    ],
    'en': [
      _ExamBody('MUET (Malaysia)', 'Majlis Peperiksaan Malaysia (MPM)'),
    ],
  };

  static const _roadmap = <_RoadmapItem>[
    _RoadmapItem(
      title: 'Exam data model',
      detail: 'Definition, level-mapping, and mock-exam tables are live.',
      done: true,
    ),
    _RoadmapItem(
      title: 'Official format research',
      detail:
          'Sections, timing, and scoring sourced from the official body before any mock is built.',
      done: false,
    ),
    _RoadmapItem(
      title: 'Timed mock exams',
      detail: 'Section-by-section practice under real exam conditions.',
      done: false,
    ),
    _RoadmapItem(
      title: 'Readiness scoring',
      detail: 'Level estimates with disclosed methodology and sources.',
      done: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final canonical = LanguageCatalog.canonicalCode(languageCode);
    final languageName = LanguageCatalog.displayName(canonical);
    final bodies = _examBodiesByLanguage[canonical];

    return Scaffold(
      appBar: AppBar(title: Text('Exam preparation — $languageName')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.construction_outlined, size: 64, color: cs.primary),
                const SizedBox(height: 16),
                Text(
                  'Building the $languageName exam module',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We refuse to show fabricated scores. Mock exams ship only after every format detail is sourced from the official body for that exam.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                // Language-specific exam bodies.
                Text(
                  bodies != null
                      ? 'OFFICIAL EXAM BODIES FOR $languageName'.toUpperCase()
                      : 'OFFICIAL EXAM MAPPING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if (bodies != null)
                  ...bodies.map(
                    (body) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 18,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: '${body.exam} — ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: body.body,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No official exam mapping has been verified for $languageName yet. We will only list an exam once its format is confirmed with the official organizer — invented exam content is never shipped.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                // Roadmap.
                Text(
                  'WHAT’S BUILT, WHAT’S NEXT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ..._roadmap.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          item.done
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: item.done
                              ? const Color(0xFF22C55E)
                              : cs.outline,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.detail,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to learning'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoadmapItem {
  final String title;
  final String detail;
  final bool done;

  const _RoadmapItem({
    required this.title,
    required this.detail,
    required this.done,
  });
}

class _ExamBody {
  final String exam;
  final String body;

  const _ExamBody(this.exam, this.body);
}
