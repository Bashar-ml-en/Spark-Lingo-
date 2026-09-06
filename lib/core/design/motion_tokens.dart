import 'package:flutter/material.dart';

/// Motion tokens — generated from the ui-ux-pro-max skill's motion database
/// (data/motion.csv), converted from GSAP timing/easing to Flutter curves.
///
/// Intensity tiers from the skill:
///   Subtle:   250-350ms, power1.out  → entrance fades, small reveals
///   Standard: 400-600ms, power2.out  → card entrances, screen transitions
///   Complex:  300-500ms elastic      → AVOID on mobile (skill guidance:
///             magnetic/tilt effects fight native scroll, noisy past 1-2
///             focal elements)
///
/// Rule #99 Motion Sensitivity (High): honor reduced-motion preferences and
/// render the final readable state without decorative motion.
abstract final class SparkMotion {
  // Durations ----------------------------------------------------------
  static const Duration subtle = Duration(milliseconds: 300);
  static const Duration standard = Duration(milliseconds: 500);
  static const Duration feedback = Duration(milliseconds: 180); // tap/hover

  // Easing (decelerate when arriving, accelerate when leaving — rule #14)
  static const Curve arrive = Curves.easeOutCubic; // power2.out
  static const Curve leave = Curves.easeInCubic;
  static const Curve subtleArrive = Curves.easeOut; // power1.out
  static const Curve progress = Curves.linear;

  // Stagger (rule from skill: 0.02-0.04s per item, <=8 items, else laggy)
  static const Duration stagger = Duration(milliseconds: 35);
  static const int maxStaggerItems = 8;

  /// True when the user requested reduced motion (OS accessibility
  /// setting). Decorative animations must render their final state.
  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// Duration that becomes zero under reduced motion.
  static Duration d(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
