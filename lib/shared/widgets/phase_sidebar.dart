import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/language_theme_registry.dart';

/// Learning-path (phase/unit) navigation sidebar for the home screen.
///
/// Shown as a permanent leading panel on wide layouts and as an end drawer on
/// compact layouts ([PhaseSidebar.drawerBody]). Tapping a phase scrolls the
/// matching unit into view via [onUnitSelected].
class PhaseSidebar extends StatelessWidget {
  final String langCode;
  final List<(String id, String title)> units;
  final int selectedUnitIndex;
  final ValueChanged<int> onUnitSelected;

  const PhaseSidebar({
    super.key,
    required this.langCode,
    required this.units,
    required this.selectedUnitIndex,
    required this.onUnitSelected,
  });

  static const double panelWidth = 250;

  /// Drawer variant used by compact layouts.
  static Widget drawerBody({
    required BuildContext scaffoldContext,
    required String langCode,
    required List<(String id, String title)> units,
    required int selectedUnitIndex,
    required ValueChanged<int> onUnitSelected,
  }) {
    return PhaseSidebar(
      langCode: langCode,
      units: units,
      selectedUnitIndex: selectedUnitIndex,
      onUnitSelected: (index) {
        Navigator.of(scaffoldContext).pop();
        onUnitSelected(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = LanguageThemeRegistry.themeFor(langCode);
    return Container(
      width: panelWidth,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: national symbol + language names.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SvgPicture.asset(
                    theme.motifAsset,
                    width: 40,
                    height: 40,
                    placeholderBuilder: (_) =>
                        const SizedBox(width: 40, height: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${units.length} phases',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'LEARNING PATH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          // Phase list.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: units.length,
              itemBuilder: (context, index) {
                final selected = index == selectedUnitIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: selected
                        ? theme.primaryColor.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onUnitSelected(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? theme.primaryColor
                                    : const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                units[index].$2,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.3,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? theme.primaryColor
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
