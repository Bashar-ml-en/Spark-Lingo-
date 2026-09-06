import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme.dart';

enum PathNodeState { completed, active, milestone, locked }

class PathNodeWidget extends StatefulWidget {
  final int index;
  final String title;
  final String? subtitle;
  final PathNodeState state;
  final int stars;
  final VoidCallback? onTap;

  const PathNodeWidget({
    super.key,
    required this.index,
    required this.title,
    this.subtitle,
    this.state = PathNodeState.locked,
    this.stars = 3,
    this.onTap,
  });

  @override
  State<PathNodeWidget> createState() => _PathNodeWidgetState();
}

class _PathNodeWidgetState extends State<PathNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.state == PathNodeState.active) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PathNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == PathNodeState.active &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.state != PathNodeState.active &&
        _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.state == PathNodeState.locked;
    final isActive = widget.state == PathNodeState.active;
    final isMilestone = widget.state == PathNodeState.milestone;
    final isCompleted = widget.state == PathNodeState.completed;

    return Semantics(
      label: 'Unit ${widget.index}: ${widget.title}, state: ${widget.state.name}',
      button: !isLocked,
      enabled: !isLocked,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SparkTheme.electricCyan,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x6600E5FF),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00363D),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'TAP TO RESUME',
                      style: TextStyle(
                        color: Color(0xFF00363D),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            GestureDetector(
              onTap: isLocked
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onTap?.call();
                    },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isActive ? _pulseAnimation.value : 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Glow aura for active/milestone
                        if (isActive)
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SparkTheme.electricCyan.withAlpha(50),
                            ),
                          ),
                        if (isMilestone)
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SparkTheme.solarGold.withAlpha(60),
                            ),
                          ),
                        // Main circular node body
                        Container(
                          width: isActive ? 72 : 64,
                          height: isActive ? 72 : 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isMilestone
                                ? const LinearGradient(
                                    colors: [
                                      SparkTheme.solarGold,
                                      SparkTheme.solarGoldContainer,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : isActive
                                    ? const LinearGradient(
                                        colors: [
                                          SparkTheme.primaryCyanDim,
                                          SparkTheme.electricCyan,
                                          SparkTheme.primaryCyan,
                                        ],
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight,
                                      )
                                    : null,
                            color: (!isActive && !isMilestone)
                                ? SparkTheme.surfaceContainerHighest
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: isMilestone
                                    ? const Color(0x55FFB77A)
                                    : isActive
                                        ? const Color(0x6600E5FF)
                                        : Colors.black.withAlpha(80),
                                blurRadius: isActive || isMilestone ? 16 : 8,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: isActive ? 52 : 44,
                              height: isActive ? 52 : 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? SparkTheme.surfaceContainerLowest
                                    : isCompleted
                                        ? SparkTheme.surfaceBright
                                        : SparkTheme.surfaceContainer,
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : isActive
                                        ? Icons.play_arrow_rounded
                                        : isMilestone
                                            ? Icons.military_tech_rounded
                                            : Icons.lock_rounded,
                                color: isCompleted
                                    ? SparkTheme.electricCyan
                                    : isActive
                                        ? SparkTheme.electricCyan
                                        : isMilestone
                                            ? SparkTheme.solarGoldFixed
                                            : SparkTheme.outlineColor,
                                size: isActive ? 32 : 24,
                              ),
                            ),
                          ),
                        ),
                        // 3 Stars badge for completed
                        if (isCompleted)
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: SparkTheme.solarGoldContainer,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  widget.stars.clamp(1, 3),
                                  (i) => const Icon(
                                    Icons.star_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Trophy ribbon for milestone
                        if (isMilestone)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: SparkTheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.stars_rounded,
                                size: 14,
                                color: SparkTheme.solarGold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? SparkTheme.electricCyan
                          : isMilestone
                              ? SparkTheme.solarGold
                              : SparkTheme.textPrimary,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? SparkTheme.textSecondary
                            : SparkTheme.outlineColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
