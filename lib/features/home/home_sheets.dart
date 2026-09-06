import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/router/router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/language_theme_registry.dart';
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

