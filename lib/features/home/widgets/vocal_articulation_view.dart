import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/components.dart';

/// LingoPulse AI — Vocal Articulation & Resonance Trainer (*Makhārij Al-Hurūf*)
/// Directly implements Stitch Screen 556092434328406111:
/// Anatomical vocal tract cutaway diagram with epiglottic/pharyngeal resonance nodes,
/// live F1/F2 formant meters, and real-time audio shadowing engine.
class VocalArticulationView extends StatefulWidget {
  final String languageCode;

  const VocalArticulationView({
    super.key,
    required this.languageCode,
  });

  @override
  State<VocalArticulationView> createState() => _VocalArticulationViewState();
}

class _VocalArticulationViewState extends State<VocalArticulationView> {
  int _selectedTargetIndex = 0;
  bool _isShadowing = false;
  double _pitchMatchScore = 96.0;

  Map<String, dynamic> _getArticulationData(String code) {
    return switch (code.toLowerCase()) {
      'ar' => {
        'title': 'MAKHĀRIJ AL-ḤURŪF (مَخَارِج الحُرُوف)',
        'subtitle': 'Anatomical Pharyngeal Articulation Studio',
        'targets': [
          {
            'symbol': 'ع',
            'name': '‘Ayn',
            'ipa': '/ʕ/',
            'type': 'Voiced Pharyngeal Fricative',
            'zone': 'Middle Throat / Epiglottis',
            'f1': '620 Hz',
            'f2': '1380 Hz',
            'guidance': 'Constrict the pharyngeal walls and draw the epiglottis backward towards the posterior pharyngeal wall without creating oral closure.',
          },
          {
            'symbol': 'ح',
            'name': 'Ḥā’',
            'ipa': '/ħ/',
            'type': 'Voiceless Pharyngeal Fricative',
            'zone': 'Middle Throat (Wasaṭ Al-Ḥalq)',
            'f1': '540 Hz',
            'f2': '1550 Hz',
            'guidance': 'Release a continuous, warm stream of unvoiced breath directly from the middle of the pharynx with slight epiglottic narrowing.',
          },
          {
            'symbol': 'ص',
            'name': 'Ṣād',
            'ipa': '/sˤ/',
            'type': 'Pharyngealized Alveolar Fricative',
            'zone': 'Dental-Alveolar + Velar Backing',
            'f1': '780 Hz',
            'f2': '1120 Hz',
            'guidance': 'Place the tongue blade against the upper alveolar ridge while simultaneously raising the back of the tongue toward the soft palate (Iṭbāq).',
          },
          {
            'symbol': 'ق',
            'name': 'Qāf',
            'ipa': '/q/',
            'type': 'Voiceless Uvular Stop',
            'zone': 'Uvula / Extreme Root of Tongue',
            'f1': '450 Hz',
            'f2': '1240 Hz',
            'guidance': 'Make a crisp, explosive closure between the very back of the tongue dorsum and the lowest hanging tip of the soft palate (Uvula).',
          },
        ],
      },
      'es' => {
        'title': 'ENTRENADOR DE ARTICULACIÓN FONÉTICA',
        'subtitle': 'Acoustic Resonance & Articulatory Mechanics',
        'targets': [
          {
            'symbol': 'rr',
            'name': 'Vibrante Múltiple',
            'ipa': '/r/',
            'type': 'Alveolar Trill (Multiple Vibration)',
            'zone': 'Upper Alveolar Ridge',
            'f1': '480 Hz',
            'f2': '1650 Hz',
            'guidance': 'Relax the tongue tip against the alveolar ridge allowing aerodynamic Bernoulli pressure to create 2–3 rapid aerodynamic trills.',
          },
          {
            'symbol': 'c / z',
            'name': 'Ceceo Castizo',
            'ipa': '/θ/',
            'type': 'Voiceless Interdental Fricative',
            'zone': 'Interdental (Teeth Apex)',
            'f1': '650 Hz',
            'f2': '1820 Hz',
            'guidance': 'Position the apex of the tongue lightly between the upper and lower incisors without biting, releasing soft friction.',
          },
          {
            'symbol': 'j / g',
            'name': 'Jota Velar',
            'ipa': '/x/',
            'type': 'Voiceless Velar Fricative',
            'zone': 'Velum (Soft Palate)',
            'f1': '520 Hz',
            'f2': '1410 Hz',
            'guidance': 'Raise the back of the tongue toward the velum, producing dry, unvoiced friction similar to clearing the throat lightly.',
          },
        ],
      },
      'ms' => {
        'title': 'MAKMAL FONETIK DAN ARTIKULASI SEBUTAN',
        'subtitle': 'Austronesian Acoustic Articulation Lab',
        'targets': [
          {
            'symbol': '-k',
            'name': 'Hentian Glotis',
            'ipa': '/ʔ/',
            'type': 'Glottal Stop (Koda Suku Kata)',
            'zone': 'Vocal Cords / Glottis',
            'f1': '380 Hz',
            'f2': '1100 Hz',
            'guidance': 'Tutup pita suara secara mendadak pada akhir suku kata (contoh: budak, tidak) tanpa meletuskan bunyi [k] kras.',
          },
          {
            'symbol': 'ng',
            'name': 'Nasal Velar',
            'ipa': '/ŋ/',
            'type': 'Voiced Velar Nasal',
            'zone': 'Velum (Lelangit Lembut)',
            'f1': '280 Hz',
            'f2': '2200 Hz',
            'guidance': 'Rapatkan pangkal lidah ke lelangit lembut dan alirkan resonansi udara sepenuhnya melalui rongga hidung.',
          },
          {
            'symbol': 'ny',
            'name': 'Nasal Palatal',
            'ipa': '/ɲ/',
            'type': 'Voiced Palatal Nasal',
            'zone': 'Lelangit Keras (Palatum)',
            'f1': '310 Hz',
            'f2': '2050 Hz',
            'guidance': 'Rapatkan daun lidah ke lelangit keras sambil mengeluarkan suara melalui hidung (contoh: nyanyi, nyaman).',
          },
        ],
      },
      _ => {
        'title': 'PHONETIC ARTICULATION TRAINER',
        'subtitle': 'Acoustic Resonance & Shadowing Lab',
        'targets': [
          {
            'symbol': 'th',
            'name': 'Interdental Fricative',
            'ipa': '/θ/',
            'type': 'Voiceless Interdental Fricative',
            'zone': 'Incisors / Tongue Tip',
            'f1': '580 Hz',
            'f2': '1700 Hz',
            'guidance': 'Place the tongue tip between the teeth and blow softly without voicing.',
          },
          {
            'symbol': 'r',
            'name': 'Alveolar Approximant',
            'ipa': '/ɹ/',
            'type': 'Post-Alveolar Approximant',
            'zone': 'Hard Palate / Alveolar',
            'f1': '420 Hz',
            'f2': '1300 Hz',
            'guidance': 'Curl the tongue tip back slightly without touching the roof of the mouth.',
          },
        ],
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _getArticulationData(widget.languageCode);
    final targets = data['targets'] as List<Map<String, String>>;
    final currentTarget = targets[_selectedTargetIndex.clamp(0, targets.length - 1)];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Lab Header
        Text(
          data['title'] as String,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: StitchTokens.primaryEmber,
            letterSpacing: 1.5,
            fontFamily: 'JetBrains Mono',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          data['subtitle'] as String,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Plus Jakarta Sans',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Target Consonant Selector Chips
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: targets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final t = targets[idx];
              final isSelected = _selectedTargetIndex == idx;
              return GestureDetector(
                onTap: () => setState(() => _selectedTargetIndex = idx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? StitchTokens.primaryTerracotta.withValues(alpha: 0.25)
                        : StitchTokens.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? StitchTokens.primaryEmber
                          : StitchTokens.borderHairline,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: StitchTokens.primaryTerracotta.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        t['symbol']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : StitchTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? StitchTokens.primaryEmber
                              : StitchTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // Anatomical Sagittal Vocal Tract Diagram Card
        StitchGlassCard(
          isElevated: true,
          borderColor: StitchTokens.borderAmberHairline,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SAGITTAL VOCAL TRACT CUTAWAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: StitchTokens.textTertiary,
                      letterSpacing: 1.0,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: StitchTokens.primaryTerracotta.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      currentTarget['type']!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: StitchTokens.primaryEmber,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Visual Sagittal Cutaway Mock Canvas with Compression Rings
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: StitchTokens.surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: StitchTokens.borderHairline),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid background
                    Opacity(
                      opacity: 0.15,
                      child: CustomPaint(
                        size: const Size(double.infinity, 160),
                        painter: _GridPainter(),
                      ),
                    ),
                    // Vocal Anatomy Compression Graphic
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: StitchTokens.primaryEmber.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            gradient: RadialGradient(
                              colors: [
                                StitchTokens.primaryTerracotta.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              currentTarget['symbol']!,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: StitchTokens.surfaceLow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: StitchTokens.borderAmberHairline),
                          ),
                          child: Text(
                            'ACTIVE ZONE: ${currentTarget['zone']!.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: StitchTokens.primaryEmber,
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

              // Physical Articulation Guidance
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: StitchTokens.surfaceLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.accessibility_new_rounded,
                      size: 20,
                      color: StitchTokens.accentTeal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        currentTarget['guidance']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: StitchTokens.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Formant Frequency Resonance Meters (F1 & F2)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: StitchTokens.surfaceLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: StitchTokens.borderHairline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FORMANT F1 (PHARYNX)',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: StitchTokens.textTertiary,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentTarget['f1']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: StitchTokens.surfaceLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: StitchTokens.borderHairline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FORMANT F2 (ORAL CAVITY)',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: StitchTokens.textTertiary,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentTarget['f2']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Audio Shadowing Actuator
              GestureDetector(
                onTapDown: (_) => setState(() => _isShadowing = true),
                onTapUp: (_) => setState(() => _isShadowing = false),
                onTapCancel: () => setState(() => _isShadowing = false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: _isShadowing
                        ? const LinearGradient(
                            colors: [StitchTokens.accentTeal, StitchTokens.accentEmerald],
                          )
                        : StitchTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (_isShadowing ? StitchTokens.accentTeal : StitchTokens.primaryTerracotta)
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isShadowing ? Icons.mic_rounded : Icons.record_voice_over_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isShadowing
                            ? 'LISTENING TO YOUR RESONANCE...'
                            : 'HOLD TO SHADOW ARTICULATION',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_pitchMatchScore > 0) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'ACOUSTIC CONTOUR MATCH: ${_pitchMatchScore.toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: StitchTokens.accentEmerald,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
