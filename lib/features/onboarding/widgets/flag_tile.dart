import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FlagTile extends StatefulWidget {
  final String nativeName;
  final String englishName;
  final String flagAsset;
  final VoidCallback onTap;

  const FlagTile({
    super.key,
    required this.nativeName,
    required this.englishName,
    required this.flagAsset,
    required this.onTap,
  });

  @override
  State<FlagTile> createState() => _FlagTileState();
}

class _FlagTileState extends State<FlagTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(opacity: _fadeAnimation.value, child: child),
            );
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x05000000),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flag container ensuring 48dp+ tap targets
                Container(
                  width: 64,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFF3F4F6),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SvgPicture.asset(
                    widget.flagAsset,
                    fit: BoxFit.cover,
                    placeholderBuilder: (BuildContext context) => Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Native name as the primary label
                Text(
                  widget.nativeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // English name as a smaller subtitle
                Text(
                  widget.englishName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
