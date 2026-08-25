import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/language_catalog.dart';

/// Voice preference for spoken practice content.
enum VoicePreference {
  system,
  male,
  female;

  static VoicePreference parse(String? value) => switch (value) {
    'male' => VoicePreference.male,
    'female' => VoicePreference.female,
    _ => VoicePreference.system,
  };
}

/// Text-to-speech with selectable male/female voice variants.
///
/// Strategy per language:
/// 1. Prefer a real engine voice matching the language whose name indicates
///    the requested gender (most platform TTS engines name voices like
///    "en-gb-AbbiNeural" or expose Male/Female markers).
/// 2. Fall back to the language default voice with a pitch shift so the
///    gendered preference is still audible on engines without named variants.
///
/// The choice persists across sessions (shared_preferences) and can be
/// changed from Settings without restarting the app.
class TTSService {
  static const String _prefKey = 'spark_voice_preference';

  final FlutterTts _flutterTts = FlutterTts();
  late final Future<void> _ready;

  VoicePreference _preference = VoicePreference.system;

  TTSService() {
    _ready = _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preference = VoicePreference.parse(prefs.getString(_prefKey));
    } catch (e) {
      debugPrint('Voice preference load failed: $e');
    }
  }

  VoicePreference get preference => _preference;

  /// Updates the persisted voice preference. Subsequent [speak] calls use it.
  Future<void> setPreference(VoicePreference value) async {
    _preference = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, value.name);
    } catch (e) {
      debugPrint('Voice preference save failed: $e');
    }
  }

  /// Resolves canonical codes, legacy names, and regional values to BCP-47.
  /// Keeping this public and pure also makes language selection testable
  /// without invoking a platform TTS plugin.
  static String localeFor(String language) =>
      LanguageCatalog.defaultLocale(language);

  /// Speaks the provided text with the active language and voice preference.
  Future<void> speak(String text, String language) async {
    if (text.trim().isEmpty) return;
    await _ready;
    final locale = localeFor(language);
    await _flutterTts.setLanguage(locale);
    await _applyVoiceFor(locale);
    await _flutterTts.speak(text);
  }

  /// Applies the best available voice for [locale] given the preference.
  Future<void> _applyVoiceFor(String locale) async {
    final pref = _preference;
    if (pref == VoicePreference.system) {
      await _flutterTts.setPitch(1.0);
      return;
    }

    try {
      final voices = await _flutterTts.getVoices;
      final candidates = _voicesForLocale(voices, locale);
      final match = _pickGenderedVoice(candidates, pref);
      if (match != null) {
        await _flutterTts.setVoice(match);
        await _flutterTts.setPitch(1.0);
        return;
      }
    } catch (e) {
      debugPrint('Voice lookup failed, falling back to pitch: $e');
    }

    // Pitch-shift fallback so the preference remains perceptible even when
    // the engine exposes no gendered voice names for this locale.
    await _flutterTts.setPitch(pref == VoicePreference.male ? 0.8 : 1.25);
  }

  /// Filters engine voices to those matching the locale language (and,
  /// when possible, the exact region).
  List<Map<String, String>> _voicesForLocale(
    dynamic voices,
    String locale,
  ) {
    final wantedLang = locale.split('-').first.toLowerCase();
    final wantedFull = locale.toLowerCase();
    final all = <Map<String, String>>[];
    if (voices is List) {
      for (final v in voices) {
        if (v is Map) {
          final m = Map<String, String>.from(
            v.map((k, value) => MapEntry(k.toString(), value.toString())),
          );
          final name = (m['name'] ?? '').toLowerCase();
          final lang = (m['locale'] ?? m['lang'] ?? '').toLowerCase();
          if (name.startsWith(wantedFull) ||
              lang.startsWith(wantedFull) ||
              name.startsWith(wantedLang) ||
              lang.startsWith(wantedLang)) {
            all.add(m);
          }
        }
      }
    }
    return all;
  }

  /// Chooses a voice whose name signals the requested gender.
  Map<String, String>? _pickGenderedVoice(
    List<Map<String, String>> candidates,
    VoicePreference pref,
  ) {
    if (candidates.isEmpty) return null;
    final markers = pref == VoicePreference.male
        ? const ['male', 'man', 'masculine']
        : const ['female', 'woman', 'feminine'];
    // Avoid false positives: "female" contains "male".
    for (final v in candidates) {
      final name = (v['name'] ?? '').toLowerCase();
      if (pref == VoicePreference.female) {
        if (markers.any(name.contains)) return v;
      } else {
        if (name.contains('male') && !name.contains('female')) return v;
        if (markers.any(name.contains)) return v;
      }
    }
    return null;
  }

  Future<void> stop() async {
    await _ready;
    await _flutterTts.stop();
  }
}
