import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/spaced_repetition_service.dart';
import '../../shared/widgets/landmark_painter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openAITutor(BuildContext context, String activeLanguage) {
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
                      "Hello! I am Sparky, your AI tutor.\nChoose to practice speaking and listening mock accents in ${activeLanguage.toUpperCase()}.",
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _AISpeechPracticeSession(language: activeLanguage),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                      ListTile(
                        leading: const Text("🇨🇳", style: TextStyle(fontSize: 24)),
                        title: const Text("Mandarin / 中文"),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(databaseServiceProvider).updateTargetLanguages(user.id, ['mandarin']);
                          ref.invalidate(userProfileProvider(user.id));
                        },
                      ),
                      ListTile(
                        leading: const Text("🇮🇳", style: TextStyle(fontSize: 24)),
                        title: const Text("Hindi / हिन्दी"),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(databaseServiceProvider).updateTargetLanguages(user.id, ['hindi']);
                          ref.invalidate(userProfileProvider(user.id));
                        },
                      ),
                      ListTile(
                        leading: const Text("🇷🇺", style: TextStyle(fontSize: 24)),
                        title: const Text("Russian / Русский"),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(databaseServiceProvider).updateTargetLanguages(user.id, ['russian']);
                          ref.invalidate(userProfileProvider(user.id));
                        },
                      ),
                      ListTile(
                        leading: const Text("🇲🇾", style: TextStyle(fontSize: 24)),
                        title: const Text("Malay / Bahasa Melayu"),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(databaseServiceProvider).updateTargetLanguages(user.id, ['bahasa melayu']);
                          ref.invalidate(userProfileProvider(user.id));
                        },
                      ),
                      ListTile(
                        leading: const Text("🇸🇦", style: TextStyle(fontSize: 24)),
                        title: const Text("Arabic / العربية"),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(databaseServiceProvider).updateTargetLanguages(user.id, ['arabic']);
                          ref.invalidate(userProfileProvider(user.id));
                        },
                      ),
                    ],
                  ),
                ),
              ),
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
      floatingActionButton: user == null
          ? null
          : ref.watch(userProfileProvider(user.id)).maybeWhen(
                data: (profile) {
                  if (profile == null || profile.targetLanguages.isEmpty) return null;
                  return FloatingActionButton(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.bolt),
                    onPressed: () => _openAITutor(context, profile.targetLanguages.first),
                  );
                },
                orElse: () => null,
              ),
    );
  }

  // Beautiful onboarding grid to select the target language
  Widget _buildLanguageSelector(BuildContext context, WidgetRef ref, String userId) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
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
            const SizedBox(height: 24),
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
            const SizedBox(height: 12),
            _LanguageSelectCard(
              label: "English",
              flag: "🇺🇸",
              description: "Master workplace introductions and basic airport navigation.",
              onTap: () async {
                await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['english']);
                ref.invalidate(userProfileProvider(userId));
              },
            ),
            const SizedBox(height: 12),
            _LanguageSelectCard(
              label: "French / Français",
              flag: "🇫🇷",
              description: "Practice greeting accents, ordering cafés, and basic dialogues.",
              onTap: () async {
                await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['french']);
                ref.invalidate(userProfileProvider(userId));
              },
            ),
            const SizedBox(height: 12),
            _LanguageSelectCard(
              label: "Mandarin / 中文",
              flag: "🇨🇳",
              description: "Explore core tones, greetings, and numbers.",
              onTap: () async {
                await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['mandarin']);
                ref.invalidate(userProfileProvider(userId));
              },
            ),
            const SizedBox(height: 12),
            _LanguageSelectCard(
              label: "Hindi / हिन्दी",
              flag: "🇮🇳",
              description: "Understand polite greetings and cultural phrases.",
              onTap: () async {
                await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['hindi']);
                ref.invalidate(userProfileProvider(userId));
              },
            ),
            const SizedBox(height: 12),
            _LanguageSelectCard(
              label: "Russian / Русский",
              flag: "🇷🇺",
              description: "Learn Russian alphabet basics and polite greetings.",
              onTap: () async {
                await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['russian']);
                ref.invalidate(userProfileProvider(userId));
              },
            ),
            const SizedBox(height: 12),
            _LanguageSelectCard(
              label: "Malay / Bahasa Melayu",
              flag: "🇲🇾",
              description: "Practice simple conversational Malay and vocabulary.",
              onTap: () async {
                await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['bahasa melayu']);
                ref.invalidate(userProfileProvider(userId));
              },
            ),
            const SizedBox(height: 12),
            _LanguageSelectCard(
              label: "Arabic / العربية",
              flag: "🇸🇦",
              description: "Read basic text script letters, welcomes, and greetings.",
              onTap: () async {
                await ref.read(databaseServiceProvider).updateTargetLanguages(userId, ['arabic']);
                ref.invalidate(userProfileProvider(userId));
              },
            ),
          ],
        ),
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
      case 'mandarin':
        return const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFFFD54F)], // Chinese Red and Imperial Gold
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'hindi':
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFFFFF), Color(0xFF4CAF50)], // Indian saffron, white, green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'russian':
        return const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFFD32F2F), Color(0xFF37474F)], // Russian blue and red
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'bahasa melayu':
        return const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFFFFD54F), Color(0xFFB71C1C)], // Malaysian flag colours
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'arabic':
        return const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF81C784)], // Saudi green to bright green
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
      case 'mandarin':
        return PagodaPainter(color: color);
      case 'hindi':
        return TajMahalPainter(color: color);
      case 'russian':
        return StBasilsPainter(color: color);
      case 'bahasa melayu':
        return PetronasTowersPainter(color: color);
      case 'arabic':
        return PalmAndOasisPainter(color: color);
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
                      onTap: () => _openVocabularySheet(context, lesson, langKey),
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
  void _openVocabularySheet(BuildContext context, dynamic lesson, String langKey) {
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _FlashcardStudySession(
                        title: lesson.title,
                        flashcards: lesson.flashcards,
                        languageKey: langKey,
                      ),
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

class _FlashcardStudySession extends ConsumerStatefulWidget {
  final String title;
  final List<dynamic> flashcards;
  final String languageKey;

  const _FlashcardStudySession({
    required this.title,
    required this.flashcards,
    required this.languageKey,
  });

  @override
  ConsumerState<_FlashcardStudySession> createState() => _FlashcardStudySessionState();
}

class _FlashcardStudySessionState extends ConsumerState<_FlashcardStudySession> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Map<String, SRSState> _sessionProgress = {};

  void _handleQualitySelect(int quality) {
    final card = widget.flashcards[_currentIndex];
    
    // Calculate next SM-2 interval
    final nextState = SpacedRepetitionService.calculateNextState(
      quality: quality,
      prevRepetitions: 0,
      prevEfactor: 2.5,
      prevInterval: 0,
    );
    
    _sessionProgress[card.id] = nextState;

    // Sync stats to Supabase database reactively
    final user = ref.read(authProvider);
    if (user != null) {
      ref.read(databaseServiceProvider).upsertCardReview(
        userId: user.id,
        cardId: card.id,
        languageKey: widget.languageKey,
        interval: nextState.interval,
        repetitions: nextState.repetitions,
        efactor: nextState.efactor,
        nextReview: nextState.nextReviewAt,
      ).catchError((e) {
        debugPrint("Failed to sync card review back to database: $e");
      });
    }

    setState(() {
      if (_currentIndex < widget.flashcards.length - 1) {
        _currentIndex++;
        _isFlipped = false;
      } else {
        _currentIndex = widget.flashcards.length; // completed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = _currentIndex >= widget.flashcards.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("${widget.title} — SM-2 Study"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isCompleted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
                  const SizedBox(height: 24),
                  Text(
                    "Session Completed! 🎉",
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "You reviewed ${widget.flashcards.length} cards using Spaced Repetition.",
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back to Dashboard"),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: widget.flashcards.isEmpty ? 1.0 : (_currentIndex / widget.flashcards.length),
                    backgroundColor: theme.colorScheme.primary.withAlpha(25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Card ${_currentIndex + 1} of ${widget.flashcards.length}",
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                  const Spacer(),
                  // Flashcard Container
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFlipped = !_isFlipped;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(32),
                      height: 240,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(_isFlipped ? 100 : 38),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isFlipped ? "MEANING" : "FRONT",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isFlipped
                                  ? widget.flashcards[_currentIndex].back
                                  : widget.flashcards[_currentIndex].front,
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_isFlipped && widget.flashcards[_currentIndex].context != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                widget.flashcards[_currentIndex].context!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.flip),
                      label: Text(_isFlipped ? "Show Front" : "Reveal Answer"),
                      onPressed: () {
                        setState(() {
                          _isFlipped = !_isFlipped;
                        });
                      },
                    ),
                  ),
                  const Spacer(),
                  // Quality Rating buttons
                  if (_isFlipped) ...[
                    Text(
                      "How well did you recall this card?",
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQualityButton(0, "Forgot ❌", Colors.redAccent),
                        _buildQualityButton(2, "Hard ⏳", Colors.orangeAccent),
                        _buildQualityButton(4, "Good 👍", Colors.blueAccent),
                        _buildQualityButton(5, "Easy ⭐", Colors.green),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 60),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildQualityButton(int q, String label, Color btnColor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _handleQualitySelect(q),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _AISpeechPracticeSession extends StatefulWidget {
  final String language;

  const _AISpeechPracticeSession({required this.language});

  @override
  State<_AISpeechPracticeSession> createState() => _AISpeechPracticeSessionState();
}

class _AISpeechPracticeSessionState extends State<_AISpeechPracticeSession> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _addSparkyGreeting();
  }

  void _addSparkyGreeting() {
    String greeting;
    switch (widget.language.toLowerCase()) {
      case 'spanish':
        greeting = "¡Hola! Soy Sparky, tu tutor de IA. ¿Cómo estás hoy? ¿De qué te gustaría hablar?";
        break;
      case 'french':
        greeting = "Bonjour! Je suis Sparky, ton tuteur d'IA. Comment ça va aujourd'hui? De quoi aimerais-tu parler ?";
        break;
      case 'mandarin':
        greeting = "你好！我是你的 AI 导师 Sparky。你今天怎么样？想聊点什么呢？";
        break;
      case 'hindi':
        greeting = "नमस्ते! मैं आपका एआई ट्यूटर स्पार्की हूँ। आप आज कैसे हैं? आप किस बारे में बात करना चाहेंगे?";
        break;
      case 'russian':
        greeting = "Привет! Я Спарки, твой ИИ-репетитор. Как дела сегодня? О чём ты хочешь поговорить?";
        break;
      case 'bahasa melayu':
        greeting = "Selamat pagi! Saya Sparky, tutor AI anda. Apa khabar hari ini? Anda mahu sembang tentang apa?";
        break;
      case 'arabic':
        greeting = "مرحباً! أنا سباركي، معلم الذكاء الاصطناعي الخاص بك. كيف حالك اليوم؟ ما الذي تود التحدث عنه؟";
        break;
      case 'english':
      default:
        greeting = "Hello! I am Sparky, your AI tutor. How are you doing today? What would you like to chat about?";
        break;
    }
    _messages.add({"sender": "sparky", "text": greeting});
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({"sender": "user", "text": text});
    });

    _scrollToBottom();
    _simulateSparkyResponse(text);
  }

  void _simulateVoiceInput() {
    setState(() {
      _isListening = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      String simulatedSpeech;
      switch (widget.language.toLowerCase()) {
        case 'spanish':
          simulatedSpeech = "Hola Sparky, quiero practicar mi español contigo hoy.";
          break;
        case 'french':
          simulatedSpeech = "Bonjour Sparky, je veux pratiquer mon français avec toi aujourd'hui.";
          break;
        case 'mandarin':
          simulatedSpeech = "你好 Sparky，我想今天和你练习中文。";
          break;
        case 'arabic':
          simulatedSpeech = "مرحباً سباركي، أريد ممارسة اللغة العربية اليوم.";
          break;
        case 'english':
        default:
          simulatedSpeech = "Hi Sparky, I want to practice English speaking today.";
          break;
      }

      setState(() {
        _isListening = false;
        _messages.add({"sender": "user", "text": simulatedSpeech});
      });
      _scrollToBottom();
      _simulateSparkyResponse(simulatedSpeech);
    });
  }

  void _simulateSparkyResponse(String userText) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      String response;
      
      final lowerText = userText.toLowerCase();
      switch (widget.language.toLowerCase()) {
        case 'spanish':
          if (lowerText.contains("hola")) {
            response = "¡Excelente! Me alegra mucho. Dime, ¿cómo te llamas y de dónde eres?";
          } else {
            response = "¡Muy interesante! Tu pronunciación y vocabulario en español van mejorando mucho. ¿Tienes alguna pregunta sobre verbos o palabras?";
          }
          break;
        case 'french':
          if (lowerText.contains("bonjour")) {
            response = "Merveilleux ! Commençons. Comment t'appelles-tu et quel âge as-tu ?";
          } else {
            response = "C'est fantastique ! Votre français est très naturel. Continuons à discuter. Quel est votre passe-temps préféré ?";
          }
          break;
        case 'mandarin':
          response = "很好！你的中文发音很标准。我们来聊聊你最喜欢的食物吧，你喜欢吃饺子吗？";
          break;
        case 'arabic':
          response = "رائع جداً! لغتك العربية ممتازة وتتحسن باستمرار. هل تفضل التحدث بالفصحى أم باللهجة العامية؟";
          break;
        case 'english':
        default:
          if (lowerText.contains("hello") || lowerText.contains("hi")) {
            response = "Awesome! Let's practice. What is your name and where are you calling from?";
          } else {
            response = "That sounds great! Your grammar structure looks solid. Let's talk about your hobbies. What do you do in your free time?";
          }
          break;
      }

      setState(() {
        _messages.add({"sender": "sparky", "text": response});
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.face, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            const Text("Sparky — AI Tutor"),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isSparky = msg["sender"] == "sparky";
                return Align(
                  alignment: isSparky ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isSparky
                          ? theme.cardColor
                          : theme.colorScheme.primary.withAlpha(38),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isSparky ? Radius.zero : const Radius.circular(16),
                        bottomRight: isSparky ? const Radius.circular(16) : Radius.zero,
                      ),
                      border: Border.all(
                        color: isSparky
                            ? theme.colorScheme.primary.withAlpha(25)
                            : theme.colorScheme.primary.withAlpha(51),
                      ),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isListening)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 10),
                  Text("Listening...", style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.colorScheme.primary.withAlpha(25))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.redAccent : theme.colorScheme.secondary,
                  ),
                  onPressed: _isListening ? null : _simulateVoiceInput,
                  tooltip: "Simulate Speaking voice input",
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Type your reply...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
