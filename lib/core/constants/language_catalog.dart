/// One canonical representation for every language used by the app.
///
/// Persist only the two-letter [code] in profiles, routes, curriculum queries,
/// and review records.  The aliases keep existing installations (which stored
/// names such as `spanish` and `bahasa melayu`) working while they are migrated
/// naturally the next time a user changes their language.
class LanguageCatalog {
  LanguageCatalog._();

  static const Map<String, _LanguageMetadata> _languages = {
    'en': _LanguageMetadata(
      displayName: 'English',
      curriculumKey: 'english',
      tutorName: 'English',
      defaultLocale: 'en-US',
    ),
    'fr': _LanguageMetadata(
      displayName: 'French',
      curriculumKey: 'french',
      tutorName: 'French',
      defaultLocale: 'fr-FR',
    ),
    'de': _LanguageMetadata(
      displayName: 'German',
      curriculumKey: 'german',
      tutorName: 'German',
      defaultLocale: 'de-DE',
    ),
    'es': _LanguageMetadata(
      displayName: 'Spanish',
      curriculumKey: 'spanish',
      tutorName: 'Spanish',
      defaultLocale: 'es-ES',
    ),
    'it': _LanguageMetadata(
      displayName: 'Italian',
      curriculumKey: 'italian',
      tutorName: 'Italian',
      defaultLocale: 'it-IT',
    ),
    'pt': _LanguageMetadata(
      displayName: 'Portuguese',
      curriculumKey: 'portuguese',
      tutorName: 'Portuguese',
      defaultLocale: 'pt-BR',
    ),
    'zh': _LanguageMetadata(
      displayName: 'Chinese (Mandarin)',
      curriculumKey: 'mandarin',
      tutorName: 'Mandarin Chinese',
      defaultLocale: 'zh-CN',
    ),
    'ja': _LanguageMetadata(
      displayName: 'Japanese',
      curriculumKey: 'japanese',
      tutorName: 'Japanese',
      defaultLocale: 'ja-JP',
    ),
    'ko': _LanguageMetadata(
      displayName: 'Korean',
      curriculumKey: 'korean',
      tutorName: 'Korean',
      defaultLocale: 'ko-KR',
    ),
    'ru': _LanguageMetadata(
      displayName: 'Russian',
      curriculumKey: 'russian',
      tutorName: 'Russian',
      defaultLocale: 'ru-RU',
    ),
    'ar': _LanguageMetadata(
      displayName: 'Arabic',
      curriculumKey: 'arabic',
      tutorName: 'Arabic',
      defaultLocale: 'ar-SA',
    ),
    'hi': _LanguageMetadata(
      displayName: 'Hindi',
      curriculumKey: 'hindi',
      tutorName: 'Hindi',
      defaultLocale: 'hi-IN',
    ),
    'th': _LanguageMetadata(
      displayName: 'Thai',
      curriculumKey: 'thai',
      tutorName: 'Thai',
      defaultLocale: 'th-TH',
    ),
    'tl': _LanguageMetadata(
      displayName: 'Tagalog',
      curriculumKey: 'tagalog',
      tutorName: 'Tagalog',
      defaultLocale: 'tl-PH',
    ),
    'ms': _LanguageMetadata(
      displayName: 'Malay',
      curriculumKey: 'bahasa melayu',
      tutorName: 'Malay',
      defaultLocale: 'ms-MY',
    ),
  };

  static const Map<String, String> _aliases = {
    'english': 'en',
    'french': 'fr',
    'german': 'de',
    'spanish': 'es',
    'italian': 'it',
    'portuguese': 'pt',
    'mandarin': 'zh',
    'mandarin chinese': 'zh',
    'chinese': 'zh',
    'chinese (mandarin)': 'zh',
    'japanese': 'ja',
    'korean': 'ko',
    'russian': 'ru',
    'arabic': 'ar',
    'hindi': 'hi',
    'thai': 'th',
    'tagalog': 'tl',
    'malay': 'ms',
    'bahasa melayu': 'ms',
    'bahasa malaysia': 'ms',
  };

  /// Returns a supported two-letter code, or null for an unrecognised value.
  /// Locale values (for example `es-MX`) and legacy display names are accepted.
  static String? tryCanonicalCode(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase().replaceAll('_', '-');
    if (normalized.isEmpty) return null;

    if (_languages.containsKey(normalized)) return normalized;
    if (_aliases.containsKey(normalized)) return _aliases[normalized];

    final localeCode = normalized.split('-').first;
    if (_languages.containsKey(localeCode)) return localeCode;
    return null;
  }

  /// Converts user-supplied values to a supported code, with an explicit
  /// fallback for UI-only uses.
  static String canonicalCode(String? value, {String fallback = 'en'}) =>
      tryCanonicalCode(value) ?? fallback;

  static bool isSupported(String? value) => tryCanonicalCode(value) != null;

  static List<String> canonicalizeAll(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final code = tryCanonicalCode(value);
      if (code != null && seen.add(code)) result.add(code);
    }
    return result;
  }

  static String displayName(String? value) =>
      _languages[canonicalCode(value)]!.displayName;

  static String tutorName(String? value) =>
      _languages[canonicalCode(value)]!.tutorName;

  static String defaultLocale(String? value) =>
      _languages[canonicalCode(value)]!.defaultLocale;

  static String curriculumKey(String? value) =>
      _languages[canonicalCode(value)]!.curriculumKey;

  static bool hasBundledCurriculum(String? value) {
    // Launch eligibility requires both reviewed curriculum and complete visual
    // assets. Malay data exists in an internal draft, but it has no shipped
    // theme/flag asset yet, so it is intentionally not selectable at launch.
    switch (tryCanonicalCode(value)) {
      case 'en':
      case 'es':
      case 'fr':
      case 'zh':
      case 'hi':
      case 'ru':
      case 'ar':
        return true;
      default:
        return false;
    }
  }
}

class _LanguageMetadata {
  final String displayName;
  final String curriculumKey;
  final String tutorName;
  final String defaultLocale;

  const _LanguageMetadata({
    required this.displayName,
    required this.curriculumKey,
    required this.tutorName,
    required this.defaultLocale,
  });
}
