import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class AudioWaveVisualizer extends StatefulWidget {
  final bool isListening;
  final double height;
  final int barCount;
  final Color? color;
  final Color? glowColor;

  const AudioWaveVisualizer({
    super.key,
    this.isListening = true,
    this.height = 48,
    this.barCount = 10,
    this.color,
    this.glowColor,
  });

  @override
  State<AudioWaveVisualizer> createState() => _AudioWaveVisualizerState();
}

class _AudioWaveVisualizerState extends State<AudioWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Base multiplier pattern for 10 bars (symmetric bell curve)
  static const List<double> _baseMultipliers = [
    0.3, 0.55, 0.8, 1.0, 0.9, 0.75, 1.0, 0.85, 0.5, 0.35,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
      _controller.animateTo(0.2, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? SparkLingoTheme.electricCyan;
    final glow = widget.glowColor ?? primaryColor.withValues(alpha: 0.5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final base = _baseMultipliers[index % _baseMultipliers.length];
              final phase = (index * 0.25);
              final animVal = widget.isListening
                  ? (math.sin((_controller.value * 2 * math.pi) + phase) + 1) / 2
                  : 0.15;
              final barHeight = math.max(6.0, widget.height * (0.2 + 0.8 * base * animVal));

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4,
                height: barHeight,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    if (widget.isListening)
                      BoxShadow(
                        color: glow,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
