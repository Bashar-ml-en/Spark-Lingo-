import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../shared/models/curriculum.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/models/language_theme.dart';
import '../../shared/widgets/language_symbol_badge.dart';
import '../../shared/widgets/phase_sidebar.dart';
import 'curriculum_path.dart';
import 'home_drawer.dart';
import 'home_sheets.dart';
import 'sparky_chat_session.dart';
import 'vocabulary_sheets.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _curriculumScrollController = ScrollController();
  final List<GlobalKey> _unitKeys = [];
  int _selectedUnitIndex = 0;

  @override
  void dispose() {
    _curriculumScrollController.dispose();
    super.dispose();
  }

  /// Jumps the curriculum list to a phase chosen from the sidebar.
  void _scrollToUnit(int index) {
    setState(() => _selectedUnitIndex = index);
    final target = index < _unitKeys.length
        ? _unitKeys[index].currentContext
        : null;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    }
  }

  /// End drawer carrying the learning-path sidebar for compact layouts.
  /// Returns null when there is nothing to show, so no empty panel renders.
  Widget? _buildPhaseEndDrawer(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) return null;
    final profileState = ref.watch(userProfileProvider(user.id));
    final profile = profileState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    if (profile == null || profile.targetLanguages.isEmpty) return null;
    final routeCode = LanguageCatalog.tryCanonicalCode(
      GoRouterState.of(context).pathParameters['langCode'],
    );
    final lang = profile.targetLanguages.contains(routeCode)
        ? routeCode!
        : (profile.activeLanguage ?? profile.targetLanguages.first);
    final units = ref.watch(unitsProvider(lang)).maybeWhen(
      data: (value) => value,
      orElse: () => <Unit>[],
    );
    if (units.isEmpty) return null;
    return Drawer(
      child: PhaseSidebar.drawerBody(
        scaffoldContext: context,
        langCode: lang,
        units: units,
        selectedUnitIndex: _selectedUnitIndex,
        onUnitSelected: _scrollToUnit,
        onLessonSelected: _openLessonFromSidebar,
      ),
    );
  }

  /// Opens a lesson chosen from the learning-path sidebar using the same
  /// practice sheets as the inline curriculum list.
  void _openLessonFromSidebar(int unitIndex, Lesson lesson) {
    _scrollToUnit(unitIndex);
    if (lesson.type == 'ai_tutor_session' ||
        lesson.type == 'mock_exam_section') {
      _openSpeechPracticeSession(context, ref, lesson, _currentLanguageCode());
    } else {
      _openVocabularySheet(context, lesson, _currentLanguageCode());
    }
  }

  /// Resolves the active language code exactly like build() does.
  String _currentLanguageCode() {
    final routeCode = LanguageCatalog.tryCanonicalCode(
      GoRouterState.of(context).pathParameters['langCode'],
    );
    final user = ref.read(authProvider);
    if (routeCode != null) return routeCode;
    if (user == null) return 'en';
    final profile = ref.read(userProfileProvider(user.id)).maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    return profile?.activeLanguage ??
        (profile?.targetLanguages.isNotEmpty == true
            ? profile!.targetLanguages.first
            : 'en');
  }

  void _openAITutor(BuildContext context, String activeLanguage) {
    showAITutorSheet(context, activeLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);

    final profileAsync = user != null
        ? ref.watch(userProfileProvider(user.id))
        : null;

    // Resolve active language with route parameter and profile fallback
    final routeLangCode = GoRouterState.of(context).pathParameters['langCode'];
    String? activeLanguage = LanguageCatalog.tryCanonicalCode(routeLangCode);
    if (activeLanguage == null && profileAsync != null) {
      activeLanguage = profileAsync.maybeWhen(
        data: (profile) =>
            profile?.activeLanguage ??
            (profile?.targetLanguages.isNotEmpty == true
                ? profile!.targetLanguages.first
                : null),
        orElse: () => null,
      );
    }

    final activeTheme = activeLanguage != null
        ? LanguageThemeRegistry.themeFor(activeLanguage)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Pure white as requested
      drawer: user == null
          ? null
          : ref
                .watch(userProfileProvider(user.id))
                .maybeWhen(
                  data: (profile) {
                    if (profile == null) return null;
      return buildHomeDrawer(
        context: context,
        ref: ref,
        userId: user.id,
        activeLanguage: activeLanguage,
        profile: profile,
        onOpenLanguageSwitcher: _openLanguageSwitcher,
      );
                  },
                  orElse: () => null,
                ),
      endDrawer: user == null ? null : _buildPhaseEndDrawer(context),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom Sleek Flat Header
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    border: Border(
                      bottom: BorderSide(
                        color: activeTheme != null
                            ? activeTheme.primaryColor.withValues(alpha: 0.08)
                            : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Large subtle motif background asset
                      if (activeTheme != null &&
                          activeTheme.motifAsset.isNotEmpty)
                        PositionedDirectional(
                          end: -30,
                          top: -30,
                          child: Opacity(
                            opacity: 0.05,
                            child: SvgPicture.asset(
                              activeTheme.motifAsset,
                              width: 140,
                              height: 140,
                              colorFilter: ColorFilter.mode(
                                activeTheme.primaryColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(
                                    Icons.menu,
                                    color: Colors.black87,
                                  ),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Spark Lingo",
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontFamily:
                                          activeTheme?.fontFamily == 'Inter'
                                          ? null
                                          : activeTheme?.fontFamily,
                                    ),
                                  ),
                                  if (activeLanguage != null &&
                                      profileAsync != null)
                                    profileAsync.maybeWhen(
                                      data: (profile) {
                                        if (profile == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                start: 8.0,
                                              ),
                                          child: GestureDetector(
                                            onTap: () => _openLanguageSwitcher(
                                              context,
                                              ref,
                                              profile.id,
                                            ),
                                            child: LanguageSymbolBadge(
                                              langCode: activeLanguage!,
                                            ),
                                          ),
                                        );
                                      },
                                      orElse: () => const SizedBox.shrink(),
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.black87,
                                ),
                                onPressed: () async => await ref
                                    .read(authProvider.notifier)
                                    .signOut(),
                              ),
                              // Learning-path sidebar drawer (compact layouts;
                              // wide layouts pin the sidebar permanently).
                              if (profileAsync != null &&
                                  MediaQuery.of(context).size.width < 900)
                                profileAsync.maybeWhen(
                                  data: (profile) {
                                    if (profile == null ||
                                        profile.targetLanguages.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Builder(
                                      builder: (scaffoldContext) => IconButton(
                                        tooltip: 'Learning path',
                                        icon: const Icon(
                                          Icons.format_list_numbered,
                                          color: Colors.black87,
                                        ),
                                        onPressed: () => Scaffold.of(
                                          scaffoldContext,
                                        ).openEndDrawer(),
                                      ),
                                    );
                                  },
                                  orElse: () => const SizedBox.shrink(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ref
                      .watch(userProfileProvider(user.id))
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => const Center(
                          child: Text(
                            'We could not load your profile. Please retry.',
                          ),
                        ),
                        data: (profile) {
                          if (profile == null) {
                            return const Center(
                              child: Text("Profile data not found."),
                            );
                          }
                          if (profile.targetLanguages.isEmpty) {
                            return _buildLanguageSelector(
                              context,
                              ref,
                              profile.id,
                            );
                          }

                          // Route param or profile fallback
                          final requestedLanguage =
                              LanguageCatalog.tryCanonicalCode(
                                GoRouterState.of(
                                  context,
                                ).pathParameters['langCode'],
                              );
                          final activeLanguage =
                              profile.targetLanguages.contains(
                                requestedLanguage,
                              )
                              ? requestedLanguage!
                              : (profile.activeLanguage ??
                                    profile.targetLanguages.first);

                          return ref
                              .watch(unitsProvider(activeLanguage))
                              .when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (err, stack) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Lessons are unavailable right now.',
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton.icon(
                                        onPressed: () => ref.invalidate(
                                          unitsProvider(activeLanguage),
                                        ),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                                data: (units) {
                                  if (units.isEmpty) {
                                    return _buildEmptyState(
                                      context,
                                      ref,
                                      activeTheme,
                                      activeLanguage,
                                    );
                                  }
                                  final wide =
                                      MediaQuery.of(context).size.width >= 900;
                                  final curriculum = CurriculumPath(
                                    userId: profile.id,
                                    units: units,
                                    langKey: activeLanguage,
                                    scrollController: _curriculumScrollController,
                                    unitKeys: _unitKeys,
                                    onOpenSpeechSession: (lesson, langKey) =>
                                        _openSpeechPracticeSession(
                                          context,
                                          ref,
                                          lesson,
                                          langKey,
                                        ),
                                    onOpenVocabularySheet: (lesson, langKey) =>
                                        _openVocabularySheet(
                                          context,
                                          lesson,
                                          langKey,
                                        ),
                                  );
                                  if (!wide) return curriculum;
                                  // Wide layouts pin the learning-path sidebar
                                  // beside the curriculum content.
                                  return Row(
                                    children: [
                                      PhaseSidebar(
                                        langCode: activeLanguage,
                                        units: units,
                                        selectedUnitIndex: _selectedUnitIndex,
                                        onUnitSelected: _scrollToUnit,
                                        onLessonSelected: _openLessonFromSidebar,
                                      ),
                                      VerticalDivider(
                                        width: 1,
                                        thickness: 1,
                                        color: activeTheme?.primaryColor
                                                .withValues(alpha: 0.12) ??
                                            const Color(0xFFE5E7EB),
                                      ),
                                      Expanded(child: curriculum),
                                    ],
                                  );
                                },
                              );
                        },
                      ),
                ),
              ],
            ),
      floatingActionButton: user == null
          ? null
          : ref
                .watch(userProfileProvider(user.id))
                .maybeWhen(
                  data: (profile) {
                    if (profile == null || profile.targetLanguages.isEmpty) {
                      return null;
                    }
                    return FloatingActionButton(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.bolt),
                      onPressed: () {
                        final requestedLanguage =
                            LanguageCatalog.tryCanonicalCode(
                              GoRouterState.of(
                                context,
                              ).pathParameters['langCode'],
                            );
                        final activeLanguage =
                            profile.targetLanguages.contains(requestedLanguage)
                            ? requestedLanguage!
                            : (profile.activeLanguage ??
                                  profile.targetLanguages.first);
                        _openAITutor(context, activeLanguage);
                      },
                    );
                  },
                  orElse: () => null,
                ),
    );
  }

  // Beautiful onboarding grid to select the target language
  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    return buildLanguageSelector(context, ref, userId);
  }

  void _openSpeechPracticeSession(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
    String langKey,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: SparkyChatSession(language: langKey, lesson: lesson),
          ),
        );
      },
    );
  }

  // Sheet showing list of study flashcards
  void _openVocabularySheet(
    BuildContext context,
    dynamic lesson,
    String langKey,
  ) {
    showVocabularySheet(context, lesson, langKey);
  }

  void _openLanguageSwitcher(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    showLanguageSwitcher(context, ref, userId);
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    LanguageTheme? theme,
    String langCode,
  ) {
    return buildHomeEmptyState(context, ref, theme, langCode, _openLanguageSwitcher);
  }
}
