import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/getwidget_theme.dart';

/// In-app Help Center — consistent, always-present self-help location
/// (UX audit rule #105). Links point to the verified live legal pages and
/// support email; FAQ answers are restricted to facts true in the current
/// build.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const String _supportEmail = 'mailto:abulithbisha@gmail.com';

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open this link on your device.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final links = <(String, String, IconData)>[
      ('Privacy policy', 'https://spark-lingo.vercel.app/legal/privacy.html',
          Icons.privacy_tip_outlined),
      ('Terms of service', 'https://spark-lingo.vercel.app/legal/terms.html',
          Icons.description_outlined),
      ('AI & voice notice',
          'https://spark-lingo.vercel.app/legal/ai-and-voice-notice.html',
          Icons.smart_toy_outlined),
      ('Analytics notice',
          'https://spark-lingo.vercel.app/legal/analytics-notice.html',
          Icons.insights_outlined),
      ('Delete my account',
          'https://spark-lingo.vercel.app/legal/account-deletion.html',
          Icons.delete_forever_outlined),
      ('Export my data',
          'https://spark-lingo.vercel.app/legal/data-export.html',
          Icons.download_outlined),
      ('Manage subscription',
          'https://spark-lingo.vercel.app/legal/subscription-management.html',
          Icons.card_membership_outlined),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Help center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SparkGF.card(
            margin: EdgeInsets.zero,
            content: Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: theme.colorScheme.primary,
                  size: 34,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need a human?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email support — we answer within 2 working days.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SparkGF.primaryButton(
                        label: 'Email support',
                        icon: const Icon(Icons.mail_outline_rounded, size: 18),
                        onPressed: () => _open(context, _supportEmail),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SparkGF.card(
            margin: EdgeInsets.zero,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frequently asked',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const GFAccordion(
                  title: 'Why does Sparky AI need my consent?',
                  collapsedTitleBackgroundColor: Colors.transparent,
                  expandedTitleBackgroundColor: Colors.transparent,
                  contentBackgroundColor: Colors.transparent,
                  content:
                      'AI features process your messages on our servers to '
                      'generate replies. We only do that after you agree, '
                      'and your agreement is recorded so you stay in '
                      'control. You can withdraw consent in Settings.',
                ),
                const GFAccordion(
                  title: 'Is my voice recording saved?',
                  collapsedTitleBackgroundColor: Colors.transparent,
                  expandedTitleBackgroundColor: Colors.transparent,
                  contentBackgroundColor: Colors.transparent,
                  content:
                      'Voice input is uploaded only to be transcribed into '
                      'text for your practice. Recordings are not kept as '
                      'permanent account data.',
                ),
                const GFAccordion(
                  title: 'Are the exam scores official?',
                  collapsedTitleBackgroundColor: Colors.transparent,
                  expandedTitleBackgroundColor: Colors.transparent,
                  contentBackgroundColor: Colors.transparent,
                  content:
                      'No — and we never pretend they are. Exam content '
                      'shows verified official formats and practice drills '
                      'report only what happened in your session. Official '
                      'results come only from the exam body.',
                ),
                const GFAccordion(
                  title: 'How do I delete everything?',
                  collapsedTitleBackgroundColor: Colors.transparent,
                  expandedTitleBackgroundColor: Colors.transparent,
                  contentBackgroundColor: Colors.transparent,
                  content:
                      'Settings → Account → Delete account. Everything '
                      'linked to your account is removed permanently.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SparkGF.card(
            margin: EdgeInsets.zero,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Policies & account',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                for (final (label, url, icon) in links)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: theme.colorScheme.primary),
                    title: Text(label),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () => _open(context, url),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
