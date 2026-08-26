import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/router/router.dart';
import '../../core/services/database_service.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/models/curriculum.dart';
import '../../shared/widgets/landmark_painter.dart';
import '../exam_prep/exam_picker_screen.dart';

/// The structured learning path for the active language: goal header with the
/// national landmark, national-symbol watermark, and the unit/lesson list.
///
/// The parent owns [scrollController] and [unitKeys] so the phase sidebar can
/// scroll to each unit from outside this widget.
class CurriculumPath extends ConsumerWidget {
  final String userId;
  final List<Unit> units;
  final String langKey;
  final ScrollController scrollController;
  final List<GlobalKey> unitKeys;
  final void Function(Lesson lesson, String langKey) onOpenSpeechSession;
  final void Function(Lesson lesson, String langKey) onOpenVocabularySheet;

  const CurriculumPath({
    super.key,
    required this.userId,
    required this.units,
    required this.langKey,
    required this.scrollController,
    required this.unitKeys,
    required this.onOpenSpeechSession,
    required this.onOpenVocabularySheet,
  });

  // Get active country accent gradient
  LinearGradient _getCountryGradient(String language) {
    switch (LanguageCatalog.canonicalCode(language)) {
      case 'es':
        return const LinearGradient(
          colors: [
            Color(0xFF8B0000),
            Color(0xFFFF8C00),
          ], // Spanish crimson to gold
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'fr':
        return const LinearGradient(
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFFB71C1C),
          ], // French tricolour gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'zh':
        return const LinearGradient(
          colors: [
            Color(0xFFB71C1C),
            Color(0xFFFFD54F),
          ], // Chinese Red and Imperial Gold
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'hi':
        return const LinearGradient(
          colors: [
            Color(0xFFFF9800),
            Color(0xFFFFFFFF),
            Color(0xFF4CAF50),
          ], // Indian saffron, white, green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ru':
        return const LinearGradient(
          colors: [
            Color(0xFF1E88E5),
            Color(0xFFD32F2F),
            Color(0xFF37474F),
          ], // Russian blue and red
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ms':
        return const LinearGradient(
          colors: [
            Color(0xFF0D47A1),
            Color(0xFFFFD54F),
            Color(0xFFB71C1C),
          ], // Malaysian flag colours
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ar':
        return const LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF81C784),
          ], // Saudi green to bright green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'en':
      default:
        return const LinearGradient(
          colors: [
            Color(0xFF1A237E),
            Color(0xFF0D47A1),
          ], // Deep royal navy gradients
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  // Get active CustomPainter for target country landmark
  CustomPainter _getLandmarkPainter(String language, Color color) {
    switch (LanguageCatalog.canonicalCode(language)) {
      case 'es':
        return SagradaFamiliaPainter(color: color);
      case 'fr':
        return EiffelTowerPainter(color: color);
      case 'zh':
        return PagodaPainter(color: color);
      case 'hi':
        return TajMahalPainter(color: color);
      case 'ru':
        return StBasilsPainter(color: color);
      case 'ms':
        return PetronasTowersPainter(color: color);
      case 'ar':
        return PalmAndOasisPainter(color: color);
      case 'en':
      default:
        return BigBenPainter(color: color);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final billingReady =
        ref.watch(billingAccessProvider).value == BillingAccessState.ready;

    // Keep one stable key per unit so the sidebar can scroll to each phase.
    while (unitKeys.length < units.length) {
      unitKeys.add(GlobalKey());
    }

    final curriculumTheme = LanguageThemeRegistry.themeFor(langKey);
    return Stack(
      children: [
        // National-symbol watermark behind the learning path.
        Positioned.fill(
          child: Center(
            child: SvgPicture.asset(
              curriculumTheme.motifAsset,
              width: 460,
              height: 460,
              colorFilter: ColorFilter.mode(
                curriculumTheme.primaryColor.withValues(alpha: 0.06),
                BlendMode.srcIn,
              ),
              placeholderBuilder: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
        ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          itemCount: units.length + 1,
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
                PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withAlpha(38),
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text("Change"),
                    onPressed: () async {
                      await ref
                          .read(databaseServiceProvider)
                          .updateTargetLanguages(userId, []);
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
                          painter: _getLandmarkPainter(
                            langKey,
                            theme.colorScheme.onSurface.withAlpha(204),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Core Course Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GOAL: ${LanguageCatalog.displayName(langKey)}',
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 24,
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  25,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Beginner pathway",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Explore units, lessons, and Spaced Repetition cards below.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  204,
                                ),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ExamPickerScreen(
                                      userId: userId,
                                      languageCode: langKey,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.school),
                              label: const Text('Exam preparation (preview)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                foregroundColor:
                                    theme.colorScheme.onPrimaryContainer,
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

        final unit = units[index - 1];
        return Consumer(
          key: unitKeys[index - 1],
          builder: (context, ref, _) {
            final progressAsync = ref.watch(
              lessonProgressProvider(CardReviewsParam(userId, langKey)),
            );
            final progressMap = progressAsync.value ?? const <String, int>{};

            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.primary.withAlpha(25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(unit.title, style: theme.textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                unit.description,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        // Unit completion ring: completed lessons in this
                        // unit vs. total (computed from live lesson data).
                        _UnitProgressRing(
                          unit: unit,
                          progressMap: progressMap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    // Render lessons list fetched from Supabase
                    Consumer(
                      builder: (context, ref, child) {
                        final lessonsAsync = ref.watch(lessonsProvider(unit.id));
                        return lessonsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text('Lessons are unavailable right now.'),
                              ),
                              IconButton(
                                tooltip: 'Retry',
                                onPressed: () =>
                                    ref.invalidate(lessonsProvider(unit.id)),
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          data: (lessons) {
                            return Column(
                              children: lessons.map((lesson) {
                                final isCompleted =
                                    progressMap.containsKey(lesson.id);
                                final attempts = progressMap[lesson.id] ?? 0;
                                final isAiLesson =
                                    lesson.type == 'ai_tutor_session' ||
                                    lesson.type == 'mock_exam_section';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      if ((index - 1) > 0 &&
                                          billingReady &&
                                          !isPremium) {
                                        context.push(SparkRouter.paywall);
                                      } else if (isAiLesson) {
                                        onOpenSpeechSession(lesson, langKey);
                                      } else {
                                        onOpenVocabularySheet(lesson, langKey);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? SparkStatus.success
                                                .withValues(alpha: 0.07)
                                            : theme.scaffoldBackgroundColor
                                                .withAlpha(127),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isCompleted
                                              ? SparkStatus.success
                                                  .withValues(alpha: 0.35)
                                              : theme.colorScheme.primary
                                                  .withAlpha(15),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Lesson type indicator.
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: isCompleted
                                                  ? SparkStatus.success
                                                      .withValues(alpha: 0.15)
                                                  : theme.colorScheme.primary
                                                      .withValues(alpha: 0.10),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isCompleted
                                                  ? Icons.check_circle
                                                  : isAiLesson
                                                      ? Icons.mic_outlined
                                                      : Icons.style_outlined,
                                              size: 20,
                                              color: isCompleted
                                                  ? SparkStatus.success
                                                  : theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lesson.title,
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  lesson.description,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(fontSize: 12),
                                                ),
                                                if (isCompleted && attempts > 1)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 2,
                                                        ),
                                                    child: Text(
                                                      'Completed $attempts times',
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                            fontSize: 11,
                                                            color: SparkStatus
                                                                .success,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: isCompleted
                                                ? SparkStatus.success
                                                : theme.colorScheme.secondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
        ),
      ],
    );
  }
}

/// Compact completion ring for a unit header: completed lessons over total.
class _UnitProgressRing extends ConsumerWidget {
  final Unit unit;
  final Map<String, int> progressMap;

  const _UnitProgressRing({
    required this.unit,
    required this.progressMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider(unit.id));
    return lessonsAsync.maybeWhen(
      data: (lessons) {
        final total = lessons.length;
        if (total == 0) return const SizedBox.shrink();
        final lessonIds = lessons.map((l) => l.id).toSet();
        final completed =
            progressMap.keys.where(lessonIds.contains).length;
        return SparkGoalRing(
          progress: completed / total,
          centerLabel: '$completed/$total',
          size: 44,
          strokeWidth: 5,
          color: completed == total
              ? SparkStatus.success
              : Theme.of(context).colorScheme.primary,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
