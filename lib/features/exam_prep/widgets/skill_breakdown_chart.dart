import 'package:flutter/material.dart';

class SkillBreakdownChart extends StatelessWidget {
  final Map<String, double>
  skillScores; // e.g. {'listening': 6.5, 'reading': 7.0}
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Breakdown',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...skillScores.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildSkillBar(context, entry.key, entry.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkillBar(BuildContext context, String skillName, double score) {
    final progress = (score / maxScore).clamp(0.0, 1.0);
    // Capitalize first letter of skill
    final formattedName = skillName.isNotEmpty
        ? '${skillName[0].toUpperCase()}${skillName.substring(1)}'
        : skillName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              score.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getColorForSkill(context, skillName),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForSkill(BuildContext context, String skill) {
    switch (skill.toLowerCase()) {
      case 'listening':
        return Colors.blue;
      case 'reading':
        return Colors.green;
      case 'writing':
        return Colors.orange;
      case 'speaking':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
