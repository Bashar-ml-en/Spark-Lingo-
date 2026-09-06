import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class SkillBreakdownChart extends StatelessWidget {
  final Map<String, double> skillScores; // e.g. {'listening': 6.5, 'reading': 7.0}
  final double maxScore; // e.g. 9.0 for IELTS, 120 for TOEFL

  const SkillBreakdownChart({
    super.key,
    required this.skillScores,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    if (skillScores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SparkLingoTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FOUR-PILLAR RUBRIC SCORES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: SparkLingoTheme.solarGold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'MAX ${maxScore.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...skillScores.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: _buildSkillBar(context, entry.key, entry.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkillBar(BuildContext context, String skillName, double score) {
    final progress = (score / maxScore).clamp(0.0, 1.0);
    final formattedName = skillName.isNotEmpty
        ? '${skillName[0].toUpperCase()}${skillName.substring(1)}'
        : skillName;
    final color = _getColorForSkill(skillName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${score.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(1)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: SparkLingoTheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getColorForSkill(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening':
      case 'fluency & coherence':
        return SparkLingoTheme.electricCyan;
      case 'reading':
      case 'lexical resource':
        return const Color(0xFF10B981); // Emerald
      case 'writing':
      case 'grammatical range':
        return SparkLingoTheme.solarGold;
      case 'speaking':
      case 'pronunciation':
        return const Color(0xFFA855F7); // Purple
      default:
        return SparkLingoTheme.electricCyan;
    }
  }
}
