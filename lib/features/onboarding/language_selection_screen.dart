import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/services/database_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/widgets/flag_grid.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String _selectedLang = 'es';
  String _selectedLevel = 'A1-A2'; // A1-A2, B1-B2, C1-C2
  bool _isSaving = false;

  static const List<Map<String, String>> _levels = [
    {
      'code': 'A1-A2',
      'title': 'Beginner',
      'desc': 'First steps & basic phrases',
    },
    {
      'code': 'B1-B2',
      'title': 'Intermediate',
      'desc': 'Conversational & fluency',
    },
    {
      'code': 'C1-C2',
      'title': 'Advanced',
      'desc': 'Mastery & professional nuance',
    },
  ];

  Future<void> _handleConfirm() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    final canonicalCode = LanguageCatalog.canonicalCode(_selectedLang);
    final previousLocalLanguage = ref.read(localActiveLanguageProvider);

    ref.read(localActiveLanguageProvider.notifier).state = canonicalCode;

    try {
      final profile =
          await ref.read(databaseServiceProvider).getProfile(user.id);
      if (profile != null) {
        final list = List<String>.from(profile.targetLanguages);
        if (!list.contains(canonicalCode)) {
          list.insert(0, canonicalCode);
        } else {
          list.remove(canonicalCode);
          list.insert(0, canonicalCode);
        }
        await ref
            .read(databaseServiceProvider)
            .updateTargetLanguages(user.id, list);
        await ref
            .read(databaseServiceProvider)
            .updateActiveLanguage(user.id, canonicalCode);
      } else {
        await ref
            .read(databaseServiceProvider)
            .upsertProfile(user.id, canonicalCode);
      }
      ref.invalidate(userProfileProvider(user.id));
      if (mounted) {
        context.go('/home/$canonicalCode');
      }
    } catch (_) {
      ref.read(localActiveLanguageProvider.notifier).state =
          previousLocalLanguage;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not save your language choice. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SparkLingoTheme.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SparkLingoTheme.electricCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SparkLingoTheme.electricCyan.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'STEP 1 OF 3',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: SparkLingoTheme.electricCyan,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What do you want to learn?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Plus Jakarta Sans',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your target language and starting proficiency.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Flag Grid
            Expanded(
              child: FlagGrid(
                selectedLanguageCode: _selectedLang,
                onLanguageSelected: (langCode, flag) {
                  setState(() => _selectedLang = langCode);
                },
              ),
            ),

            // CEFR Baseline Level Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: SparkLingoTheme.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(
                    color: SparkLingoTheme.surfaceContainerHighest,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BASELINE PROFICIENCY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: SparkLingoTheme.solarGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        _selectedLevel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _levels.map((lvl) {
                      final isSelected = lvl['code'] == _selectedLevel;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLevel = lvl['code']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SparkLingoTheme.electricCyan.withValues(alpha: 0.15)
                                  : SparkLingoTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? SparkLingoTheme.electricCyan
                                    : SparkLingoTheme.surfaceContainerHighest,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  lvl['code']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? SparkLingoTheme.electricCyan
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lvl['title']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // CTA Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SparkLingoTheme.electricCyan,
                      foregroundColor: SparkLingoTheme.surfaceCanvas,
                      minimumSize: const Size.fromHeight(50),
                      elevation: 4,
                      shadowColor: SparkLingoTheme.electricCyan.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: SparkLingoTheme.surfaceCanvas,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start Learning ${LanguageCatalog.displayName(_selectedLang)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
