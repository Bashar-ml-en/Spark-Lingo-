import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// GetWidget component theming, applied once globally.
///
/// GetWidget (getwidget.dev) ships Material components with neutral
/// defaults. Theming GFCard and GFButton HERE fixes visual drift across
/// every screen that uses them: consistent radius, elevation, colors, and
/// typography pulled from the SparkLingo design tokens.
abstract final class SparkGF {
  // Tokens shared with SparkTheme.lightTheme (ui-ux-pro-max palette).
  static const Color _canvas = Color(0xFFEEF2FF);
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _green = Color(0xFF16A34A);
  static const Color _border = Color(0xFFC7D2FE);

  /// Language-grid / lesson cards. Consistent radius 20 + soft elevation.
  static GFCard card({
    required Widget content,
    Widget? title,
    GFPosition? titlePosition,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return GFCard(
      color: Colors.white,
      elevation: 3,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      titlePosition: titlePosition,
      title: title is GFListTile ? title : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border, width: 1),
      ),
      content: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }

  /// Primary CTA (Get Started, purchase, confirm language).
  static GFButton primaryButton({
    required VoidCallback? onPressed,
    required String label,
    Widget? icon,
    bool expanded = false,
  }) {
    return GFButton(
      onPressed: onPressed,
      color: _primary,
      textColor: Colors.white,
      elevation: 0,
      hoverElevation: 1,
      shape: GFButtonShape.standard,
      type: GFButtonType.solid,
      size: GFSize.LARGE,
      blockButton: expanded,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      child: icon == null
          ? Text(label)
          : Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [icon, const SizedBox(width: 8), Text(label)],
            ),
    );
  }

  /// Small status tag: "Popular", "New", exam status chips.
  static GFBadge badge(String text, {Color? color, Color? textColor}) {
    return GFBadge(
      text: text,
      color: color ?? _primary.withAlpha(30),
      textColor: textColor ?? _primary,
      shape: GFBadgeShape.pills,
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      size: 22,
    );
  }

  /// Animated linear progress — daily goal, session progress, readiness.
  static GFProgressBar progress(
    double fraction, {
    Color? color,
    bool animation = true,
  }) {
    return GFProgressBar(
      percentage: fraction.clamp(0.0, 1.0),
      lineHeight: 12,
      backgroundColor: _canvas,
      progressBarColor: color ?? _green,
      animation: animation,
      animationDuration: 600,
    );
  }
}
