import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/models/language_theme.dart';

class LanguageSymbolBadge extends StatelessWidget {
  final String langCode;
  final double height;

  const LanguageSymbolBadge({
    super.key,
    required this.langCode,
    this.height = 26,
  });

  @override
  Widget build(BuildContext context) {
    LanguageTheme theme;
    try {
      theme = LanguageThemeRegistry.themeFor(langCode);
    } catch (e) {
      // Fallback if registry is uninitialized or code is completely invalid
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flag SVG
          Container(
            width: 20,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: SvgPicture.asset(
              theme.flags.isNotEmpty
                  ? theme.flags.first.flagAsset
                  : 'assets/flags/en_us.svg',
              fit: BoxFit.cover,
              placeholderBuilder: (context) =>
                  Container(color: const Color(0xFFE5E7EB)),
            ),
          ),
          const SizedBox(width: 6),
          // Motif Icon SVG
          SvgPicture.asset(
            theme.motifAsset,
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
            placeholderBuilder: (context) =>
                const SizedBox(width: 14, height: 14),
          ),
        ],
      ),
    );
  }
}
