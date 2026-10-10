import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/components.dart';

/// LingoPulse AI — Tri-Mode Cognitive Decoder Widget
/// Directly implements Stitch Screen b73623d2fea542c389abcfce2f5a8f18:
/// 3-Mode Cognitive Switcher:
/// 1. Natural EN: Idiomatic conversational translation
/// 2. Literal Gloss: Word-for-word grammatical syntactic alignment
/// 3. Pragmatics: Cultural and socio-linguistic mechanics breakdown
class TriModeDecoderWidget extends StatefulWidget {
  final String foreignPhrase;
  final String naturalEn;
  final List<Map<String, String>> literalTokens;
  final String pragmaticNotes;
  final String contextLocation;

  const TriModeDecoderWidget({
    super.key,
    required this.foreignPhrase,
    required this.naturalEn,
    required this.literalTokens,
    required this.pragmaticNotes,
    this.contextLocation = 'Atmospheric Scenario Dialogue',
  });

  @override
  State<TriModeDecoderWidget> createState() => _TriModeDecoderWidgetState();
}

class _TriModeDecoderWidgetState extends State<TriModeDecoderWidget> {
  int _activeDecoderMode = 0; // 0 = Natural EN, 1 = Literal Gloss, 2 = Pragmatics

  @override
  Widget build(BuildContext context) {
    return StitchGlassCard(
      isElevated: true,
      borderColor: StitchTokens.borderAmberHairline,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scenario Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: StitchTokens.primaryEmber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.contextLocation.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: StitchTokens.primaryEmber,
                      letterSpacing: 1.0,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
              const StitchCefrBadge(level: 'B2+'),
            ],
          ),
          const SizedBox(height: 12),

          // Foreign Phrase
          Text(
            widget.foreignPhrase,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.4,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 16),

          // Tri-Mode Tab Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: StitchTokens.surfaceLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: StitchTokens.borderHairline),
            ),
            child: Row(
              children: [
                _buildModeTab(0, 'Natural EN'),
                _buildModeTab(1, 'Literal Gloss'),
                _buildModeTab(2, 'Pragmatics'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Decoder Mode Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildModeContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(int index, String label) {
    final isSelected = _activeDecoderMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeDecoderMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? StitchTokens.surfaceDefault
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: StitchTokens.borderAmberHairline)
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : StitchTokens.textSecondary,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeContent() {
    switch (_activeDecoderMode) {
      case 0:
        return Container(
          key: const ValueKey('mode_natural'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StitchTokens.surfaceLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.translate_rounded,
                size: 18,
                color: StitchTokens.primaryEmber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '“${widget.naturalEn}”',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );

      case 1:
        return Container(
          key: const ValueKey('mode_gloss'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StitchTokens.surfaceLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 8,
            children: widget.literalTokens.map((token) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: StitchTokens.surfaceLowest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: StitchTokens.borderHairline),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      token['word'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      token['gloss'] ?? '',
                      style: const TextStyle(
                        fontSize: 10,
                        color: StitchTokens.primaryEmber,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );

      case 2:
      default:
        return Container(
          key: const ValueKey('mode_pragmatics'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StitchTokens.surfaceLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: StitchTokens.borderAmberHairline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                size: 18,
                color: StitchTokens.accentAmber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.pragmaticNotes,
                  style: const TextStyle(
                    fontSize: 12,
                    color: StitchTokens.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
