import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/consent_service.dart';

/// Presents a contextual affirmative-consent choice for a processing action.
///
/// This is deliberately a notice-and-choice UI, not a substitute for a
/// legally approved policy. It is invoked only after [LegalConfig] has
/// supplied a valid versioned notice; the caller still must record the choice
/// through the server before enabling the feature.
Future<bool> requestProcessingConsent(
  BuildContext context, {
  required ConsentPurpose purpose,
}) async {
  final document = purpose.document;
  if (document == null) return false;

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
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await launchUrl(
                            document.uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          // The consent decision remains unavailable until the
                          // learner can deliberately continue or cancel.
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Read the current processing notice'),
                    ),
                    Text(
                      'Notice version: ${document.version}',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
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
