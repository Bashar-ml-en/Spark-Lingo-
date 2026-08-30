import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/router.dart';
import '../../core/services/database_service.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/models/user_profile.dart';
import '../monetization/paywall_screen.dart';
import '../academy/script_academy_screen.dart';
import '../settings/help_center_screen.dart';
import 'home_sheets.dart';

/// The signed-in user's side drawer: language list, premium entry,
/// settings, reset-languages, and account deletion.
Widget buildHomeDrawer({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required String? activeLanguage,
  required UserProfile profile,
  required void Function(BuildContext context, WidgetRef ref, String userId) onOpenLanguageSwitcher,
}) {
  final theme = Theme.of(context);
  return Drawer(
    child: Container(
      // Theme-aware: white in light mode, deep charcoal in dark mode.
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary.withAlpha(15),
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
                                  Padding(
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
                                        color: theme.colorScheme.onSurfaceVariant,
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
                                            color: theme.dividerColor,
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
                                              : theme.colorScheme.onSurface,
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
                                              userId,
                                              code,
                                            );
                                        ref.invalidate(
                                          userProfileProvider(userId),
                                        );
                                        if (context.mounted) {
                                          context.go('/home/$code');
                                        }
                                      },
                                    );
                                  }),
                                  Divider(
                                    color: theme.dividerColor,
                                    height: 24,
                                  ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.add,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(
                                      "Add a Language",
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onOpenLanguageSwitcher(
                                        context,
                                        ref,
                                        userId,
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
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  title: Text(
                                    isPremium
                                        ? "Spark Premium Active"
                                        : "Upgrade to Premium",
                                    style: TextStyle(
                                      color: isPremium
                                          ? Colors.amber.shade700
                                          : theme.colorScheme.onSurfaceVariant,
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
                              leading: Icon(
                                Icons.translate_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                'Writing Academy',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              subtitle: Text(
                                'Letters, sounds & scripts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withAlpha(170),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScriptAcademyScreen(
                                      languageKey: activeLanguage ?? 'en',
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.settings_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                'Settings & help',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                context.push(SparkRouter.settings);
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.help_outline_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                'Help center',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const HelpCenterScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.refresh,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                "Reset Active Languages",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
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
                                    .updateTargetLanguages(userId, []);
                                ref.invalidate(userProfileProvider(userId));
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
                                showDeleteAccountDialog(context, ref);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
}
