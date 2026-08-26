import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/spaced_repetition_service.dart';
import '../../core/services/tts_service.dart';

class FlashcardStudySession extends ConsumerStatefulWidget {
  final String title;
  final List<dynamic> flashcards;
  final String languageKey;

  const FlashcardStudySession({
    super.key,
    required this.title,
    required this.flashcards,
    required this.languageKey,
  });

  @override
  ConsumerState<FlashcardStudySession> createState() =>
      _FlashcardStudySessionState();
}

class _FlashcardStudySessionState
    extends ConsumerState<FlashcardStudySession> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Map<String, SRSState> _sessionProgress = {};
  final TTSService _tts = TTSService();
  final Map<int, int> _qualityCounts = {};

  void _speakCardText(bool flipped) {
    final card = widget.flashcards[_currentIndex];
    // Front is the target language; the back is the English bridge.
    _tts.speak(
      flipped ? card.back : card.front,
      flipped ? 'en' : widget.languageKey,
    );
  }

  void _handleQualitySelect(int quality) {
    final card = widget.flashcards[_currentIndex];
    _qualityCounts.update(quality, (v) => v + 1, ifAbsent: () => 1);

    final user = ref.read(authProvider);
    if (user == null) return;

    final cardReviewsAsync = ref.read(
      cardReviewsProvider(CardReviewsParam(user.id, widget.languageKey)),
    );
    final cardReviews = cardReviewsAsync.value ?? {};
    final existingState = _sessionProgress[card.id] ?? cardReviews[card.id];

    final prevRepetitions = existingState?.repetitions ?? 0;
    final prevEfactor = existingState?.efactor ?? 2.5;
    final prevInterval = existingState?.interval ?? 0;

    // Calculate next SM-2 interval
    final nextState = SpacedRepetitionService.calculateNextState(
      quality: quality,
      prevRepetitions: prevRepetitions,
      prevEfactor: prevEfactor,
      prevInterval: prevInterval,
    );

    _sessionProgress[card.id] = nextState;

    // Sync stats to Supabase database reactively
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

    setState(() {
      if (_currentIndex < widget.flashcards.length - 1) {
        _currentIndex++;
        _isFlipped = false;
      } else {
        _currentIndex = widget.flashcards.length; // completed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please sign in.")));
    }

    final cardReviewsAsync = ref.watch(
      cardReviewsProvider(CardReviewsParam(user.id, widget.languageKey)),
    );

    return cardReviewsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Text('Review progress is unavailable right now.'),
        ),
      ),
      data: (reviews) {
        final isCompleted = _currentIndex >= widget.flashcards.length;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('${widget.title} — practice session'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: isCompleted
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 72,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Session Completed! 🎉",
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You practiced ${widget.flashcards.length} cards. Your ratings schedule future reviews.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Recall breakdown from this session.
                      if (_qualityCounts.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _sessionStat('Forgot', _qualityCounts[0] ?? 0, Colors.redAccent),
                            const SizedBox(width: 16),
                            _sessionStat('Hard', _qualityCounts[3] ?? 0, Colors.orangeAccent),
                            const SizedBox(width: 16),
                            _sessionStat('Good', _qualityCounts[4] ?? 0, Colors.blueAccent),
                            const SizedBox(width: 16),
                            _sessionStat('Easy', _qualityCounts[5] ?? 0, Colors.green),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Back to Dashboard"),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress indicator
                      LinearProgressIndicator(
                        value: widget.flashcards.isEmpty
                            ? 1.0
                            : (_currentIndex / widget.flashcards.length),
                        backgroundColor: theme.colorScheme.primary.withAlpha(
                          25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Card ${_currentIndex + 1} of ${widget.flashcards.length}",
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                      const Spacer(),
                      // Flashcard Container
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFlipped = !_isFlipped;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(32),
                          height: 240,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.primary.withAlpha(
                                _isFlipped ? 100 : 38,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isFlipped ? "MEANING" : "FRONT",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isFlipped
                                      ? widget.flashcards[_currentIndex].back
                                      : widget.flashcards[_currentIndex].front,
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_isFlipped &&
                                    widget.flashcards[_currentIndex].context !=
                                        null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.flashcards[_currentIndex].context!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.flip),
                              label: Text(
                                _isFlipped ? "Show Front" : "Reveal Answer",
                              ),
                              onPressed: () {
                                setState(() {
                                  _isFlipped = !_isFlipped;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            // Listen button: speaks the visible side with
                            // the configured voice (male/female/auto).
                            TextButton.icon(
                              icon: const Icon(Icons.volume_up_rounded),
                              label: const Text("Listen"),
                              onPressed: () => _speakCardText(_isFlipped),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Quality Rating buttons
                      if (_isFlipped) ...[
                        Text(
                          "How well did you recall this card?",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQualityButton(
                              0,
                              "Forgot ❌",
                              Colors.redAccent,
                            ),
                            _buildQualityButton(
                              3,
                              "Hard ⏳",
                              Colors.orangeAccent,
                            ),
                            _buildQualityButton(
                              4,
                              "Good 👍",
                              Colors.blueAccent,
                            ),
                            _buildQualityButton(5, "Easy ⭐", Colors.green),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 60),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _sessionStat(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildQualityButton(int q, String label, Color btnColor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _handleQualitySelect(q),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

/// Display metadata for a Sparky conversation mode. Only the mode token is
/// sent to the server; labels and icons stay client-side.
