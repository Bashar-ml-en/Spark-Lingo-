import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_config.dart';

/// Client for the authenticated, server-authoritative AI gateway.
///
/// The app must never send an OpenAI credential, choose a model, or build a
/// privileged system prompt. Those decisions are enforced by the Edge
/// Function after it verifies the current Supabase user session.
class AIService {
  static const _requestTimeout = Duration(seconds: 45);
  static const _maxClientMessages = 20;
  static const _maxMessageCharacters = 2000;
  // Leave UTF-8/JSON headroom below the Edge Function's 16k-character and
  // 64KiB request caps. Keep the newest turns rather than sending an
  // unbounded transcript that will be rejected after the user presses Send.
  static const _maxHistoryCharacters = 12000;
  // Keep client feedback requests aligned with the server-enforced cap.
  static const _maxPracticeResponseCharacters = 6000;

  static String get _edgeFunctionBaseUrl =>
      '${SupabaseConfig.url}/functions/v1/sparky-ai';

  String _accessToken() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const AIServiceException(
        'Please sign in before using AI practice.',
      );
    }
    return token;
  }

  Map<String, String> _headers(String accessToken) {
    if (SupabaseConfig.publishableKey.isEmpty || SupabaseConfig.url.isEmpty) {
      throw const AIServiceException('AI practice is not configured.');
    }

    // `apikey` identifies the public Supabase project for gateway routing.
    // Authorization is the user's session and is the only identity trusted by
    // the Edge Function.
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'apikey': SupabaseConfig.publishableKey,
      'Authorization': 'Bearer $accessToken',
    };
  }

  Map<String, String> _multipartHeaders(String accessToken) {
    final headers = _headers(accessToken);
    // MultipartRequest supplies its own boundary-bearing content type.
    headers.remove('Content-Type');
    return headers;
  }

  Future<http.Response> _postJson(
    String action,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_edgeFunctionBaseUrl?action=$action'),
          headers: _headers(_accessToken()),
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AIServiceException(
        _messageForStatus(response.statusCode, response.body),
      );
    }
    return response;
  }

  String _messageForStatus(int statusCode, [String? responseBody]) {
    // The Edge Function deliberately returns a short allow-listed error code.
    // Prefer that code over displaying a generic authentication error to a
    // guest who is blocked before any prompt, audio, quota, or provider call.
    try {
      final decoded = jsonDecode(responseBody ?? '');
      if (decoded is Map<String, dynamic> &&
          decoded['code'] == 'verified_account_required') {
        return 'AI practice is available after you sign in with a recoverable account.';
      }
    } catch (_) {
      // Error bodies are untrusted transport data; use the status fallback.
    }

    switch (statusCode) {
      case 401:
      case 403:
        return 'Please sign in again before using AI practice.';
      case 413:
        return 'That practice response is too large. Please shorten it and try again.';
      case 429:
        return 'You have reached your current AI practice limit. Please try again later.';
      default:
        return 'AI practice is temporarily unavailable. Please try again.';
    }
  }

  /// Transcribes a local audio file through the authenticated Edge Function.
  Future<String?> transcribeAudio(String filePath) async {
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('$_edgeFunctionBaseUrl?action=transcribe'),
            )
            ..headers.addAll(_multipartHeaders(_accessToken()))
            ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send().timeout(_requestTimeout);
      final responseBody = await streamedResponse.stream
          .bytesToString()
          .timeout(_requestTimeout);

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        throw AIServiceException(
          _messageForStatus(streamedResponse.statusCode, responseBody),
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const AIServiceException(
          'AI practice returned an invalid response.',
        );
      }
      final text = decoded['text'];
      if (text is! String || text.trim().isEmpty) {
        throw const AIServiceException(
          'No speech was detected. Please try again.',
        );
      }
      return text.trim();
    } on AIServiceException {
      rethrow;
    } on TimeoutException {
      throw const AIServiceException(
        'Voice transcription timed out. Please try again.',
      );
    } catch (_) {
      throw const AIServiceException(
        'Voice transcription is temporarily unavailable.',
      );
    }
  }

  /// Generates a response using bounded, user/assistant-only conversation history.
  Future<String?> generateChatResponse(
    List<Map<String, String>> history,
    String targetLanguage,
  ) async {
    final language = targetLanguage.trim();
    if (language.isEmpty) {
      throw const AIServiceException(
        'Choose a language before starting practice.',
      );
    }

    final messages = <Map<String, String>>[];
    for (final message in history) {
      final sender = message['sender'];
      final role = sender == 'user'
          ? 'user'
          : sender == 'sparky'
          ? 'assistant'
          : null;
      final content = (message['text'] ?? '').trim();
      if (role != null && content.isNotEmpty) {
        messages.add(<String, String>{
          'role': role,
          'content': _truncate(content, _maxMessageCharacters),
        });
      }
    }

    if (messages.isEmpty) {
      throw const AIServiceException(
        'Send a practice message before asking Sparky.',
      );
    }

    final messageCountLimited = messages.length > _maxClientMessages
        ? messages.sublist(messages.length - _maxClientMessages)
        : messages;
    final recentMessages = _retainNewestWithinCharacterBudget(
      messageCountLimited,
      _maxHistoryCharacters,
    );

    try {
      final response = await _postJson('chat', <String, dynamic>{
        'targetLanguage': language,
        'messages': recentMessages,
      });
      return _assistantContent(response.body);
    } on AIServiceException {
      rethrow;
    } on TimeoutException {
      throw const AIServiceException(
        'AI practice timed out. Please try again.',
      );
    } catch (_) {
      throw const AIServiceException(
        'AI practice is temporarily unavailable. Please try again.',
      );
    }
  }

  /// Scores an attempt against a server-approved rubric.
  Future<Map<String, dynamic>?> scorePracticeAttempt({
    required String userResponse,
    required String rubricRef,
    required String targetLanguage,
    String? promptTemplate,
  }) async {
    final responseText = userResponse.trim();
    if (responseText.isEmpty) {
      throw const AIServiceException(
        'Add a response before asking for feedback.',
      );
    }
    if (responseText.length > _maxPracticeResponseCharacters) {
      throw const AIServiceException(
        'That response is too large. Please submit a shorter practice attempt.',
      );
    }

    try {
      final response = await _postJson('score', <String, dynamic>{
        'targetLanguage': targetLanguage.trim(),
        'rubricRef': rubricRef.trim(),
        'userResponse': responseText,
        if (promptTemplate != null && promptTemplate.trim().isNotEmpty)
          'promptTemplate': promptTemplate.trim(),
      });

      final content = _assistantContent(response.body).trim();
      final normalized = content
          .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
      final decoded = jsonDecode(normalized);
      if (decoded is! Map<String, dynamic>) {
        throw const AIServiceException(
          'AI feedback returned an invalid response.',
        );
      }
      return decoded;
    } on AIServiceException {
      rethrow;
    } on TimeoutException {
      throw const AIServiceException(
        'AI feedback timed out. Please try again.',
      );
    } on FormatException {
      throw const AIServiceException(
        'AI feedback could not be read. Please try again.',
      );
    } catch (_) {
      throw const AIServiceException(
        'AI feedback is temporarily unavailable. Please try again.',
      );
    }
  }

  String _assistantContent(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const AIServiceException(
        'AI practice returned an invalid response.',
      );
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      throw const AIServiceException(
        'AI practice returned an invalid response.',
      );
    }
    final message = (choices.first as Map)['message'];
    final content = message is Map ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const AIServiceException('AI practice returned an empty response.');
    }
    return content;
  }

  List<Map<String, String>> _retainNewestWithinCharacterBudget(
    List<Map<String, String>> messages,
    int characterBudget,
  ) {
    var remaining = characterBudget;
    final retained = <Map<String, String>>[];

    for (final message in messages.reversed) {
      if (remaining <= 0) break;
      final content = message['content'] ?? '';
      final clipped = _truncate(content, remaining);
      if (clipped.isEmpty) continue;
      retained.insert(0, <String, String>{
        'role': message['role'] ?? 'user',
        'content': clipped,
      });
      remaining -= clipped.length;
    }

    return retained;
  }

  String _truncate(String value, int maximumLength) {
    if (maximumLength <= 0) return '';
    if (value.length <= maximumLength) return value;

    var end = maximumLength;
    // Do not cut a UTF-16 surrogate pair in half before JSON encoding.
    if (end > 0 &&
        end < value.length &&
        _isHighSurrogate(value.codeUnitAt(end - 1)) &&
        _isLowSurrogate(value.codeUnitAt(end))) {
      end -= 1;
    }
    return value.substring(0, end);
  }

  bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

  bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
}

class AIServiceException implements Exception {
  const AIServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
