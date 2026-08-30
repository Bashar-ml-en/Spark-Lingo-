/// Adaptive daily goal — innovation layer for retention.
///
/// Computes a goal suggestion from the learner's real XP history: the
/// median of their recent ACTIVE days (days with any XP), rounded to the
/// nearest 5. No fabricated motivation: the suggestion is derived only
/// from recorded practice, the learner always approves any change, and
/// empty history yields null (no suggestion shown).
class AdaptiveGoal {
  /// Minimum active days before we suggest anything.
  static const int minActiveDays = 3;

  /// Suggests a daily XP goal from per-day XP totals (active days only,
  /// most recent last). Returns null when history is too thin.
  static int? suggest(List<int> activeDayXp) {
    if (activeDayXp.length < minActiveDays) return null;
    // Use the most recent 7 active days so the suggestion tracks current
    // behavior, not month-old habits.
    final recent = activeDayXp.length > 7
        ? activeDayXp.sublist(activeDayXp.length - 7)
        : activeDayXp;
    final sorted = List<int>.from(recent)..sort();
    final mid = sorted.length ~/ 2;
    final median = sorted.length.isOdd
        ? sorted[mid]
        : ((sorted[mid - 1] + sorted[mid]) / 2).round();
    // Round to nearest 5, keep within the server-enforced goal bounds.
    final rounded = (median / 5).round() * 5;
    return rounded.clamp(10, 500);
  }

  /// True when the suggestion is worth surfacing (meaningfully different
  /// from the current goal — avoids nagging on trivial deltas).
  static bool shouldOffer(int currentGoal, int? suggested) {
    if (suggested == null) return false;
    return (suggested - currentGoal).abs() >= 10;
  }
}
