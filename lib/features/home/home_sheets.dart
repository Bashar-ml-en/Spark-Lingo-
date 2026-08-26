import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/spaced_repetition_service.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/widgets/flag_grid.dart';
import 'flashcard_study_session.dart';

/// Bottom sheet listing a lesson's flashcards with due-review logic.
void showVocabularySheet(
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
                                        FlashcardStudySession(
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

/// Bottom sheet for switching or adding the active language.
void showLanguageSwitcher(
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
