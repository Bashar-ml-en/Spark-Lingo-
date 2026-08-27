import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens.dart';
import '../../core/services/database_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/language_catalog.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/widgets/flag_grid.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Choose a Language',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SparkSpacing.lg,
                vertical: SparkSpacing.sm,
              ),
              child: Text(
                'Select a language with lessons and guided practice available in this release',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: FlagGrid(
                onLanguageSelected: (langCode, flagInfo) async {
                  if (user == null) return;
                  final canonicalCode = LanguageCatalog.canonicalCode(langCode);
                  final previousLocalLanguage = ref.read(
                    localActiveLanguageProvider,
                  );

                  // 1. Instantly override local active language (flash-free transition)
                  ref.read(localActiveLanguageProvider.notifier).state =
                      canonicalCode;

                  // 2. Persist to Supabase database (background update)
                  var saved = false;
                  try {
                    final profile = await ref
                        .read(databaseServiceProvider)
                        .getProfile(user.id);
                    if (profile != null) {
                      final list = List<String>.from(profile.targetLanguages);
                      if (!list.contains(canonicalCode)) {
                        list.insert(0, canonicalCode);
                      } else {
                        // Move to front
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
                    // Refresh profile provider
                    ref.invalidate(userProfileProvider(user.id));
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

                  // 3. Navigate to Localized Home screen
                  if (saved && context.mounted) {
                    context.go('/home/$canonicalCode');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
