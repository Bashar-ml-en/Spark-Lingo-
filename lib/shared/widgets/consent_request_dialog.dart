import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/consent_service.dart';
import '../../core/services/test_consent_service.dart';

/// Presents a contextual affirmative-consent choice for a processing action.
///
/// This is deliberately a notice-and-choice UI, not a substitute for a
/// legally-approved policy. It is invoked only after [LegalConfig] has
/// supplied a valid versioned notice; the caller still must record the choice
/// through the server before enabling the feature.
///
/// Exception: when [TestConsentService.active] is compiled in (web test
/// deployments only), the dialog runs against an in-app draft notice and the
/// caller records the choice on-device instead of the server ledger.
Future<bool> requestProcessingConsent(
  BuildContext context, {
  required ConsentPurpose purpose,
}) async {
  final document = purpose.document;
  final testMode = document == null && TestConsentService.active;
  if (document == null && !testMode) return false;

  final content = switch (purpose) {
    ConsentPurpose.analytics => (
      title: 'Enable analytics & diagnostics?',
      message:
          'If you choose to enable this, Spark Lingo may collect analytics and diagnostic data as described in the current notice. You can turn this off later in Settings.',
      confirmation: 'I agree to enable analytics and diagnostics.',
    ),
    ConsentPurpose.aiProcessing => (
      title: 'Use AI practice?',
      message:
          'If you continue, the practice content you submit will be sent to the configured AI processing service. Do not include sensitive personal information.',
      confirmation: 'I agree to AI processing for this practice.',
    ),
    ConsentPurpose.voiceProcessing => (
      title: 'Use voice practice?',
      message:
          'If you continue, Spark Lingo will request microphone access and send the audio you choose to record to the configured transcription service. Do not record sensitive personal information.',
      confirmation:
          'I agree to voice recording and transcription for practice.',
    ),
  };

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          var acknowledged = false;
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              title: Text(content.title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.message),
                    const SizedBox(height: 8),
                    if (testMode)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFFB13D).withAlpha(120),
                          ),
                        ),
                        child: Text(
                          'TEST DEPLOYMENT — draft notice. Approved public '
                          'policy URLs are not configured yet; your choice is '
                          'stored on this device only.\n\n'
                          '${_draftNoticeText(purpose)}',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      )
                    else ...[
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await launchUrl(
                              document!.uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {
                            // The consent decision remains unavailable until the
                            // learner can deliberately continue or cancel.
                          }
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text(
                          'Read the current processing notice',
                        ),
                      ),
                      Text(
                        'Notice version: ${document!.version}',
                        style: Theme.of(
                          dialogContext,
                        ).textTheme.bodySmall,
                      ),
                    ],
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: acknowledged,
                      onChanged: (value) {
                        setDialogState(() => acknowledged = value ?? false);
                      },
                      title: Text(content.confirmation),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  onPressed: acknowledged
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
        },
      ) ??
      false;
}

/// Draft notice body shown only in test deployments. Mirrors the reviewed
/// in-app legal drafts in SettingsScreen; never presented as approved policy.
String _draftNoticeText(ConsentPurpose purpose) {
  switch (purpose) {
    case ConsentPurpose.analytics:
      return 'Analytics & diagnostics: Spark Lingo includes privacy-safe '
          'telemetry to monitor performance and stability. No personal '
          'identifiers, voice audio, or transcripts are included. You can '
          'toggle this consent on or off anytime in Settings.';
    case ConsentPurpose.aiProcessing:
      return 'AI processing: Spark Lingo uses AI language models to generate '
          'contextual conversation practice and feedback. Prompts are '
          'processed for the practice session; avoid sharing sensitive '
          'personal information.';
    case ConsentPurpose.voiceProcessing:
      return 'AI & voice processing: voice recordings are converted to text '
          'strictly for practice feedback, processed transiently, and kept '
          'private to your account. You may pause or disable AI features at '
          'any time.';
  }
}
