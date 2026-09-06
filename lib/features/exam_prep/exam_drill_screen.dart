import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/getwidget.dart';

import '../../core/constants/language_catalog.dart';
import '../../core/design/getwidget_theme.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/theme.dart';
import '../practice/practice_engine.dart';
import 'exam_drill_engine.dart';
import 'exam_format_registry.dart';

/// Timed exam-section drill — Exam module Phase 1.
///
/// Honesty contract:
///  * Questions come ONLY from the real reviewed curriculum (21,600 cards).
///  * The timer pace is derived from the official section minutes where the
///    exam body publishes them; otherwise a labeled 45s training default.
///  * Results report what actually happened (answered/correct counts). No
///    predicted scores, no readiness percentages, no fabricated banks.
class ExamDrillScreen extends ConsumerStatefulWidget {
  final String languageKey;
  final ExamSection section;

  const ExamDrillScreen({
    super.key,
    required this.languageKey,
    required this.section,
  });

  @override
  ConsumerState<ExamDrillScreen> createState() => _ExamDrillScreenState();
}

class _ExamDrillScreenState extends ConsumerState<ExamDrillScreen> {
  static const int _questionCount = 10;

  List<TimedDrillQuestion> _questions = const [];
  int _index = 0;
  int _correct = 0;
  int _answered = 0;
  int? _selected;
  bool _revealed = false;
  bool _finished = false;
  String? _loadError;
  bool _loading = true;

  Timer? _timer;
  int _secondsLeft = 0;
  late final int _paceSeconds;

  @override
  void initState() {
    super.initState();
    _paceSeconds = ExamDrillEngine.trainingPaceSeconds(
      officialSectionMinutes: widget.section.minutesInt,
      questionCount: _questionCount,
    );
    _secondsLeft = _paceSeconds;
    _loadCards();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final db = ref.read(databaseServiceProvider);
      final units = await db.fetchUnits(widget.languageKey);
      final cards = <PracticeCard>[];
      for (final unit in units) {
        if (cards.length >= _questionCount * 4) break;
        final lessons = await db.fetchLessons(unit.id);
        for (final lesson in lessons) {
          if (cards.length >= _questionCount * 4) break;
          final flashcards = await db.fetchFlashcards(lesson.id);
          for (final f in flashcards) {
            cards.add(PracticeCard(
              id: f.id,
              front: f.front,
              back: f.back,
              context: f.context,
            ));
            if (cards.length >= _questionCount * 4) break;
          }
        }
      }
      if (!mounted) return;
      if (cards.isEmpty) {
        setState(() {
          _loading = false;
          _loadError =
              'No reviewed curriculum is available for this language yet, '
              'so the drill cannot start. We will not fabricate questions.';
        });
        return;
      }
      final drill = ExamDrillEngine().buildDrill(
        cards,
        questionCount: _questionCount,
      );
      setState(() {
        _questions = drill;
        _loading = false;
      });
      _startTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'The drill could not load content. Please try again.';
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          t.cancel();
          _onTimeout();
        }
      });
    });
  }

  void _onTimeout() {
    if (_revealed || _finished) return;
    setState(() {
      _revealed = true;
      _answered++;
    });
  }

  void _select(int idx) {
    if (_revealed || _finished) return;
    final q = _questions[_index];
    setState(() {
      _selected = idx;
      _revealed = true;
      _answered++;
      if (idx == q.correctIndex) _correct++;
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
      _secondsLeft = _paceSeconds;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageName = LanguageCatalog.displayName(widget.languageKey);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${widget.section.name} drill · $languageName'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _ErrorCard(message: _loadError!)
              : _finished
                  ? _ResultCard(
                      correct: _correct,
                      answered: _answered,
                      total: _questions.length,
                      sectionName: widget.section.name,
                      paceSeconds: _paceSeconds,
                      hadOfficialTiming: widget.section.minutesInt != null,
                      onRestart: () {
                        setState(() {
                          _finished = false;
                          _index = 0;
                          _correct = 0;
                          _answered = 0;
                          _selected = null;
                          _revealed = false;
                          _secondsLeft = _paceSeconds;
                        });
                        _startTimer();
                      },
                      onExit: () => Navigator.of(context).pop(),
                    )
                  : _buildQuestion(theme),
    );
  }

  Widget _buildQuestion(ThemeData theme) {
    final q = _questions[_index];
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SparkGF.badge(
                '${_index + 1} / ${_questions.length}',
              ),
              const Spacer(),
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '$mm:$ss',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _secondsLeft <= 10
                      ? SparkTheme.errorRed
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GFProgressBar(
            percentage: ((_index) / _questions.length).clamp(0.0, 1.0),
            lineHeight: 8,
            backgroundColor: const Color(0xFFEEF2FF),
            progressBarColor: const Color(0xFF4F46E5),
            animation: true,
            animationDuration: 300,
          ),
          const SizedBox(height: 10),
          Text(
            'Training timer'
            '${widget.section.minutesInt != null ? ' — pace from official ${widget.section.minutes}' : ' — 45s default (no official timing published)'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SparkGF.card(
            margin: EdgeInsets.zero,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.direction == 'l2-to-l1'
                      ? 'What does this mean?'
                      : 'How do you say this?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  q.prompt,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: q.choices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final choice = q.choices[i];
                final isCorrect = _revealed && i == q.correctIndex;
                final isWrongPick =
                    _revealed && _selected == i && i != q.correctIndex;
                Color bg = theme.cardColor;
                Color border = const Color(0xFFC7D2FE);
                if (isCorrect) {
                  bg = const Color(0xFF16A34A).withAlpha(26);
                  border = const Color(0xFF16A34A);
                } else if (isWrongPick) {
                  bg = SparkTheme.errorRed.withAlpha(22);
                  border = SparkTheme.errorRed;
                }
                return Material(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _revealed ? null : () => _select(i),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              choice,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isCorrect)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF16A34A),
                              size: 20,
                            ),
                          if (isWrongPick)
                            Icon(
                              Icons.cancel_rounded,
                              color: SparkTheme.errorRed,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_revealed)
            SparkGF.primaryButton(
              onPressed: _next,
              label: _index + 1 >= _questions.length ? 'Finish' : 'Next',
              expanded: true,
            ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SparkGF.card(
          margin: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int correct;
  final int answered;
  final int total;
  final String sectionName;
  final int paceSeconds;
  final bool hadOfficialTiming;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _ResultCard({
    required this.correct,
    required this.answered,
    required this.total,
    required this.sectionName,
    required this.paceSeconds,
    required this.hadOfficialTiming,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SparkGF.card(
          margin: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$sectionName drill complete',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You answered $answered of $total questions and got '
                '$correct correct.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'This is a practice summary of what happened in this '
                'session — it is NOT an official exam score or a readiness '
                'prediction. Official results come only from the exam body '
                'on exam day.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SparkGF.primaryButton(
                onPressed: onRestart,
                label: 'Practice again',
                expanded: true,
              ),
              const SizedBox(height: 10),
              SparkGF.primaryButton(
                onPressed: onExit,
                label: 'Back to exam prep',
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
