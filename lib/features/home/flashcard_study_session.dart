import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/retention_service.dart';
import '../../core/services/spaced_repetition_service.dart';
import '../../core/services/voice_controller.dart';
import '../../shared/models/curriculum.dart';
import '../practice/practice_engine.dart';

/// Progressive practice session powered by [PracticeEngine].
///
/// Escalates easy→hard through four phases instead of passive flipping:
///   Learn → Recognize (4-choice) → Produce (type it) → Recall (failed items).
class FlashcardStudySession extends ConsumerStatefulWidget {
  final String title;
  final List<dynamic> flashcards;
  final String languageKey;

  /// Curriculum lesson id this session belongs to. When set, finishing the
  /// session records a lesson completion (migration 015).
  final String? lessonId;

  const FlashcardStudySession({
    super.key,
    required this.title,
    required this.flashcards,
    required this.languageKey,
    this.lessonId,
  });

  @override
  ConsumerState<FlashcardStudySession> createState() =>
      _FlashcardStudySessionState();
}

class _FlashcardStudySessionState
    extends ConsumerState<FlashcardStudySession> {
  final PracticeEngine _engine = PracticeEngine();
  final VoiceController _voice = VoiceController();
  final TextEditingController _typeController = TextEditingController();

  late final List<PracticeCard> _practiceCards;
  List<Exercise> _queue = const [];
  int _index = 0;

  // Recall phase bookkeeping: failed items awaiting re-test.
  final Map<String, int> _recallStrikes = {};

  // Session stats.
  int _correct = 0;
  int _wrong = 0;

  // Interaction state for the current exercise.
  String? _selectedChoice; // recognize phase
  bool _answered = false;
  bool _wasCorrect = false;
  String? _typeFeedback;

  final Map<String, SRSState> _sessionProgress = {};
  final Map<int, int> _qualityCounts = {};

  @override
  void initState() {
    super.initState();
    _practiceCards = [
      for (final c in widget.flashcards)
        if (c is Flashcard)
          PracticeCard(
            id: c.id,
            front: c.front,
            back: c.back,
            context: c.context,
          ),
    ];
    _queue = _engine.buildSession(_practiceCards);
  }

  @override
  void dispose() {
    _typeController.dispose();
    _voice.stop();
    super.dispose();
  }

  Exercise? get _currentExercise =>
      _index < _queue.length ? _queue[_index] : null;

  String _phaseLabel(ExerciseType type) => switch (type) {
        ExerciseType.learn => 'Learn',
        ExerciseType.recognize => 'Recognize',
        ExerciseType.produce => 'Write it',
        ExerciseType.recall => 'Second chance',
      };

  // ------------------------------------------------------------- actions

  void _next() {
    final ex = _currentExercise;
    if (ex == null) return;

    // Failed recognize/produce items re-enter as recall exercises.
    if (!_wasCorrect &&
        (ex.type == ExerciseType.recognize ||
            ex.type == ExerciseType.produce)) {
      final strikes = (_recallStrikes[ex.card.id] ?? 0) + 1;
      _recallStrikes[ex.card.id] = strikes;
      if (strikes < 3) {
        setState(() {
          _queue = [
            ..._queue,
            _engine.recallExercise(
              ex.card,
              frontToBack: !ex.frontToBack, // flip direction on retry
            ),
          ];
        });
      }
    }

    setState(() {
      _index++;
      _selectedChoice = null;
      _answered = false;
      _wasCorrect = false;
      _typeFeedback = null;
      _typeController.clear();
    });

    if (_index >= _queue.length) {
      _finishSession();
    }
  }

  void _finishSession() {
    final user = ref.read(authProvider);
    if (user == null) return;
    ref.read(retentionServiceProvider).awardXp(
      source: 'review_session',
      amount: XpAmounts.reviewSession,
      languageCode: widget.languageKey,
    );
    final lessonId = widget.lessonId;
    if (lessonId != null) {
      ref
          .read(databaseServiceProvider)
          .completeLesson(lessonId, widget.languageKey)
          .then((_) {
            ref.invalidate(
              lessonProgressProvider(
                CardReviewsParam(user.id, widget.languageKey),
              ),
            );
          })
          .catchError((e) {
            debugPrint('Lesson-completion sync failed.');
          });
    }
  }

  void _recordOutcome(bool passed) {
    final ex = _currentExercise;
    if (ex == null) return;
    setState(() {
      _answered = true;
      _wasCorrect = passed;
      if (passed) {
        _correct++;
      } else {
        _wrong++;
      }
    });

    // SRS only for exercises that test memory (skip pure learn exposure
    // for cards already known? keep simple: grade every tested card once).
    final quality = srsQualityFor(type: ex.type, passed: passed);
    if (ex.type != ExerciseType.learn) {
      _qualityCounts.update(quality, (v) => v + 1, ifAbsent: () => 1);
      _applySrs(ex.card, quality);
    }
  }

  void _applySrs(PracticeCard card, int quality) {
    final user = ref.read(authProvider);
    if (user == null) return;

    final cardReviewsAsync = ref.read(
      cardReviewsProvider(CardReviewsParam(user.id, widget.languageKey)),
    );
    final cardReviews = cardReviewsAsync.value ?? {};
    final existingState = _sessionProgress[card.id] ?? cardReviews[card.id];

    final nextState = SpacedRepetitionService.calculateNextState(
      quality: quality,
      prevRepetitions: existingState?.repetitions ?? 0,
      prevEfactor: existingState?.efactor ?? 2.5,
      prevInterval: existingState?.interval ?? 0,
    );
    _sessionProgress[card.id] = nextState;

    ref
        .read(databaseServiceProvider)
        .upsertCardReview(
          userId: user.id,
          cardId: card.id,
          languageKey: widget.languageKey,
          interval: nextState.interval,
          repetitions: nextState.repetitions,
          efactor: nextState.efactor,
          nextReview: nextState.nextReviewAt,
        )
        .catchError((e) {
          debugPrint('Card-review synchronization failed.');
        });
  }

  void _speakPrompt(Exercise ex) {
    // Prompts in the target language are spoken in the target language.
    final isTarget = ex.frontToBack;
    _voice.toggle(
      ex.prompt,
      isTarget ? widget.languageKey : 'en',
    );
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please sign in.")));
    }

    final isCompleted = _index >= _queue.length;
    final ex = _currentExercise;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${widget.title} — practice'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isCompleted
            ? _buildCompletion(theme)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SparkProgressBar(
                    progress: _queue.isEmpty ? 1.0 : _index / _queue.length,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        avatar: Icon(
                          switch (ex!.type) {
                            ExerciseType.learn => Icons.auto_stories,
                            ExerciseType.recognize => Icons.touch_app,
                            ExerciseType.produce => Icons.keyboard,
                            ExerciseType.recall => Icons.replay,
                          },
                          size: 16,
                        ),
                        label: Text(_phaseLabel(ex.type)),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '${_index + 1} / ${_queue.length}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(child: _buildExercise(theme, ex)),
                ],
              ),
      ),
    );
  }

  Widget _buildExercise(ThemeData theme, Exercise ex) {
    return switch (ex.type) {
      ExerciseType.learn => _buildLearn(theme, ex),
      ExerciseType.recognize => _buildRecognize(theme, ex),
      ExerciseType.produce ||
      ExerciseType.recall =>
        _buildProduce(theme, ex),
    };
  }

  // Phase 1 — Learn ------------------------------------------------------

  Widget _buildLearn(ThemeData theme, Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(SparkRadius.card),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(38),
                width: 2,
              ),
              boxShadow: SparkShadows.card,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ex.card.front,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: const Text('Listen'),
                  onPressed: () => _voice.toggle(
                    ex.card.front,
                    widget.languageKey,
                  ),
                ),
                if (ex.card.context != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    ex.card.context!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  ex.card.back,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SparkButton(
          label: 'Got it — next',
          expanded: true,
          onPressed: _next,
        ),
      ],
    );
  }

  // Phase 2 — Recognize ---------------------------------------------------

  Widget _buildRecognize(ThemeData theme, Exercise ex) {
    final options = [...ex.distractors, ex.answer]..shuffle();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What does this mean?',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                ex.prompt,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Listen',
              icon: const Icon(Icons.volume_up_rounded),
              onPressed: () => _speakPrompt(ex),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final opt = options[i];
              final isAnswer = opt == ex.answer;
              Color? fill;
              Color border = theme.dividerColor;
              if (_answered) {
                if (isAnswer) {
                  fill = SparkStatus.success.withAlpha(30);
                  border = SparkStatus.success;
                } else if (opt == _selectedChoice) {
                  fill = SparkStatus.danger.withAlpha(30);
                  border = SparkStatus.danger;
                }
              } else if (opt == _selectedChoice) {
                border = theme.colorScheme.primary;
              }
              return InkWell(
                borderRadius: BorderRadius.circular(SparkRadius.button),
                onTap: _answered
                    ? null
                    : () {
                        setState(() => _selectedChoice = opt);
                        _recordOutcome(isAnswer);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SparkSpacing.md,
                    vertical: SparkSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: fill ?? theme.cardColor,
                    borderRadius:
                        BorderRadius.circular(SparkRadius.button),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      if (_answered && isAnswer)
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: SparkStatus.success,
                        ),
                      if (_answered &&
                          opt == _selectedChoice &&
                          !isAnswer)
                        const Icon(
                          Icons.cancel,
                          size: 20,
                          color: SparkStatus.danger,
                        ),
                      if (_answered &&
                          (isAnswer || opt == _selectedChoice))
                        const SizedBox(width: 8),
                      Expanded(child: Text(opt)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_answered) ...[
          const SizedBox(height: 12),
          SparkButton(
            label: 'Continue',
            variant: _wasCorrect
                ? SparkButtonVariant.primary
                : SparkButtonVariant.secondary,
            expanded: true,
            onPressed: _next,
          ),
        ],
      ],
    );
  }

  // Phase 3/4 — Produce / Recall -----------------------------------------

  Widget _buildProduce(ThemeData theme, Exercise ex) {
    final isRecall = ex.type == ExerciseType.recall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isRecall
              ? 'Second chance — write it from memory'
              : (ex.frontToBack
                  ? 'Write the meaning'
                  : 'Write it in your new language'),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                ex.prompt,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Listen',
              icon: const Icon(Icons.volume_up_rounded),
              onPressed: () => _speakPrompt(ex),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _typeController,
          enabled: !_answered,
          autofocus: true,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
          decoration: InputDecoration(
            hintText: 'Type your answer…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparkRadius.button),
            ),
          ),
          onSubmitted: (_) {
            if (!_answered) _gradeTyped(ex);
          },
        ),
        if (_typeFeedback != null) ...[
          const SizedBox(height: 10),
          Text(
            _typeFeedback!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _wasCorrect ? SparkStatus.success : SparkStatus.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const Spacer(),
        if (!_answered)
          SparkButton(
            label: 'Check',
            expanded: true,
            onPressed: _typeController.text.trim().isEmpty
                ? null
                : () => _gradeTyped(ex),
          )
        else ...[
          if (!_wasCorrect)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Correct answer: ${ex.answer}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: SparkStatus.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SparkButton(
            label: 'Continue',
            variant: _wasCorrect
                ? SparkButtonVariant.primary
                : SparkButtonVariant.secondary,
            expanded: true,
            onPressed: _next,
          ),
        ],
      ],
    );
  }

  void _gradeTyped(Exercise ex) {
    final given = _typeController.text;
    final passed = answersMatch(ex.answer, given);
    setState(() {
      _typeFeedback = passed
          ? 'Correct! 🎉'
          : 'Not quite — expected “${ex.answer}”';
    });
    _recordOutcome(passed);
  }

  // Completion ------------------------------------------------------------

  Widget _buildCompletion(ThemeData theme) {
    final total = _correct + _wrong;
    final accuracy = total == 0 ? 0 : (_correct * 100 / total).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SparkStatus.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 56,
              color: SparkStatus.success,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Practice complete!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Center(child: SparkXpBadge(xp: XpAmounts.reviewSession)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _sessionStat('Correct', _correct, SparkStatus.success),
            const SizedBox(width: 24),
            _sessionStat('Missed', _wrong, SparkStatus.danger),
            const SizedBox(width: 24),
            _sessionStat('Accuracy', accuracy, SparkStatus.info,
                suffix: '%'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'You practiced ${_practiceCards.length} cards through learn → '
          'recognize → write → recall.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SparkButton(
          label: 'Back to Dashboard',
          expanded: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _sessionStat(String label, int count, Color color,
      {String suffix = ''}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count$suffix',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
