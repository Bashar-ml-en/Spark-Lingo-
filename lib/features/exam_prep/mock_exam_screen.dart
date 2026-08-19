import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/database_service.dart';
import '../../shared/models/exam.dart';

class MockExamScreen extends ConsumerStatefulWidget {
  final String userId;
  final String mockExamId;

  const MockExamScreen({
    super.key,
    required this.userId,
    required this.mockExamId,
  });

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen> {
  int _currentSectionIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isExamActive = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startExam(List<MockExamSection> sections, int totalMinutes) {
    setState(() {
      _isExamActive = true;
      _secondsRemaining = totalMinutes * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _submitExam();
      }
    });
  }

  void _submitExam() {
    setState(() {
      _isExamActive = false;
    });
    // In a full implementation, gather all user answers and send to AI scoring.
    // For now, simulate submission and return.

    // final db = ref.read(databaseServiceProvider);
    // db.saveMockExamAttempt(...);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Exam Submitted'),
        content: const Text('Your answers have been submitted for scoring.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _nextSection(int totalSections) {
    if (_currentSectionIndex < totalSections - 1) {
      setState(() {
        _currentSectionIndex++;
      });
    } else {
      _timer?.cancel();
      _submitExam();
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(
      mockExamSectionsProvider(widget.mockExamId),
    );
    // Since mock_exams are fetched by examId usually, we just assume 60 mins for now or pass it.
    // Ideally we fetch the specific MockExam to get timeLimitMinutes.
    final int defaultTimeLimit = 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Exam'),
        centerTitle: true,
        automaticallyImplyLeading: !_isExamActive,
        actions: [
          if (_isExamActive)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _formatTime(_secondsRemaining),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _secondsRemaining < 300 ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: sectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(
          child: Text('Exam sections are unavailable right now.'),
        ),
        data: (sections) {
          if (sections.isEmpty) {
            return const Center(
              child: Text('No sections found for this exam.'),
            );
          }

          if (!_isExamActive) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ready to begin?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This exam has ${sections.length} sections and a time limit of $defaultTimeLimit minutes. The timer cannot be paused.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () => _startExam(sections, defaultTimeLimit),
                      child: const Text(
                        'Start Exam',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final currentSection = sections[_currentSectionIndex];
          return Column(
            children: [
              LinearProgressIndicator(
                value: (_currentSectionIndex + 1) / sections.length,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Section ${_currentSectionIndex + 1} of ${sections.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSection.skill.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionContent(currentSection),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _nextSection(sections.length),
                          child: Text(
                            _currentSectionIndex < sections.length - 1
                                ? 'Next Section'
                                : 'Submit Exam',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionContent(MockExamSection section) {
    switch (section.skill.toLowerCase()) {
      case 'reading':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                section.promptContent['passage'] ?? 'No passage provided.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Questions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Mock questions
            const TextField(
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 'listening':
        return Column(
          children: [
            const Icon(Icons.audio_file_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Audio Player Placeholder'),
            const SizedBox(height: 24),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Type your answer based on audio...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 'writing':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.promptContent['prompt'] ?? 'Write an essay...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            const TextField(
              maxLines: 15,
              decoration: InputDecoration(
                hintText: 'Start typing your response here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 'speaking':
        return Column(
          children: [
            Text(
              section.promptContent['prompt'] ?? 'Speak about...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FloatingActionButton.large(
              onPressed: () {},
              child: const Icon(Icons.mic),
            ),
            const SizedBox(height: 16),
            const Text('Tap to record your response'),
          ],
        );
      default:
        return const Text('Unknown skill type.');
    }
  }
}
