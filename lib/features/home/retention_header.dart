import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/services/adaptive_goal.dart';
import '../../core/services/retention_service.dart';

/// Daily retention strip: streak badge, XP badge, today's goal ring, and
/// (when the learner's history justifies it) an adaptive goal suggestion.
/// Degrades silently to zero states while loading or signed out.
class RetentionHeader extends ConsumerWidget {
  const RetentionHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(retentionStatsProvider);
    final xpTodayAsync = ref.watch(xpTodayProvider);
    final theme = Theme.of(context);

    final stats = statsAsync.value ?? RetentionStats.empty;
    final xpToday = xpTodayAsync.value ?? 0;
    final goalProgress =
        stats.dailyGoalXp > 0 ? xpToday / stats.dailyGoalXp : 0.0;
    final activeToday = xpToday > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: SparkSpacing.md,
            vertical: SparkSpacing.xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SparkSpacing.md,
            vertical: SparkSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: SparkRadius.cardRadius,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              SparkStreakBadge(
                days: stats.streakDays,
                activeToday: activeToday,
              ),
              const SizedBox(width: SparkSpacing.xs),
              SparkXpBadge(xp: stats.totalXp),
              const Spacer(),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SparkGoalRing(
                    progress: goalProgress,
                    centerLabel: '$xpToday',
                    size: 44,
                    strokeWidth: 5,
                    color: SparkStatus.success,
                  ),
                  const SizedBox(height: SparkSpacing.xxxs),
                  Text(
                    'of ${stats.dailyGoalXp} XP goal',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Innovation: adaptive daily goal from the learner's real history.
        // Offered only when the suggestion differs meaningfully; the
        // learner always approves or dismisses — nothing changes silently.
        if (stats.dailyGoalXp > 0)
          AdaptiveGoalBanner(currentGoal: stats.dailyGoalXp),
      ],
    );
  }
}

/// Offers to adjust the daily XP goal to the median of the learner's
/// recent active days. Pure suggestion — requires an explicit tap.
class AdaptiveGoalBanner extends ConsumerStatefulWidget {
  final int currentGoal;

  const AdaptiveGoalBanner({super.key, required this.currentGoal});

  @override
  ConsumerState<AdaptiveGoalBanner> createState() =>
      _AdaptiveGoalBannerState();
}

class _AdaptiveGoalBannerState extends ConsumerState<AdaptiveGoalBanner> {
  bool _dismissed = false;
  bool _applied = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _applied) return const SizedBox.shrink();
    final suggestionAsync = ref.watch(adaptiveGoalSuggestionProvider);
    final suggestion = suggestionAsync.value;
    if (suggestion == null ||
        !AdaptiveGoal.shouldOffer(widget.currentGoal, suggestion)) {
      return const SizedBox.shrink();
    }
    // suggestion is non-nullable here (promoted by the check above).
    final suggestedGoal = suggestion;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        SparkSpacing.md,
        0,
        SparkSpacing.md,
        SparkSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SparkSpacing.md,
        vertical: SparkSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.10),
        borderRadius: SparkRadius.cardRadius,
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: SparkSpacing.sm),
          Expanded(
            child: Text(
              'Based on your recent sessions, a $suggestedGoal XP goal fits '
              'you better.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(retentionServiceProvider)
                  .setDailyGoal(suggestedGoal);
              ref.invalidate(retentionStatsProvider);
              if (mounted) setState(() => _applied = true);
            },
            child: Text('Use $suggestedGoal'),
          ),
          IconButton(
            tooltip: 'Keep my goal',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}
