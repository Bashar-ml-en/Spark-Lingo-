import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/router/router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/spaced_repetition_service.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/models/language_theme.dart';
import '../../shared/widgets/flag_grid.dart';
import 'flashcard_study_session.dart';
import 'sparky_chat_session.dart';

/// Intro sheet that launches a free Sparky chat session.
void showAITutorSheet(BuildContext context, String activeLanguage) {
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
                        SparkyChatSession(language: activeLanguage),
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

/// Destructive account-deletion confirmation with typed confirmation.
void showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
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

/// First-launch language selector shown when no active language is set.
Widget buildLanguageSelector(
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

/// Shown when the chosen language has no reviewed curriculum yet.
Widget buildHomeEmptyState(
  BuildContext context,
  WidgetRef ref,
  LanguageTheme? theme,
  String langCode,
  void Function(BuildContext context, WidgetRef ref, String userId) onSwitchLanguage,
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
                onSwitchLanguage(context, ref, user.id);
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
