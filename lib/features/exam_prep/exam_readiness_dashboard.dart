import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/database_service.dart';
import 'widgets/score_band_gauge.dart';
import 'widgets/skill_breakdown_chart.dart';
import 'mock_exam_screen.dart';
import '../../shared/models/exam.dart';
import '../monetization/paywall_screen.dart';
import 'placement_test_screen.dart';
import '../../core/services/monetization_service.dart';
import '../../core/services/revenuecat_service.dart';

class ExamReadinessDashboard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final param = UserExamParam(userId, examId);
    final readinessAsync = ref.watch(userExamReadinessProvider(param));
    final attemptsAsync = ref.watch(userMockExamAttemptsProvider(param));
    final mockExamsAsync = ref.watch(mockExamsProvider(examId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Readiness'), centerTitle: true),
      body: readinessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            const Center(child: Text('Exam data is unavailable right now.')),
        data: (readiness) {
          if (readiness == null) {
            return _buildEmptyState(context, ref);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScoreBandGauge(
                  currentLevel: readiness.currentEstimatedLevel ?? 'N/A',
                  targetLevel: readiness.targetLevel ?? 'Not set',
                  // simplistic progress calculation for visual effect:
                  progress: 0.65,
                ),
                const SizedBox(height: 24),

                // Set Target Button
                OutlinedButton.icon(
                  onPressed: () => _showTargetEditor(context, ref, readiness),
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Set Target Level & Date'),
                ),
                const SizedBox(height: 32),

                // Skill Breakdown
                attemptsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      const Text('Attempt history is unavailable right now.'),
                  data: (attempts) {
                    if (attempts.isEmpty) {
                      return const Center(
                        child: Text('Take a mock exam to see skill breakdown.'),
                      );
                    }
                    final latest = attempts.first;
                    // Mock breakdown if not fully populated
                    final Map<String, double> skills = {
                      'listening':
                          latest.aiFeedback?['listening']?.toDouble() ?? 6.0,
                      'reading':
                          latest.aiFeedback?['reading']?.toDouble() ?? 6.5,
                      'writing':
                          latest.aiFeedback?['writing']?.toDouble() ?? 5.5,
                      'speaking':
                          latest.aiFeedback?['speaking']?.toDouble() ?? 6.0,
                    };

                    final isPremium =
                        ref.watch(isPremiumProvider).value ?? false;
                    final displayAttempts = isPremium
                        ? attempts
                        : attempts.take(3).toList();
                    final hasMore = !isPremium && attempts.length > 3;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SkillBreakdownChart(
                          skillScores: skills,
                          maxScore: 9.0, // Should be dynamic based on exam
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Recent Attempts',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...displayAttempts.map(
                          (a) => ListTile(
                            leading: const Icon(Icons.history),
                            title: Text('Score: ${a.overallScore ?? "N/A"}'),
                            subtitle: Text(
                              a.startedAt.toString().substring(0, 10),
                            ),
                          ),
                        ),
                        if (hasMore)
                          ListTile(
                            leading: const Icon(
                              Icons.lock,
                              color: Colors.amber,
                            ),
                            title: const Text('Unlock full history'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PaywallScreen(),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 48),

                Text(
                  'Practice Tests',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                mockExamsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      const Text('Practice tests are unavailable right now.'),
                  data: (mockExams) {
                    if (mockExams.isEmpty) {
                      return const Center(
                        child: Text('No practice tests available.'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mockExams.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final mock = mockExams[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              mock.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${mock.timeLimitMinutes} minutes • ${mock.targetLevel} target',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final mon = ref.read(
                                  monetizationServiceProvider,
                                );
                                if (await mon.canTakeMockExam()) {
                                  await mon.incrementMockExamCount();
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MockExamScreen(
                                          userId: userId,
                                          mockExamId: mock.id,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PaywallScreen(),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Start'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_ind_rounded,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'No Readiness Data',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Take a quick placement test to estimate your current level and start your exam prep journey.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final mon = ref.read(monetizationServiceProvider);
                if (await mon.canTakePlacementTest(languageCode)) {
                  await mon.incrementPlacementTestCount(languageCode);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlacementTestScreen(
                          userId: userId,
                          examId: examId,
                          languageCode: languageCode,
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
              child: const Text('Take Placement Test'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTargetEditor(
    BuildContext context,
    WidgetRef ref,
    UserExamReadiness readiness,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set Target',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Simulating an editor
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Target Level (e.g. Band 7.5, B2)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Target Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
