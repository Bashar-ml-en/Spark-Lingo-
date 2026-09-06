// Official language-exam format registry.
//
// Honesty contract (Workstream C, Phase 0):
// Every fact below was sourced from an official exam body or its published
// specification during the 2026-08 research pass. Anything that could NOT
// be verified from an official source is deliberately omitted rather than
// estimated.
//
// What this registry provides (all verified):
//   * the sections an official exam actually contains,
//   * the time allotted to each section,
//   * the scoring/passing scale published by the body.
// What it deliberately does NOT provide:
//   * fabricated readiness percentages,
//   * invented question counts per section (only totals I could verify),
//   * any "you would score X" prediction.

/// One verifiable component of an official exam.
class ExamSection {
  final String name;
  final String? code; // official paper code when the body publishes one
  final String? minutes; // official time allotment, if published
  final String? note;

  const ExamSection({
    required this.name,
    this.code,
    this.minutes,
    this.note,
  });

  /// Parses the published duration into whole minutes for drill pacing.
  /// Returns null when the body publishes no timing (drills then use the
  /// conservative training default and say so).
  int? get minutesInt {
    if (minutes == null) return null;
    final match = RegExp(r'(\d+)\s*min').firstMatch(minutes!.toLowerCase());
    if (match != null) return int.tryParse(match.group(1)!);
    return int.tryParse(minutes!.replaceAll(RegExp(r'[^0-9]'), ''));
  }
}

/// A verified official exam for one learning language.
class OfficialExamFormat {
  final String examName;
  final String organizer; // official body
  final String source; // where the facts were verified
  final List<String> levels; // official level names
  final List<ExamSection> sections;
  final String? scoringScale; // published score/passing scale
  final String? passingRule; // published passing requirement
  final String? formatNotes;

  const OfficialExamFormat({
    required this.examName,
    required this.organizer,
    required this.source,
    required this.levels,
    required this.sections,
    this.scoringScale,
    this.passingRule,
    this.formatNotes,
  });
}

/// Verified exam formats keyed by the SparkLingo language code.
///
/// Sourcing notes (2026-08-26 research pass):
///  * MUET details read directly from the official Majlis Peperiksaan
///    Malaysia portal (portal.mpm.edu.my), which lists the four papers and
///    their durations.
///  * HSK/JLPT/TOPIK/DELF section lists, timings and scales compiled from the
///    official bodies' published specifications; per-section question counts
///    are intentionally omitted where I could not verify them.
const Map<String, OfficialExamFormat> officialExamFormats = {
  // --------------------------------------------------------------- MUET
  'en': OfficialExamFormat(
    examName: 'MUET — Malaysian University English Test',
    organizer: 'Majlis Peperiksaan Malaysia (MPM)',
    source: 'portal.mpm.edu.my (official MUET components page)',
    levels: ['Band 1', 'Band 2', 'Band 3', 'Band 4', 'Band 5', 'Band 5+'],
    sections: [
      ExamSection(code: '800/1', name: 'Listening', minutes: '50 min'),
      ExamSection(code: '800/2', name: 'Speaking', minutes: '30 min'),
      ExamSection(code: '800/3', name: 'Reading', minutes: '75 min'),
      ExamSection(code: '800/4', name: 'Writing', minutes: '75 min'),
    ],
    scoringScale: 'Aggregate score mapped to Bands 1–5+',
    passingRule:
        'No single pass mark; universities set their own minimum Band '
        '(commonly Band 4).',
    formatNotes: 'Four papers; Speaking may be run as a group task.',
  ),

  // ---------------------------------------------------------------- HSK
  'zh': OfficialExamFormat(
    examName: 'HSK — Hanyu Shuiping Kaoshi',
    organizer: 'Chinese Testing International (CTI)',
    source: 'Official HSK specifications (2026 research pass)',
    levels: ['HSK 1', 'HSK 2', 'HSK 3', 'HSK 4', 'HSK 5', 'HSK 6'],
    sections: [
      ExamSection(
        name: 'Listening',
        note: 'All levels; pinyin support on HSK 1–2.',
      ),
      ExamSection(name: 'Reading', note: 'All levels.'),
      ExamSection(
        name: 'Writing',
        note: 'HSK 3–6 only.',
      ),
    ],
    scoringScale: 'HSK 1–2 out of 200; HSK 3–6 out of 300.',
    passingRule: 'Pass at 120/200 (HSK 1–2) or 180/300 (HSK 3–6).',
    formatNotes:
        'Note: a revised HSK 3.0 framework is rolling out; verify the format '
        'that applies to your test window before registering.',
  ),

  // --------------------------------------------------------------- JLPT
  'ja': OfficialExamFormat(
    examName: 'JLPT — Japanese Language Proficiency Test',
    organizer: 'The Japan Foundation & JEES',
    source: 'Official JLPT specifications (2026 research pass)',
    levels: ['N5', 'N4', 'N3', 'N2', 'N1'],
    sections: [
      ExamSection(
        name: 'Language Knowledge (Vocabulary/Grammar/Kanji) + Reading',
        minutes: '~105–170 min by level',
      ),
      ExamSection(name: 'Listening', minutes: 'by level'),
    ],
    scoringScale: 'Scored out of 180 at N4/N5.',
    passingRule:
        'Must pass BOTH the overall minimum and every sectional minimum '
        '(e.g. N4: 90/180 overall, ≥38/120 Language Knowledge+Reading, '
        '≥19/60 Listening).',
    formatNotes: 'N5/N4 have two score blocks; N3–N1 add a third.',
  ),

  // -------------------------------------------------------------- TOPIK
  'ko': OfficialExamFormat(
    examName: 'TOPIK — Test of Proficiency in Korean',
    organizer: 'National Institute for International Education (NIIED)',
    source: 'Official TOPIK specifications (2026 research pass)',
    levels: ['TOPIK I', 'TOPIK II'],
    sections: [
      ExamSection(
        name: 'Listening',
        note: 'Both TOPIK I and TOPIK II.',
      ),
      ExamSection(
        name: 'Reading',
        note: 'Both TOPIK I and TOPIK II.',
      ),
      ExamSection(name: 'Writing', note: 'TOPIK II only.'),
    ],
    scoringScale:
        'TOPIK I grades 1–2; TOPIK II grades 3–6, from total points.',
    passingRule: 'Grade thresholds set by NIIED on the total score.',
    formatNotes: 'TOPIK I ≈100 min (70 items, listening+reading).',
  ),

  // --------------------------------------------------------------- DELF
  'fr': OfficialExamFormat(
    examName: 'DELF / DALF — Diplômes d’études en langue française',
    organizer: 'France Éducation international',
    source: 'Official DELF/DALF specifications (2026 research pass)',
    levels: ['DELF A1', 'DELF A2', 'DELF B1', 'DELF B2', 'DALF C1', 'DALF C2'],
    sections: [
      ExamSection(name: 'Listening comprehension'),
      ExamSection(name: 'Reading comprehension'),
      ExamSection(name: 'Writing production'),
      ExamSection(name: 'Speaking production'),
    ],
    scoringScale: 'Four sections, 25 points each (100 total).',
    passingRule:
        'Pass at 50/100 overall AND at least 5/25 in every section.',
  ),

  // ----------------------------------------------------------------- RU
  // No official international proficiency exam is universally mapped to
  // SparkLingo's Russian track at this time. TORFL (ТРКИ) exists but I did
  // not verify its current official specifications in this research pass,
  // so it is intentionally NOT listed. We show an honest notice instead.
};
