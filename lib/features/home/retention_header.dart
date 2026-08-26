import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/services/retention_service.dart';

/// Daily retention strip: streak badge, XP badge, and today's goal ring.
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

    return Container(
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
          SparkStreakBadge(days: stats.streakDays, activeToday: activeToday),
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
    );
  }
}
