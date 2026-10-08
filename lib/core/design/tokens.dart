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
  static const Color streak = Color(0xFFF59E0B);
  static const Color xp = Color(0xFF6366F1);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFF43F5E);
  static const Color info = Color(0xFF6366F1);
}

/// Stitch Design System — LingoCraft Obsidian palette & specular tokens.
abstract final class StitchTokens {
  // Foundation Surfaces (OLED Deep Obsidian Architecture)
  static const Color canvasBase = Color(0xFF090A0F);
  static const Color surfaceLowest = Color(0xFF0B0E18);
  static const Color surfaceLow = Color(0xFF12141F);
  static const Color surfaceDefault = Color(0xFF1D1F2A);
  static const Color surfaceHigh = Color(0xFF272935);
  static const Color surfaceHighest = Color(0xFF323440);
  static const Color borderHairline = Color(0xFF2A2F45);
  static const Color borderSubtle = Color(0x402A2F45);

  // Semantic & Performance Accents
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color masteryEmerald = Color(0xFF10B981);
  static const Color kineticAmber = Color(0xFFF59E0B);
  static const Color diagnosticRose = Color(0xFFF43F5E);

  // Text Contrast Tiers
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF475569);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryIndigo, primaryViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGlow = LinearGradient(
    colors: [Color(0x336366F1), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Specular Edge & Halos
  static const List<BoxShadow> activeVoiceGlow = [
    BoxShadow(
      color: Color(0x406366F1),
      blurRadius: 24,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> masteryGlow = [
    BoxShadow(
      color: Color(0x3310B981),
      blurRadius: 20,
    ),
  ];

  static const List<BoxShadow> diagnosticGlow = [
    BoxShadow(
      color: Color(0x33F43F5E),
      blurRadius: 16,
    ),
  ];
}
