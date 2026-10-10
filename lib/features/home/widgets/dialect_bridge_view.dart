import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/components.dart';

/// LingoPulse AI — Dialect Register Bridge View
/// Directly implements Stitch Screens 556092434328406111 & b73623d2fea542c389abcfce2f5a8f18:
/// Dual-track audio, register toggles (Literary Standard vs Colloquial Street),
/// phonetic divergence waveforms, and socio-pragmatic coach query chips.
class DialectBridgeView extends StatefulWidget {
  final String languageCode;
  final VoidCallback onStartLiveSession;

  const DialectBridgeView({
    super.key,
    required this.languageCode,
    required this.onStartLiveSession,
  });

  @override
  State<DialectBridgeView> createState() => _DialectBridgeViewState();
}

class _DialectBridgeViewState extends State<DialectBridgeView> {
  bool _isColloquial = false;
  double _playbackSpeed = 1.0;
  bool _isPlaying = false;
  int _activeQueryChip = -1;

  // Language-specific dialect metadata
  Map<String, dynamic> _getDialectData(String code) {
    return switch (code.toLowerCase()) {
      'ar' => {
        'coachName': 'Sparky Fasih',
        'coachTitle': 'Senior Morpho-Phonetician & Dialectologist',
        'standardName': 'Modern Standard (فصحى)',
        'colloquialName': 'Levantine Shami (شامي)',
        'standardPhrase': 'مَاذَا تُرِيدُ أَنْ تَشْرَبَ الْيَوْمَ؟',
        'standardIpa': '/maːðaː turiːdu ʔan taʃraba l-jawm/',
        'colloquialPhrase': 'شو حابب تشرب اليوم يا غالي؟',
        'colloquialIpa': '/ʃuː ħaːbib tiʃrab el-joːm jaː ɣaːliː/',
        'naturalEn': 'What would you like to drink today, my friend?',
        'divergencePoint': 'Glottal stop shift: [mādhā] → [shū], informal vocative [yā ghālī]',
        'queryChips': [
          'Why drop the dual grammatical case in Shami?',
          'How does Qāf shift to Hamza in Damascus?',
          '3 Native Greeting Alternatives',
        ],
      },
      'es' => {
        'coachName': 'Sparky Castizo',
        'coachTitle': 'Pragmatic Register & Poly-Dialect Coach',
        'standardName': 'Castilian Madrid (Ceceo / Vos)',
        'colloquialName': 'Mexican CDMX (Chilango)',
        'standardPhrase': '¿Me pones un tinto de verano, por fa, que entra de lujo?',
        'standardIpa': '/me ˈpones un ˈtinto ðe βeˈɾano poɾ fa ke ˈentɾa ðe ˈluxo/',
        'colloquialPhrase': '¿Qué onda carnal, te echas una chelita bien muerta?',
        'colloquialIpa': '/ke ˈonda kaɾˈnal te ˈetʃas ˈuna tʃeˈlita bjen ˈmweɾta/',
        'naturalEn': 'Could you get me a drink? Really hits the spot!',
        'divergencePoint': 'Pragmatic verb shift: [poner] in Madrid vs [echar] in CDMX; tavern culture norms',
        'queryChips': [
          'Explain ¿Qué hubo vs ¿Qué onda?',
          'Subjunctive vs Imperfect Nuance',
          'Tavern Hospitality Etiquette in Madrid',
        ],
      },
      'ms' => {
        'coachName': 'Sparky Nusantara',
        'coachTitle': 'Austronesian Morpho-Syntax Specialist',
        'standardName': 'Bahasa Melayu Baku (Formal)',
        'colloquialName': 'Bahasa Pasar / Basilect',
        'standardPhrase': 'Bolehkah saya membantu anda menyelesaikan urusan ini?',
        'standardIpa': '/bolehkah saja membantu anda meɲlesajkan urusan ini/',
        'colloquialPhrase': 'Ada apa-apa nak minta tolong ke, bro?',
        'colloquialIpa': '/ada apa apa nak minta toloŋ ke bro/',
        'naturalEn': 'Can I help you get this sorted out?',
        'divergencePoint': 'Affix elision: meN- dropping in speech; clitic [ke] and English loan [bro]',
        'queryChips': [
          'When is imbuhan meN- required vs omitted?',
          'Colloquial short forms: [nak], [dah], [tak]',
          'Politeness levels across Malaysia',
        ],
      },
      'ja' => {
        'coachName': 'Sparky Yamato',
        'coachTitle': 'Socio-Linguistics & Keigo Specialist',
        'standardName': 'Tokyo Kanto (Teineigo)',
        'colloquialName': 'Kansai-ben (Osaka Colloquial)',
        'standardPhrase': '本日はどのようなご用件でしょうか？',
        'standardIpa': '/hoɴdʒitsu wa dono joː na go joːkeɴ deʃoː ka/',
        'colloquialPhrase': '今日何しに来たん？手伝おか？',
        'colloquialIpa': '/kjoː nani ɕini kitaɴ tetsudaoka/',
        'naturalEn': 'What brings you here today? Can I help?',
        'divergencePoint': 'Verb ending shift: [-deshou ka] → [-tan? / -oka?], pitch-accent inversion',
        'queryChips': [
          'Kansai copula: [ya] vs Kanto [da]',
          'Keigo 3-tier hierarchy breakdown',
          'Softening sentence particles',
        ],
      },
      _ => {
        'coachName': 'Sparky Linguist',
        'coachTitle': 'Cognitive Sociolinguistic Specialist',
        'standardName': 'Formal Literary Standard',
        'colloquialName': 'Spoken Vernacular',
        'standardPhrase': 'It is a pleasure to make your acquaintance.',
        'standardIpa': '/ɪt ɪz ə ˈplɛʒər tu meɪk jʊər əˈkweɪntəns/',
        'colloquialPhrase': 'Hey, great to finally meet you!',
        'colloquialIpa': '/heɪ ɡreɪt tu ˈfaɪnəli miːt juː/',
        'naturalEn': 'Pleased to meet you.',
        'divergencePoint': 'Register shift: formal Latinate lexicon to Germanic conversational phrasal idiom',
        'queryChips': [
          'Register appropriateness in casual settings',
          'Phonetic vowel reduction in connected speech',
          'Idiomatic alternatives',
        ],
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _getDialectData(widget.languageCode);
    final activePhrase = _isColloquial ? data['colloquialPhrase'] as String : data['standardPhrase'] as String;
    final activeIpa = _isColloquial ? data['colloquialIpa'] as String : data['standardIpa'] as String;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Studio Sub-Header: Dialect Pragmatics Badge & Krashen i+1 Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: StitchTokens.primaryTerracotta.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: StitchTokens.borderAmberHairline),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology_alt_rounded,
                    size: 14,
                    color: StitchTokens.primaryEmber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'KRASHEN (i+1) COMPREHENSIBLE INPUT',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: StitchTokens.primaryEmber,
                      letterSpacing: 0.8,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: StitchTokens.accentTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'FLOW: 94% NATURAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: StitchTokens.accentEmerald,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // AI Coach Identity Card
        StitchGlassCard(
          isElevated: true,
          borderColor: StitchTokens.borderAmberHairline,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: StitchTokens.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: StitchTokens.primaryTerracotta.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['coachName'] as String,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['coachTitle'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: StitchTokens.textSecondary,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.mic, color: StitchTokens.primaryEmber),
                onPressed: widget.onStartLiveSession,
                tooltip: 'Start Live Coaching',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dialect Register Switcher Bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: StitchTokens.surfaceLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StitchTokens.borderHairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isColloquial = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isColloquial
                          ? StitchTokens.surfaceDefault
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: !_isColloquial
                          ? Border.all(color: StitchTokens.borderAmberHairline)
                          : null,
                    ),
                    child: Text(
                      data['standardName'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !_isColloquial ? FontWeight.w800 : FontWeight.w500,
                        color: !_isColloquial ? Colors.white : StitchTokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isColloquial = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isColloquial
                          ? StitchTokens.surfaceDefault
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: _isColloquial
                          ? Border.all(color: StitchTokens.borderAmberHairline)
                          : null,
                    ),
                    child: Text(
                      data['colloquialName'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isColloquial ? FontWeight.w800 : FontWeight.w500,
                        color: _isColloquial ? Colors.white : StitchTokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dual-Track Acoustic Bridge Player Card
        StitchGlassCard(
          isElevated: true,
          borderColor: StitchTokens.borderAmberHairline,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isColloquial
                              ? StitchTokens.accentAmber
                              : StitchTokens.primaryEmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isColloquial ? 'STREET COLLOQUIAL' : 'FORMAL LITERARY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _isColloquial
                              ? StitchTokens.accentAmber
                              : StitchTokens.primaryEmber,
                          letterSpacing: 1.2,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_playbackSpeed}x SPEED',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: StitchTokens.textSecondary,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Active Phrase Display
              Text(
                activePhrase,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.4,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                activeIpa,
                style: const TextStyle(
                  fontSize: 12,
                  color: StitchTokens.textTertiary,
                  fontFamily: 'JetBrains Mono',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Natural English Translation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: StitchTokens.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '“${data['naturalEn']}”',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: StitchTokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),

              // Mock Acoustic Waveform Canvas
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: StitchTokens.surfaceLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: StitchTokens.borderHairline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(28, (i) {
                    final height = 10.0 + ((i * 7) % 32).toDouble();
                    final isHighlighted = (i >= 8 && i <= 14);
                    return Container(
                      width: 4,
                      height: height,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? StitchTokens.primaryEmber
                            : StitchTokens.borderHairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),

              // Divergence Callout
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StitchTokens.primaryTerracotta.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StitchTokens.borderAmberHairline),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.compare_arrows_rounded,
                      size: 16,
                      color: StitchTokens.primaryEmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['divergencePoint'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: StitchTokens.textSecondary,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Audio Controls Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded),
                    color: StitchTokens.textSecondary,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isPlaying = !_isPlaying);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: StitchTokens.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: StitchTokens.primaryTerracotta.withValues(alpha: 0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _playbackSpeed = _playbackSpeed == 1.0 ? 0.8 : 1.0;
                      });
                    },
                    child: Text(
                      '${_playbackSpeed}x',
                      style: const TextStyle(
                        color: StitchTokens.primaryEmber,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 1-Tap Quick Coach Query Chips
        const Text(
          '1-TAP SOCIO-PRAGMATIC QUERIES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: StitchTokens.textTertiary,
            letterSpacing: 1.0,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            (data['queryChips'] as List<String>).length,
            (idx) {
              final chipText = (data['queryChips'] as List<String>)[idx];
              final isSelected = _activeQueryChip == idx;
              return GestureDetector(
                onTap: () {
                  setState(() => _activeQueryChip = isSelected ? -1 : idx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? StitchTokens.primaryTerracotta.withValues(alpha: 0.2)
                        : StitchTokens.surfaceLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? StitchTokens.primaryEmber
                          : StitchTokens.borderHairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 14,
                        color: isSelected
                            ? StitchTokens.primaryEmber
                            : StitchTokens.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        chipText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : StitchTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
