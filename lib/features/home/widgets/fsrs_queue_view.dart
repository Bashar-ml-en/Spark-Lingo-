import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/components.dart';

/// LingoPulse AI — FSRS Morphological Spaced Repetition Queue
/// Directly implements Stitch Screen 556092434328406111:
/// FSRS Stability decay bars, root card queue, retrievability scoring,
/// and high-intensity 3-minute sprint launcher.
class FsrsQueueView extends StatefulWidget {
  final String languageCode;
  final VoidCallback? onStartSprint;

  const FsrsQueueView({
    super.key,
    required this.languageCode,
    this.onStartSprint,
  });

  @override
  State<FsrsQueueView> createState() => _FsrsQueueViewState();
}

class _FsrsQueueViewState extends State<FsrsQueueView> {
  bool _sprintActive = false;

  List<Map<String, dynamic>> _getQueueItems(String code) {
    return switch (code.toLowerCase()) {
      'ar' => [
        {
          'root': 'ك - ت - ب',
          'transcription': 'K-T-B',
          'derivationCount': 12,
          'stabilityDays': 14.2,
          'retention': 0.92,
          'status': 'Decaying (Due Today)',
          'isDue': true,
        },
        {
          'root': 'ع - ل - م',
          'transcription': '‘-L-M',
          'derivationCount': 9,
          'stabilityDays': 28.5,
          'retention': 0.97,
          'status': 'Stable (In 4 Days)',
          'isDue': false,
        },
        {
          'root': 'ح - ك - م',
          'transcription': 'Ḥ-K-M',
          'derivationCount': 8,
          'stabilityDays': 3.1,
          'retention': 0.74,
          'status': 'Critical Attention',
          'isDue': true,
        },
        {
          'root': 'ن - ظ - ر',
          'transcription': 'N-Ẓ-R',
          'derivationCount': 11,
          'stabilityDays': 45.0,
          'retention': 0.99,
          'status': 'Solidified Long-Term',
          'isDue': false,
        },
      ],
      'es' => [
        {
          'root': 'Escribir / Scrib-',
          'transcription': 'Writing Morpheme',
          'derivationCount': 8,
          'stabilityDays': 12.0,
          'retention': 0.88,
          'status': 'Decaying (Due Today)',
          'isDue': true,
        },
        {
          'root': 'Poner / Posit-',
          'transcription': 'Placement / Hospitality',
          'derivationCount': 14,
          'stabilityDays': 18.4,
          'retention': 0.94,
          'status': 'Stable (In 2 Days)',
          'isDue': false,
        },
        {
          'root': 'Haber / Habit-',
          'transcription': 'Auxiliary & Existential',
          'derivationCount': 6,
          'stabilityDays': 4.5,
          'retention': 0.76,
          'status': 'Critical Review',
          'isDue': true,
        },
      ],
      'ms' => [
        {
          'root': 'Tulis',
          'transcription': 'Awalan meN- & peN-',
          'derivationCount': 7,
          'stabilityDays': 15.0,
          'retention': 0.91,
          'status': 'Decaying (Due Today)',
          'isDue': true,
        },
        {
          'root': 'Bantu',
          'transcription': 'Bantuan & Membantu',
          'derivationCount': 5,
          'stabilityDays': 32.0,
          'retention': 0.98,
          'status': 'Solidified',
          'isDue': false,
        },
        {
          'root': 'Jual',
          'transcription': 'Penjual & Jualan',
          'derivationCount': 6,
          'stabilityDays': 5.2,
          'retention': 0.79,
          'status': 'Review Needed',
          'isDue': true,
        },
      ],
      _ => [
        {
          'root': 'Write / Script',
          'transcription': 'Core Lexeme',
          'derivationCount': 6,
          'stabilityDays': 14.0,
          'retention': 0.90,
          'status': 'Due for Review',
          'isDue': true,
        },
        {
          'root': 'Speak / Phon',
          'transcription': 'Acoustic Morpheme',
          'derivationCount': 8,
          'stabilityDays': 21.0,
          'retention': 0.95,
          'status': 'Stable',
          'isDue': false,
        },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = _getQueueItems(widget.languageCode);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // FSRS Algorithm Header
        const Text(
          'FSRS-4.5 ADAPTIVE SCHEDULING',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: StitchTokens.primaryEmber,
            letterSpacing: 1.5,
            fontFamily: 'JetBrains Mono',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Morphological Memory Queue',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Plus Jakarta Sans',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Retrievability is calculated dynamically using memory decay curves (R = e^-t/S). Keep roots stabilized.',
          style: TextStyle(
            fontSize: 13,
            color: StitchTokens.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Sprint Launcher CTA Card
        StitchGlassCard(
          isElevated: true,
          borderColor: StitchTokens.borderAmberHairline,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: StitchTokens.primaryTerracotta.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: StitchTokens.primaryEmber,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'HIGH-INTENSITY MORPHO SPRINT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: StitchTokens.primaryEmber,
                          letterSpacing: 0.8,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '3 MINS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: StitchTokens.accentAmber,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Review 2 decaying morphological roots and consolidate 18 derived branch tokens before memory decay reaches critical threshold.',
                style: TextStyle(
                  fontSize: 13,
                  color: StitchTokens.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() => _sprintActive = true);
                  widget.onStartSprint?.call();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: StitchTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: StitchTokens.primaryTerracotta.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _sprintActive
                          ? 'SPRINT ACTIVE — READY'
                          : 'BEGIN 12-ROOT SPRINT (3 MINS)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Queue Items Header
        const Text(
          'ACTIVE ROOT REPOSITORIES IN MEMORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: StitchTokens.textTertiary,
            letterSpacing: 1.0,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 10),

        // List of Root Cards
        ...items.map((item) {
          final retention = item['retention'] as double;
          final isDue = item['isDue'] as bool;
          final retentionPercent = (retention * 100).toInt();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: StitchGlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: isDue
                  ? StitchTokens.borderAmberHairline
                  : StitchTokens.borderHairline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['root'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '(${item['transcription']})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: StitchTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDue
                              ? StitchTokens.primaryTerracotta.withValues(alpha: 0.2)
                              : StitchTokens.accentTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['status'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDue
                                ? StitchTokens.primaryEmber
                                : StitchTokens.accentEmerald,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stability & Retention Metrics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STABILITY: ${item['stabilityDays']} DAYS',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: StitchTokens.textTertiary,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      Text(
                        'RETENTION: $retentionPercent%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: retention > 0.9
                              ? StitchTokens.accentEmerald
                              : StitchTokens.accentAmber,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: retention,
                      backgroundColor: StitchTokens.surfaceLowest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        retention > 0.9
                            ? StitchTokens.accentEmerald
                            : StitchTokens.primaryEmber,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}
