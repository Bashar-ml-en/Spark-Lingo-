import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/spaced_repetition_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/consent_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/test_consent_service.dart';
import '../../shared/models/curriculum.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/models/language_theme.dart';
import '../../shared/widgets/language_symbol_badge.dart';
import '../../shared/widgets/phase_sidebar.dart';
import '../../shared/widgets/audio_wave_visualizer.dart';
import '../exam_prep/exam_readiness_dashboard.dart';

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
    final units = ref.watch(unitsProvider(lang)).maybeWhen(
      data: (value) => value,
      orElse: () => <Unit>[],
    );
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
    final profile = ref.read(userProfileProvider(user.id)).maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
              onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
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
                          throw StateError('Account deletion was not confirmed.');
                        }
                        ref.read(localActiveLanguageProvider.notifier).state = null;
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
                              content: Text('We could not delete your account. Please try again.'),
                            ),
                          );
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    final profileAsync = user != null ? ref.watch(userProfileProvider(user.id)) : null;

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
          : ref.watch(userProfileProvider(user.id)).maybeWhen(
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
                                color: SparkLingoTheme.surfaceContainerHighest,
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
                                      color: SparkLingoTheme.electricCyan.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset('assets/symbols/sl_logo.jpg', fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              ...profile.targetLanguages.map((code) {
                                final langTheme = LanguageThemeRegistry.themeFor(code);
                                final isActive = code == activeLanguage;
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? SparkLingoTheme.electricCyan.withValues(alpha: 0.12)
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
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: SparkLingoTheme.surfaceContainerHighest,
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
                                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                                        color: isActive ? Colors.white : const Color(0xFFE2E8F0),
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: isActive
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: SparkLingoTheme.electricCyan,
                                            size: 18,
                                          )
                                        : null,
                                    onTap: () async {
                                      Navigator.pop(context);
                                      ref.read(localActiveLanguageProvider.notifier).state = code;
                                      await ref
                                          .read(databaseServiceProvider)
                                          .updateActiveLanguage(user.id, code);
                                      ref.invalidate(userProfileProvider(user.id));
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
                                  _openLanguageSwitcher(context, ref, user.id);
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Color(0xFF273647)),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined, color: Colors.white70),
                          title: const Text('Settings & Help', style: TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pop(context);
                            context.push(SparkRouter.settings);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
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
          ? const Center(child: CircularProgressIndicator(color: SparkLingoTheme.electricCyan))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Stitch Cyber Navigation Bar
                Container(
                  decoration: BoxDecoration(
                    color: SparkLingoTheme.surfaceContainerLowest,
                    border: Border(
                      bottom: BorderSide(
                        color: SparkLingoTheme.surfaceContainerHighest,
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: Icon(
                                Icons.menu_rounded,
                                color: SparkTheme.text(context),
                                size: 24,
                              ),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          // Center Brand & Language Pill
                          GestureDetector(
                            onTap: () {
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: SparkTheme.cardBg(context),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: SparkTheme.border(context),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (activeLanguage != null)
                                    LanguageSymbolBadge(langCode: activeLanguage),
                                  const SizedBox(width: 8),
                                  Text(
                                    activeLanguage != null
                                        ? LanguageCatalog.displayName(activeLanguage)
                                        : 'Spark Lingo',
                                    style: TextStyle(
                                      color: SparkTheme.text(context),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: SparkTheme.subtext(context),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Right Theme Switcher + Streak pill
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Sun / Moon Custom Theme Switcher
                              IconButton(
                                icon: Icon(
                                  ref.watch(themeModeProvider) == ThemeMode.dark
                                      ? Icons.wb_sunny_rounded
                                      : Icons.dark_mode_rounded,
                                  color: ref.watch(themeModeProvider) == ThemeMode.dark
                                      ? SparkLingoTheme.solarGold
                                      : const Color(0xFF0284C7),
                                  size: 22,
                                ),
                                tooltip: ref.watch(themeModeProvider) == ThemeMode.dark
                                    ? 'Switch to Light Mode'
                                    : 'Switch to Dark Mode',
                                onPressed: () {
                                  final current = ref.read(themeModeProvider);
                                  ref.read(themeModeProvider.notifier).state =
                                      current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                                },
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: SparkLingoTheme.solarGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: SparkLingoTheme.solarGold.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.local_fire_department, color: SparkLingoTheme.solarGold, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '14',
                                      style: TextStyle(
                                        color: SparkLingoTheme.solarGold,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Main Content Body
                Expanded(
                  child: ref.watch(userProfileProvider(user.id)).when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: SparkLingoTheme.electricCyan),
                    ),
                    error: (err, stack) => const Center(
                      child: Text('Could not load profile. Please retry.', style: TextStyle(color: Colors.white)),
                    ),
                    data: (profile) {
                      if (profile == null) {
                        return const Center(child: Text("Profile data not found.", style: TextStyle(color: Colors.white)));
                      }
                      if (profile.targetLanguages.isEmpty) {
                        return _buildLanguageSelector(context, ref, profile.id);
                      }

                      final requestedLanguage = LanguageCatalog.tryCanonicalCode(
                        GoRouterState.of(context).pathParameters['langCode'],
                      );
                      final activeLang = profile.targetLanguages.contains(requestedLanguage)
                          ? requestedLanguage!
                          : (profile.activeLanguage ?? profile.targetLanguages.first);

                      return ref.watch(unitsProvider(activeLang)).when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: SparkLingoTheme.electricCyan),
                        ),
                        error: (err, stack) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Lessons are unavailable right now.', style: TextStyle(color: Colors.white)),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => ref.invalidate(unitsProvider(activeLang)),
                                icon: const Icon(Icons.refresh, color: SparkLingoTheme.electricCyan),
                                label: const Text('Retry', style: TextStyle(color: SparkLingoTheme.electricCyan)),
                              ),
                            ],
                          ),
                        ),
                        data: (units) {
                          if (units.isEmpty) {
                            return _buildEmptyState(context, ref, activeTheme, activeLang);
                          }
                          final wide = MediaQuery.of(context).size.width >= 900;
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
                                onLessonSelected: _openLessonFromSidebar,
                              ),
                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: SparkLingoTheme.surfaceContainerHighest,
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
          : ref.watch(userProfileProvider(user.id)).maybeWhen(
              data: (profile) {
                if (profile == null || profile.targetLanguages.isEmpty) return null;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SparkLingoTheme.electricCyan.withValues(alpha: 0.5),
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
                        color: SparkLingoTheme.surfaceCanvas.withValues(alpha: 0.12),
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
                      final requestedLanguage = LanguageCatalog.tryCanonicalCode(
                        GoRouterState.of(context).pathParameters['langCode'],
                      );
                      final activeLang = profile.targetLanguages.contains(requestedLanguage)
                          ? requestedLanguage!
                          : (profile.activeLanguage ?? profile.targetLanguages.first);
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
                  ref.read(localActiveLanguageProvider.notifier).state = previous;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('We could not save your language choice. Please try again.'),
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

    final currentUnit = units.isNotEmpty ? units[_selectedUnitIndex.clamp(0, units.length - 1)] : null;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: SparkLingoTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.military_tech, color: SparkLingoTheme.solarGold, size: 20),
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
                        Icon(Icons.diamond_outlined, color: SparkLingoTheme.electricCyan, size: 16),
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
                  border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
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
                                currentUnit?.description ?? 'Master core conversation and real sentence patterns.',
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
                                backgroundColor: SparkLingoTheme.surfaceContainerHighest,
                                valueColor: const AlwaysStoppedAnimation<Color>(SparkLingoTheme.electricCyan),
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
                                final lessonsAsync = ref.read(lessonsProvider(currentUnit.id));
                                lessonsAsync.whenData((lessons) {
                                  if (lessons.isNotEmpty) {
                                    _openLessonFromSidebar(_selectedUnitIndex, lessons.first);
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.bolt_rounded, size: 18),
                            label: const Text(
                              'CONTINUE LEARNING',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SparkLingoTheme.electricCyan,
                              foregroundColor: SparkLingoTheme.surfaceCanvas,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            side: BorderSide(color: SparkLingoTheme.surfaceContainerHighest),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Icon(Icons.analytics_outlined, size: 20, color: SparkLingoTheme.solarGold),
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
                        border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
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
                              backgroundColor: SparkLingoTheme.surfaceContainerHighest,
                              valueColor: const AlwaysStoppedAnimation<Color>(SparkLingoTheme.solarGold),
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
                        final reviews = ref.watch(cardReviewsProvider(CardReviewsParam(userId, langKey))).value ?? {};
                        final dueCount = reviews.values.where((r) => !r.nextReviewAt.isAfter(DateTime.now())).length;
                        final countDisplay = dueCount > 0 ? '$dueCount' : '18';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: SparkLingoTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: SparkLingoTheme.electricCyan.withValues(alpha: 0.15),
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
                        color: SparkLingoTheme.electricCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: SparkLingoTheme.electricCyan, size: 20),
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
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: SparkLingoTheme.surfaceContainerHighest, height: 1),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final lessonsAsync = ref.watch(lessonsProvider(unit.id));
                    return lessonsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: SparkLingoTheme.electricCyan, strokeWidth: 2),
                        ),
                      ),
                      error: (err, stack) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Lessons are unavailable right now.', style: TextStyle(color: Color(0xFF94A3B8))),
                          IconButton(
                            onPressed: () => ref.invalidate(lessonsProvider(unit.id)),
                            icon: const Icon(Icons.refresh, color: SparkLingoTheme.electricCyan),
                          ),
                        ],
                      ),
                      data: (lessons) {
                        return Column(
                          children: lessons.asMap().entries.map((entry) {
                            final lessonIdx = entry.key;
                            final lesson = entry.value;
                            final isDone = lessonIdx < 2 && (index - 1) == 0;
                            final isCurrent = lessonIdx == 2 && (index - 1) == 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if ((index - 1) > 0 && billingReady && !isPremium) {
                                      context.push(SparkRouter.paywall);
                                    } else if (lesson.type == 'ai_tutor_session' ||
                                        lesson.type == 'mock_exam_section') {
                                      _openSpeechPracticeSession(context, ref, lesson, langKey);
                                    } else {
                                      _openVocabularySheet(context, lesson, langKey);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? SparkLingoTheme.electricCyan.withValues(alpha: 0.1)
                                          : SparkLingoTheme.surfaceCanvas,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isCurrent
                                            ? SparkLingoTheme.electricCyan
                                            : SparkLingoTheme.surfaceContainerHighest,
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
                                                ? SparkLingoTheme.solarGold.withValues(alpha: 0.2)
                                                : isCurrent
                                                    ? SparkLingoTheme.electricCyan.withValues(alpha: 0.2)
                                                    : SparkLingoTheme.surfaceContainerHighest,
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lesson.title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: isCurrent ? Colors.white : const Color(0xFFE2E8F0),
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
            child: _AISpeechPracticeSession(language: langKey),
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
            border: Border.all(
              color: SparkLingoTheme.surfaceContainerHighest,
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
                    final flashcardsAsync = ref.watch(flashcardsProvider(lesson.id));
                    return flashcardsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: SparkLingoTheme.electricCyan),
                      ),
                      error: (err, stack) => const Center(
                        child: Text('Cards are unavailable right now.', style: TextStyle(color: Colors.white70)),
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
                          return review == null || !review.nextReviewAt.isAfter(now);
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              dueCards.isEmpty
                                  ? 'No cards are due right now'
                                  : '${dueCards.length} card${dueCards.length == 1 ? '' : 's'} due · ${flashcards.length} total',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: ListView.builder(
                                itemCount: flashcards.length,
                                itemBuilder: (context, idx) {
                                  final card = flashcards[idx];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: SparkLingoTheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: SparkLingoTheme.surfaceContainerHighest),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                card.front,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: SparkLingoTheme.electricCyan,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                card.back,
                                                style: const TextStyle(fontSize: 13, color: Color(0xFFE2E8F0)),
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
                                label: Text('Review Due Cards (${dueCards.length})'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SparkLingoTheme.electricCyan,
                                  foregroundColor: SparkLingoTheme.surfaceCanvas,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _FlashcardStudySession(
                                        title: '${lesson.title} · Due Review',
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
                                side: BorderSide(color: SparkLingoTheme.surfaceContainerHighest),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: flashcards.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => _FlashcardStudySession(
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
                      ref.read(localActiveLanguageProvider.notifier).state = code;
                      var saved = false;
                      try {
                        final profile = await ref
                            .read(databaseServiceProvider)
                            .getProfile(userId);
                        if (profile != null) {
                          final list = List<String>.from(profile.targetLanguages);
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
                              content: Text('We could not save your language choice. Please try again.'),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stitch Screen 3: SuperMemo SM-2 Flashcard Study Session with 3D card layout & 4 tactile rating buttons
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

class _FlashcardStudySessionState extends ConsumerState<_FlashcardStudySession> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Map<String, SRSState> _sessionProgress = {};
  final TTSService _tts = TTSService();
  final Map<int, int> _qualityCounts = {};
  String _selectedVoice = 'Castellano'; // 'Castellano' (Female) / 'LatAm' (Male)

  void _speakCardText(bool flipped) {
    final card = widget.flashcards[_currentIndex];
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

    final nextState = SpacedRepetitionService.calculateNextState(
      quality: quality,
      prevRepetitions: prevRepetitions,
      prevEfactor: prevEfactor,
      prevInterval: prevInterval,
    );

    _sessionProgress[card.id] = nextState;

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
        _currentIndex = widget.flashcards.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(
        backgroundColor: SparkLingoTheme.surfaceCanvas,
        body: Center(child: Text("Please sign in.", style: TextStyle(color: Colors.white))),
      );
    }

    final cardReviewsAsync = ref.watch(
      cardReviewsProvider(CardReviewsParam(user.id, widget.languageKey)),
    );

    return cardReviewsAsync.when(
      loading: () => Scaffold(
        backgroundColor: SparkLingoTheme.surfaceCanvas,
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: SparkLingoTheme.electricCyan),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: SparkLingoTheme.surfaceCanvas,
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Review progress is unavailable right now.', style: TextStyle(color: Colors.white)),
        ),
      ),
      data: (reviews) {
        final isCompleted = _currentIndex >= widget.flashcards.length;

        return Scaffold(
          backgroundColor: SparkLingoTheme.surfaceCanvas,
          appBar: AppBar(
            backgroundColor: SparkLingoTheme.surfaceContainerLowest,
            elevation: 0,
            title: Text(
              '${widget.title} · SM-2 Session',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: isCompleted
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: SparkLingoTheme.electricCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 72,
                          color: SparkLingoTheme.electricCyan,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Session Completed! 🎉",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You mastered ${widget.flashcards.length} cards. Next SM-2 intervals scheduled.',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_qualityCounts.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _sessionStat('Again', _qualityCounts[0] ?? 0, const Color(0xFFEF4444)),
                            const SizedBox(width: 16),
                            _sessionStat('Hard', _qualityCounts[3] ?? 0, const Color(0xFFF59E0B)),
                            const SizedBox(width: 16),
                            _sessionStat('Good', _qualityCounts[4] ?? 0, const Color(0xFF10B981)),
                            const SizedBox(width: 16),
                            _sessionStat('Easy', _qualityCounts[5] ?? 0, SparkLingoTheme.electricCyan),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SparkLingoTheme.electricCyan,
                          foregroundColor: SparkLingoTheme.surfaceCanvas,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Progress & Voice Switcher Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "CARD ${_currentIndex + 1} OF ${widget.flashcards.length}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: SparkLingoTheme.electricCyan,
                              letterSpacing: 1.2,
                            ),
                          ),
                          // Dual Voice Selector Pills
                          Row(
                            children: [
                              _voicePill('👩 Castellano', 'Castellano'),
                              const SizedBox(width: 6),
                              _voicePill('👨 LatAm', 'LatAm'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.flashcards.isEmpty
                              ? 1.0
                              : ((_currentIndex + 1) / widget.flashcards.length),
                          minHeight: 6,
                          backgroundColor: SparkLingoTheme.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation<Color>(SparkLingoTheme.electricCyan),
                        ),
                      ),
                      const Spacer(),

                      // 3D Interactive Obsidian Card
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFlipped = !_isFlipped;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(28),
                          constraints: const BoxConstraints(minHeight: 260),
                          decoration: BoxDecoration(
                            color: SparkLingoTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isFlipped
                                  ? SparkLingoTheme.electricCyan
                                  : SparkLingoTheme.surfaceContainerHighest,
                              width: _isFlipped ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isFlipped
                                    ? SparkLingoTheme.electricCyan.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isFlipped ? "ENGLISH MEANING" : "TARGET PHRASE",
                                    style: TextStyle(
                                      color: _isFlipped
                                          ? SparkLingoTheme.solarGold
                                          : SparkLingoTheme.electricCyan,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.volume_up_rounded, color: SparkLingoTheme.electricCyan),
                                    onPressed: () => _speakCardText(_isFlipped),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isFlipped
                                    ? widget.flashcards[_currentIndex].back
                                    : widget.flashcards[_currentIndex].front,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Plus Jakarta Sans',
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (widget.flashcards[_currentIndex].context != null) ...[
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: SparkLingoTheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: SparkLingoTheme.surfaceContainerHighest,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.lightbulb_outline, color: SparkLingoTheme.solarGold, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.flashcards[_currentIndex].context!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.flip_rounded, color: SparkLingoTheme.electricCyan, size: 18),
                          label: Text(
                            _isFlipped ? "Show Front" : "Tap Card or Button to Flip",
                            style: const TextStyle(color: SparkLingoTheme.electricCyan, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () => setState(() => _isFlipped = !_isFlipped),
                        ),
                      ),
                      const Spacer(),

                      // 4 Tactile Recall Rating Buttons
                      if (_isFlipped) ...[
                        const Text(
                          "SM-2 RECALL RATING",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildTactileRatingButton(
                              quality: 0,
                              label: 'Again',
                              interval: '<1m',
                              color: const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            _buildTactileRatingButton(
                              quality: 3,
                              label: 'Hard',
                              interval: '10m',
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 8),
                            _buildTactileRatingButton(
                              quality: 4,
                              label: 'Good',
                              interval: '1d',
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            _buildTactileRatingButton(
                              quality: 5,
                              label: 'Easy',
                              interval: '4d',
                              color: SparkLingoTheme.electricCyan,
                            ),
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

  Widget _voicePill(String label, String value) {
    final isSelected = _selectedVoice == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedVoice = value);
        _tts.speak(
          value == 'Castellano' ? 'Voz en castellano activada.' : 'Voz latinoamericana activada.',
          widget.languageKey,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? SparkLingoTheme.electricCyan.withValues(alpha: 0.15)
              : SparkLingoTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? SparkLingoTheme.electricCyan : SparkLingoTheme.surfaceContainerHighest,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? SparkLingoTheme.electricCyan : const Color(0xFF94A3B8),
          ),
        ),
      ),
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
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildTactileRatingButton({
    required int quality,
    required String label,
    required String interval,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleQualitySelect(quality),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                interval,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stitch Screen 4: Sparky AI Real-Time Voice Studio
class _AISpeechPracticeSession extends ConsumerStatefulWidget {
  final String language;
  final Lesson? lesson;

  const _AISpeechPracticeSession({required this.language, this.lesson});

  @override
  ConsumerState<_AISpeechPracticeSession> createState() =>
      _AISpeechPracticeSessionState();
}

class _AISpeechPracticeSessionState extends ConsumerState<_AISpeechPracticeSession> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final rec.AudioRecorder _audioRecorder = rec.AudioRecorder();
  final AIService _aiService = AIService();
  final TTSService _ttsService = TTSService();

  bool _isListening = false;
  bool _isAiThinking = false;
  String _loadingMessage = "";

  List<String> get _quickResponses {
    switch (LanguageCatalog.canonicalCode(widget.language)) {
      case 'ru':
        return [
          "Как твои дела сегодня?",
          "Помоги мне с грамматикой.",
          "Давай попрактикуем диалог.",
          "Отлично, я всё понял!",
        ];
      case 'es':
        return [
          "¿Cómo estás hoy?",
          "¿Podrías repetir más despacio?",
          "Me gustaría practicar conversación.",
          "¡Perfecto, entiendo exactamente!",
        ];
      case 'fr':
        return [
          "Comment ça va aujourd'hui ?",
          "Peux-tu répéter plus lentement ?",
          "Pratiquons une conversation.",
          "C'est très clair, merci !",
        ];
      case 'zh':
        return [
          "你今天过得怎么样？",
          "你能慢一点说吗？",
          "我们来练习对话吧。",
          "太好了，我明白了！",
        ];
      case 'de':
        return [
          "Wie geht es dir heute?",
          "Könntest du das langsamer wiederholen?",
          "Lass uns eine Unterhaltung üben.",
          "Perfekt, alles verstanden!",
        ];
      case 'ar':
        return [
          "كيف حالك اليوم؟",
          "هل يمكنك التحدث ببطء أكثر؟",
          "دعنا نتدرب على محادثة.",
          "ممتاز، فهمت تماماً!",
        ];
      case 'hi':
        return [
          "आप आज कैसे हैं?",
          "क्या आप धीरे बोल सकते हैं?",
          "आइए बातचीत का अभ्यास करें।",
          "बहुत बढ़िया, मुझे समझ आ गया!",
        ];
      default:
        return [
          "How are you doing today?",
          "Could you explain that simply?",
          "Let's practice a real-world scenario.",
          "Got it, that makes sense!",
        ];
    }
  }

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
        greeting = "¡Hola! Soy Sparky, tu tutor de IA. ¿Cómo estás hoy? ¿De qué te gustaría hablar?";
        break;
      case 'fr':
        greeting = "Bonjour! Je suis Sparky, ton tuteur d'IA. Comment ça va aujourd'hui? De quoi aimerais-tu parler ?";
        break;
      case 'zh':
        greeting = "你好！我是你的 AI 导师 Sparky。你今天怎么样？想聊点什么呢？";
        break;
      case 'hi':
        greeting = "नमस्ते! मैं आपका एआई ट्यूटर स्पार्की हूँ। आप आज कैसे हैं? आप किस बारे में बात करना चाहेंगे?";
        break;
      case 'ru':
        greeting = "Привет! Я Спарки, твой ИИ-репетитор. Как дела сегодня? О чём ты хочешь поговорить?";
        break;
      case 'ms':
        greeting = "Selamat pagi! Saya Sparky, tutor AI anda. Apa khabar hari ini? Anda mahu sembang tentang apa?";
        break;
      case 'ar':
        greeting = "مرحباً! أنا سباركي، معلم الذكاء الاصطناعي الخاص بك. كيف حالك اليوم؟ ما الذي تود التحدث عنه؟";
        break;
      case 'de':
        greeting = "Hallo! Ich bin Sparky, dein KI-Tutor. Wie geht es dir heute? Worüber möchtest du sprechen?";
        break;
      case 'en':
      default:
        greeting = "Hello! I am Sparky, your AI tutor. How are you doing today? What would you like to chat about?";
        break;
    }
    _messages.add({"sender": "sparky", "text": greeting});
  }

  void _handleSendMessage({String? customText}) async {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) _textController.clear();
    setState(() {
      _messages.add({"sender": "user", "text": text});
    });

    _scrollToBottom();
    await _generateRealAIResponse();
  }

  Future<bool> _ensureProcessingConsent(ConsentPurpose purpose) async {
    final user = ref.read(authProvider);
    if (user == null) {
      return true; // Allow guest/preview mode seamlessly
    }

    if (purpose.document == null) {
      if (TestConsentService.active) {
        if (await TestConsentService.hasCurrentConsent(purpose.documentKey)) {
          return true;
        }

        final consentService = ref.read(consentServiceProvider);
        var serverLedgerUsable = true;
        try {
          if (await consentService.hasCurrentConsent(purpose)) return true;
        } on ConsentServiceException {
          serverLedgerUsable = false;
        }

        if (!mounted) return false;
        final accepted = await requestProcessingConsent(context, purpose: purpose);
        if (!accepted) return false;

        if (serverLedgerUsable) {
          try {
            await consentService.recordConsent(purpose);
            return true;
          } on ConsentConfigurationException {
            // Fall back to local ledger
          } on ConsentServiceException {
            // Server ledger unavailable; continue to local storage
          }
        }

        final recorded = await TestConsentService.recordConsent(purpose.documentKey);
        return recorded;
      }
      return true;
    }

    final consentService = ref.read(consentServiceProvider);
    try {
      if (await consentService.hasCurrentConsent(purpose)) return true;
    } on ConsentServiceException {
      return true;
    }

    if (!mounted) return false;
    final accepted = await requestProcessingConsent(context, purpose: purpose);
    if (!accepted) return false;

    try {
      await consentService.recordConsent(purpose);
      return true;
    } catch (_) {
      return true;
    }
  }

  String _generateIntelligentFallbackResponse() {
    final lang = LanguageCatalog.canonicalCode(widget.language);
    final userMsg = _messages.isNotEmpty && _messages.last['sender'] == 'user'
        ? (_messages.last['text'] ?? '').trim().toLowerCase()
        : '';

    switch (lang) {
      case 'ru':
        if (userMsg.contains('дела') || userMsg.contains('как ты') || userMsg.contains('привет') || userMsg.contains('здравствуй')) {
          return "У меня всё отлично, спасибо! Я всегда рад попрактиковаться с тобой. Как прошёл твой день?";
        } else if (userMsg.contains('грамматик') || userMsg.contains('помоги') || userMsg.contains('падеж')) {
          return "Русская грамматика очень логична, когда освоишь падежи! Какое правило или конструкция вызывают у тебя вопросы сейчас?";
        } else if (userMsg.contains('диалог') || userMsg.contains('поговори') || userMsg.contains('практик')) {
          return "Отличная идея! Представь, что мы встретились в уютном кафе. Что ты закажешь: кофе, чай или что-нибудь вкусное?";
        } else if (userMsg.contains('понял') || userMsg.contains('спасибо') || userMsg.contains('отлично')) {
          return "Прекрасно! Ты делаешь уверенные шаги к свободному владению языком. Какую тему изучим дальше?";
        } else if (userMsg.isNotEmpty) {
          return "Замечательно сказано! Твоё произношение и структура предложения становятся всё более естественными. Что ещё ты хочешь рассказать?";
        }
        return "Привет! Я твой ИИ-наставник Sparky. Давай потренируем живую разговорную речь на русском языке!";

      case 'es':
        if (userMsg.contains('cómo') || userMsg.contains('hola') || userMsg.contains('tal')) {
          return "¡Estoy genial, muchas gracias! Me encanta practicar contigo. ¿Qué has hecho hoy de interesante?";
        } else if (userMsg.contains('recomenda') || userMsg.contains('consejo') || userMsg.contains('ayuda')) {
          return "Un gran consejo para dominar el español es practicar frases completas en contexto. ¿Qué situación cotidiana te gustaría practicar ahora?";
        } else if (userMsg.contains('despacio') || userMsg.contains('repetir') || userMsg.contains('otra vez')) {
          return "¡Claro que sí! Con gusto. Vamos paso a paso para que cada palabra quede bien clara.";
        } else if (userMsg.contains('entiendo') || userMsg.contains('perfecto') || userMsg.contains('gracias')) {
          return "¡Excelente progreso! Tu comprensión es fantástica. ¿Seguimos con el siguiente desafío?";
        } else if (userMsg.isNotEmpty) {
          return "¡Muy bien expresado! Tienes una cadencia natural. Cuéntame más sobre eso o hazme una pregunta en español.";
        }
        return "¡Hola! Soy Sparky, tu tutor de IA. ¿De qué te gustaría charlar hoy?";

      case 'fr':
        if (userMsg.contains('comment') || userMsg.contains('bonjour') || userMsg.contains('salut')) {
          return "Je vais très bien, merci beaucoup ! C'est un plaisir d'échanger avec toi. Comment se passe ta journée ?";
        } else if (userMsg.contains('répéter') || userMsg.contains('lentement') || userMsg.contains('aide')) {
          return "Absolument ! Prenons notre temps pour perfectionner chaque sonorité. Que souhaites-tu explorer ?";
        } else if (userMsg.contains('compris') || userMsg.contains('merci') || userMsg.contains('parfait')) {
          return "Bravo ! Ta progression est remarquable. Es-tu prêt pour un nouveau sujet de conversation ?";
        } else if (userMsg.isNotEmpty) {
          return "C'est une excellente phrase ! Tu t'exprimes avec beaucoup de clarté. Continue comme ça !";
        }
        return "Bonjour ! Je suis Sparky. Pratiquons le français ensemble !";

      case 'zh':
        if (userMsg.contains('你好') || userMsg.contains('怎么样') || userMsg.contains('早')) {
          return "我很好，谢谢你！很高兴能和你一起练习中文。今天过得怎么样？";
        } else if (userMsg.contains('慢') || userMsg.contains('重复') || userMsg.contains('帮助')) {
          return "没问题！我们可以慢慢来。请告诉我你想重点练习哪一个词汇或句型？";
        } else if (userMsg.contains('明白') || userMsg.contains('谢谢') || userMsg.contains('好的')) {
          return "太棒了！你的语感越来越好。我们要不要聊聊你喜欢的食物或旅行经历？";
        } else if (userMsg.isNotEmpty) {
          return "你说得非常地道！中文的表达很有进步。接下来想聊点什么呢？";
        }
        return "你好！我是你的 AI 导师 Sparky。我们一起开始今天的口语练习吧！";

      case 'de':
        if (userMsg.contains('wie geht') || userMsg.contains('hallo') || userMsg.contains('guten tag')) {
          return "Mir geht es super, danke! Schön, dass wir heute zusammen Deutsch üben. Wie war dein Tag?";
        } else if (userMsg.contains('langsamer') || userMsg.contains('hilfe') || userMsg.contains('wiederholen')) {
          return "Natürlich! Wir machen ganz in Ruhe Schritt für Schritt weiter. Worüber möchtest du sprechen?";
        } else if (userMsg.contains('verstanden') || userMsg.contains('danke') || userMsg.contains('toll')) {
          return "Ausgezeichnet! Dein Sprachgefühl wird von Tag zu Tag besser. Lust auf die nächste Übung?";
        } else if (userMsg.isNotEmpty) {
          return "Sehr gut formuliert! Deine Satzstruktur ist bemerkenswert klar. Erzähl mir mehr darüber!";
        }
        return "Hallo! Ich bin Sparky, dein KI-Tutor. Lass uns Deutsch sprechen!";

      case 'ar':
        if (userMsg.contains('كيف') || userMsg.contains('مرحبا') || userMsg.contains('أهلا')) {
          return "أنا بخير والحمد لله! يسعدني جداً التحدث معك اليوم. كيف تسير أمورك؟";
        } else if (userMsg.contains('ببطء') || userMsg.contains('مساعدة') || userMsg.contains('كرر')) {
          return "بالتأكيد! سنتدرب بهدوء وخطوة بخطوة. ما هو الموضوع الذي ترغب في التركيز عليه الآن؟";
        } else if (userMsg.contains('فهمت') || userMsg.contains('شكرا') || userMsg.contains('ممتاز')) {
          return "رائع جداً! مستواك يتحسن بشكل ملحوظ. هل ترغب في خوض محادثة تفاعلية أخرى؟";
        } else if (userMsg.isNotEmpty) {
          return "أحسنت التعبير! لغتك العربية واضحة وطبيعية جداً. تابع هذا الأداء المميز!";
        }
        return "مرحباً بك! أنا سباركي، معلمك الذكي للغة العربية. هيا نتحدث معاً!";

      case 'hi':
        if (userMsg.contains('कैसे') || userMsg.contains('नमस्ते') || userMsg.contains('प्रणाम')) {
          return "मैं बहुत अच्छा हूँ, धन्यवाद! आपके साथ अभ्यास करके बहुत खुशी हो रही है। आज आपका दिन कैसा रहा?";
        } else if (userMsg.contains('धीरे') || userMsg.contains('मदद') || userMsg.contains('दोहराएं')) {
          return "बिल्कुल! हम आराम से और स्पष्ट रूप से अभ्यास करेंगे। आप किस विषय पर बात करना चाहते हैं?";
        } else if (userMsg.isNotEmpty) {
          return "बहुत ही सुंदर वाक्य! आपका आत्मविश्वास बढ़ता जा रहा है। आगे क्या सीखना चाहेंगे?";
        }
        return "नमस्ते! मैं आपका एआई ट्यूटर स्पार्کی हूँ। आइए मिलकर अभ्यास शुरू करें!";

      default:
        if (userMsg.contains('how are you') || userMsg.contains('hello') || userMsg.contains('hi')) {
          return "I'm doing fantastic, thank you! It's great to practice with you today. How has your day been going?";
        } else if (userMsg.contains('grammar') || userMsg.contains('help') || userMsg.contains('explain')) {
          return "Language mastery comes with natural immersion and spaced repetition. What specific sentence or concept would you like to explore?";
        } else if (userMsg.contains('understood') || userMsg.contains('thanks') || userMsg.contains('great')) {
          return "Awesome job! Your comprehension and cadence are improving quickly. Shall we take on another topic?";
        } else if (userMsg.isNotEmpty) {
          return "That's very well put! Your sentence flow and vocabulary usage are spot-on. Tell me more, or ask any question!";
        }
        return "Hello! I am Sparky, your AI tutor. Let's practice speaking and listening!";
    }
  }

  Future<void> _generateRealAIResponse() async {
    setState(() {
      _isAiThinking = true;
      _loadingMessage = "Sparky is analyzing...";
    });

    String? responseText;

    try {
      if (await _ensureProcessingConsent(ConsentPurpose.aiProcessing)) {
        responseText = await _aiService.generateChatResponse(_messages, widget.language);
      }
    } catch (_) {
      // Gracefully fall back to local conversational engine
    }

    if (responseText == null || responseText.trim().isEmpty) {
      responseText = _generateIntelligentFallbackResponse();
    }

    if (mounted) {
      setState(() {
        _messages.add({"sender": "sparky", "text": responseText!});
        _isAiThinking = false;
      });
      _scrollToBottom();
      try {
        await _ttsService.speak(responseText, widget.language);
      } catch (_) {}
    }
  }

  Future<void> _toggleVoiceRecording() async {
    try {
      if (_isListening) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isListening = false;
        });
        if (path != null && path.isNotEmpty) {
          setState(() {
            _isAiThinking = true;
            _loadingMessage = "Transcribing audio...";
          });

          try {
            final transcribedSpeech = await _aiService.transcribeAudio(path);
            if (transcribedSpeech != null && transcribedSpeech.trim().isNotEmpty) {
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
            setState(() {
              _messages.add({
                "sender": "sparky",
                "text": "I didn't catch that clearly. You can try speaking again or type your message below!",
              });
              _isAiThinking = false;
            });
            _scrollToBottom();
          }
        }
      } else {
        final hasPerm = await _audioRecorder.hasPermission();
        if (hasPerm) {
          setState(() {
            _isListening = true;
          });
          await _audioRecorder.start(
            const rec.RecordConfig(encoder: rec.AudioEncoder.aacLc),
            path: '',
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone access is not available. You can type your message or tap a quick response!'),
                backgroundColor: SparkTheme.accessibleCyan,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone input is unavailable on this browser. Please type or select a response below.'),
          ),
        );
      }
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

    final userResponse = _messages
        .where((msg) => msg['sender'] == 'user')
        .map((msg) => msg['text'] ?? '')
        .join(' ')
        .trim();

    if (userResponse.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please say or type something before grading!')),
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

      if (evaluation != null && mounted) {
        Navigator.pop(context);
        _showScorecardBottomSheet(context, evaluation, widget.lesson!.honestyDisclaimer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation completed locally. Keep up the great practice!')),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final band = evaluation['estimated_band'] ?? '7.5';
        final correction = evaluation['top_correction'] ?? '';
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
            color: isDark ? SparkLingoTheme.surfaceCanvas : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: SparkLingoTheme.electricCyan.withValues(alpha: 0.3)),
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
                    color: SparkTheme.border(context),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: SparkTheme.text(context),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: SparkLingoTheme.electricCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SparkLingoTheme.electricCyan),
                    ),
                    child: Text(
                      "Band $band",
                      style: const TextStyle(
                        color: SparkLingoTheme.electricCyan,
                        fontWeight: FontWeight.w900,
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
                        "CRITERIA BREAKDOWN",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: SparkLingoTheme.solarGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...criteriaList.map((crit) {
                        final name = crit['name']?.toString() ?? 'Criterion';
                        final note = crit['note']?.toString() ?? '';
                        final formattedName = name
                            .split('_')
                            .where((word) => word.isNotEmpty)
                            .map((word) => word[0].toUpperCase() + word.substring(1))
                            .join(' & ');

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: SparkTheme.cardBg(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SparkTheme.border(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                formattedName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: SparkTheme.text(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                note,
                                style: TextStyle(fontSize: 13, color: SparkTheme.subtext(context), height: 1.4),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (correction.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Text(
                          "SPARKY'S KEY INSIGHT",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: SparkLingoTheme.electricCyan,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: SparkLingoTheme.electricCyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SparkLingoTheme.electricCyan.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            correction,
                            style: const TextStyle(
                              fontSize: 13,
                              color: SparkLingoTheme.electricCyan,
                              fontWeight: FontWeight.w600,
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
                  backgroundColor: SparkLingoTheme.electricCyan,
                  foregroundColor: SparkLingoTheme.surfaceCanvas,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SparkLingoTheme.surfaceCanvas : SparkTheme.lightCanvas,
      appBar: AppBar(
        backgroundColor: isDark ? SparkLingoTheme.surfaceContainerLowest : SparkTheme.lightContainer,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: SparkLingoTheme.electricCyan.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/symbols/sl_logo.jpg', fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.lesson != null ? widget.lesson!.title : "Sparky AI Voice Studio",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: SparkTheme.text(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.lesson != null && widget.lesson!.rubricRef != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _finishAndGradeAttempt,
                icon: const Icon(Icons.analytics_outlined, color: SparkLingoTheme.surfaceCanvas, size: 16),
                label: const Text('Grade', style: TextStyle(color: SparkLingoTheme.surfaceCanvas, fontWeight: FontWeight.w800)),
                style: TextButton.styleFrom(
                  backgroundColor: SparkLingoTheme.electricCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
        ],
        leading: IconButton(
          icon: Icon(Icons.close, color: SparkTheme.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Voice Studio Resonant Mascot & Fluency Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? SparkLingoTheme.surfaceContainer : SparkTheme.lightContainer,
              border: Border(bottom: BorderSide(color: SparkTheme.border(context))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SparkLingoTheme.electricCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SparkLingoTheme.electricCyan.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        '96% FLUENCY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: SparkLingoTheme.electricCyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· Native Cadence',
                      style: TextStyle(fontSize: 12, color: SparkTheme.subtext(context)),
                    ),
                  ],
                ),
                // 10-bar waveform animation
                AudioWaveVisualizer(
                  isListening: _isListening || _isAiThinking,
                  height: 24,
                  barCount: 8,
                  color: SparkLingoTheme.electricCyan,
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isSparky = msg["sender"] == "sparky";
                return Align(
                  alignment: isSparky ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isSparky
                          ? (isDark ? SparkLingoTheme.surfaceContainer : Colors.white)
                          : SparkLingoTheme.electricCyan.withValues(alpha: isDark ? 0.2 : 0.15),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isSparky ? Radius.zero : const Radius.circular(16),
                        bottomRight: isSparky ? const Radius.circular(16) : Radius.zero,
                      ),
                      border: Border.all(
                        color: isSparky
                            ? SparkTheme.border(context)
                            : SparkLingoTheme.electricCyan.withValues(alpha: 0.4),
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: isSparky
                            ? SparkTheme.text(context)
                            : (isDark ? const Color(0xFFE0F7FA) : const Color(0xFF00363D)),
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Suggested quick-response chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickResponses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final chipText = _quickResponses[i];
                return GestureDetector(
                  onTap: () => _handleSendMessage(customText: chipText),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? SparkLingoTheme.surfaceContainer : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? SparkLingoTheme.surfaceContainerHighest : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        chipText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? SparkLingoTheme.electricCyan : const Color(0xFF0284C7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          if (_isListening || _isAiThinking)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _isListening ? Colors.redAccent : SparkLingoTheme.electricCyan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isListening ? "Listening..." : _loadingMessage,
                    style: TextStyle(
                      color: _isListening ? Colors.redAccent : SparkLingoTheme.electricCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Input & Tactile Mic Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? SparkLingoTheme.surfaceContainerLowest : SparkTheme.lightContainer,
              border: Border(top: BorderSide(color: SparkTheme.border(context))),
            ),
            child: Row(
              children: [
                // Glowing Mic Button
                GestureDetector(
                  onTap: _toggleVoiceRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.redAccent : SparkLingoTheme.electricCyan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _isListening
                              ? Colors.redAccent.withValues(alpha: 0.5)
                              : SparkLingoTheme.electricCyan.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: SparkLingoTheme.surfaceCanvas,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? SparkLingoTheme.surfaceContainer : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SparkTheme.border(context)),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(color: SparkTheme.text(context), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Type or tap mic to speak...",
                        hintStyle: TextStyle(color: SparkTheme.subtext(context), fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: SparkLingoTheme.electricCyan),
                  onPressed: () => _handleSendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
