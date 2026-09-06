import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/services/database_service.dart';
import 'widgets/score_band_gauge.dart';
import 'widgets/skill_breakdown_chart.dart';
import 'mock_exam_screen.dart';
import '../monetization/paywall_screen.dart';
import 'placement_test_screen.dart';
import '../../core/services/monetization_service.dart';
import '../../shared/widgets/stitch_top_bar.dart';

class ExamReadinessDashboard extends ConsumerStatefulWidget {
  final String userId;
  final String examId;
  final String languageCode;

  const ExamReadinessDashboard({
    super.key,
    required this.userId,
    required this.examId,
    required this.languageCode,
  });

  @override
  ConsumerState<ExamReadinessDashboard> createState() =>
      _ExamReadinessDashboardState();
}

class _ExamReadinessDashboardState
    extends ConsumerState<ExamReadinessDashboard> {
  String _selectedExamMode = 'IELTS'; // 'IELTS' or 'CEFR'

  @override
  Widget build(BuildContext context) {
    final param = UserExamParam(widget.userId, widget.examId);
    final readinessAsync = ref.watch(userExamReadinessProvider(param));
    final attemptsAsync = ref.watch(userMockExamAttemptsProvider(param));
    final mockExamsAsync = ref.watch(mockExamsProvider(widget.examId));

    return Scaffold(
      backgroundColor: SparkTheme.bg(context),
      body: Column(
        children: [
          StitchTopBar(
            activeLanguage: widget.languageCode,
            streakDays: 21,
            totalXP: 1480,
            onLogoTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: readinessAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: SparkLingoTheme.electricCyan),
        ),
        error: (err, stack) => const Center(
          child: Text('Exam data is unavailable right now.', style: TextStyle(color: Colors.white)),
        ),
        data: (readiness) {
          final isIelts = _selectedExamMode == 'IELTS';
          final currentLevel = readiness?.currentEstimatedLevel ?? (isIelts ? 'Band 7.5' : 'CEFR C1');
          final targetLevel = readiness?.targetLevel ?? (isIelts ? 'Band 8.5' : 'CEFR C2');

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode Segmented Switcher (IELTS / CEFR)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: SparkLingoTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
                  ),
                  child: Row(
                    children: [
                      _buildModeSegment('IELTS ACADEMIC', 'IELTS'),
                      _buildModeSegment('CEFR CALIBRATION', 'CEFR'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Semi-circular Score Band Gauge
                ScoreBandGauge(
                  currentLevel: currentLevel,
                  targetLevel: targetLevel,
                  progress: 0.78,
                  score: isIelts ? 7.5 : null,
                  bandTitle: isIelts ? 'Good User · Band 7.5' : 'Effective Operational Proficiency',
                ),
                const SizedBox(height: 18),

                // Four-Pillar Rubric Breakdown
                attemptsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: SparkLingoTheme.electricCyan),
                    ),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (attempts) {
                    final Map<String, double> skills = attempts.isNotEmpty && attempts.first.aiFeedback != null
                        ? {
                            'Fluency & Coherence': attempts.first.aiFeedback?['fluency']?.toDouble() ?? 7.5,
                            'Lexical Resource': attempts.first.aiFeedback?['lexical']?.toDouble() ?? 8.0,
                            'Grammatical Range': attempts.first.aiFeedback?['grammar']?.toDouble() ?? 7.0,
                            'Pronunciation': attempts.first.aiFeedback?['pronunciation']?.toDouble() ?? 7.5,
                          }
                        : {
                            'Fluency & Coherence': 7.5,
                            'Lexical Resource': 8.0,
                            'Grammatical Range': 7.0,
                            'Pronunciation': 7.5,
                          };

                    return SkillBreakdownChart(
                      skillScores: skills,
                      maxScore: isIelts ? 9.0 : 100.0,
                    );
                  },
                ),
                const SizedBox(height: 18),

                // AI Proctor Examiner Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: SparkLingoTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: SparkLingoTheme.electricCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: SparkLingoTheme.electricCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: SparkLingoTheme.electricCyan.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.psychology_outlined, color: SparkLingoTheme.electricCyan, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'AI Examiner: Dr. Elena Vance',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Strict rubric calibration against official Cambridge & CEFR benchmarks.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Timed Mock Practice Simulations
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TIMED SIMULATIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: SparkLingoTheme.solarGold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'OFFICIAL SPECS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                mockExamsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: SparkLingoTheme.electricCyan),
                  ),
                  error: (err, stack) => const Text(
                    'Practice tests unavailable right now.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  data: (mockExams) {
                    if (mockExams.isEmpty) {
                      return _buildDefaultMockCard(context);
                    }
                    return Column(
                      children: mockExams.map((mock) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: SparkLingoTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: SparkLingoTheme.electricCyan.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.timer_outlined, color: SparkLingoTheme.electricCyan, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mock.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${mock.timeLimitMinutes} min · Target ${mock.targetLevel}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final mon = ref.read(monetizationServiceProvider);
                                  if (await mon.canTakeMockExam()) {
                                    await mon.incrementMockExamCount();
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MockExamScreen(
                                            userId: widget.userId,
                                            mockExamId: mock.id,
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SparkLingoTheme.electricCyan,
                                  foregroundColor: SparkLingoTheme.surfaceCanvas,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Placement Test CTA
                OutlinedButton.icon(
                  onPressed: () async {
                    final mon = ref.read(monetizationServiceProvider);
                    if (await mon.canTakePlacementTest(widget.languageCode)) {
                      await mon.incrementPlacementTestCount(widget.languageCode);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlacementTestScreen(
                              userId: widget.userId,
                              examId: widget.examId,
                              languageCode: widget.languageCode,
                            ),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaywallScreen()),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.assignment_turned_in_outlined, color: SparkLingoTheme.solarGold, size: 18),
                  label: const Text('Calibrate Level with Placement Test'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SparkLingoTheme.solarGold,
                    side: BorderSide(color: SparkLingoTheme.solarGold.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    ),
  ],
),
);
}

  Widget _buildModeSegment(String title, String mode) {
    final isSelected = _selectedExamMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedExamMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? SparkLingoTheme.electricCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isSelected ? SparkLingoTheme.surfaceCanvas : Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultMockCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SparkLingoTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SparkLingoTheme.electricCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.mic_external_on_outlined, color: SparkLingoTheme.electricCyan, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Full Speaking Part 1-3 Simulation',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '14 min · AI Proctor Feedback',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlacementTestScreen(
                    userId: widget.userId,
                    examId: widget.examId,
                    languageCode: widget.languageCode,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SparkLingoTheme.electricCyan,
              foregroundColor: SparkLingoTheme.surfaceCanvas,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
