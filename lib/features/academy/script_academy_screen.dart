import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/services/voice_controller.dart';
import 'script_data.dart';

/// The Writing Academy: an interactive, language-aware script trainer.
///
/// Three modes:
///   1. Browse  — grid of every glyph with name, sound, and example.
///   2. Drill   — flash cards, tap to reveal, self-rate.
///   3. Quiz    — 4-choice glyph→romanization test.
class ScriptAcademyScreen extends StatefulWidget {
  final String languageKey;

  const ScriptAcademyScreen({super.key, required this.languageKey});

  @override
  State<ScriptAcademyScreen> createState() => _ScriptAcademyScreenState();
}

class _ScriptAcademyScreenState extends State<ScriptAcademyScreen> {
  int _modeIndex = 0; // 0 browse, 1 drill, 2 quiz
  final VoiceController _voice = VoiceController();

  late final ScriptAcademy? _academy =
      scriptAcademies[widget.languageKey];

  @override
  void dispose() {
    _voice.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final academy = _academy;

    if (academy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Writing Academy')),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.translate,
                size: 56,
                color: theme.colorScheme.primary.withAlpha(120),
              ),
              const SizedBox(height: 16),
              Text(
                'This language uses the same alphabet as English — no new '
                'script to learn. Dive straight into vocabulary!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              SparkButton(
                label: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${academy.languageName} · ${academy.scriptName}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SparkSpacing.md,
              SparkSpacing.sm,
              SparkSpacing.md,
              0,
            ),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.grid_view_outlined, size: 18),
                  label: Text('Browse'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.style_outlined, size: 18),
                  label: Text('Drill'),
                ),
                ButtonSegment(
                  value: 2,
                  icon: Icon(Icons.quiz_outlined, size: 18),
                  label: Text('Quiz'),
                ),
              ],
              selected: {_modeIndex},
              onSelectionChanged: (s) =>
                  setState(() => _modeIndex = s.first),
            ),
          ),
          Expanded(
            child: switch (_modeIndex) {
              0 => _BrowseMode(academy: academy, voice: _voice),
              1 => _DrillMode(academy: academy, voice: _voice),
              _ => _QuizMode(academy: academy),
            },
          ),
        ],
      ),
    );
  }
}

/// Mode 1 — Browse: every glyph in a tappable grid, examples expand inline.
class _BrowseMode extends StatefulWidget {
  final ScriptAcademy academy;
  final VoiceController voice;

  const _BrowseMode({required this.academy, required this.voice});

  @override
  State<_BrowseMode> createState() => _BrowseModeState();
}

class _BrowseModeState extends State<_BrowseMode> {
  String? _expandedGlyph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(SparkSpacing.md),
      children: [
        // Intro card
        Container(
          padding: const EdgeInsets.all(SparkSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(SparkRadius.card),
          ),
          child: Text(
            widget.academy.intro,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        for (final section in widget.academy.sections) ...[
          const SizedBox(height: 20),
          Text(
            section.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (section.subtitle != null)
            Text(
              section.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          for (final entry in section.entries)
            _BrowseTile(
              entry: entry,
              expanded: _expandedGlyph == entry.glyph,
              languageKey: widget.academy.languageKey,
              voice: widget.voice,
              onTap: () {
                setState(() {
                  _expandedGlyph =
                      _expandedGlyph == entry.glyph ? null : entry.glyph;
                });
              },
            ),
        ],
      ],
    );
  }
}

class _BrowseTile extends StatelessWidget {
  final ScriptEntry entry;
  final bool expanded;
  final String languageKey;
  final VoiceController voice;
  final VoidCallback onTap;

  const _BrowseTile({
    required this.entry,
    required this.expanded,
    required this.languageKey,
    required this.voice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetLanguage = switch (languageKey) {
      'en' || 'fr' || 'es' || 'de' || 'pt' => 'en',
      _ => languageKey,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(SparkRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(SparkRadius.button),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SparkSpacing.md,
              vertical: SparkSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SparkRadius.button),
              border: Border.all(
                color: expanded
                    ? theme.colorScheme.primary
                    : theme.dividerColor.withAlpha(120),
                width: expanded ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        entry.glyph,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: SparkSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            entry.roman.isEmpty
                                ? (entry.sound ?? '')
                                : '/${entry.roman}/'
                                    '${entry.sound != null ? ' — ${entry.sound}' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const Divider(height: 16),
                  if (entry.example != null) ...[
                    Row(
                      children: [
                        Text(
                          entry.example!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (entry.exampleMeaning != null)
                          Expanded(
                            child: Text(
                              entry.exampleMeaning!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Listen',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.volume_up_rounded,
                            size: 18,
                          ),
                          onPressed: () => voice.toggle(
                            entry.example!,
                            targetLanguage,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      entry.sound ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mode 2 — Drill: flash cards through every entry, tap to reveal.
class _DrillMode extends StatefulWidget {
  final ScriptAcademy academy;
  final VoiceController voice;

  const _DrillMode({required this.academy, required this.voice});

  @override
  State<_DrillMode> createState() => _DrillModeState();
}

class _DrillModeState extends State<_DrillMode> {
  late List<ScriptEntry> _deck;
  int _index = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _deck = [
      for (final s in widget.academy.sections) ...s.entries,
    ]..shuffle(Random(42));
  }

  void _advance() {
    setState(() {
      _index++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_index >= _deck.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 64, color: SparkStatus.success),
            const SizedBox(height: 16),
            Text(
              'Drill complete! You covered ${_deck.length} symbols.',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SparkButton(
              label: 'Drill again',
              onPressed: () {
                setState(() {
                  _deck.shuffle();
                  _index = 0;
                  _revealed = false;
                });
              },
            ),
          ],
        ),
      );
    }
    final entry = _deck[_index];
    return Padding(
      padding: const EdgeInsets.all(SparkSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_index + 1} of ${_deck.length}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SparkProgressBar(progress: _index / _deck.length),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _revealed = !_revealed),
            child: Container(
              height: 260,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(SparkRadius.card),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(
                    _revealed ? 100 : 38,
                  ),
                  width: 2,
                ),
                boxShadow: SparkShadows.card,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.glyph,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 64,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _revealed
                        ? Column(
                            key: const ValueKey('revealed'),
                            children: [
                              Text(
                                '${entry.name}  /${entry.roman}/',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                              ),
                              if (entry.sound != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  entry.sound!,
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          )
                        : Text(
                            'Tap to reveal',
                            key: const ValueKey('hidden'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SparkButton(
            label: _revealed ? 'Next symbol' : 'Reveal',
            expanded: true,
            onPressed: _revealed ? _advance : () => setState(() => _revealed = true),
          ),
        ],
      ),
    );
  }
}

/// Mode 3 — Quiz: 4-choice glyph → romanization.
class _QuizMode extends StatefulWidget {
  final ScriptAcademy academy;

  const _QuizMode({required this.academy});

  @override
  State<_QuizMode> createState() => _QuizModeState();
}

class _QuizModeState extends State<_QuizMode> {
  late final List<ScriptEntry> _pool;
  final Random _rng = Random(2026);
  ScriptEntry? _question;
  List<String> _options = [];
  int _score = 0;
  int _asked = 0;
  String? _picked;
  bool _done = false;

  static const int _quizLength = 10;

  @override
  void initState() {
    super.initState();
    _pool = [
      for (final s in widget.academy.sections)
        ...s.entries.where((e) => e.roman.isNotEmpty),
    ];
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_asked >= _quizLength) {
      setState(() => _done = true);
      return;
    }
    final q = _pool[_rng.nextInt(_pool.length)];
    final distractors = <String>{};
    var guard = 0;
    while (distractors.length < 3 && guard++ < 200) {
      final candidate = _pool[_rng.nextInt(_pool.length)].roman;
      if (candidate != q.roman) distractors.add(candidate);
    }
    final opts = [...distractors, q.roman]..shuffle(_rng);
    setState(() {
      _question = q;
      _options = opts;
      _picked = null;
    });
  }

  void _pick(String option) {
    if (_picked != null) return;
    setState(() {
      _picked = option;
      _asked++;
      if (option == _question!.roman) _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_done) {
      final pct = (_score * 100 / _quizLength).round();
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$pct%',
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You got $_score of $_quizLength right',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SparkButton(
              label: 'New quiz',
              onPressed: () {
                setState(() {
                  _score = 0;
                  _asked = 0;
                  _done = false;
                  _nextQuestion();
                });
              },
            ),
          ],
        ),
      );
    }
    final q = _question!;
    return Padding(
      padding: const EdgeInsets.all(SparkSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${_asked + (_picked == null ? 1 : 0)} of $_quizLength',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SparkProgressBar(progress: _asked / _quizLength),
          const Spacer(),
          Text(
            'How do you read this?',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            q.glyph,
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 60,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          for (final opt in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    width: 1.5,
                    color: _picked == null
                        ? theme.dividerColor
                        : opt == q.roman
                            ? SparkStatus.success
                            : opt == _picked
                                ? SparkStatus.danger
                                : theme.dividerColor,
                  ),
                  backgroundColor: _picked == null
                      ? theme.cardColor
                      : opt == q.roman
                          ? SparkStatus.success.withAlpha(26)
                          : opt == _picked
                              ? SparkStatus.danger.withAlpha(26)
                              : theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(SparkRadius.button),
                  ),
                ),
                onPressed: () => _pick(opt),
                child: Text(
                  opt,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          const Spacer(),
          if (_picked != null)
            SparkButton(
              label: 'Next',
              expanded: true,
              onPressed: _nextQuestion,
            ),
        ],
      ),
    );
  }
}
