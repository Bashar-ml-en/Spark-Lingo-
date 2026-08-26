import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Retention layer: XP ledger, streaks, and daily goals.
///
/// All math happens server-side in the security-definer RPCs from migration
/// 014 (award_xp / xp_today) — the client only reads aggregates and requests
/// awards, so streaks can never be forged from a build.

/// XP amounts per qualifying activity. Tuned for a ~3-minute lesson ≈ 15 XP
/// so the default 30 XP daily goal takes roughly two activities.
abstract final class XpAmounts {
  static const int lessonComplete = 15;
  static const int reviewSession = 10;
  static const int aiChatTurn = 2;
  static const int examAttempt = 25;

  static const int defaultDailyGoal = 30;
}

/// Denormalized per-user retention summary (mirrors user_retention_stats).
@immutable
class RetentionStats {
  final int totalXp;
  final int streakDays;
  final int longestStreakDays;
  final DateTime? lastActivityDay;
  final int dailyGoalXp;

  const RetentionStats({
    required this.totalXp,
    required this.streakDays,
    required this.longestStreakDays,
    required this.lastActivityDay,
    required this.dailyGoalXp,
  });

  factory RetentionStats.fromMap(Map<String, dynamic> map) {
    return RetentionStats(
      totalXp: map['total_xp'] as int? ?? 0,
      streakDays: map['streak_days'] as int? ?? 0,
      longestStreakDays: map['longest_streak_days'] as int? ?? 0,
      lastActivityDay: map['last_activity_day'] != null
          ? DateTime.tryParse(map['last_activity_day'] as String)
          : null,
      dailyGoalXp: map['daily_goal_xp'] as int? ?? XpAmounts.defaultDailyGoal,
    );
  }

  static const empty = RetentionStats(
    totalXp: 0,
    streakDays: 0,
    longestStreakDays: 0,
    lastActivityDay: null,
    dailyGoalXp: XpAmounts.defaultDailyGoal,
  );
}

class RetentionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Awards XP for a completed activity. Streak math is atomic server-side.
  /// Best-effort: an award failure never breaks the learner's flow.
  Future<void> awardXp({
    required String source,
    required int amount,
    String languageCode = '',
  }) async {
    try {
      await _client.rpc('award_xp', params: {
        'p_source': source,
        'p_amount': amount,
        'p_language_code': languageCode,
        'p_local_today': _localTodayIso(),
      });
    } catch (e) {
      debugPrint('XP award failed: $e');
    }
  }

  /// XP earned on the learner's local calendar day so far.
  Future<int> xpToday() async {
    try {
      final result = await _client.rpc(
        'xp_today',
        params: {'p_local_today': _localTodayIso()},
      );
      return result is int ? result : 0;
    } catch (e) {
      debugPrint('XP today lookup failed: $e');
      return 0;
    }
  }

  /// Current retention summary, or null when no row exists yet.
  Future<RetentionStats?> fetchStats() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final row = await _client
          .from('user_retention_stats')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) return RetentionStats.empty;
      return RetentionStats.fromMap(row);
    } catch (e) {
      debugPrint('Retention stats lookup failed: $e');
      return null;
    }
  }

  /// Learner sets their own daily XP goal (bounded 10..500 server-side).
  Future<void> setDailyGoal(int xp) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      await _client.from('user_retention_stats').upsert({
        'user_id': user.id,
        'daily_goal_xp': xp.clamp(10, 500),
      });
    } catch (e) {
      debugPrint('Daily goal update failed: $e');
    }
  }

  String _localTodayIso() {
    final now = DateTime.now();
    final local = DateTime(now.year, now.month, now.day);
    return local.toIso8601String().substring(0, 10);
  }
}

final retentionServiceProvider = Provider<RetentionService>((ref) {
  return RetentionService();
});

/// Live retention summary for the signed-in user; empty stats when signed
/// out or before the first award.
final retentionStatsProvider =
    FutureProvider.autoDispose<RetentionStats>((ref) async {
  final stats = await ref.watch(retentionServiceProvider).fetchStats();
  return stats ?? RetentionStats.empty;
});

/// XP earned today on the learner's local calendar.
final xpTodayProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(retentionServiceProvider).xpToday();
});
