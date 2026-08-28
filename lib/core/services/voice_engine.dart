// Mobile/desktop voice engine backed by `flutter_tts`.
// Selected by voice_controller.dart on all non-web platforms.
// On the web the conditional import swaps this for the web engine, which
// drives the browser Speech Synthesis API instead (flutter_tts has no web
// implementation there).
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceEngine {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, String locale) async {
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('Voice stop failed: $e');
    }
  }
}
