import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';

/// Top Navigation Bar adhering to the world-class Stitch design system.
///
/// Layout:
/// [ Logo Badge ]  [ 🇪🇸 ES (B2) ⌵ ]  [ 🔥 21 ]  [ ⚡ 1.4k XP ]  [ ☀️/🌙 ]  [ 👤● ]
class StitchTopBar extends ConsumerWidget {
  final String? activeLanguage;
  final int streakDays;
  final int totalXP;
  final VoidCallback? onLogoTap;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onProfileTap;
  final bool showSubTabs;
  final String activeSubTab;
  final ValueChanged<String>? onSubTabSelected;

  const StitchTopBar({
    super.key,
    this.activeLanguage,
    this.streakDays = 21,
    this.totalXP = 1480,
    this.onLogoTap,
    this.onLanguageTap,
    this.onProfileTap,
    this.showSubTabs = false,
    this.activeSubTab = 'pathway',
    this.onSubTabSelected,
  });

  static String flagEmoji(String? code) {
    if (code == null) return '🇪🇸';
    switch (code.toLowerCase()) {
      case 'es':
        return '🇪🇸';
      case 'ru':
        return '🇷🇺';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'zh':
        return '🇨🇳';
      case 'ar':
        return '🇸🇦';
      case 'hi':
        return '🇮🇳';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇧🇷';
      case 'en':
        return '🇺🇸';
      default:
        return '🌐';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = SparkTheme.isDarkMode(context);
    final langCode = activeLanguage ?? 'es';
    final langUpper = langCode.toUpperCase();
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: SparkTheme.bg(context),
        border: Border(
          bottom: BorderSide(
            color: SparkTheme.border(context).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // 1. Far Left: Stitch Cyber Logo Emblem Box
                  GestureDetector(
                    onTap: onLogoTap ??
                        () {
                          try {
                            Scaffold.of(context).openDrawer();
                          } catch (_) {}
                        },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF071322),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SparkLingoTheme.electricCyan.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SparkLingoTheme.electricCyan.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: const [
                            Icon(
                              Icons.shield_rounded,
                              color: SparkLingoTheme.electricCyan,
                              size: 22,
                            ),
                            Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFF071322),
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Language Selector Pill [ 🇪🇸 ES (B2) ⌵ ]
                  GestureDetector(
                    onTap: onLanguageTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          Text(
                            flagEmoji(langCode),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$langUpper (B2)',
                            style: TextStyle(
                              color: SparkTheme.text(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: SparkTheme.subtext(context),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 3. Streak Pill [ 🔥 21 ]
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: SparkLingoTheme.solarGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: SparkLingoTheme.solarGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: SparkLingoTheme.solarGold,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$streakDays',
                          style: const TextStyle(
                            color: SparkLingoTheme.solarGold,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 4. XP Pill [ ⚡ 1,480 XP ]
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFF0284C7),
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${_formatXP(totalXP)} XP',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 5. Theme Switcher [ ☀️ / 🌙 ]
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.wb_sunny_rounded
                          : Icons.dark_mode_rounded,
                      color: themeMode == ThemeMode.dark
                          ? SparkLingoTheme.solarGold
                          : const Color(0xFF0284C7),
                      size: 18,
                    ),
                    tooltip: themeMode == ThemeMode.dark
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).state =
                          themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                    },
                  ),
                  const SizedBox(width: 4),

                  // 6. Profile Avatar [ 👤 ● ]
                  GestureDetector(
                    onTap: onProfileTap ?? () => context.push('/settings'),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SparkTheme.cardBg(context),
                            border: Border.all(
                              color: SparkTheme.border(context),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981),
                            border: Border.all(
                              color: SparkTheme.cardBg(context),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Optional Sub-header Tabs (Pathway / Boss Drills / Immersion)
            if (showSubTabs) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: SparkTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SparkTheme.border(context)),
                  ),
                  child: Row(
                    children: [
                      _buildSubTab(context, 'Pathway', Icons.route_rounded, 'pathway'),
                      _buildSubTab(context, 'Boss Drills', Icons.military_tech_rounded, 'boss_drills'),
                      _buildSubTab(context, 'Immersion', Icons.headphones_rounded, 'immersion'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubTab(BuildContext context, String label, IconData icon, String tabId) {
    final isSelected = activeSubTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSubTabSelected?.call(tabId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? SparkLingoTheme.electricCyan.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? SparkLingoTheme.electricCyan.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? SparkLingoTheme.electricCyan
                    : SparkTheme.subtext(context),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? SparkLingoTheme.electricCyan
                      : SparkTheme.subtext(context),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatXP(int xp) {
    if (xp >= 1000) {
      final k = xp / 1000.0;
      return '${k.toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return '$xp';
  }
}
