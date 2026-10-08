import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/components.dart';
import '../../../shared/models/curriculum.dart';
import '../../../shared/models/user_profile.dart';

/// Stitch Design System — Adaptive Flight Path Bento Header
/// Corresponds to Stitch screen: "Adaptive Flight Path Dashboard"
class FlightPathBentoHeader extends StatelessWidget {
  final UserProfile profile;
  final Unit? currentUnit;
  final double completionRate; // 0.0 to 1.0
  final VoidCallback onContinueLearning;
  final VoidCallback onAnalyticsTap;

  const FlightPathBentoHeader({
    super.key,
    required this.profile,
    this.currentUnit,
    required this.completionRate,
    required this.onContinueLearning,
    required this.onAnalyticsTap,
  });

  String _leagueName(int xp) {
    if (xp >= 5000) return 'OBSIDIAN ELITE';
    if (xp >= 2500) return 'DIAMOND LEAGUE';
    if (xp >= 1000) return 'EMERALD TIER';
    if (xp >= 500) return 'VIOLET ASCENT';
    return 'INITIATE PATH';
  }

  String _formatXP(int xp) {
    if (xp >= 1000) {
      final k = xp / 1000.0;
      return '${k.toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return '$xp';
  }

  @override
  Widget build(BuildContext context) {
    final percentInt = (completionRate * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Telemetry Rank Bar
        StitchGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.military_tech,
                    color: StitchTokens.kineticAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _leagueName(profile.totalXp),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: StitchTokens.textPrimary,
                      letterSpacing: 1.2,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: StitchTokens.primaryIndigo,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatXP(profile.totalXp)} XP',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: StitchTokens.primaryIndigo,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Unit Roadmap Bento Card with circular retention ring
        StitchGlassCard(
          isElevated: true,
          borderColor: StitchTokens.borderHairline,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const StitchCefrBadge(level: 'B1', compact: true),
                            const SizedBox(width: 8),
                            Text(
                              currentUnit != null
                                  ? 'UNIT ${currentUnit!.orderIndex + 1}'
                                  : 'CURRENT STAGE',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: StitchTokens.primaryIndigo,
                                letterSpacing: 1.5,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentUnit?.title ?? 'Active Pathway',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: StitchTokens.textPrimary,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        if (currentUnit?.description != null &&
                            currentUnit!.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            currentUnit!.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: StitchTokens.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Retention & Fluency Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: completionRate > 0 ? completionRate : 0.05,
                          strokeWidth: 5,
                          backgroundColor: StitchTokens.surfaceLowest,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            StitchTokens.masteryEmerald,
                          ),
                        ),
                      ),
                      Text(
                        '$percentInt%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: StitchTokens.textPrimary,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StitchGradientButton(
                      label: 'CONTINUE FLIGHT PATH',
                      icon: Icons.bolt_rounded,
                      onPressed: onContinueLearning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: StitchTokens.surfaceLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: StitchTokens.borderHairline),
                    ),
                    child: IconButton(
                      tooltip: 'Fluency Intelligence',
                      onPressed: onAnalyticsTap,
                      icon: const Icon(
                        Icons.insights_rounded,
                        size: 20,
                        color: StitchTokens.kineticAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Dual Cadence & Spacing Telemetry Chips
        Row(
          children: [
            Expanded(
              child: StitchGlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: StitchTokens.kineticAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: StitchTokens.kineticAmber,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STREAK CADENCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: StitchTokens.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${profile.streakDays} Days Active',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: StitchTokens.textPrimary,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StitchGlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: StitchTokens.masteryEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: StitchTokens.masteryEmerald,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RETENTION STABILITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: StitchTokens.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Text(
                          '94% SM-2 Recall',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: StitchTokens.textPrimary,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
