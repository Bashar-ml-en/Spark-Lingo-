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

  String _targetPhrase(String code) {
    return switch (code.toLowerCase()) {
      'ms' => 'Selamat pagi! Boleh saya bantu anda hari ini?',
      'ja' => 'はじめまして、どうぞよろしくおねがいします。',
      'ar' => 'مرحباً بك، كيف يمكنني مساعدتك اليوم؟',
      'es' => '¡Buenos días! ¿Cómo puedo ayudarte hoy?',
      'fr' => 'Bonjour ! Comment puis-je vous aider aujourd’hui ?',
      'de' => 'Guten Tag! Wie kann ich Ihnen heute helfen?',
      'zh' => '你好！今天我有什么可以帮你的吗？',
      'ko' => '안녕하세요! 오늘 어떤 도움이 필요하신가요?',
      'ru' => 'Здравствуйте! Чем я могу вам помочь сегодня?',
      'it' => 'Buongiorno! Come posso aiutarla oggi?',
      'pt' => 'Bom dia! Como posso ajudar você hoje?',
      'hi' => 'नमस्ते! आज मैं आपकी क्या मदद कर सकता हूँ?',
      'th' => 'สวัสดีครับ วันนี้มีอะไรให้ช่วยไหมครับ?',
      'tl' => 'Magandang umaga! May maitutulong ba ako sa iyo ngayon?',
      _ => 'Hello! How can I help you today?',
    };
  }

  @override
  Widget build(BuildContext context) {
    final phrase = _targetPhrase(languageCode);
    final isRtl = languageCode.toLowerCase() == 'ar';

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
                'Low-latency conversational immersion with instant phonetic formant analysis and live feedback.',
                style: TextStyle(
                  fontSize: 13,
                  color: StitchTokens.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Active Target Language Sentence Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: StitchTokens.surfaceLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StitchTokens.borderHairline),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.volume_up_rounded,
                          color: StitchTokens.primaryIndigo,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TARGET PHONETIC PROMPT (${languageCode.toUpperCase()})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: StitchTokens.primaryIndigo,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phrase,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: StitchTokens.textPrimary,
                        height: 1.4,
                      ),
                      textAlign: isRtl ? TextAlign.right : TextAlign.center,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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

/// Backward compatibility alias
typedef VoiceStudioView = ImmersionView;
