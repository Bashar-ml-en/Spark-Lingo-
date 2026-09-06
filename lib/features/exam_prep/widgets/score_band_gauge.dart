import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class ScoreBandGauge extends StatelessWidget {
  final String currentLevel;
  final String targetLevel;
  final double progress; // 0.0 to 1.0
  final double? score; // e.g. 7.5
  final String? bandTitle; // e.g. "Good User"

  const ScoreBandGauge({
    super.key,
    required this.currentLevel,
    required this.targetLevel,
    required this.progress,
    this.score,
    this.bandTitle,
  });

  @override
  Widget build(BuildContext context) {
    final displayScore = score != null ? score!.toStringAsFixed(1) : currentLevel;
    final displayDesc = bandTitle ?? 'Proficiency Level';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: SparkLingoTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SparkLingoTheme.surfaceContainerHighest,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXAM READINESS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: SparkLingoTheme.electricCyan,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SparkLingoTheme.electricCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: SparkLingoTheme.electricCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${(progress * 100).toInt()}% CONFIDENCE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: SparkLingoTheme.electricCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Semicircular Gauge
          SizedBox(
            height: 140,
            width: 240,
            child: CustomPaint(
              painter: _SemiCircularGaugePainter(
                progress: progress.clamp(0.0, 1.0),
                trackColor: SparkLingoTheme.surfaceContainerHighest,
                primaryColor: SparkLingoTheme.electricCyan,
                accentColor: SparkLingoTheme.solarGold,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayScore,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                            height: 1.0,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayDesc.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SparkLingoTheme.solarGold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Target level trajectory
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SparkLingoTheme.surfaceCanvas.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: SparkLingoTheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrajectoryNode(
                  context,
                  label: 'CURRENT',
                  value: currentLevel,
                  color: SparkLingoTheme.electricCyan,
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
                _buildTrajectoryNode(
                  context,
                  label: 'TARGET',
                  value: targetLevel,
                  color: SparkLingoTheme.solarGold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrajectoryNode(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _SemiCircularGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color primaryColor;
  final Color accentColor;

  _SemiCircularGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 16;
    const strokeWidth = 14.0;

    // Track arc (-pi to 0)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    if (progress > 0) {
      final sweepAngle = math.pi * progress;
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: math.pi,
          endAngle: 2 * math.pi,
          colors: [primaryColor, accentColor],
          tileMode: TileMode.clamp,
          transform: GradientRotation(math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        sweepAngle,
        false,
        progressPaint,
      );

      // Indicator pip at the tip
      final tipAngle = math.pi + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(tipX, tipY), 9, glowPaint);

      final pipPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(tipX, tipY), 4, pipPaint);
    }
  }

  @override
  bool shouldRepaint(_SemiCircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
