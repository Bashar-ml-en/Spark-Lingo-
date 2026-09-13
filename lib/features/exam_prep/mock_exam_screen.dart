import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Kept as a defensive route target while scored mock exams are unavailable.
///
/// This page intentionally contains no timer, answer capture, recording,
/// placeholder player, submission action, or result. A deep link or an old
/// caller therefore cannot turn an incomplete feature into a fake assessment.
class MockExamScreen extends StatelessWidget {
  const MockExamScreen({
    super.key,
    required this.userId,
    required this.mockExamId,
  });

  final String userId;
  final String mockExamId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mockExamPreview)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Semantics(
                container: true,
                label: l10n.mockExamPreviewSemantics,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.construction_outlined, size: 48),
                        const SizedBox(height: 20),
                        Text(
                          l10n.mockExamsUnavailable,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.mockExamPreviewAvailability),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.returnToExamPreview),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
