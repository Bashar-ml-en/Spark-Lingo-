import 'package:flutter/material.dart';

/// Depth layering system (UX audit rule #95).
///
/// One z-axis vocabulary for the whole app: every elevated surface uses a
/// layer from here instead of ad-hoc shadows, so layering reads the same
/// on every screen. Light mode uses neumorphic dual shadows (extruded
/// surfaces); dark mode uses elevation + subtle borders because paired
/// light/dark shadows lose contrast on near-black canvases.
abstract final class SparkDepth {
  // z0 — canvas / scaffold (no shadow).
  static const double z0 = 0;

  // z1 — cards, list tiles, chat bubbles.
  static const double z1 = 3;

  // z2 — active/dragged cards, selection states.
  static const double z2 = 8;

  // z3 — sheets, dialogs, floating bars.
  static const double z3 = 16;

  /// Card surface decoration for the current brightness.
  static BoxDecoration surface(
    BuildContext context, {
    double layer = z1,
    Color? color,
    BorderRadius? radius,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = radius ?? BorderRadius.circular(20);
    if (isDark) {
      return BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: r,
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: layer * 2,
            offset: Offset(0, layer / 2),
          ),
        ],
      );
    }
    // Light: soft dual shadows (top-left highlight, bottom-right shade).
    return BoxDecoration(
      color: color ?? theme.colorScheme.surface,
      borderRadius: r,
      boxShadow: [
        BoxShadow(
          color: Colors.white.withAlpha(220),
          blurRadius: layer * 2,
          offset: Offset(-layer / 2, -layer / 2),
        ),
        BoxShadow(
          color: const Color(0xFF312E81).withAlpha(22),
          blurRadius: layer * 2,
          offset: Offset(layer / 2, layer / 2),
        ),
      ],
    );
  }
}
