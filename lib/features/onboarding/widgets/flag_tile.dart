import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design/getwidget_theme.dart';
import '../../../core/services/voice_controller.dart';

class FlagTile extends StatefulWidget {
  final String nativeName;
  final String englishName;
  final String flagAsset;
  final VoidCallback onTap;

  /// Native greeting displayed on the card and spoken on demand.
  final String greeting;

  /// Language key used for TTS of the greeting.
  final String languageKey;

  /// Shows a "Popular" GFBadge on the card (Malay-first highlights).
  final bool popular;

  const FlagTile({
    super.key,
    required this.nativeName,
    required this.englishName,
    required this.flagAsset,
    required this.onTap,
    required this.greeting,
    required this.languageKey,
    this.popular = false,
  });

  @override
  State<FlagTile> createState() => _FlagTileState();
}

class _FlagTileState extends State<FlagTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  /// Shared voice controller (one utterance at a time across the grid).
  static final VoiceController _voice = VoiceController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Run anim and reverse quickly
    _controller.forward().then((_) => _controller.reverse());
    // Trigger navigation callback immediately without waiting/blocking
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Stack(
                  children: [
                    // GetWidget GFCard themed once via SparkGF — consistent
                    // radius/elevation/border across the whole app.
                    SparkGF.card(
                      margin: EdgeInsets.zero,
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Flag container ensuring 48dp+ tap targets
                          Container(
                            width: 64,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.dividerColor.withAlpha(90),
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SvgPicture.asset(
                              widget.flagAsset,
                              fit: BoxFit.cover,
                              placeholderBuilder: (BuildContext context) =>
                                  Container(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.nativeName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.englishName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Interactive greeting: see it, then hear it.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.greeting,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hear the greeting',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  icon: Icon(
                                    Icons.volume_up_rounded,
                                    size: 15,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    _voice.toggle(
                                      widget.greeting,
                                      widget.languageKey,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.popular)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: SparkGF.badge(
                          'Popular',
                          color: const Color(0xFF16A34A).withAlpha(26),
                          textColor: const Color(0xFF15803D),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
