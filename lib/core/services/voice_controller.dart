import 'package:flutter/foundation.dart';

import '../constants/language_catalog.dart';
// Platform-specific voice engine. The web build compiles the browser Speech
// Synthesis implementation; every other platform (and VM tests) gets the
// flutter_tts engine. This is why voice works on the website now even
// though flutter_tts has no web support.
import 'voice_engine.dart'
    if (dart.library.js_interop) 'voice_engine_web.dart';

/// Voice output that works on every platform SparkLingo ships to.
///
/// Web: the `flutter_tts` plugin has no web implementation, so speech there
/// previously silently did nothing. On web the engine drives the browser's
/// built-in Speech Synthesis API directly (no plugin required).
/// Mobile/desktop: delegates to `flutter_tts`.
class VoiceController {
  final VoiceEngine _engine = VoiceEngine();

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  /// Speaks [text] in [language]; if something is already playing, stops it
  /// (tap-to-toggle behavior from the chat UI).
  Future<void> toggle(String text, String language) async {
    if (_isSpeaking) {
      await stop();
      return;
    }
    if (text.trim().isEmpty) return;
    final locale = LanguageCatalog.defaultLocale(language);
    try {
      _isSpeaking = true;
      await _engine.speak(text, locale);
      // flutter_tts has no per-call completion future; treat the call as
      // fire-and-forget but leave the speaking flag on until stopped.
      if (!kIsWeb) {
        // Keep the flag; mobile UI relies on the stop button to clear it.
      } else {
        _isSpeaking = false;
      }
    } catch (e) {
      debugPrint('Voice playback failed: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    await _engine.stop();
    _isSpeaking = false;
  }
}
