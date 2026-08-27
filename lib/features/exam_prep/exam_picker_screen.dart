import 'package:flutter/material.dart';

/// Exam preparation entry point.
///
/// Honesty contract: no placement levels, scoring, or readiness numbers are
/// shown until they are built from officially-documented exam formats. This
/// screen states exactly what exists, what is next, and which official
/// bodies define each exam — no fabricated rubrics.
class ExamPickerScreen extends StatelessWidget {
  final String userId;
  final String languageCode;

  const ExamPickerScreen({
    super.key,
    required this.userId,
    required this.languageCode,
  });

  static const _roadmap = <_RoadmapItem>[
    _RoadmapItem(
      icon: Icons.table_rows_outlined,
      title: 'Exam data model',
      detail: 'Definition, level-mapping, and mock-exam tables are live.',
      done: true,
    ),
    _RoadmapItem(
      icon: Icons.fact_check_outlined,
      title: 'Official format research',
      detail:
          'Each exam’s sections, timing, and scoring sourced from its official body before any mock is built.',
      done: false,
    ),
    _RoadmapItem(
      icon: Icons.timer_outlined,
      title: 'Timed mock exams',
      detail: 'Section-by-section practice under real exam conditions.',
      done: false,
    ),
    _RoadmapItem(
      icon: Icons.analytics_outlined,
      title: 'Readiness scoring',
      detail: 'Level estimates with disclosed methodology and sources.',
      done: false,
    ),
  ];

  static const _officialBodies = <_ExamBody>[
    _ExamBody('Chinese', 'HSK', 'Chinese Testing International (CTI)'),
    _ExamBody('Japanese', 'JLPT', 'The Japan Foundation & JEES'),
    _ExamBody('Korean', 'TOPIK', 'National Institute for International Education (NIIED)'),
    _ExamBody('French', 'DELF / DALF', 'France Éducation international'),
    _ExamBody('English (Malaysia)', 'MUET', 'Majlis Peperiksaan Malaysia (MPM)'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Exam preparation')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  Icons.construction_outlined,
                  size: 64,
                  color: cs.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Building the exam module',
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
                const SizedBox(height: 20),
                // Official bodies — verified names, no invented details.
                Text(
                  'OFFICIAL EXAM BODIES WE SOURCE FROM',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ..._officialBodies.map(
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
                                  text: '${body.language}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: '${body.exam} — ${body.body}',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
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
  final IconData icon;
  final String title;
  final String detail;
  final bool done;

  const _RoadmapItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.done,
  });
}

class _ExamBody {
  final String language;
  final String exam;
  final String body;

  const _ExamBody(this.language, this.exam, this.body);
}
