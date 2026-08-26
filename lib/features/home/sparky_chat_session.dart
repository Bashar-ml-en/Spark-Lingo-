import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart' as rec;
import '../../core/constants/language_catalog.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/consent_service.dart';
import '../../core/services/retention_service.dart';
import '../../core/services/test_consent_service.dart';
import '../../core/services/tts_service.dart';
import '../../shared/models/curriculum.dart';
import '../../shared/widgets/consent_request_dialog.dart';
import 'sparky_scorecard.dart';

class _ChatModeMeta {
  final String label;
  final IconData icon;
  const _ChatModeMeta(this.label, this.icon);
}

class SparkyChatSession extends ConsumerStatefulWidget {
  final String language;
  final Lesson? lesson;

  const SparkyChatSession({super.key, required this.language, this.lesson});

  @override
  ConsumerState<SparkyChatSession> createState() =>
      _SparkyChatSessionState();
}

class _SparkyChatSessionState
    extends ConsumerState<SparkyChatSession> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final rec.AudioRecorder _audioRecorder = rec.AudioRecorder();

  final AIService _aiService = AIService();
  final TTSService _ttsService = TTSService();

  bool _isListening = false;
  bool _isAiThinking = false;
  String _loadingMessage = "";

  /// XP for AI practice is awarded once per session, not per turn.
  bool _xpAwardedThisSession = false;

  /// Active Sparky conversation mode (server-validated token). Shown as a
  /// chip row under the app bar; defaults to free_chat.
  String _chatMode = 'free_chat';

  static const Map<String, _ChatModeMeta> _modeMeta = {
    'free_chat': _ChatModeMeta('Chat', Icons.chat_bubble_outline),
    'roleplay': _ChatModeMeta('Roleplay', Icons.theater_comedy_outlined),
    'correction_focus': _ChatModeMeta('Corrections', Icons.spellcheck_outlined),
    'grammar_drill': _ChatModeMeta('Grammar', Icons.school_outlined),
  };

  @override
  void initState() {
    super.initState();
    _restoreOrGreet();
  }

  /// Restores the persisted conversation when one exists; otherwise shows the
  /// standard greeting. History loading is best-effort and never blocks.
  Future<void> _restoreOrGreet() async {
    if (widget.lesson != null) {
      // Graded lesson tasks always start fresh with the task prompt.
      _addSparkyGreeting();
      return;
    }
    final history = await _aiService.loadChatHistory(widget.language);
    if (!mounted) return;
    if (history.isNotEmpty) {
      setState(() {
        _messages.addAll(history);
      });
      _scrollToBottom();
      return;
    }
    _addSparkyGreeting();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _ttsService.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addSparkyGreeting() {
    if (widget.lesson != null && widget.lesson!.sparkyPromptTemplate != null) {
      _messages.add({
        "sender": "sparky",
        "text":
            "Task: ${widget.lesson!.sparkyPromptTemplate!}\n\nHello! I am Sparky. Whenever you are ready, please complete this task. Speak or type your answer!",
      });
      return;
    }
    String greeting;
    switch (LanguageCatalog.canonicalCode(widget.language)) {
      case 'es':
        greeting =
            "¡Hola! Soy Sparky, tu tutor de IA. ¿Cómo estás hoy? ¿De qué te gustaría hablar?";
        break;
      case 'fr':
        greeting =
            "Bonjour! Je suis Sparky, ton tuteur d'IA. Comment ça va aujourd'hui? De quoi aimerais-tu parler ?";
        break;
      case 'zh':
        greeting = "你好！我是你的 AI 导师 Sparky。你今天怎么样？想聊点什么呢？";
        break;
      case 'hi':
        greeting =
            "नमस्ते! मैं आपका एआई ट्यूटर स्पार्की हूँ। आप आज कैसे हैं? आप किस बारे में बात करना चाहेंगे?";
        break;
      case 'ru':
        greeting =
            "Привет! Я Спарки, твой ИИ-репетитор. Как дела сегодня? О чём ты хочешь поговорить?";
        break;
      case 'ms':
        greeting =
            "Selamat pagi! Saya Sparky, tutor AI anda. Apa khabar hari ini? Anda mahu sembang tentang apa?";
        break;
      case 'ar':
        greeting =
            "مرحباً! أنا سباركي، معلم الذكاء الاصطناعي الخاص بك. كيف حالك اليوم؟ ما الذي تود التحدث عنه؟";
        break;
      case 'en':
      default:
        greeting =
            "Hello! I am Sparky, your AI tutor. How are you doing today? What would you like to chat about?";
        break;
    }
    _messages.add({"sender": "sparky", "text": greeting});
  }

  void _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({"sender": "user", "text": text});
    });

    _scrollToBottom();
    await _generateRealAIResponse();
  }

  Future<bool> _ensureProcessingConsent(ConsentPurpose purpose) async {
    final user = ref.read(authProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please sign in before using AI practice.',
            ),
          ),
        );
      }
      return false;
    }

    if (purpose.document == null) {
      // Test-deployment fallback: web test builds compiled with
      // ENABLE_TEST_CONSENT=true show a clearly-labelled draft notice and
      // record the choice so QA can exercise Sparky AI before approved
      // policy URLs exist (LEG-001). The server ledger is tried first: once
      // an operator registers an active consent document row, consent is
      // recorded server-side exactly like the launch flow. Store builds
      // never compile the flag, so this whole path stays off for them.
      if (TestConsentService.active) {
        final consentService = ref.read(consentServiceProvider);
        var serverLedgerUsable = true;
        try {
          if (await consentService.hasCurrentConsent(purpose)) return true;
        } on ConsentServiceException {
          serverLedgerUsable = false;
        }

        if (!mounted) return false;
        final accepted = await requestProcessingConsent(
          context,
          purpose: purpose,
        );
        if (!accepted) return false;

        if (serverLedgerUsable) {
          try {
            await consentService.recordConsent(purpose);
            return true;
          } on ConsentConfigurationException {
            // No active server document (yet): fall back to device ledger.
          } on ConsentServiceException {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'We could not record your choice. Nothing was sent.',
                  ),
                ),
              );
            }
            return false;
          }
        }

        final recorded = await TestConsentService.recordConsent(
          purpose.documentKey,
        );
        if (!recorded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'We could not record your choice. Nothing was sent.',
              ),
            ),
          );
        }
        return recorded;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This processing feature is not available in this build.',
            ),
          ),
        );
      }
      return false;
    }

    final consentService = ref.read(consentServiceProvider);
    try {
      if (await consentService.hasCurrentConsent(purpose)) return true;
    } on ConsentServiceException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This processing feature is temporarily unavailable.',
            ),
          ),
        );
      }
      return false;
    }

    if (!mounted) return false;
    final accepted = await requestProcessingConsent(context, purpose: purpose);
    if (!accepted) return false;

    try {
      await consentService.recordConsent(purpose);
      return true;
    } on ConsentServiceException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not record your choice. Nothing was sent.'),
          ),
        );
      }
      return false;
    } on ConsentConfigurationException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This processing feature is not available in this build.',
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _generateRealAIResponse() async {
    if (!await _ensureProcessingConsent(ConsentPurpose.aiProcessing)) return;
    if (!mounted) return;

    setState(() {
      _isAiThinking = true;
      _loadingMessage = "Sparky is thinking...";
      // Streaming placeholder bubble: deltas append into this entry so the
      // reply appears token-by-token instead of after a long blank wait.
      _messages.add({"sender": "sparky", "text": ""});
    });
    _scrollToBottom();

    final buffer = StringBuffer();
    try {
      await for (final delta in _aiService.streamChatResponse(
        _messages.where((m) => (m["text"] ?? "").isNotEmpty).toList(),
        widget.language,
        mode: _chatMode,
      )) {
        buffer.write(delta);
        if (!mounted) break;
        setState(() {
          _messages.last["text"] = buffer.toString();
        });
        _scrollToBottom();
      }
      if (!mounted) return;
      final finalText = buffer.toString().trim();
      if (finalText.isEmpty) {
        setState(() {
          _messages.last["text"] =
              "Sparky couldn't think of a reply. Please try again.";
        });
      } else {
        _ttsService.speak(finalText, widget.language);
        // Retention: one XP award for the first successful AI exchange in a
        // session (not per turn, to keep the economy honest).
        if (!_xpAwardedThisSession) {
          _xpAwardedThisSession = true;
          ref.read(retentionServiceProvider).awardXp(
            source: 'ai_chat',
            amount: XpAmounts.aiChatTurn,
            languageCode: widget.language,
          );
        }
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final partial = buffer.toString().trim();
      setState(() {
        _messages.last["text"] = partial.isNotEmpty
            ? partial
            : "Sparky is having trouble connecting right now. Please check your connection and try again.";
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isAiThinking = false;
        });
      }
    }
  }

  Future<void> _toggleVoiceRecording() async {
    try {
      if (_isListening) {
        // Stop recording user speech
        final path = await _audioRecorder.stop();
        setState(() {
          _isListening = false;
        });
        if (path != null) {
          debugPrint("Audio recorded successfully to target: $path");

          setState(() {
            _isAiThinking = true;
            _loadingMessage = "Transcribing...";
          });

          try {
            final transcribedSpeech = await _aiService.transcribeAudio(path);
            if (transcribedSpeech != null &&
                transcribedSpeech.trim().isNotEmpty) {
              setState(() {
                _messages.add({"sender": "user", "text": transcribedSpeech});
              });
              _scrollToBottom();
              await _generateRealAIResponse();
            } else {
              setState(() {
                _isAiThinking = false;
              });
            }
          } catch (e) {
            debugPrint('Transcription failed.');
            setState(() {
              _messages.add({
                "sender": "sparky",
                "text":
                    "I didn't quite catch that. Could you try again or type it?",
              });
              _isAiThinking = false;
            });
            _scrollToBottom();
          }
        }
      } else {
        if (!await _ensureProcessingConsent(ConsentPurpose.voiceProcessing)) {
          return;
        }
        if (!mounted) return;

        // Verify audio input permissions first
        if (await _audioRecorder.hasPermission()) {
          setState(() {
            _isListening = true;
          });
          await _audioRecorder.start(
            const rec.RecordConfig(encoder: rec.AudioEncoder.aacLc),
            path: '',
          );
        } else {
          debugPrint(
            "Microphone permission was denied by client operating system.",
          );
        }
      }
    } catch (e) {
      debugPrint('Audio recording failed.');
      setState(() {
        _isListening = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _finishAndGradeAttempt() async {
    if (widget.lesson == null || widget.lesson!.rubricRef == null) return;

    // Accumulate all user responses
    final userResponse = _messages
        .where((msg) => msg['sender'] == 'user')
        .map((msg) => msg['text'] ?? '')
        .join(' ')
        .trim();

    if (userResponse.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please say or type something before grading!'),
          ),
        );
      }
      return;
    }

    if (!await _ensureProcessingConsent(ConsentPurpose.aiProcessing)) return;
    if (!mounted) return;

    setState(() {
      _isAiThinking = true;
      _loadingMessage = "Evaluating against rubric...";
    });

    try {
      final evaluation = await _aiService.scorePracticeAttempt(
        userResponse: userResponse,
        rubricRef: widget.lesson!.rubricRef!,
        targetLanguage: widget.language,
        promptTemplate: widget.lesson!.sparkyPromptTemplate,
      );

      if (evaluation != null) {
        if (mounted) {
          Navigator.pop(context); // close chat sheet
          _showScorecardBottomSheet(
            context,
            evaluation,
            widget.lesson!.honestyDisclaimer,
          );
        }
      }
    } catch (e) {
      debugPrint('Practice evaluation failed.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiThinking = false;
        });
      }
    }
  }

  void _showScorecardBottomSheet(
    BuildContext context,
    Map<String, dynamic> evaluation,
    String? customDisclaimer,
  ) {
    showScorecardSheet(context, evaluation, customDisclaimer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.face, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              widget.lesson != null
                  ? widget.lesson!.title
                  : "Sparky — AI Tutor",
            ),
          ],
        ),
        actions: [
          if (widget.lesson != null && widget.lesson!.rubricRef != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: TextButton.icon(
                onPressed: _finishAndGradeAttempt,
                icon: Icon(
                  Icons.analytics,
                  color: theme.colorScheme.onSecondary,
                  size: 18,
                ),
                label: Text(
                  'Finish & Grade',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Conversation-mode picker. Only the mode token leaves the device;
          // all prompt composition stays server-side.
          if (widget.lesson == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  for (final entry in _modeMeta.entries)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          entry.value.icon,
                          size: 16,
                          color: _chatMode == entry.key
                              ? theme.colorScheme.onSecondary
                              : theme.colorScheme.secondary,
                        ),
                        label: Text(entry.value.label),
                        selected: _chatMode == entry.key,
                        selectedColor: theme.colorScheme.secondary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _chatMode == entry.key
                              ? theme.colorScheme.onSecondary
                              : theme.colorScheme.onSurface,
                        ),
                        onSelected: (_) {
                          if (_isAiThinking) return;
                          setState(() => _chatMode = entry.key);
                        },
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isSparky = msg["sender"] == "sparky";
                return Align(
                  alignment: isSparky
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isSparky
                          ? theme.cardColor
                          : theme.colorScheme.primary.withAlpha(38),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isSparky
                            ? Radius.zero
                            : const Radius.circular(16),
                        bottomRight: isSparky
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                      border: Border.all(
                        color: isSparky
                            ? theme.colorScheme.primary.withAlpha(25)
                            : theme.colorScheme.primary.withAlpha(51),
                      ),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isListening || _isAiThinking)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _isListening
                          ? Colors.redAccent
                          : theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isListening ? "Listening..." : _loadingMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isListening
                          ? Colors.redAccent
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(color: theme.colorScheme.primary.withAlpha(25)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Colors.redAccent
                        : theme.colorScheme.secondary,
                  ),
                  onPressed: _toggleVoiceRecording,
                  tooltip: "Record Voice",
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Type your reply...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

