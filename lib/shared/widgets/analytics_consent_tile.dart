import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/consent_service.dart';
import '../../core/services/telemetry_consent_service.dart';
import 'consent_request_dialog.dart';

/// A settings surface for optional aggregate analytics and diagnostics.
///
/// It stays unavailable unless this build includes a versioned legal notice
/// and the server registry is healthy. It never enables collection based on a
/// local preference alone.
class AnalyticsConsentTile extends ConsumerStatefulWidget {
  const AnalyticsConsentTile({super.key, required this.signedIn});

  final bool signedIn;

  @override
  ConsumerState<AnalyticsConsentTile> createState() =>
      _AnalyticsConsentTileState();
}

class _AnalyticsConsentTileState extends ConsumerState<AnalyticsConsentTile> {
  bool _isLoading = true;
  bool _isAvailable = false;
  bool _hasConsent = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant AnalyticsConsentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signedIn != widget.signedIn) _refresh();
  }

  Future<void> _refresh() async {
    if (!widget.signedIn || ConsentPurpose.analytics.document == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAvailable = false;
          _hasConsent = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      final hasConsent = await ref
          .read(consentServiceProvider)
          .hasCurrentConsent(ConsentPurpose.analytics);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAvailable = true;
          _hasConsent = hasConsent;
        });
      }
    } on ConsentServiceException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAvailable = false;
          _hasConsent = false;
        });
      }
    }
  }

  Future<void> _toggle() async {
    if (_isLoading || !_isAvailable || !widget.signedIn) return;

    if (_hasConsent) {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Turn off analytics & diagnostics?'),
              content: const Text(
                'This stops optional analytics and diagnostics collection for this account on this device. A future app launch may be needed for all provider settings to take effect.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Keep enabled'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Turn off'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;

      try {
        await ref
            .read(consentServiceProvider)
            .withdrawConsent(ConsentPurpose.analytics);
        await TelemetryConsentService.disable();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analytics & diagnostics turned off.'),
            ),
          );
        }
      } on ConsentServiceException {
        if (mounted) _showUnavailableMessage();
      } on ConsentConfigurationException {
        if (mounted) _showUnavailableMessage();
      }
      await _refresh();
      return;
    }

    final accepted = await requestProcessingConsent(
      context,
      purpose: ConsentPurpose.analytics,
    );
    if (!accepted) return;

    try {
      await ref
          .read(consentServiceProvider)
          .recordConsent(ConsentPurpose.analytics);
      await TelemetryConsentService.enableAfterRecordedConsent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analytics & diagnostics enabled.')),
        );
      }
    } on ConsentServiceException {
      if (mounted) _showUnavailableMessage();
    } on ConsentConfigurationException {
      if (mounted) _showUnavailableMessage();
    }
    await _refresh();
  }

  void _showUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This privacy preference is temporarily unavailable.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configured = ConsentPurpose.analytics.document != null;
    final isEnabled = configured && widget.signedIn && _isAvailable;
    final subtitle = !configured
        ? 'Unavailable in this build.'
        : !widget.signedIn
        ? 'Sign in to manage this preference.'
        : !_isAvailable
        ? 'Temporarily unavailable.'
        : _hasConsent
        ? 'Enabled. Tap to turn it off.'
        : 'Disabled. Tap to review and enable.';

    return ListTile(
      leading: const Icon(Icons.analytics_outlined),
      title: const Text('Analytics & diagnostics'),
      subtitle: Text(subtitle),
      trailing: _isLoading && widget.signedIn && configured
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_hasConsent ? Icons.toggle_on : Icons.toggle_off),
      enabled: isEnabled && !_isLoading,
      onTap: isEnabled && !_isLoading ? _toggle : null,
    );
  }
}
