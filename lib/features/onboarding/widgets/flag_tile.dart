import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/theme.dart';


class FlagTile extends StatefulWidget {
  final String nativeName;
  final String englishName;
  final String flagAsset;
  final bool isSelected;
  final VoidCallback onTap;

  /// Native greeting displayed on the card and spoken on demand.
  final String? greeting;
/// Language key used for TTS of the greeting.
  final String? languageKey;
/// Shows a "Popular" GFBadge on the card (Malay-first highlights).
  final bool popular;

  const FlagTile({
    super.key,
    required this.nativeName,
    required this.englishName,
    required this.flagAsset,
    this.isSelected = false,
    required this.onTap,
    this.greeting,
this.languageKey,
this.popular = false,
  });

  @override
  State<FlagTile> createState() => _FlagTileState();
}

class _FlagTileState extends State<FlagTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  /// Shared voice controller (one utterance at a time across the grid).
  
  @override
  void initState() {
    super.initState();
    // SparkMotion.feedback (180ms) — press feedback per the motion
    // database; keep displacement under 2px scale change so it reads as
    // feedback, not motion (skill guidance).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final primaryCyan = SparkLingoTheme.electricCyan;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryCyan.withValues(alpha: 0.12)
                  : SparkLingoTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? primaryCyan
                    : SparkLingoTheme.surfaceContainerHighest,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: primaryCyan.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Flag Container
                    Container(
                      width: 52,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? primaryCyan.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SvgPicture.asset(
                        widget.flagAsset,
                        fit: BoxFit.cover,
                        placeholderBuilder: (context) => Container(
                          color: SparkLingoTheme.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // English Name
                    Text(
                      widget.englishName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Native script
                    Text(
                      widget.nativeName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? primaryCyan
                            : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: primaryCyan,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
