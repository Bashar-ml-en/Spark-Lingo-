import 'package:flutter/material.dart';

/// SparkLingo design tokens — the single source of truth for layout metrics.
///
/// Every new widget should consume these instead of raw numbers so the whole
/// app moves as one system. Existing screens migrate to them incrementally.

/// 8-point spacing grid with half-step for tight clusters.
abstract final class SparkSpacing {
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const EdgeInsets padXs = EdgeInsets.all(xs);
  static const EdgeInsets padMd = EdgeInsets.all(md);
  static const EdgeInsets padLg = EdgeInsets.all(lg);
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: md);
}

/// Corner-radius scale: chips/buttons small, cards medium, sheets large.
abstract final class SparkRadius {
  static const double chip = 8;
  static const double button = 12;
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 999;

  static BorderRadius get chipRadius => BorderRadius.circular(chip);
  static BorderRadius get buttonRadius => BorderRadius.circular(button);
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get sheetRadius => BorderRadius.circular(sheet);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
  static BorderRadius get sheetTopRadius => const BorderRadius.only(
        topLeft: Radius.circular(sheet),
        topRight: Radius.circular(sheet),
      );
}

/// Elevation scale. Shadows stay subtle in light mode; dark mode relies on
/// surface color steps instead (per Material 3 dark guidance).
abstract final class SparkShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  static const List<BoxShadow> overlay = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

/// Motion tokens: durations + curves. Kept short — perceived responsiveness
/// beats theatrical animation in a practice app.
abstract final class SparkMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve ease = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// Touch-target and component sizing (WCAG/AA minimum is 48dp).
abstract final class SparkSize {
  static const double touchTarget = 48;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double avatarSm = 32;
  static const double avatarMd = 44;
  static const double progressHeight = 10;
}

/// Semantic status colors shared by streaks, XP, and feedback states.
abstract final class SparkStatus {
  static const Color streak = Color(0xFFFF9500);
  static const Color xp = Color(0xFFFFC800);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color danger = Color(0xFFFF1744);
  static const Color info = Color(0xFF2196F3);
}
