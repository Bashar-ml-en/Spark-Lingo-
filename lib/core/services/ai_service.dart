import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  /// Server-validated conversation modes (must match the Edge Function enum).
  /// The client sends only these tokens; the server composes all prompts.
  static const List<String> chatModes = <String>[
    'free_chat',
    'roleplay',
    'correction_focus',
    'grammar_drill',
  ];

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
      case 400:
        return 'Sparky couldn’t start that request. Please try sending your message again.';
      case 401:
      case 403:
        return 'Please sign in again before using AI practice.';
      case 413:
        return 'That practice response is too large. Please shorten it and try again.';
      case 429:
        return 'You have reached your current AI practice limit. Please try again in a little while.';
      case 503:
        return 'Sparky’s service is briefly unavailable. Please try again in a moment.';
      default:
        // Keep the HTTP status visible so support can pinpoint the cause.
        return 'AI practice is temporarily unavailable (error $statusCode). Please try again.';
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

  /// Loads the learner's persisted Sparky conversation for a language,
  /// oldest first. Returns an empty list when nothing is stored or the
  /// request fails — history is an enhancement, never a launch blocker.
  Future<List<Map<String, String>>> loadChatHistory(String targetLanguage) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_edgeFunctionBaseUrl?action=history'),
            headers: _headers(_accessToken()),
            body: jsonEncode(<String, dynamic>{
              'targetLanguage': targetLanguage.trim(),
            }),
          )
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return const [];
      final messages = decoded['messages'];
      if (messages is! List) return const [];
      final restored = <Map<String, String>>[];
      for (final message in messages) {
        if (message is! Map) continue;
        final sender = message['sender'];
        final text = message['text'];
        if ((sender == 'user' || sender == 'assistant') && text is String) {
          restored.add(<String, String>{
            'sender': sender == 'assistant' ? 'sparky' : 'user',
            'text': text,
          });
        }
      }
      return restored;
    } catch (_) {
      return const [];
    }
  }

  /// Streams a chat response as Server-Sent Events, yielding text deltas in
  /// arrival order. The caller appends deltas to build the reply. Throws
  /// [AIServiceException] for any server-reported failure, including errors
  /// delivered mid-stream as SSE error events. [mode] must be one of
  /// [chatModes] (server-validated); null means free_chat.
  Stream<String> streamChatResponse(
    List<Map<String, String>> history,
    String targetLanguage, {
    String? mode,
  }) async* {
    final language = targetLanguage.trim();
    if (language.isEmpty) {
      throw const AIServiceException(
        'Choose a language before starting practice.',
      );
    }
    if (mode != null && !chatModes.contains(mode)) {
      throw const AIServiceException(
        'Unsupported conversation mode.',
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

    final request = http.Request(
      'POST',
      Uri.parse('$_edgeFunctionBaseUrl?action=chat&stream=1'),
    );
    request.headers.addAll(_headers(_accessToken()));
    request.body = jsonEncode(<String, dynamic>{
      'targetLanguage': language,
      'messages': recentMessages,
      if (mode != null) 'mode': mode, // ignore: use_null_aware_elements
    });

    final client = http.Client();
    try {
      final streamedResponse = await client
          .send(request)
          .timeout(_requestTimeout);

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        final responseBody = await streamedResponse.stream
            .bytesToString()
            .timeout(_requestTimeout);
        throw AIServiceException(
          _messageForStatus(streamedResponse.statusCode, responseBody),
        );
      }

      var buffer = '';
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        var newlineIndex = buffer.indexOf('\n');
        while (newlineIndex >= 0) {
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          newlineIndex = buffer.indexOf('\n');
          if (!line.startsWith('data:')) continue;
          final data = line.substring(5).trim();
          if (data == '[DONE]') return;
          Map<String, dynamic>? decoded;
          try {
            final parsed = jsonDecode(data);
            if (parsed is Map<String, dynamic>) decoded = parsed;
          } on FormatException {
            // Malformed or keep-alive lines are skipped, never surfaced.
            continue;
          }
          if (decoded == null) continue;
          final error = decoded['error'];
          if (error is Map) {
            final message = error['message'];
            throw AIServiceException(
              message is String && message.trim().isNotEmpty
                  ? message
                  : 'AI practice is temporarily unavailable. Please try again.',
            );
          }
          final delta = decoded['delta'];
          if (delta is String && delta.isNotEmpty) {
            yield delta;
          }
          if (decoded['done'] == true) return;
        }
      }
    } on AIServiceException {
      rethrow;
    } on TimeoutException {
      throw const AIServiceException(
        'AI practice timed out. Please try again.',
      );
    } catch (e, stack) {
      // Log the real cause for diagnostics; the learner still gets a short,
      // actionable message rather than a raw stack trace.
      debugPrint('Sparky chat failed: $e\n$stack');
      throw AIServiceException(
        'AI practice could not connect (${e.runtimeType}). Please check your connection and try again.',
      );
    } finally {
      client.close();
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
