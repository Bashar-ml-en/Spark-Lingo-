import 'package:flutter/material.dart';

/// The previous exam flow manufactured placement levels and mock submissions.
/// Keep the entry point visible but explicitly unavailable until validated exam
/// content, scoring, and disclosure requirements are implemented end-to-end.
class ExamPickerScreen extends StatelessWidget {
  final String userId;
  final String languageCode;

  const ExamPickerScreen({
    super.key,
    required this.userId,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam preparation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Exam preparation is not available in this release',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Official exam mappings, validated placement tests, timed mock exams, and readiness scores are still being built. Current lessons and AI feedback are learning aids, not certification results.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('Back to learning'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
