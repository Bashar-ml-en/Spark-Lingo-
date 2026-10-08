import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/components.dart';

/// Stitch Design System — Multimodal AI Voice Lab / Immersion View
/// Corresponds to Stitch screen: "Multimodal AI Voice Lab"
class ImmersionView extends StatelessWidget {
  final String languageCode;
  final VoidCallback onStartLiveSession;

  const ImmersionView({
    super.key,
    required this.languageCode,
    required this.onStartLiveSession,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Lab Hero Container
        StitchGlassCard(
          isElevated: true,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'ACOUSTIC SPEECH LAB',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: StitchTokens.primaryIndigo,
                  letterSpacing: 1.5,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Real-Time Multimodal Voice',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: StitchTokens.textPrimary,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Low-latency full conversational immersion with instant phonetic formant analysis and grammatical feedback.',
                style: TextStyle(
                  fontSize: 13,
                  color: StitchTokens.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Central Voice Capture Pulsing Actuator
              GestureDetector(
                onTap: onStartLiveSession,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: StitchTokens.primaryGradient,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D6366F1),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TAP TO ENTER VOICE LAB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: StitchTokens.textPrimary,
                  letterSpacing: 1.0,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hands-free speech recognition active',
                style: TextStyle(
                  fontSize: 11,
                  color: StitchTokens.masteryEmerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Telemetry Feature Highlights
        Row(
          children: [
            Expanded(
              child: StitchGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.graphic_eq_rounded,
                      color: StitchTokens.masteryEmerald,
                      size: 22,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Phonetic Formants',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: StitchTokens.textPrimary,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real-time accent curve and stress calibration.',
                      style: TextStyle(
                        fontSize: 11,
                        color: StitchTokens.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StitchGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.auto_fix_high_rounded,
                      color: StitchTokens.kineticAmber,
                      size: 22,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Live Corrections',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: StitchTokens.textPrimary,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Automated syntax and inflection suggestions.',
                      style: TextStyle(
                        fontSize: 11,
                        color: StitchTokens.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
