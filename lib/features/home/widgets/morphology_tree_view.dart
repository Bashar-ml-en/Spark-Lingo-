import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/components.dart';

/// LingoPulse AI — Scientific Morphology Tree (*Mīzān Aṣ-Ṣarfī* / Affix Matrix)
/// Directly implements Stitch Screen 556092434328406111:
/// The Root Nucleus, Form I–X Derivation Branches, Weight/Wazn formulas,
/// and cognitive morphological explorer across multiple language families.
class MorphologyTreeView extends StatefulWidget {
  final String languageCode;

  const MorphologyTreeView({
    super.key,
    required this.languageCode,
  });

  @override
  State<MorphologyTreeView> createState() => _MorphologyTreeViewState();
}

class _MorphologyTreeViewState extends State<MorphologyTreeView> {
  int _selectedBranchIndex = 0;

  Map<String, dynamic> _getMorphologyData(String code) {
    return switch (code.toLowerCase()) {
      'ar' => {
        'systemName': 'MĪZĀN AṢ-ṢARFĪ (مِيزَان الصَّرْف)',
        'rootTitle': 'TRILITERAL ROOT NUCLEUS',
        'rootLetters': 'ك - ت - ب',
        'rootTranscription': 'K-T-B',
        'rootConcept': 'The Core Semantic Archetype of "Writing, Inscribing & Documenting"',
        'branches': [
          {
            'form': 'Form I Noun',
            'wazn': 'فِعَال (Fi‘āl)',
            'word': 'كِتَاب',
            'transcription': 'Kitāb',
            'meaning': 'Book / Text',
            'role': 'Noun of Patient / Concrete Manifestation',
            'cefr': 'A1',
            'example': 'هَذَا كِتَابٌ مُفِيدٌ جِدًّا فِي دِرَاسَتِنَا.',
            'exampleEn': 'This is a very useful book in our study.',
          },
          {
            'form': 'Form I Active Participle',
            'wazn': 'فَاعِل (Fā‘il)',
            'word': 'كَاتِب',
            'transcription': 'Kātib',
            'meaning': 'Author / Scribe',
            'role': 'Doer of the Action (Subject Agent)',
            'cefr': 'A2',
            'example': 'الْكَاتِبُ يَعْمَلُ عَلَى رِوَايَتِهِ الْجَدِيدَةِ.',
            'exampleEn': 'The author is working on his new novel.',
          },
          {
            'form': 'Form I Noun of Place',
            'wazn': 'مَفْعَل (Maf‘al)',
            'word': 'مَكْتَب',
            'transcription': 'Maktab',
            'meaning': 'Office / Desk',
            'role': 'Spatial Locus of Inscription',
            'cefr': 'A2',
            'example': 'أَنَا ذَاهِبٌ إِلَى الْمَكْتَبِ الْآنَ.',
            'exampleEn': 'I am going to the office right now.',
          },
          {
            'form': 'Form I Noun of Place (Fem)',
            'wazn': 'مَفْعَلَة (Maf‘alah)',
            'word': 'مَكْتَبَة',
            'transcription': 'Maktabah',
            'meaning': 'Library / Bookstore',
            'role': 'Collective Repository of Inscriptions',
            'cefr': 'B1',
            'example': 'نَلْتَقِي فِي الْمَكْتَبَةِ الْعَامَّةِ مَسَاءً.',
            'exampleEn': 'We meet at the public library this evening.',
          },
          {
            'form': 'Form VIII Verbal Noun',
            'wazn': 'اِفْتِعَال (Ifti‘āl)',
            'word': 'اِكْتِتَاب',
            'transcription': 'Iktitāb',
            'meaning': 'Subscription / Enrollment',
            'role': 'Reflexive Mutual Formal Inscription',
            'cefr': 'C1',
            'example': 'تَمَّ فَتْحُ بَابِ الِاكْتِتَابِ فِي الْمَشْرُوعِ.',
            'exampleEn': 'Subscription was officially opened for the project.',
          },
        ],
      },
      'ms' => {
        'systemName': 'SISTEM MORFOLOGI IMBUHAN NUSANTARA',
        'rootTitle': 'KATA DASAR (ROOT STEM)',
        'rootLetters': 'T - U - L - I - S',
        'rootTranscription': 'Tulis',
        'rootConcept': 'The Core Semantic Archetype of "Writing & Inscribing"',
        'branches': [
          {
            'form': 'Awalan meN- (Active Transitive)',
            'wazn': 'meN- + tulis → menulis',
            'word': 'Menulis',
            'transcription': 'me-nu-lis',
            'meaning': 'To Write (Active)',
            'role': 'Active Subject Action',
            'cefr': 'A1',
            'example': 'Dia sedang menulis surat kepada rakannya.',
            'exampleEn': 'He is currently writing a letter to his friend.',
          },
          {
            'form': 'Awalan peN- (Agentive Noun)',
            'wazn': 'peN- + tulis → penulis',
            'word': 'Penulis',
            'transcription': 'pe-nu-lis',
            'meaning': 'Writer / Author',
            'role': 'Doer of the Writing (Agent)',
            'cefr': 'A2',
            'example': 'Penulis terkenal itu melancarkan buku baharu.',
            'exampleEn': 'The famous writer launched a new book.',
          },
          {
            'form': 'Akhiran -an (Resultant Noun)',
            'wazn': 'tulis + -an → tulisan',
            'word': 'Tulisan',
            'transcription': 'tu-li-san',
            'meaning': 'Handwriting / Script',
            'role': 'Concrete Result of the Writing',
            'cefr': 'B1',
            'example': 'Tulisan tangannya sangat kemas dan mudah dibaca.',
            'exampleEn': 'His handwriting is very neat and easy to read.',
          },
          {
            'form': 'Awalan ber- (Stative / Intransitive)',
            'wazn': 'ber- + tulis → bertulis',
            'word': 'Bertulis',
            'transcription': 'ber-tu-lis',
            'meaning': 'In Written Form',
            'role': 'Stative Quality / Adverbial Form',
            'cefr': 'B2',
            'example': 'Perjanjian itu telah dibuat secara bertulis.',
            'exampleEn': 'The agreement was executed in written form.',
          },
          {
            'form': 'Apitan meN-...-kan (Causative)',
            'wazn': 'meN- + tulis + -kan',
            'word': 'Menuliskan',
            'transcription': 'me-nu-lis-kan',
            'meaning': 'To Write Down For Someone',
            'role': 'Benefactive & Causative Transitivizer',
            'cefr': 'C1',
            'example': 'Bolehkah anda menuliskan alamatnya untuk saya?',
            'exampleEn': 'Could you please write down the address for me?',
          },
        ],
      },
      'es' => {
        'systemName': 'MATRIZ MORFOLÓGICA DE DERIVACIÓN LATINA',
        'rootTitle': 'LATIN VERBAL RADIX',
        'rootLetters': 'S - C - R - I - B',
        'rootTranscription': 'Scrib- / Escrib-',
        'rootConcept': 'The Latin Root Archetype *scrībere* ("to engrave, write")',
        'branches': [
          {
            'form': 'Infinitive Core',
            'wazn': 'Radix + -ir',
            'word': 'Escribir',
            'transcription': 'es-kri-ˈβiɾ',
            'meaning': 'To write',
            'role': 'Base Verbal Action',
            'cefr': 'A1',
            'example': 'Me gusta escribir en mi diario todos los días.',
            'exampleEn': 'I like to write in my journal every day.',
          },
          {
            'form': 'Agentive Noun (-tor)',
            'wazn': 'Radix + -tor',
            'word': 'Escritor',
            'transcription': 'es-kri-ˈtoɾ',
            'meaning': 'Writer / Author',
            'role': 'Agent / Creator',
            'cefr': 'A2',
            'example': 'El escritor firmó copias de su nueva novela.',
            'exampleEn': 'The writer signed copies of his new novel.',
          },
          {
            'form': 'Spatial Noun (-torio)',
            'wazn': 'Radix + -torio',
            'word': 'Escritorio',
            'transcription': 'es-kri-ˈto-ɾjo',
            'meaning': 'Desk / Study Office',
            'role': 'Spatial Locus of Composition',
            'cefr': 'A2',
            'example': 'Dejé los documentos importantes sobre el escritorio.',
            'exampleEn': 'I left the important documents on the desk.',
          },
          {
            'form': 'Participial Noun (-tura)',
            'wazn': 'Radix + -tura',
            'word': 'Escritura',
            'transcription': 'es-kri-ˈtu-ɾa',
            'meaning': 'Script / Deed / Scripture',
            'role': 'Abstract System & Formal Legal Text',
            'cefr': 'B2',
            'example': 'La escritura cuneiforme es una de las más antiguas.',
            'exampleEn': 'Cuneiform script is one of the oldest in the world.',
          },
          {
            'form': 'Prefix Sub- + Radix',
            'wazn': 'Sub- + Radix + -ción',
            'word': 'Suscripción',
            'transcription': 'sus-kɾip-ˈsjon',
            'meaning': 'Subscription / Undertaking',
            'role': 'Formal Contractual Endorsement',
            'cefr': 'C1',
            'example': 'Renové mi suscripción anual a la revista literaria.',
            'exampleEn': 'I renewed my annual subscription to the literary magazine.',
          },
        ],
      },
      'ja' => {
        'systemName': 'KANJI MORPHEME COMPOUND MATRIX (形態素合成)',
        'rootTitle': 'KANJI ROOT RADICAL',
        'rootLetters': '書',
        'rootTranscription': 'SHO / KAKU',
        'rootConcept': 'The Ideographic Concept of "Documenting & Brushing Characters"',
        'branches': [
          {
            'form': 'Kun-yomi Base Verb',
            'wazn': '書 + く',
            'word': '書く (kaku)',
            'transcription': 'kaku',
            'meaning': 'To Write',
            'role': 'Native Japanese Action',
            'cefr': 'A1',
            'example': '手紙を丁寧に書きました。',
            'exampleEn': 'I wrote the letter politely.',
          },
          {
            'form': 'On-yomi Spatial Compound',
            'wazn': '書 + 斎 (study room)',
            'word': '書斎 (shosai)',
            'transcription': 'sho-sai',
            'meaning': 'Study / Library Room',
            'role': 'Spatial Locus',
            'cefr': 'B1',
            'example': '父は書斎で本を読んでいます。',
            'exampleEn': 'Father is reading a book in his study.',
          },
          {
            'form': 'On-yomi Institutional Place',
            'wazn': '図 + 書 + 館',
            'word': '図書館 (toshokan)',
            'transcription': 'to-sho-kan',
            'meaning': 'Public Library',
            'role': 'Repository Building',
            'cefr': 'A2',
            'example': '放課後に図書館で勉強します。',
            'exampleEn': 'I will study at the library after school.',
          },
          {
            'form': 'On-yomi Formal Document',
            'wazn': '契 + 約 + 書',
            'word': '契約書 (keiyakusho)',
            'transcription': 'kei-yaku-sho',
            'meaning': 'Legal Contract',
            'role': 'Formal Binding Inscription',
            'cefr': 'B2',
            'example': '契約書に署名と捺印を行いました。',
            'exampleEn': 'I signed and sealed the contract agreement.',
          },
        ],
      },
      _ => {
        'systemName': 'INDO-EUROPEAN MORPHOLOGICAL DERIVATION',
        'rootTitle': 'CORE LEXICAL MORPHEME',
        'rootLetters': 'W - R - I - T - E',
        'rootTranscription': 'Write',
        'rootConcept': 'Proto-Germanic *wrītaną ("to scratch, incise, draw lines")',
        'branches': [
          {
            'form': 'Base Verb',
            'wazn': 'Write',
            'word': 'Write',
            'transcription': '/raɪt/',
            'meaning': 'To record thoughts in symbols',
            'role': 'Core Action',
            'cefr': 'A1',
            'example': 'Please write your name clearly.',
            'exampleEn': 'Please write your name clearly.',
          },
          {
            'form': 'Agentive Suffix (-er)',
            'wazn': 'Write + -er',
            'word': 'Writer',
            'transcription': '/ˈraɪtər/',
            'meaning': 'One who composes',
            'role': 'Agent',
            'cefr': 'A2',
            'example': 'She is a talented writer.',
            'exampleEn': 'She is a talented writer.',
          },
          {
            'form': 'Gerund / Concrete Product (-ing)',
            'wazn': 'Write + -ing',
            'word': 'Writing',
            'transcription': '/ˈraɪtɪŋ/',
            'meaning': 'The written work or script',
            'role': 'Action / Artifact',
            'cefr': 'A2',
            'example': 'Her handwriting is distinct.',
            'exampleEn': 'Her handwriting is distinct.',
          },
        ],
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _getMorphologyData(widget.languageCode);
    final branches = data['branches'] as List<Map<String, String>>;
    final selectedBranch = branches[_selectedBranchIndex.clamp(0, branches.length - 1)];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // System Header
        Text(
          data['systemName'] as String,
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
        const Text(
          'Scientific Morphology Tree',
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
          'Explore how an entire semantic family of words sprouts from a single core morphological root.',
          style: TextStyle(
            fontSize: 13,
            color: StitchTokens.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // The Central Root Nucleus Card
        StitchGlassCard(
          isElevated: true,
          borderColor: StitchTokens.borderAmberHairline,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Text(
                data['rootTitle'] as String,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: StitchTokens.primaryEmber,
                  letterSpacing: 1.2,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(height: 10),
              // Root Emblem Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      StitchTokens.primaryTerracotta.withValues(alpha: 0.25),
                      StitchTokens.terracottaDark.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: StitchTokens.primaryEmber.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: StitchTokens.primaryTerracotta.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  data['rootLetters'] as String,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 6,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data['rootConcept'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: StitchTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Bento Derivation Branch Selector Pills
        const Text(
          'DERIVATION BRANCHES (SELECT TO INSPECT)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: StitchTokens.textTertiary,
            letterSpacing: 1.0,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: branches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final branch = branches[idx];
              final isSelected = _selectedBranchIndex == idx;
              return GestureDetector(
                onTap: () => setState(() => _selectedBranchIndex = idx),
                child: Container(
                  width: 128,
                  padding: const EdgeInsets.all(10),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StitchCefrBadge(level: branch['cefr']!, compact: true),
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 14,
                            color: isSelected
                                ? StitchTokens.primaryEmber
                                : StitchTokens.textTertiary,
                          ),
                        ],
                      ),
                      Text(
                        branch['word']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : StitchTokens.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        branch['meaning']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? StitchTokens.primaryEmber
                              : StitchTokens.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // Deep Inspection Bento Card of the Selected Branch
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: StitchTokens.surfaceLowest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: StitchTokens.borderHairline),
                    ),
                    child: Text(
                      selectedBranch['form']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: StitchTokens.primaryEmber,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ),
                  StitchCefrBadge(level: selectedBranch['cefr']!),
                ],
              ),
              const SizedBox(height: 14),

              // Large Word & Transcription
              Text(
                selectedBranch['word']!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${selectedBranch['transcription']} • “${selectedBranch['meaning']}”',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: StitchTokens.primaryEmber,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              // Wazn / Formula Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: StitchTokens.surfaceLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: StitchTokens.borderHairline),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.architecture_rounded,
                      size: 18,
                      color: StitchTokens.accentTeal,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MORPHO-SYNTACTIC PATTERN (WEIGHT)',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: StitchTokens.textTertiary,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                        Text(
                          selectedBranch['wazn']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Role Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: StitchTokens.surfaceLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.psychology_rounded,
                      size: 18,
                      color: StitchTokens.primaryEmber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SEMANTIC ROLE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: StitchTokens.textTertiary,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedBranch['role']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: StitchTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Example Sentence
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: StitchTokens.surfaceLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: StitchTokens.borderAmberHairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CORPUS USAGE IN CONTEXT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: StitchTokens.primaryEmber,
                        letterSpacing: 0.8,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedBranch['example']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedBranch['exampleEn']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: StitchTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
