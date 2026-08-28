import 'package:flutter/material.dart';

/// Light neumorphism tokens.
///
/// Neumorphism ("soft UI") extrudes surfaces from the background using a
/// pair of opposing shadows: a light highlight top-left and a soft dark
/// shadow bottom-right. These tokens keep it subtle and accessible:
///   * background is an off-white (never pure white, which kills the effect)
///   * shadows are low-alpha so contrast stays WCAG-friendly
///   * pressed elements invert to inset shadows
abstract final class SparkNeumorph {
  // Canvas ------------------------------------------------------------
  static const Color canvas = Color(0xFFF2F4F8);
  static const Color surface = Color(0xFFF2F4F8); // extruded = same as canvas
  static const Color ink = Color(0xFF3B4256);
  static const Color inkSoft = Color(0xFF8A91A8);

  // Shadow pair --------------------------------------------------------
  static const Color _light = Colors.white;
  static const Color _dark = Color(0x29B0B8CE); // ~16% blue-gray

  /// Extruded card: rises off the canvas.
  static List<BoxShadow> raised({double distance = 6, double blur = 14}) => [
        BoxShadow(
          color: _light,
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: _dark,
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
      ];

  /// Pressed/inset: element pushed into the canvas.
  static List<BoxShadow> inset({double distance = 4, double blur = 9}) => [
        BoxShadow(
          color: _dark,
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: _light,
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
      ];

  // Radii ---------------------------------------------------------------
  static const double card = 24;
  static const double button = 16;
  static const double pill = 999;

  /// Extruded card decoration.
  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(card),
        boxShadow: raised(),
      );

  /// Inset field/track decoration.
  static BoxDecoration insetDecoration({Color? color}) => BoxDecoration(
        color: color ?? canvas,
        borderRadius: BorderRadius.circular(button),
        boxShadow: inset(),
      );
}

/// A neumorphically extruded container.
class SparkNeumorphCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const SparkNeumorphCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = SparkNeumorph.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SparkNeumorph.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: SparkNeumorph.raised(),
      ),
      child: child,
    );
  }
}

/// Neumorphic button: extruded at rest, inset while pressed.
class SparkNeumorphButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  const SparkNeumorphButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
  });

  @override
  State<SparkNeumorphButton> createState() => _SparkNeumorphButtonState();
}

class _SparkNeumorphButtonState extends State<SparkNeumorphButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: SparkNeumorph.surface,
          borderRadius: BorderRadius.circular(SparkNeumorph.button),
          boxShadow: _pressed ? SparkNeumorph.inset() : SparkNeumorph.raised(),
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: widget.child,
        ),
      ),
    );
  }
}
