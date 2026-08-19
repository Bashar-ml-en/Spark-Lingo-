import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/database_service.dart';
import '../../shared/models/exam.dart';
import 'exam_readiness_dashboard.dart';

class PlacementTestScreen extends ConsumerStatefulWidget {
  final String userId;
  final String examId;
  final String languageCode;

  const PlacementTestScreen({
    super.key,
    required this.userId,
    required this.examId,
    required this.languageCode,
  });

  @override
  ConsumerState<PlacementTestScreen> createState() =>
      _PlacementTestScreenState();
}

class _PlacementTestScreenState extends ConsumerState<PlacementTestScreen> {
  int _currentQuestion = 0;
  final int _totalQuestions = 10;
  bool _isSubmitting = false;

  void _nextQuestion() {
    if (_currentQuestion < _totalQuestions - 1) {
      setState(() {
        _currentQuestion++;
      });
    } else {
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    setState(() {
      _isSubmitting = true;
    });

    final db = ref.read(databaseServiceProvider);

    // In a real app, AI service would grade the responses and determine level
    final estimatedLevel = 'Intermediate (B1)';

    final readiness = UserExamReadiness(
      userId: widget.userId,
      examId: widget.examId,
      currentEstimatedLevel: estimatedLevel,
      targetLevel: null,
      targetDate: null,
    );

    await db.upsertUserExamReadiness(readiness);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ExamReadinessDashboard(
            userId: widget.userId,
            examId: widget.examId,
            languageCode: widget.languageCode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic Test'), centerTitle: true),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Analyzing your responses...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: (_currentQuestion + 1) / _totalQuestions,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Question ${_currentQuestion + 1} of $_totalQuestions',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Which sentence is grammatically correct?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...['Option A', 'Option B', 'Option C', 'Option D'].map((
                    opt,
                  ) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: _nextQuestion,
                        child: Text(opt),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
