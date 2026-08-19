import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/legal_config.dart';
import '../../core/router/router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/widgets/analytics_consent_tile.dart';

/// A public, fail-closed surface for legal, support, and account links.
///
/// Legal and support destinations are supplied only by build-time HTTPS
/// configuration. The app deliberately does not substitute sample policies,
/// placeholder contacts, or insecure destinations when a release has not
/// configured a real endpoint.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openExternalLink(
    BuildContext context,
    Uri? uri, {
    required String label,
  }) async {
    if (uri == null) {
      _showMessage(context, '$label is not available in this build.');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        _showMessage(context, 'We could not open $label.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'We could not open $label.');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final confirmationController = TextEditingController();
    var isDeleting = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('Delete your account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your Spark Lingo account and in-app learning data. It does not cancel App Store or Google Play subscriptions, and other providers may retain data under their own policies.',
              ),
              const SizedBox(height: 16),
              const Text('Type DELETE to confirm.'),
              const SizedBox(height: 8),
              TextField(
                controller: confirmationController,
                enabled: !isDeleting,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Confirmation',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: isDeleting || confirmationController.text != 'DELETE'
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        final deleted = await ref
                            .read(databaseServiceProvider)
                            .deleteCurrentAccount();
                        if (!deleted) {
                          throw StateError(
                            'Account deletion was not confirmed.',
                          );
                        }

                        ref.read(localActiveLanguageProvider.notifier).state =
                            null;
                        try {
                          await ref.read(authProvider.notifier).signOut();
                        } catch (_) {
                          // A successful server deletion can invalidate the
                          // session before the client attempts sign-out.
                        }

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (context.mounted) {
                          context.go(SparkRouter.welcome);
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() => isDeleting = false);
                        }
                        if (context.mounted) {
                          _showMessage(
                            context,
                            'We could not delete your account. Please try again.',
                          );
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete account'),
            ),
          ],
        ),
      ),
    ).whenComplete(confirmationController.dispose);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & help')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const _SettingsSectionLabel('Legal'),
            _ExternalLinkTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              uri: LegalConfig.termsOfServiceUri,
              onOpen: _openExternalLink,
            ),
            _ExternalLinkTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              uri: LegalConfig.privacyPolicyUri,
              onOpen: _openExternalLink,
            ),
            _ExternalLinkTile(
              icon: Icons.mic_none_outlined,
              title: 'AI & voice processing notice',
              uri: LegalConfig.aiAndVoiceNoticeUri,
              onOpen: _openExternalLink,
            ),
            _ExternalLinkTile(
              icon: Icons.analytics_outlined,
              title: 'Analytics notice',
              uri: LegalConfig.analyticsNoticeDocument?.uri,
              onOpen: _openExternalLink,
            ),
            const Divider(),
            const _SettingsSectionLabel('Analytics & diagnostics'),
            AnalyticsConsentTile(signedIn: user != null),
            const Divider(),
            const _SettingsSectionLabel('Help & support'),
            _ExternalLinkTile(
              icon: Icons.help_outline,
              title: 'Help & support',
              uri: LegalConfig.supportUri,
              onOpen: _openExternalLink,
            ),
            const Divider(),
            const _SettingsSectionLabel('Your data'),
            if (user != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete account'),
                subtitle: const Text('Permanently remove your in-app account.'),
                onTap: () => _showDeleteAccountDialog(context, ref),
              ),
            _ExternalLinkTile(
              icon: Icons.open_in_new,
              title: 'Account deletion request',
              subtitle: 'For requests made after uninstalling the app.',
              uri: LegalConfig.accountDeletionUri,
              onOpen: _openExternalLink,
            ),
            _ExternalLinkTile(
              icon: Icons.download_outlined,
              title: 'Request a copy of your data',
              uri: LegalConfig.dataExportUri,
              onOpen: _openExternalLink,
            ),
            _ExternalLinkTile(
              icon: Icons.receipt_long_outlined,
              title: 'Manage subscription',
              uri: LegalConfig.subscriptionManagementUri,
              onOpen: _openExternalLink,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExternalLinkTile extends StatelessWidget {
  const _ExternalLinkTile({
    required this.icon,
    required this.title,
    required this.uri,
    required this.onOpen,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Uri? uri;
  final Future<void> Function(BuildContext, Uri?, {required String label})
  onOpen;

  @override
  Widget build(BuildContext context) {
    final isAvailable = uri != null;
    final unavailableSubtitle = subtitle == null
        ? 'Unavailable in this build.'
        : '$subtitle Unavailable in this build.';

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        isAvailable
            ? subtitle ?? 'Opens in your browser.'
            : unavailableSubtitle,
      ),
      trailing: Icon(isAvailable ? Icons.open_in_new : Icons.block_outlined),
      enabled: isAvailable,
      onTap: isAvailable ? () => onOpen(context, uri, label: title) : null,
    );
  }
}
