import 'package:flutter/material.dart';

class AIScoreDisclaimer extends StatelessWidget {
  final String? customDisclaimer;

  const AIScoreDisclaimer({super.key, this.customDisclaimer});

  @override
  Widget build(BuildContext context) {
    final text =
        customDisclaimer ??
        "AI-scored practice estimate — not an official exam result. Useful for tracking trends, not for visa or university submission.";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber 50
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFD97706), // Amber 600
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF92400E), // Amber 800
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
