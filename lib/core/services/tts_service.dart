import 'package:flutter_tts/flutter_tts.dart';
import '../constants/language_catalog.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  late final Future<void> _ready;

  TTSService() {
    _ready = _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  /// Resolves canonical codes, legacy names, and regional values to BCP-47.
  /// Keeping this public and pure also makes language selection testable without
  /// invoking a platform TTS plugin.
  static String localeFor(String language) =>
      LanguageCatalog.defaultLocale(language);

  /// Speaks the provided text using the appropriate language pronunciation engine.
  Future<void> speak(String text, String language) async {
    if (text.trim().isEmpty) return;
    await _ready;
    final langCode = localeFor(language);
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _ready;
    await _flutterTts.stop();
  }
}
