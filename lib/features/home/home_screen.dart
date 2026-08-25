import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart' as rec;
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/router/router.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/spaced_repetition_service.dart';
import '../../shared/widgets/landmark_painter.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/consent_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/test_consent_service.dart';
import '../../shared/models/curriculum.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/models/language_theme.dart';
import '../../shared/widgets/flag_grid.dart';
import '../../shared/widgets/language_symbol_badge.dart';
import '../../shared/widgets/ai_score_disclaimer.dart';
import '../../shared/widgets/consent_request_dialog.dart';
import '../../shared/widgets/phase_sidebar.dart';
import '../exam_prep/exam_picker_screen.dart';
import '../monetization/paywall_screen.dart';

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
            border: Border.all(color: theme.colorScheme.primary.withAlpha(51)),
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
                  Text("Sparky — AI Tutor", style: theme.textTheme.titleLarge),
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
                      "Hello! I am Sparky, your AI tutor.\nPractice speaking and listening in ${LanguageCatalog.displayName(activeLanguage)}.",
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
                      builder: (context) =>
                          _AISpeechPracticeSession(language: activeLanguage),
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

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final confirmationController = TextEditingController();
    var isDeleting = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('Delete your account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your Spark Lingo account and in-app learning data. It does not cancel App Store or Google Play subscriptions, and other providers may retain data under their own policies.',
              ),
              const SizedBox(height: 16),
              const Text('Type DELETE to confirm.'),
              const SizedBox(height: 8),
              TextField(
                controller: confirmationController,
                enabled: !isDeleting,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Confirmation',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: isDeleting || confirmationController.text != 'DELETE'
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        final deleted = await ref
                            .read(databaseServiceProvider)
                            .deleteCurrentAccount();
                        if (!deleted) {
                          throw StateError(
                            'Account deletion was not confirmed.',
                          );
                        }

                        ref.read(localActiveLanguageProvider.notifier).state =
                            null;
                        try {
                          await ref.read(authProvider.notifier).signOut();
                        } catch (_) {
                          // The server may invalidate the session as part of
                          // deletion. Navigation still follows confirmed delete.
                        }

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (context.mounted) {
                          context.go(SparkRouter.welcome);
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() => isDeleting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'We could not delete your account. Please try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete account'),
            ),
          ],
        ),
      ),
    ).whenComplete(confirmationController.dispose);
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
                    return Drawer(
                      child: Container(
                        color: const Color(0xFFFFFFFF),
                        child: Column(
                          children: [
                            DrawerHeader(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                border: Border(
                                  bottom: BorderSide(
                                    color: theme.colorScheme.primary.withAlpha(
                                      15,
                                    ),
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.language,
                                      size: 40,
                                      color: theme.colorScheme.secondary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Spark Lingo",
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  const Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      start: 16,
                                      top: 16,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      "My Languages",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9CA3AF),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  ...profile.targetLanguages.map((code) {
                                    final langTheme =
                                        LanguageThemeRegistry.themeFor(code);
                                    final isActive = code == activeLanguage;
                                    return ListTile(
                                      leading: Container(
                                        width: 32,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: SvgPicture.asset(
                                          langTheme.flags.isNotEmpty
                                              ? langTheme.flags.first.flagAsset
                                              : 'assets/flags/en_us.svg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      title: Text(
                                        langTheme.displayName,
                                        style: TextStyle(
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isActive
                                              ? theme.colorScheme.primary
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      trailing: isActive
                                          ? Icon(
                                              Icons.check_circle,
                                              color: theme.colorScheme.primary,
                                              size: 20,
                                            )
                                          : null,
                                      onTap: () async {
                                        Navigator.pop(context);
                                        ref
                                                .read(
                                                  localActiveLanguageProvider
                                                      .notifier,
                                                )
                                                .state =
                                            code;
                                        await ref
                                            .read(databaseServiceProvider)
                                            .updateActiveLanguage(
                                              user.id,
                                              code,
                                            );
                                        ref.invalidate(
                                          userProfileProvider(user.id),
                                        );
                                        if (context.mounted) {
                                          context.go('/home/$code');
                                        }
                                      },
                                    );
                                  }),
                                  const Divider(
                                    color: Color(0xFFF3F4F6),
                                    height: 24,
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.add,
                                      color: Color(0xFF4B5563),
                                    ),
                                    title: const Text(
                                      "Add a Language",
                                      style: TextStyle(
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _openLanguageSwitcher(
                                        context,
                                        ref,
                                        user.id,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Consumer(
                              builder: (context, ref, child) {
                                final isPremium =
                                    ref.watch(isPremiumProvider).value ?? false;
                                return ListTile(
                                  leading: Icon(
                                    Icons.workspace_premium,
                                    color: isPremium
                                        ? Colors.amber.shade600
                                        : const Color(0xFF9CA3AF),
                                  ),
                                  title: Text(
                                    isPremium
                                        ? "Spark Premium Active"
                                        : "Upgrade to Premium",
                                    style: TextStyle(
                                      color: isPremium
                                          ? Colors.amber.shade700
                                          : const Color(0xFF9CA3AF),
                                      fontWeight: isPremium
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PaywallScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.settings_outlined,
                                color: Color(0xFF4B5563),
                              ),
                              title: const Text(
                                'Settings & help',
                                style: TextStyle(color: Color(0xFF4B5563)),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                context.push(SparkRouter.settings);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.refresh,
                                color: Color(0xFF9CA3AF),
                              ),
                              title: const Text(
                                "Reset Active Languages",
                                style: TextStyle(color: Color(0xFF9CA3AF)),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                ref
                                        .read(
                                          localActiveLanguageProvider.notifier,
                                        )
                                        .state =
                                    null;
                                await ref
                                    .read(databaseServiceProvider)
                                    .updateTargetLanguages(user.id, []);
                                ref.invalidate(userProfileProvider(user.id));
                                if (context.mounted) {
                                  context.go(SparkRouter.selectLanguage);
                                }
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              title: Text(
                                'Delete account',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showDeleteAccountDialog(context, ref);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
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
                                  final curriculum = _buildCurriculumPath(
                                    context,
                                    ref,
                                    profile.id,
                                    units,
                                    activeLanguage,
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
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Choose a language with lessons available in this release.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FlagGrid(
              onLanguageSelected: (langCode, _) async {
                final code = LanguageCatalog.canonicalCode(langCode);
                final previous = ref.read(localActiveLanguageProvider);
                ref.read(localActiveLanguageProvider.notifier).state = code;
                try {
                  await ref.read(databaseServiceProvider).updateTargetLanguages(
                    userId,
                    [code],
                  );
                  ref.invalidate(userProfileProvider(userId));
                  if (context.mounted) context.go('/home/$code');
                } catch (_) {
                  ref.read(localActiveLanguageProvider.notifier).state =
                      previous;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'We could not save your language choice. Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

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

  // Renders the structured learning path
  Widget _buildCurriculumPath(
    BuildContext context,
    WidgetRef ref,
    String userId,
    List<Unit> units,
    String langKey,
  ) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final billingReady =
        ref.watch(billingAccessProvider).value == BillingAccessState.ready;

    // Keep one stable key per unit so the sidebar can scroll to each phase.
    while (_unitKeys.length < units.length) {
      _unitKeys.add(GlobalKey());
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
          controller: _curriculumScrollController,
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
        return Card(
          key: _unitKeys[index - 1],
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
                                  } else if (lesson.type ==
                                          'ai_tutor_session' ||
                                      lesson.type == 'mock_exam_section') {
                                    _openSpeechPracticeSession(
                                      context,
                                      ref,
                                      lesson,
                                      langKey,
                                    );
                                  } else {
                                    _openVocabularySheet(
                                      context,
                                      lesson,
                                      langKey,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor
                                        .withAlpha(127),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withAlpha(15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lesson.title,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lesson.description,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: theme.colorScheme.secondary,
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
        ),
      ],
    );
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
            child: _AISpeechPracticeSession(language: langKey, lesson: lesson),
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
              Text(lesson.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final flashcardsAsync = ref.watch(
                      flashcardsProvider(lesson.id),
                    );
                    return flashcardsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const Center(
                        child: Text('Cards are unavailable right now.'),
                      ),
                      data: (flashcards) {
                        final user = ref.read(authProvider);
                        final reviews = user == null
                            ? <String, SRSState>{}
                            : ref
                                      .watch(
                                        cardReviewsProvider(
                                          CardReviewsParam(user.id, langKey),
                                        ),
                                      )
                                      .value ??
                                  <String, SRSState>{};
                        final now = DateTime.now();
                        final dueCards = flashcards.where((card) {
                          final review = reviews[card.id];
                          return review == null ||
                              !review.nextReviewAt.isAfter(now);
                        }).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              dueCards.isEmpty
                                  ? 'No cards are due right now'
                                  : '${dueCards.length} card${dueCards.length == 1 ? '' : 's'} due now · ${flashcards.length} total',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                itemCount: flashcards.length,
                                itemBuilder: (context, idx) {
                                  final card = flashcards[idx];
                                  return Card(
                                    color: theme.cardColor,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        card.front,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            card.back,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          if (card.context != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              card.context!,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (dueCards.isNotEmpty)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.replay),
                                label: Text(
                                  'Review due cards (${dueCards.length})',
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          _FlashcardStudySession(
                                            title:
                                                '${lesson.title} · due review',
                                            flashcards: dueCards,
                                            languageKey: langKey,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.school_outlined),
                              label: const Text('Practice all cards'),
                              onPressed: flashcards.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              _FlashcardStudySession(
                                                title: lesson.title,
                                                flashcards: flashcards,
                                                languageKey: langKey,
                                              ),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLanguageSwitcher(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Switch / Add Language',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Expanded(
                  child: FlagGrid(
                    onLanguageSelected: (langCode, flagInfo) async {
                      final code = LanguageCatalog.canonicalCode(langCode);
                      final previousLocalLanguage = ref.read(
                        localActiveLanguageProvider,
                      );
                      ref.read(localActiveLanguageProvider.notifier).state =
                          code;
                      var saved = false;
                      try {
                        final profile = await ref
                            .read(databaseServiceProvider)
                            .getProfile(userId);
                        if (profile != null) {
                          final list = List<String>.from(
                            profile.targetLanguages,
                          );
                          if (!list.contains(code)) {
                            list.insert(0, code);
                          } else {
                            list.remove(code);
                            list.insert(0, code);
                          }
                          await ref
                              .read(databaseServiceProvider)
                              .updateTargetLanguages(userId, list);
                          ref.invalidate(userProfileProvider(userId));
                        } else {
                          await ref
                              .read(databaseServiceProvider)
                              .upsertProfile(userId, code);
                          ref.invalidate(userProfileProvider(userId));
                        }
                        saved = true;
                      } catch (_) {
                        ref.read(localActiveLanguageProvider.notifier).state =
                            previousLocalLanguage;
                        debugPrint('Selected-language save failed.');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'We could not save your language choice. Please try again.',
                              ),
                            ),
                          );
                        }
                      }
                      if (saved && context.mounted) {
                        Navigator.pop(context);
                        context.go('/home/$code');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    LanguageTheme? theme,
    String langCode,
  ) {
    final primaryColor = theme?.primaryColor ?? const Color(0xFF1F3A93);
    final displayName = theme?.displayName ?? langCode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (theme != null && theme.motifAsset.isNotEmpty) ...[
              SvgPicture.asset(
                theme.motifAsset,
                width: 120,
                height: 120,
                colorFilter: ColorFilter.mode(
                  primaryColor.withValues(alpha: 0.3),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              '$displayName lessons are not available yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "This release does not include reviewed curriculum for $displayName. Choose one of the available languages to start learning.",
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final user = ref.read(authProvider);
                if (user != null) {
                  _openLanguageSwitcher(context, ref, user.id);
                }
              },
              icon: const Icon(Icons.language),
              label: const Text('Choose an available language'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
  ConsumerState<_FlashcardStudySession> createState() =>
      _FlashcardStudySessionState();
}

class _FlashcardStudySessionState
    extends ConsumerState<_FlashcardStudySession> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Map<String, SRSState> _sessionProgress = {};
  final TTSService _tts = TTSService();
  final Map<int, int> _qualityCounts = {};

  void _speakCardText(bool flipped) {
    final card = widget.flashcards[_currentIndex];
    // Front is the target language; the back is the English bridge.
    _tts.speak(
      flipped ? card.back : card.front,
      flipped ? 'en' : widget.languageKey,
    );
  }

  void _handleQualitySelect(int quality) {
    final card = widget.flashcards[_currentIndex];
    _qualityCounts.update(quality, (v) => v + 1, ifAbsent: () => 1);

    final user = ref.read(authProvider);
    if (user == null) return;

    final cardReviewsAsync = ref.read(
      cardReviewsProvider(CardReviewsParam(user.id, widget.languageKey)),
    );
    final cardReviews = cardReviewsAsync.value ?? {};
    final existingState = _sessionProgress[card.id] ?? cardReviews[card.id];

    final prevRepetitions = existingState?.repetitions ?? 0;
    final prevEfactor = existingState?.efactor ?? 2.5;
    final prevInterval = existingState?.interval ?? 0;

    // Calculate next SM-2 interval
    final nextState = SpacedRepetitionService.calculateNextState(
      quality: quality,
      prevRepetitions: prevRepetitions,
      prevEfactor: prevEfactor,
      prevInterval: prevInterval,
    );

    _sessionProgress[card.id] = nextState;

    // Sync stats to Supabase database reactively
    ref
        .read(databaseServiceProvider)
        .upsertCardReview(
          userId: user.id,
          cardId: card.id,
          languageKey: widget.languageKey,
          interval: nextState.interval,
          repetitions: nextState.repetitions,
          efactor: nextState.efactor,
          nextReview: nextState.nextReviewAt,
        )
        .catchError((e) {
          debugPrint('Card-review synchronization failed.');
        });

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
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please sign in.")));
    }

    final cardReviewsAsync = ref.watch(
      cardReviewsProvider(CardReviewsParam(user.id, widget.languageKey)),
    );

    return cardReviewsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Text('Review progress is unavailable right now.'),
        ),
      ),
      data: (reviews) {
        final isCompleted = _currentIndex >= widget.flashcards.length;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('${widget.title} — practice session'),
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
                      const Icon(
                        Icons.check_circle_outline,
                        size: 72,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Session Completed! 🎉",
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You practiced ${widget.flashcards.length} cards. Your ratings schedule future reviews.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Recall breakdown from this session.
                      if (_qualityCounts.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _sessionStat('Forgot', _qualityCounts[0] ?? 0, Colors.redAccent),
                            const SizedBox(width: 16),
                            _sessionStat('Hard', _qualityCounts[3] ?? 0, Colors.orangeAccent),
                            const SizedBox(width: 16),
                            _sessionStat('Good', _qualityCounts[4] ?? 0, Colors.blueAccent),
                            const SizedBox(width: 16),
                            _sessionStat('Easy', _qualityCounts[5] ?? 0, Colors.green),
                          ],
                        ),
                      ],
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
                        value: widget.flashcards.isEmpty
                            ? 1.0
                            : (_currentIndex / widget.flashcards.length),
                        backgroundColor: theme.colorScheme.primary.withAlpha(
                          25,
                        ),
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
                              color: theme.colorScheme.primary.withAlpha(
                                _isFlipped ? 100 : 38,
                              ),
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
                                if (_isFlipped &&
                                    widget.flashcards[_currentIndex].context !=
                                        null) ...[
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.flip),
                              label: Text(
                                _isFlipped ? "Show Front" : "Reveal Answer",
                              ),
                              onPressed: () {
                                setState(() {
                                  _isFlipped = !_isFlipped;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            // Listen button: speaks the visible side with
                            // the configured voice (male/female/auto).
                            TextButton.icon(
                              icon: const Icon(Icons.volume_up_rounded),
                              label: const Text("Listen"),
                              onPressed: () => _speakCardText(_isFlipped),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Quality Rating buttons
                      if (_isFlipped) ...[
                        Text(
                          "How well did you recall this card?",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQualityButton(
                              0,
                              "Forgot ❌",
                              Colors.redAccent,
                            ),
                            _buildQualityButton(
                              3,
                              "Hard ⏳",
                              Colors.orangeAccent,
                            ),
                            _buildQualityButton(
                              4,
                              "Good 👍",
                              Colors.blueAccent,
                            ),
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
      },
    );
  }

  Widget _sessionStat(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
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
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _AISpeechPracticeSession extends ConsumerStatefulWidget {
  final String language;
  final Lesson? lesson;

  const _AISpeechPracticeSession({required this.language, this.lesson});

  @override
  ConsumerState<_AISpeechPracticeSession> createState() =>
      _AISpeechPracticeSessionState();
}

class _AISpeechPracticeSessionState
    extends ConsumerState<_AISpeechPracticeSession> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final rec.AudioRecorder _audioRecorder = rec.AudioRecorder();

  final AIService _aiService = AIService();
  final TTSService _ttsService = TTSService();

  bool _isListening = false;
  bool _isAiThinking = false;
  String _loadingMessage = "";

  @override
  void initState() {
    super.initState();
    _addSparkyGreeting();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _ttsService.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addSparkyGreeting() {
    if (widget.lesson != null && widget.lesson!.sparkyPromptTemplate != null) {
      _messages.add({
        "sender": "sparky",
        "text":
            "Task: ${widget.lesson!.sparkyPromptTemplate!}\n\nHello! I am Sparky. Whenever you are ready, please complete this task. Speak or type your answer!",
      });
      return;
    }
    String greeting;
    switch (LanguageCatalog.canonicalCode(widget.language)) {
      case 'es':
        greeting =
            "¡Hola! Soy Sparky, tu tutor de IA. ¿Cómo estás hoy? ¿De qué te gustaría hablar?";
        break;
      case 'fr':
        greeting =
            "Bonjour! Je suis Sparky, ton tuteur d'IA. Comment ça va aujourd'hui? De quoi aimerais-tu parler ?";
        break;
      case 'zh':
        greeting = "你好！我是你的 AI 导师 Sparky。你今天怎么样？想聊点什么呢？";
        break;
      case 'hi':
        greeting =
            "नमस्ते! मैं आपका एआई ट्यूटर स्पार्की हूँ। आप आज कैसे हैं? आप किस बारे में बात करना चाहेंगे?";
        break;
      case 'ru':
        greeting =
            "Привет! Я Спарки, твой ИИ-репетитор. Как дела сегодня? О чём ты хочешь поговорить?";
        break;
      case 'ms':
        greeting =
            "Selamat pagi! Saya Sparky, tutor AI anda. Apa khabar hari ini? Anda mahu sembang tentang apa?";
        break;
      case 'ar':
        greeting =
            "مرحباً! أنا سباركي، معلم الذكاء الاصطناعي الخاص بك. كيف حالك اليوم؟ ما الذي تود التحدث عنه؟";
        break;
      case 'en':
      default:
        greeting =
            "Hello! I am Sparky, your AI tutor. How are you doing today? What would you like to chat about?";
        break;
    }
    _messages.add({"sender": "sparky", "text": greeting});
  }

  void _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({"sender": "user", "text": text});
    });

    _scrollToBottom();
    await _generateRealAIResponse();
  }

  Future<bool> _ensureProcessingConsent(ConsentPurpose purpose) async {
    final user = ref.read(authProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please sign in before using AI practice.',
            ),
          ),
        );
      }
      return false;
    }

    if (purpose.document == null) {
      // Test-deployment fallback: web test builds compiled with
      // ENABLE_TEST_CONSENT=true show a clearly-labelled draft notice and
      // record the choice so QA can exercise Sparky AI before approved
      // policy URLs exist (LEG-001). The server ledger is tried first: once
      // an operator registers an active consent document row, consent is
      // recorded server-side exactly like the launch flow. Store builds
      // never compile the flag, so this whole path stays off for them.
      if (TestConsentService.active) {
        final consentService = ref.read(consentServiceProvider);
        var serverLedgerUsable = true;
        try {
          if (await consentService.hasCurrentConsent(purpose)) return true;
        } on ConsentServiceException {
          serverLedgerUsable = false;
        }

        if (!mounted) return false;
        final accepted = await requestProcessingConsent(
          context,
          purpose: purpose,
        );
        if (!accepted) return false;

        if (serverLedgerUsable) {
          try {
            await consentService.recordConsent(purpose);
            return true;
          } on ConsentConfigurationException {
            // No active server document (yet): fall back to device ledger.
          } on ConsentServiceException {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'We could not record your choice. Nothing was sent.',
                  ),
                ),
              );
            }
            return false;
          }
        }

        final recorded = await TestConsentService.recordConsent(
          purpose.documentKey,
        );
        if (!recorded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'We could not record your choice. Nothing was sent.',
              ),
            ),
          );
        }
        return recorded;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This processing feature is not available in this build.',
            ),
          ),
        );
      }
      return false;
    }

    final consentService = ref.read(consentServiceProvider);
    try {
      if (await consentService.hasCurrentConsent(purpose)) return true;
    } on ConsentServiceException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This processing feature is temporarily unavailable.',
            ),
          ),
        );
      }
      return false;
    }

    if (!mounted) return false;
    final accepted = await requestProcessingConsent(context, purpose: purpose);
    if (!accepted) return false;

    try {
      await consentService.recordConsent(purpose);
      return true;
    } on ConsentServiceException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not record your choice. Nothing was sent.'),
          ),
        );
      }
      return false;
    } on ConsentConfigurationException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This processing feature is not available in this build.',
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _generateRealAIResponse() async {
    if (!await _ensureProcessingConsent(ConsentPurpose.aiProcessing)) return;
    if (!mounted) return;

    setState(() {
      _isAiThinking = true;
      _loadingMessage = "Sparky is thinking...";
    });

    try {
      final responseText = await _aiService.generateChatResponse(
        _messages,
        widget.language,
      );
      if (responseText != null) {
        setState(() {
          _messages.add({"sender": "sparky", "text": responseText});
        });
        _scrollToBottom();
        await _ttsService.speak(responseText, widget.language);
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "sender": "sparky",
          "text":
              "Sparky is having trouble connecting right now. Please check your connection and try again.",
        });
      });
      _scrollToBottom();
    } finally {
      setState(() {
        _isAiThinking = false;
      });
    }
  }

  Future<void> _toggleVoiceRecording() async {
    try {
      if (_isListening) {
        // Stop recording user speech
        final path = await _audioRecorder.stop();
        setState(() {
          _isListening = false;
        });
        if (path != null) {
          debugPrint("Audio recorded successfully to target: $path");

          setState(() {
            _isAiThinking = true;
            _loadingMessage = "Transcribing...";
          });

          try {
            final transcribedSpeech = await _aiService.transcribeAudio(path);
            if (transcribedSpeech != null &&
                transcribedSpeech.trim().isNotEmpty) {
              setState(() {
                _messages.add({"sender": "user", "text": transcribedSpeech});
              });
              _scrollToBottom();
              await _generateRealAIResponse();
            } else {
              setState(() {
                _isAiThinking = false;
              });
            }
          } catch (e) {
            debugPrint('Transcription failed.');
            setState(() {
              _messages.add({
                "sender": "sparky",
                "text":
                    "I didn't quite catch that. Could you try again or type it?",
              });
              _isAiThinking = false;
            });
            _scrollToBottom();
          }
        }
      } else {
        if (!await _ensureProcessingConsent(ConsentPurpose.voiceProcessing)) {
          return;
        }
        if (!mounted) return;

        // Verify audio input permissions first
        if (await _audioRecorder.hasPermission()) {
          setState(() {
            _isListening = true;
          });
          await _audioRecorder.start(
            const rec.RecordConfig(encoder: rec.AudioEncoder.aacLc),
            path: '',
          );
        } else {
          debugPrint(
            "Microphone permission was denied by client operating system.",
          );
        }
      }
    } catch (e) {
      debugPrint('Audio recording failed.');
      setState(() {
        _isListening = false;
      });
    }
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

  void _finishAndGradeAttempt() async {
    if (widget.lesson == null || widget.lesson!.rubricRef == null) return;

    // Accumulate all user responses
    final userResponse = _messages
        .where((msg) => msg['sender'] == 'user')
        .map((msg) => msg['text'] ?? '')
        .join(' ')
        .trim();

    if (userResponse.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please say or type something before grading!'),
          ),
        );
      }
      return;
    }

    if (!await _ensureProcessingConsent(ConsentPurpose.aiProcessing)) return;
    if (!mounted) return;

    setState(() {
      _isAiThinking = true;
      _loadingMessage = "Evaluating against rubric...";
    });

    try {
      final evaluation = await _aiService.scorePracticeAttempt(
        userResponse: userResponse,
        rubricRef: widget.lesson!.rubricRef!,
        targetLanguage: widget.language,
        promptTemplate: widget.lesson!.sparkyPromptTemplate,
      );

      if (evaluation != null) {
        if (mounted) {
          Navigator.pop(context); // close chat sheet
          _showScorecardBottomSheet(
            context,
            evaluation,
            widget.lesson!.honestyDisclaimer,
          );
        }
      }
    } catch (e) {
      debugPrint('Practice evaluation failed.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiThinking = false;
        });
      }
    }
  }

  void _showScorecardBottomSheet(
    BuildContext context,
    Map<String, dynamic> evaluation,
    String? customDisclaimer,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final band = evaluation['estimated_band'] ?? 'N/A';
        final correction = evaluation['top_correction'] ?? '';
        // The Edge Function validates this shape, but keep the view defensive
        // so a malformed response can never crash a learner's scorecard.
        final criteriaList = (evaluation['criteria'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map(
              (criterion) => <String, dynamic>{
                'name': criterion['name'],
                'note': criterion['note'],
              },
            )
            .toList(growable: false);

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Attempt Scorecard",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Band $band",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AIScoreDisclaimer(customDisclaimer: customDisclaimer),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Criteria Breakdown",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...criteriaList.map((crit) {
                        final name = crit['name']?.toString() ?? 'Criterion';
                        final note = crit['note']?.toString() ?? '';
                        final formattedName = name
                            .split('_')
                            .where((word) => word.isNotEmpty)
                            .map(
                              (word) =>
                                  word[0].toUpperCase() + word.substring(1),
                            )
                            .join(' & ');

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withAlpha(15),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  formattedName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4B5563),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (correction.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          "Sparky's Top Correction",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Text(
                            correction,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Continue"),
              ),
            ],
          ),
        );
      },
    );
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
            Text(
              widget.lesson != null
                  ? widget.lesson!.title
                  : "Sparky — AI Tutor",
            ),
          ],
        ),
        actions: [
          if (widget.lesson != null && widget.lesson!.rubricRef != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: TextButton.icon(
                onPressed: _finishAndGradeAttempt,
                icon: Icon(
                  Icons.analytics,
                  color: theme.colorScheme.onSecondary,
                  size: 18,
                ),
                label: Text(
                  'Finish & Grade',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
        ],
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
                  alignment: isSparky
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
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
                        bottomLeft: isSparky
                            ? Radius.zero
                            : const Radius.circular(16),
                        bottomRight: isSparky
                            ? const Radius.circular(16)
                            : Radius.zero,
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
          if (_isListening || _isAiThinking)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _isListening
                          ? Colors.redAccent
                          : theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isListening ? "Listening..." : _loadingMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isListening
                          ? Colors.redAccent
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(color: theme.colorScheme.primary.withAlpha(25)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Colors.redAccent
                        : theme.colorScheme.secondary,
                  ),
                  onPressed: _toggleVoiceRecording,
                  tooltip: "Record Voice",
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
