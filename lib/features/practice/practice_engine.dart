import 'dart:math';

/// One practice item: what the learner sees and must answer.
class PracticeCard {
  final String id;
  final String front; // target-language text (shown first)
  final String back; // bridge-language meaning
  final String? context;

  const PracticeCard({
    required this.id,
    required this.front,
    required this.back,
    this.context,
  });

  /// Heuristic difficulty: shorter, common-pattern items first.
  /// Unit band is applied by the session generator before this.
  int get complexity {
    final words = front.trim().split(RegExp(r'\s+')).length;
    final chars = front.trim().length;
    // Multi-word phrases rank above single words; among equals the
    // shorter one comes first. Context presence = richer item, later.
    return words * 100 + chars + (context != null ? 10 : 0);
  }
}

/// Exercise types, in escalation order (recognition → production → recall).
enum ExerciseType {
  /// Phase 1: introduce the card with meaning, context, and TTS.
  learn,

  /// Phase 2: 4-choice recognition. Direction alternates L2→L1 / L1→L2.
  recognize,

  /// Phase 3: type the answer (fuzzy-matched).
  produce,

  /// Phase 4: re-test items the learner failed, until passed or 2 strikes.
  recall,
}

/// One exercise in the session queue.
class Exercise {
  final PracticeCard card;
  final ExerciseType type;

  /// For [ExerciseType.recognize]: the three wrong choices.
  final List<String> distractors;

  /// true = answer is the bridge language (front→back direction).
  /// false = answer is the target language (back→front direction).
  final bool frontToBack;

  const Exercise({
    required this.card,
    required this.type,
    this.distractors = const [],
    this.frontToBack = true,
  });

  String get prompt => frontToBack ? card.front : card.back;
  String get answer => frontToBack ? card.back : card.front;
}

/// Pure, deterministic practice-session generator.
///
/// Pedagogy (Workstream B, Stage 1): every lesson escalates through four
/// phases instead of passive card-flipping:
///   1. LEARN — introduce each card once (meaning + context + audio).
///   2. RECOGNIZE — 4-choice multiple choice, both directions, distractors
///      drawn from the SAME unit so the learner discriminates similar items.
///   3. PRODUCE — type the answer from memory (fuzzy matching).
///   4. RECALL — failed items re-enter the queue (max 2 strikes each).
///
/// Cards are ordered easy→hard by [PracticeCard.complexity].
class PracticeEngine {
  PracticeEngine({Random? random}) : _random = random ?? Random(2026);

  final Random _random;

  /// Builds the full escalating exercise queue for [cards].
  /// [maxRecallRounds] bounds Phase 4 re-tests per failed item.
  List<Exercise> buildSession(List<PracticeCard> cards, {int maxRecallRounds = 2}) {
    if (cards.isEmpty) return const [];

    // Easy → hard ordering.
    final ordered = List<PracticeCard>.from(cards)
      ..sort((a, b) => a.complexity.compareTo(b.complexity));

    final queue = <Exercise>[];

    // Phase 1 — learn every card once.
    for (final card in ordered) {
      queue.add(Exercise(card: card, type: ExerciseType.learn));
    }

    // Phase 2 — recognition, alternating direction.
    for (var i = 0; i < ordered.length; i++) {
      queue.add(
        Exercise(
          card: ordered[i],
          type: ExerciseType.recognize,
          frontToBack: i.isEven,
          distractors: _distractorsFor(ordered[i], ordered, frontToBack: i.isEven),
        ),
      );
    }

    // Phase 3 — production (typing), alternating direction but biased to
    // target-language production (harder, more valuable).
    for (var i = 0; i < ordered.length; i++) {
      queue.add(
        Exercise(
          card: ordered[i],
          type: ExerciseType.produce,
          frontToBack: i % 3 == 0, // 1/3 bridge production, 2/3 target
        ),
      );
    }

    return queue;
  }

  /// Adds a recall re-test exercise for a failed item.
  Exercise recallExercise(PracticeCard card, {bool frontToBack = false}) {
    return Exercise(
      card: card,
      type: ExerciseType.recall,
      frontToBack: frontToBack,
      distractors: const [],
    );
  }

  /// Three distractors from the same card pool, sharing the answer's
  /// direction so choices are comparable lengths/types.
  List<String> _distractorsFor(
    PracticeCard card,
    List<PracticeCard> pool, {
    required bool frontToBack,
  }) {
    final candidates = <String>[
      for (final c in pool)
        if (c.id != card.id) (frontToBack ? c.back : c.front),
    ];
    candidates.shuffle(_random);
    return candidates.take(3).toList();
  }
}

/// Fuzzy answer matcher for typed production exercises.
///
/// Forgives case, diacritics, punctuation, and minor spacing — strict on
/// actual words. Returns true when the learner's answer is acceptable.
bool answersMatch(String expected, String given) {
  String normalize(String s) {
    var t = s.toLowerCase().trim();
    // Strip diacritics via Unicode decomposition (Latin-1 supplement etc.).
    t = _stripDiacritics(t);
    // Drop punctuation except apostrophes inside words.
    t = t.replaceAll(RegExp(r"[^\p{L}\p{N}\p{M}'\s]", unicode: true), ' ');
    // Collapse whitespace.
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  final e = normalize(expected);
  final g = normalize(given);
  if (e == g) return true;

  // Allow omitting trailing punctuation words like "please" variants is NOT
  // allowed — the whole normalized string must match, or match modulo a
  // single leading article (common in bridge languages).
  final eNoArticle = _stripLeadingArticle(e);
  final gNoArticle = _stripLeadingArticle(g);
  if (eNoArticle == gNoArticle) return true;

  return false;
}

String _stripDiacritics(String s) {
  // Common diacritic-bearing letters used by the bundled corpora.
  const map = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i',
    'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o',
    'ô': 'o', 'õ': 'o', 'ö': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u',
    'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'ё': 'е', 'ш': 'ш', 'щ': 'щ',
  };
  final buf = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    buf.write(map[ch] ?? ch);
  }
  return buf.toString();
}

String _stripLeadingArticle(String s) {
  final articles = [
    'a ', 'an ', 'the ', 'le ', 'la ', 'les ', 'un ', 'une ', 'el ',
    'los ', 'las ', 'o ', 'os ', 'as ', 'um ', 'uma ', 'der ', 'die ',
    'das ', 'ein ', 'eine ', 'il ', 'lo ', 'gli ', 'i ',
  ];
  for (final a in articles) {
    if (s.startsWith(a)) return s.substring(a.length);
  }
  return s;
}

/// Maps an exercise outcome to an SM-2 quality grade so the existing
/// spaced-repetition ledger keeps working unchanged.
int srsQualityFor({required ExerciseType type, required bool passed}) {
  if (type == ExerciseType.learn) return 4; // exposure only
  if (passed) {
    return switch (type) {
      ExerciseType.recognize => 4,
      ExerciseType.produce => 5,
      ExerciseType.recall => 3, // passed only after failing once
      ExerciseType.learn => 4,
    };
  }
  return 1; // failed
}
