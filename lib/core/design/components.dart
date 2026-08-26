import 'package:flutter/material.dart';

import 'tokens.dart';

/// SparkLingo core UI components. Everything here consumes the design tokens
/// so spacing, radii, motion, and sizing stay consistent app-wide.

/// Primary action button with the pressed-depth affordance: a darker bottom
/// edge that compresses on press (Duolingo-style 3D tactile feel) without
/// losing the flat-premium look.
class SparkButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;
  final SparkButtonVariant variant;

  const SparkButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = false,
    this.variant = SparkButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color background;
    final Color foreground;
    switch (variant) {
      case SparkButtonVariant.primary:
        background = colorScheme.primary;
        foreground = colorScheme.onPrimary;
      case SparkButtonVariant.secondary:
        background = colorScheme.secondary;
        foreground = colorScheme.onSecondary;
      case SparkButtonVariant.surface:
        background = colorScheme.surfaceContainerHighest;
        foreground = colorScheme.onSurface;
    }

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SparkSpacing.lg,
        vertical: SparkSpacing.sm,
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: SparkSize.iconMd),
            const SizedBox(width: SparkSpacing.xs),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foreground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: SparkRadius.buttonRadius,
            onTap: onPressed,
            child: Container(
              width: expanded ? double.infinity : null,
              decoration: BoxDecoration(
                color: background,
                borderRadius: SparkRadius.buttonRadius,
                boxShadow: const [
                  // The tactile bottom edge.
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 0,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

enum SparkButtonVariant { primary, secondary, surface }

/// Rounded progress bar used for lesson progress and streak goals.
class SparkProgressBar extends StatelessWidget {
  final double progress; // 0.0 .. 1.0
  final Color? color;
  final Color? trackColor;
  final double height;

  const SparkProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.trackColor,
    this.height = SparkSize.progressHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = progress.clamp(0.0, 1.0);
    final barColor = color ?? theme.colorScheme.primary;
    final track = trackColor ?? theme.colorScheme.surfaceContainerHighest;

    return Semantics(
      label: 'Progress',
      value: '${(clamped * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(color: track),
                  AnimatedFractionallySizedBox(
                    duration: SparkMotion.standard,
                    curve: SparkMotion.ease,
                    widthFactor: clamped,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Circular daily-goal ring (streak / XP goal) with a center label.
class SparkGoalRing extends StatelessWidget {
  final double progress; // 0.0 .. 1.0
  final String centerLabel;
  final Color? color;
  final double size;
  final double strokeWidth;

  const SparkGoalRing({
    super.key,
    required this.progress,
    required this.centerLabel,
    this.color,
    this.size = 72,
    this.strokeWidth = 7,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ringColor = color ?? theme.colorScheme.secondary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _GoalRingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: ringColor,
              trackColor: theme.colorScheme.surfaceContainerHighest,
              strokeWidth: strokeWidth,
            ),
          ),
          Center(
            child: Text(
              centerLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _GoalRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // start at 12 o'clock
      6.2832 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_GoalRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

/// Streak-flame counter pill shown in headers.
class SparkStreakBadge extends StatelessWidget {
  final int days;
  final bool activeToday;

  const SparkStreakBadge({
    super.key,
    required this.days,
    required this.activeToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lit = activeToday && days > 0;

    return Semantics(
      label: 'Streak',
      value: '$days days',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SparkSpacing.sm,
          vertical: SparkSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: lit
              ? SparkStatus.streak.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: SparkRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              lit ? Icons.local_fire_department : Icons.local_fire_department_outlined,
              size: SparkSize.iconMd,
              color: lit ? SparkStatus.streak : theme.colorScheme.outline,
            ),
            const SizedBox(width: SparkSpacing.xxs),
            Text(
              '$days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: lit ? SparkStatus.streak : theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// XP counter pill (experience points currency).
class SparkXpBadge extends StatelessWidget {
  final int xp;

  const SparkXpBadge({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Experience points',
      value: '$xp XP',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SparkSpacing.sm,
          vertical: SparkSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: SparkStatus.xp.withValues(alpha: 0.12),
          borderRadius: SparkRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bolt_rounded,
              size: SparkSize.iconMd,
              color: SparkStatus.xp,
            ),
            const SizedBox(width: SparkSpacing.xxs),
            Text(
              '$xp XP',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: SparkStatus.xp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Friendly empty state with an icon, message, and optional action.
class SparkEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SparkEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: SparkSpacing.padLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: SparkSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: SparkSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: SparkSpacing.lg),
              SparkButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder shown while async content loads.
class SparkSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SparkSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = SparkRadius.chip,
  });

  @override
  State<SparkSkeleton> createState() => _SparkSkeletonState();
}

class _SparkSkeletonState extends State<SparkSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surfaceContainerLowest;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value - 0.5, 0),
              end: Alignment(-1 + 2 * _controller.value + 0.5, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
