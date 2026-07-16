import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../shared/widgets/landmark_painter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openAITutor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(51),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(51),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.face,
                    color: theme.colorScheme.secondary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Sparky — AI Tutor",
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      "Hello! I am Sparky, your AI tutor.\nChoose a target language to start practicing real-time conversations.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text("Start Practice Session"),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("AI Speech practice mode initialization..."),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Spark Lingo",
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Sign Out",
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
              },
            ),
        ],
      ),
      drawer: user == null ? null : Drawer(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(bottom: BorderSide(color: theme.colorScheme.primary.withAlpha(25))),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language, size: 40, color: theme.colorScheme.secondary),
                      const SizedBox(height: 12),
                      Text(
                        "Spark Lingo Goals",
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Text("🇪🇸", style: TextStyle(fontSize: 24)),
                title: const Text("Spanish / Español"),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(databaseServiceProvider).updateTargetLanguages(user.id, ['spanish']);
                  ref.invalidate(userProfileProvider(user.id));
                },
              ),
              ListTile(
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
                title: const Text("English"),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(databaseServiceProvider).updateTargetLanguages(user.id, ['english']);
                  ref.invalidate(userProfileProvider(user.id));
                },
              ),
              ListTile(
                leading: const Text("🇫🇷", style: TextStyle(fontSize: 24)),
                title: const Text("French / Français"),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(databaseServiceProvider).updateTargetLanguages(user.id, ['french']);
                  ref.invalidate(userProfileProvider(user.id));
                },
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text("Reset Goal"),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(databaseServiceProvider).updateTargetLanguages(user.id, []);
                  ref.invalidate(userProfileProvider(user.id));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ref.watch(userProfileProvider(user.id)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Error: $err")),
                data: (profile) {
                  if (profile == null) {
                    return const Center(child: Text("Profile data not found."));
                  }

                  // 1. If user hasn't selected a target language, show selection UI
                  if (profile.targetLanguages.isEmpty) {
                    return _buildLanguageSelector(context, ref, profile.id);
                  }

                  // 2. Load active target language syllabus
                  final activeLanguage = profile.targetLanguages.first;
                  return ref.watch(languageSyllabusProvider(activeLanguage)).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Text("Syllabus Error: $err")),
                        data: (syllabus) {
                          if (syllabus == null) {
                            return const Center(child: Text("Syllabus not found."));
                          }
                          return _buildCurriculumPath(context, ref, profile.id, syllabus);
                        },
                      );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.bolt),
        onPressed: () => _openAITutor(context),
      ),
    );
  }

  // Beautiful onboarding grid to select the target language
  Widget _buildLanguageSelector(BuildContext context, WidgetRef ref, String userId) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "What language would you like to learn today?",
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Select your primary learning goal. You can change this later.",
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Language selection cards list
          _LanguageSelectCard(
            label: "Spanish / Español",
            flag: "🇪🇸",
            description: "Study basic expressions, travel survival tools, and syntax.",
            onTap: () async {
              await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['spanish']);
              ref.invalidate(userProfileProvider(userId));
            },
          ),
          const SizedBox(height: 16),
          _LanguageSelectCard(
            label: "English",
            flag: "🇺🇸",
            description: "Master workplace introductions and basic airport navigation.",
            onTap: () async {
              await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['english']);
              ref.invalidate(userProfileProvider(userId));
            },
          ),
          const SizedBox(height: 16),
          _LanguageSelectCard(
            label: "French / Français",
            flag: "🇫🇷",
            description: "Practice greeting accents, ordering cafés, and basic dialogues.",
            onTap: () async {
              await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['french']);
              ref.invalidate(userProfileProvider(userId));
            },
          ),
        ],
      ),
    );
  }

  // Get active country accent gradient
  LinearGradient _getCountryGradient(String langName) {
    switch (langName.toLowerCase()) {
      case 'spanish':
        return const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFFF8C00)], // Spanish crimson to gold
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'french':
        return const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFFB71C1C)], // French tricolour gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'english':
      default:
        return const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)], // Deep royal navy gradients
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  // Get active CustomPainter for target country landmark
  CustomPainter _getLandmarkPainter(String langName, Color color) {
    switch (langName.toLowerCase()) {
      case 'spanish':
        return SagradaFamiliaPainter(color: color);
      case 'french':
        return EiffelTowerPainter(color: color);
      case 'english':
      default:
        return BigBenPainter(color: color);
    }
  }

  // Renders the structured learning path
  Widget _buildCurriculumPath(BuildContext context, WidgetRef ref, String userId, dynamic syllabus) {
    final theme = Theme.of(context);
    final langKey = syllabus.languageName.toLowerCase();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: syllabus.units.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Display Active Target Language Header with dynamic landmark in left corner
          return Container(
            margin: const EdgeInsets.only(bottom: 24.0),
            decoration: BoxDecoration(
              gradient: _getCountryGradient(langKey),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top-right Change Goal button
                Positioned(
                  top: 12,
                  right: 12,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withAlpha(38),
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text("Change"),
                    onPressed: () async {
                      await ref.read(databaseServiceProvider).updateTargetLanguages(userId, []);
                      ref.invalidate(userProfileProvider(userId));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      // Landmark in Left Corner
                      SizedBox(
                        width: 90,
                        height: 120,
                        child: CustomPaint(
                          painter: _getLandmarkPainter(langKey, Colors.white.withAlpha(204)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Core Course Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "GOAL: ${syllabus.languageName.toUpperCase()}",
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Level A1 Breakthrough",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Explore units, lessons, and Spaced Repetition cards below.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withAlpha(204),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final unit = syllabus.units[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary.withAlpha(25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(unit.title, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(unit.description, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                // Render lessons list
                ...unit.lessons.map<Widget>((lesson) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: () => _openVocabularySheet(context, lesson),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor.withAlpha(127),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.primary.withAlpha(15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lesson.description,
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.secondary),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Sheet showing list of study flashcards
  void _openVocabularySheet(BuildContext context, dynamic lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(51)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(51),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                lesson.title,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                "Vocabulary review session (${lesson.flashcards.length} cards)",
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: lesson.flashcards.length,
                  itemBuilder: (context, idx) {
                    final card = lesson.flashcards[idx];
                    return Card(
                      color: theme.cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(card.front, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.back, style: theme.textTheme.bodyMedium),
                            if (card.context != null) ...[
                              const SizedBox(height: 4),
                              Text(card.context!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.school),
                label: const Text("Study Spaced Repetition"),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("SM-2 flashcard study mode starting...")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageSelectCard extends StatelessWidget {
  final String label;
  final String flag;
  final String description;
  final VoidCallback onTap;

  const _LanguageSelectCard({
    required this.label,
    required this.flag,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withAlpha(38)),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16),
          ],
        ),
      ),
    );
  }
}
