// Web voice engine: drives the browser Speech Synthesis API.
// Selected by voice_controller.dart only on the web build, where
// `flutter_tts` has no implementation.
import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

class VoiceEngine {
  /// Chrome auto-pauses speech synthesis after ~15s of continuous
  /// speaking; a periodic resume() keeps longer AI replies audible.
  Timer? _keepAlive;

  Future<void> speak(String text, String locale) async {
    final synth = speechSynthesisGlobal;
    if (synth == null) {
      debugPrint('speechSynthesis unavailable in this browser');
      return;
    }
    // Chrome bug #679437: cancel() immediately before speak() makes the
    // new utterance silently drop. Only cancel when audio is actually
    // queued or playing.
    if (synth.speaking || synth.pending) {
      synth.cancel();
    }
    final utterance = JSUtterance(text);
    utterance.lang = locale;
    utterance.rate = 0.95;
    final voice = _pickVoiceFor(synth, locale);
    if (voice != null) {
      utterance.voice = voice;
    }
    final done = Completer<void>();
    void finish(JSAny? _) {
      _keepAlive?.cancel();
      _keepAlive = null;
      if (!done.isCompleted) done.complete();
    }

    utterance.onend = finish.toJS;
    utterance.onerror = finish.toJS;
    _keepAlive?.cancel();
    _keepAlive = Timer.periodic(const Duration(seconds: 10), (_) {
      try {
        synth.resume();
      } catch (e) {
        debugPrint('Voice keep-alive resume failed: $e');
      }
    });
    synth.speak(utterance);
    await done.future;
  }

  Future<void> stop() async {
    _keepAlive?.cancel();
    _keepAlive = null;
    try {
      speechSynthesisGlobal?.cancel();
    } catch (e) {
      debugPrint('Voice stop failed: $e');
    }
  }

  /// Picks an installed browser voice for [locale] (exact locale first,
  /// then same language). Returns null to let the browser choose.
  JSVoice? _pickVoiceFor(JSSpeechSynthesis synth, String locale) {
    try {
      final wantedFull = locale.toLowerCase();
      final wantedLang = locale.split('-').first.toLowerCase();
      JSVoice? langMatch;
      for (final voice in synth.getVoices().toDart) {
        final lang = voice.lang.toLowerCase();
        if (lang == wantedFull) return voice;
        if (langMatch == null && lang.startsWith(wantedLang)) {
          langMatch = voice;
        }
      }
      return langMatch;
    } catch (e) {
      debugPrint('Voice lookup failed: $e');
      return null;
    }
  }
}

/// Bindings for the browser Speech Synthesis API.
@JS('speechSynthesis')
external JSSpeechSynthesis? get speechSynthesisGlobal;

extension type JSSpeechSynthesis._(JSObject _) implements JSObject {
  external JSArray<JSVoice> getVoices();
  external void speak(JSUtterance utterance);
  external void cancel();
  external void resume();
  external bool get speaking;
  external bool get pending;
}

extension type JSUtterance._(JSObject _) implements JSObject {
  external JSUtterance(String text);
  external set lang(String value);
  external set rate(num value);
  external set voice(JSVoice value);
  external set onend(JSFunction value);
  external set onerror(JSFunction value);
}

extension type JSVoice._(JSObject _) implements JSObject {
  external String get lang;
}
