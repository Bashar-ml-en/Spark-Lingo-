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
    // Releases without a configured HTTPS endpoint still expose the reviewed
    // draft text in-app, clearly labelled as a draft. Purchases stay gated on
    // real build-time policy URLs (LEG-001); only learning surfaces open.
    if (uri == null) {
      _showInAppLegalViewer(context, label, isDraft: true);
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        _showInAppLegalViewer(context, label);
      }
    } catch (_) {
      if (context.mounted) {
        _showInAppLegalViewer(context, label);
      }
    }
  }

  void _showInAppLegalViewer(
    BuildContext context,
    String label, {
    bool isDraft = false,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        height: MediaQuery.of(dialogContext).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.colorScheme.primary.withAlpha(51)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isDraft
                        ? 'DRAFT — review copy only. Approved public policy URLs have not been configured for this release yet.\n\n${_getLegalDocumentContent(label)}'
                        : _getLegalDocumentContent(label),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLegalDocumentContent(String label) {
    switch (label) {
      case 'Terms of Service':
        return 'SPARK LINGO TERMS OF SERVICE\n\n'
            '1. Acceptance of Terms\n'
            'By using Spark Lingo, you agree to these terms. Spark Lingo provides interactive language learning, SRS flashcards, and AI conversational practice.\n\n'
            '2. Account & Usage\n'
            'You may use Spark Lingo as a guest or with a registered account. You agree not to misuse AI practice or attempt automated extraction of curriculum assets.\n\n'
            '3. Subscriptions & Payments\n'
            'In-app purchases and subscriptions are managed securely via RevenueCat and your app store account.\n\n'
            '4. Support Contact\n'
            'For questions or support, contact support@sparklingo.com.';
      case 'Privacy Policy':
        return 'SPARK LINGO PRIVACY POLICY\n\n'
            '1. Information We Collect\n'
            'We collect learning progress, active language selections, and optional diagnostic telemetry when authorized by you.\n\n'
            '2. Data Security\n'
            'Your profile and progression data are securely stored in Supabase with strict Row Level Security (RLS) policies.\n\n'
            '3. AI & Voice Privacy\n'
            'Voice audio sent for AI Tutor practice is processed strictly for transcription and conversation, and is never sold to third parties.\n\n'
            '4. Data Control\n'
            'You may request account deletion or data export at any time from Settings.';
      case 'AI & voice processing notice':
        return 'AI & VOICE PROCESSING NOTICE\n\n'
            'Spark Lingo uses AI language models to generate contextual conversation practice and real-time voice feedback.\n\n'
            '• Audio recordings are converted to text strictly for practice feedback.\n'
            '• Transcripts are processed transiently and kept private to your account.\n'
            '• You may pause or disable AI features at any time.';
      case 'Analytics notice':
        return 'ANALYTICS & DIAGNOSTICS NOTICE\n\n'
            'Spark Lingo includes privacy-safe telemetry to monitor performance and app stability.\n\n'
            '• No personal identifiers, voice audio, or transcripts are included in telemetry.\n'
            '• You can toggle Analytics & Diagnostics consent on or off anytime in Settings.';
      case 'Help & support':
        return 'SPARK LINGO HELP & SUPPORT\n\n'
            'Need help with Spark Lingo?\n\n'
            '• Email Support: support@sparklingo.com\n'
            '• Response Time: Within 24 hours\n'
            '• Topics: Account recovery, subscription issues, audio practice, or reporting content typos.';
      case 'Account deletion request':
        return 'ACCOUNT DELETION INSTRUCTIONS\n\n'
            'If you wish to delete your Spark Lingo account:\n\n'
            '1. In-App: Go to Settings -> Delete Account -> Type DELETE to confirm.\n'
            '2. External Request: Email privacy@sparklingo.com with your registered account details.\n'
            '3. Processing: All profile data and learning history will be permanently purged within 30 days.';
      default:
        return 'Spark Lingo official documentation for $label.\n\nFor further inquiries, contact support@sparklingo.com.';
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
