import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/spaced_repetition_service.dart';
import '../../shared/models/curriculum.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/models/language_theme.dart';
import '../../shared/widgets/flag_grid.dart';
import '../../shared/widgets/phase_sidebar.dart';
import '../../shared/widgets/stitch_top_bar.dart';
import '../exam_prep/exam_readiness_dashboard.dart';
import '../../core/router/router.dart';
import '../../core/services/revenuecat_service.dart';
import 'flashcard_study_session.dart';
import 'sparky_chat_session.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _curriculumScrollController = ScrollController();
  final List<GlobalKey> _unitKeys = [];
  int _selectedUnitIndex = 0;
  String _activeNavTab = 'pathway';

  @override
  void dispose() {
    _curriculumScrollController.dispose();
    super.dispose();
  }

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
    final units = ref
        .watch(unitsProvider(lang))
        .maybeWhen(data: (value) => value, orElse: () => <Unit>[]);
    if (units.isEmpty) return null;
    return Drawer(
      backgroundColor: SparkLingoTheme.surfaceCanvas,
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

  void _openLessonFromSidebar(int unitIndex, Lesson lesson) {
    _scrollToUnit(unitIndex);
    if (lesson.type == 'ai_tutor_session' ||
        lesson.type == 'mock_exam_section') {
      _openSpeechPracticeSession(context, ref, lesson, _currentLanguageCode());
    } else {
      _openVocabularySheet(context, lesson, _currentLanguageCode());
    }
  }

  String _currentLanguageCode() {
    final routeCode = LanguageCatalog.tryCanonicalCode(
      GoRouterState.of(context).pathParameters['langCode'],
    );
    final user = ref.read(authProvider);
    if (routeCode != null) return routeCode;
    if (user == null) return 'en';
    final profile = ref
        .read(userProfileProvider(user.id))
        .maybeWhen(data: (value) => value, orElse: () => null);
    return profile?.activeLanguage ??
        (profile?.targetLanguages.isNotEmpty == true
            ? profile!.targetLanguages.first
            : 'en');
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final confirmationController = TextEditingController();
    var isDeleting = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: SparkLingoTheme.surfaceContainer,
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 32,
          ),
          title: const Text(
            'Delete your account?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your Spark Lingo account and in-app learning data.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Type DELETE to confirm:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmationController,
                enabled: !isDeleting,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirmation',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: SparkLingoTheme.surfaceContainerHighest,
                    ),
                  ),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
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
                        } catch (_) {}
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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
    final user = ref.watch(authProvider);
    final profileAsync = user != null
        ? ref.watch(userProfileProvider(user.id))
        : null;

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
      backgroundColor: SparkLingoTheme.surfaceCanvas,
      drawer: user == null
          ? null
          : ref
                .watch(userProfileProvider(user.id))
                .maybeWhen(
                  data: (profile) {
                    if (profile == null) return null;
                    return Drawer(
                      backgroundColor: SparkLingoTheme.surfaceContainer,
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: SparkLingoTheme.surfaceContainerLowest,
                                border: Border(
                                  bottom: BorderSide(
                                    color:
                                        SparkLingoTheme.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: SparkLingoTheme.electricCyan
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      'assets/symbols/sl_logo.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Spark Lingo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                      ),
                                      Text(
                                        'AI Language Studio',
                                        style: TextStyle(
                                          color: SparkLingoTheme.electricCyan,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'TARGET LANGUAGES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: SparkLingoTheme.solarGold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                children: [
                                  ...profile.targetLanguages.map((code) {
                                    final langTheme =
                                        LanguageThemeRegistry.themeFor(code);
                                    final isActive = code == activeLanguage;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? SparkLingoTheme.electricCyan
                                                  .withValues(alpha: 0.12)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isActive
                                              ? SparkLingoTheme.electricCyan
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          width: 34,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: SparkLingoTheme
                                                  .surfaceContainerHighest,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: SvgPicture.asset(
                                            langTheme.flags.isNotEmpty
                                                ? langTheme
                                                      .flags
                                                      .first
                                                      .flagAsset
                                                : 'assets/flags/en_us.svg',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        title: Text(
                                          langTheme.displayName,
                                          style: TextStyle(
                                            fontWeight: isActive
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: isActive
                                                ? Colors.white
                                                : const Color(0xFFE2E8F0),
                                            fontSize: 14,
                                          ),
                                        ),
                                        trailing: isActive
                                            ? const Icon(
                                                Icons.check_circle_rounded,
                                                color: SparkLingoTheme
                                                    .electricCyan,
                                                size: 18,
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
                                      ),
                                    );
                                  }),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.add_circle_outline,
                                      color: SparkLingoTheme.electricCyan,
                                    ),
                                    title: const Text(
                                      'Add Language',
                                      style: TextStyle(
                                        color: SparkLingoTheme.electricCyan,
                                        fontWeight: FontWeight.w700,
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
                            const Divider(color: Color(0xFF273647)),
                            ListTile(
                              leading: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white70,
                              ),
                              title: const Text(
                                'Settings & Help',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                context.push(SparkRouter.settings);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              title: const Text(
                                'Delete Account',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showDeleteAccountDialog(context, ref);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  },
                  orElse: () => null,
                ),
      endDrawer: user == null ? null : _buildPhaseEndDrawer(context),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(
                color: SparkLingoTheme.electricCyan,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Stitch Cyber Navigation Bar with Logo Alignment & Sub-tabs
                StitchTopBar(
                  activeLanguage: activeLanguage,
                  streakDays: 21,
                  totalXP: 1480,
                  showSubTabs: true,
                  activeSubTab: _activeNavTab,
                  onSubTabSelected: (tabId) {
                    setState(() => _activeNavTab = tabId);
                  },
                  onLanguageTap: () {
                    if (profileAsync != null) {
                      profileAsync.maybeWhen(
                        data: (profile) {
                          if (profile != null) {
                            _openLanguageSwitcher(context, ref, profile.id);
                          }
                        },
                        orElse: () {},
                      );
                    }
                  },
                ),
                // Main Content Body
                Expanded(
                  child: ref
                      .watch(userProfileProvider(user.id))
                      .when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: SparkLingoTheme.electricCyan,
                          ),
                        ),
                        error: (err, stack) => const Center(
                          child: Text(
                            'Could not load profile. Please retry.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        data: (profile) {
                          if (profile == null) {
                            return const Center(
                              child: Text(
                                "Profile data not found.",
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          if (profile.targetLanguages.isEmpty) {
                            return _buildLanguageSelector(
                              context,
                              ref,
                              profile.id,
                            );
                          }

                          final requestedLanguage =
                              LanguageCatalog.tryCanonicalCode(
                                GoRouterState.of(
                                  context,
                                ).pathParameters['langCode'],
                              );
                          final activeLang =
                              profile.targetLanguages.contains(
                                requestedLanguage,
                              )
                              ? requestedLanguage!
                              : (profile.activeLanguage ??
                                    profile.targetLanguages.first);

                          return ref
                              .watch(unitsProvider(activeLang))
                              .when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(
                                    color: SparkLingoTheme.electricCyan,
                                  ),
                                ),
                                error: (err, stack) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Lessons are unavailable right now.',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton.icon(
                                        onPressed: () => ref.invalidate(
                                          unitsProvider(activeLang),
                                        ),
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: SparkLingoTheme.electricCyan,
                                        ),
                                        label: const Text(
                                          'Retry',
                                          style: TextStyle(
                                            color: SparkLingoTheme.electricCyan,
                                          ),
                                        ),
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
                                      activeLang,
                                    );
                                  }
                                  final wide =
                                      MediaQuery.of(context).size.width >= 900;
                                  final curriculum = _buildCurriculumPath(
                                    context,
                                    ref,
                                    profile.id,
                                    units,
                                    activeLang,
                                  );
                                  if (!wide) return curriculum;
                                  return Row(
                                    children: [
                                      PhaseSidebar(
                                        langCode: activeLang,
                                        units: units,
                                        selectedUnitIndex: _selectedUnitIndex,
                                        onUnitSelected: _scrollToUnit,
                                        onLessonSelected:
                                            _openLessonFromSidebar,
                                      ),
                                      VerticalDivider(
                                        width: 1,
                                        thickness: 1,
                                        color: SparkLingoTheme
                                            .surfaceContainerHighest,
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
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: SparkLingoTheme.electricCyan.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: FloatingActionButton.extended(
                        heroTag: 'sparky_ai_fab',
                        backgroundColor: SparkLingoTheme.electricCyan,
                        foregroundColor: SparkLingoTheme.surfaceCanvas,
                        elevation: 6,
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: SparkLingoTheme.surfaceCanvas.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color: SparkLingoTheme.surfaceCanvas,
                          ),
                        ),
                        label: const Text(
                          'Sparky AI',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.4,
                            fontFamily: 'Plus Jakarta Sans',
                            color: SparkLingoTheme.surfaceCanvas,
                          ),
                        ),
                        onPressed: () {
                          final requestedLanguage =
                              LanguageCatalog.tryCanonicalCode(
                                GoRouterState.of(
                                  context,
                                ).pathParameters['langCode'],
                              );
                          final activeLang =
                              profile.targetLanguages.contains(
                                requestedLanguage,
                              )
                              ? requestedLanguage!
                              : (profile.activeLanguage ??
                                    profile.targetLanguages.first);
                          _openAITutor(context, activeLang);
                        },
                      ),
                    );
                  },
                  orElse: () => null,
                ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Choose a target language to start learning.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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

  Widget _buildCurriculumPath(
    BuildContext context,
    WidgetRef ref,
    String userId,
    List<Unit> units,
    String langKey,
  ) {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final billingReady =
        ref.watch(billingAccessProvider).value == BillingAccessState.ready;

    while (_unitKeys.length < units.length) {
      _unitKeys.add(GlobalKey());
    }

    final currentUnit = units.isNotEmpty
        ? units[_selectedUnitIndex.clamp(0, units.length - 1)]
        : null;

    return ListView.builder(
      controller: _curriculumScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: units.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Stitch Screen 2 Header Bento Cards
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rank Tier Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: SparkLingoTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SparkLingoTheme.surfaceContainerHighest,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.military_tech,
                          color: SparkLingoTheme.solarGold,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'TIER 3 · DIAMOND LEAGUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Icon(
                          Icons.diamond_outlined,
                          color: SparkLingoTheme.electricCyan,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '1,240 XP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: SparkLingoTheme.electricCyan,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Unit Roadmap Bento Card with circular progress ring
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SparkLingoTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: SparkLingoTheme.surfaceContainerHighest,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUnit != null
                                    ? 'UNIT ${_selectedUnitIndex + 1}: ${currentUnit.title.toUpperCase()}'
                                    : 'CURRENT UNIT',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: SparkLingoTheme.electricCyan,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentUnit?.description ??
                                    'Master core conversation and real sentence patterns.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Circular Progress Ring (85%)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 54,
                              height: 54,
                              child: CircularProgressIndicator(
                                value: 0.85,
                                strokeWidth: 5,
                                backgroundColor:
                                    SparkLingoTheme.surfaceContainerHighest,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  SparkLingoTheme.electricCyan,
                                ),
                              ),
                            ),
                            const Text(
                              '85%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (currentUnit != null) {
                                final lessonsAsync = ref.read(
                                  lessonsProvider(currentUnit.id),
                                );
                                lessonsAsync.whenData((lessons) {
                                  if (lessons.isNotEmpty) {
                                    _openLessonFromSidebar(
                                      _selectedUnitIndex,
                                      lessons.first,
                                    );
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.bolt_rounded, size: 18),
                            label: const Text(
                              'CONTINUE LEARNING',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SparkLingoTheme.electricCyan,
                              foregroundColor: SparkLingoTheme.surfaceCanvas,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExamReadinessDashboard(
                                  userId: userId,
                                  examId: 'cefr_$langKey',
                                  languageCode: langKey,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: SparkLingoTheme.surfaceContainerHighest,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            size: 20,
                            color: SparkLingoTheme.solarGold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Duo Metric Cards
              Row(
                children: [
                  // Today's Target
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SparkLingoTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: SparkLingoTheme.surfaceContainerHighest,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "TODAY'S TARGET",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: const [
                              Text(
                                '11',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                ' / 15 min',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 11 / 15,
                              minHeight: 6,
                              backgroundColor:
                                  SparkLingoTheme.surfaceContainerHighest,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                SparkLingoTheme.solarGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // SM-2 Reviews Due
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final reviews =
                            ref
                                .watch(
                                  cardReviewsProvider(
                                    CardReviewsParam(userId, langKey),
                                  ),
                                )
                                .value ??
                            {};
                        final dueCount = reviews.values
                            .where(
                              (r) => !r.nextReviewAt.isAfter(DateTime.now()),
                            )
                            .length;
                        final countDisplay = dueCount > 0 ? '$dueCount' : '18';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: SparkLingoTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: SparkLingoTheme.surfaceContainerHighest,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SM-2 REVIEWS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    countDisplay,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: SparkLingoTheme.electricCyan,
                                    ),
                                  ),
                                  const Text(
                                    ' due cards',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: SparkLingoTheme.electricCyan
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Ready for review',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: SparkLingoTheme.electricCyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'LEARNING PATHWAY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: SparkLingoTheme.electricCyan,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        final unit = units[index - 1];
        return Container(
          key: _unitKeys[index - 1],
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: SparkLingoTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SparkLingoTheme.electricCyan.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: SparkLingoTheme.electricCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            unit.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: SparkLingoTheme.surfaceContainerHighest,
                  height: 1,
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final lessonsAsync = ref.watch(lessonsProvider(unit.id));
                    return lessonsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: SparkLingoTheme.electricCyan,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (err, stack) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lessons are unavailable right now.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                          IconButton(
                            onPressed: () =>
                                ref.invalidate(lessonsProvider(unit.id)),
                            icon: const Icon(
                              Icons.refresh,
                              color: SparkLingoTheme.electricCyan,
                            ),
                          ),
                        ],
                      ),
                      data: (lessons) {
                        return Column(
                          children: lessons.asMap().entries.map((entry) {
                            final lessonIdx = entry.key;
                            final lesson = entry.value;
                            final isDone = lessonIdx < 2 && (index - 1) == 0;
                            final isCurrent =
                                lessonIdx == 2 && (index - 1) == 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: Material(
                                color: Colors.transparent,
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
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? SparkLingoTheme.electricCyan
                                                .withValues(alpha: 0.1)
                                          : SparkLingoTheme.surfaceCanvas,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isCurrent
                                            ? SparkLingoTheme.electricCyan
                                            : SparkLingoTheme
                                                  .surfaceContainerHighest,
                                        width: isCurrent ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Status Icon
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isDone
                                                ? SparkLingoTheme.solarGold
                                                      .withValues(alpha: 0.2)
                                                : isCurrent
                                                ? SparkLingoTheme.electricCyan
                                                      .withValues(alpha: 0.2)
                                                : SparkLingoTheme
                                                      .surfaceContainerHighest,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isDone
                                                ? Icons.check
                                                : isCurrent
                                                ? Icons.play_arrow_rounded
                                                : Icons.lock_outline,
                                            color: isDone
                                                ? SparkLingoTheme.solarGold
                                                : isCurrent
                                                ? SparkLingoTheme.electricCyan
                                                : const Color(0xFF64748B),
                                            size: 18,
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
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: isCurrent
                                                      ? Colors.white
                                                      : const Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                lesson.description,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: isCurrent
                                              ? SparkLingoTheme.electricCyan
                                              : const Color(0xFF64748B),
                                        ),
                                      ],
                                    ),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: isDark ? SparkLingoTheme.surfaceCanvas : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(
              color: SparkLingoTheme.electricCyan.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            child: SparkyChatSession(language: langKey, lesson: lesson),
          ),
        );
      },
    );
  }

  void _openAITutor(BuildContext context, String langKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: isDark ? SparkLingoTheme.surfaceCanvas : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(
              color: SparkLingoTheme.electricCyan.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            child: SparkyChatSession(language: langKey),
          ),
        );
      },
    );
  }

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
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: SparkLingoTheme.surfaceCanvas,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
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
                    color: SparkLingoTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final flashcardsAsync = ref.watch(
                      flashcardsProvider(lesson.id),
                    );
                    return flashcardsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: SparkLingoTheme.electricCyan,
                        ),
                      ),
                      error: (err, stack) => const Center(
                        child: Text(
                          'Cards are unavailable right now.',
                          style: TextStyle(color: Colors.white70),
                        ),
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
                                  : '${dueCards.length} card${dueCards.length == 1 ? '' : 's'} due · ${flashcards.length} total',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: ListView.builder(
                                itemCount: flashcards.length,
                                itemBuilder: (context, idx) {
                                  final card = flashcards[idx];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: SparkLingoTheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: SparkLingoTheme
                                            .surfaceContainerHighest,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                card.front,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: SparkLingoTheme
                                                      .electricCyan,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                card.back,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFFE2E8F0),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (dueCards.isNotEmpty)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.replay),
                                label: Text(
                                  'Review Due Cards (${dueCards.length})',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SparkLingoTheme.electricCyan,
                                  foregroundColor:
                                      SparkLingoTheme.surfaceCanvas,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FlashcardStudySession(
                                            title:
                                                '${lesson.title} · Due Review',
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
                              label: const Text('Practice All Cards'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color:
                                      SparkLingoTheme.surfaceContainerHighest,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: flashcards.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FlashcardStudySession(
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
      backgroundColor: SparkLingoTheme.surfaceCanvas,
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
                      color: Colors.white,
                      fontFamily: 'Plus Jakarta Sans',
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
    final displayName = theme?.displayName ?? langCode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$displayName lessons are not available yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "This release does not include reviewed curriculum for $displayName. Choose one of the available languages to start learning.",
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
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
                backgroundColor: SparkLingoTheme.electricCyan,
                foregroundColor: SparkLingoTheme.surfaceCanvas,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
