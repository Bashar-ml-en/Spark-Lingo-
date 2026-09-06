import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/legal_config.dart';
import '../../core/router/router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../shared/widgets/analytics_consent_tile.dart';

/// World-class Settings and Preferences screen aligned with Stitch specifications.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _speechCadence = 1.0;
  String _selectedTutorPersona = 'sparky';
  bool _hapticFeedback = true;
  bool _autoPlayAudio = true;
  bool _soundEffects = true;

  Future<void> _openExternalLink(
    BuildContext context,
    Uri? uri, {
    required String label,
  }) async {
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        height: MediaQuery.of(dialogContext).size.height * 0.75,
        decoration: BoxDecoration(
          color: SparkTheme.surfaceCanvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: SparkTheme.surfaceContainerHighest),
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
                  color: SparkTheme.surfaceContainerHighest,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0xFF273647)),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isDraft
                        ? 'DRAFT — review copy only. Approved public policy URLs have not been configured for this release yet.\n\n${_getLegalDocumentContent(label)}'
                        : _getLegalDocumentContent(label),
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14,
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

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final confirmationController = TextEditingController();
    var isDeleting = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: SparkTheme.surfaceContainer,
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 32,
          ),
          title: const Text(
            'Delete your account?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your Spark Lingo account and in-app learning data.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Type DELETE to confirm:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: confirmationController,
                enabled: !isDeleting,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirmation',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SparkTheme.surfaceContainerHighest),
                  ),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
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
                          throw StateError('Account deletion was not confirmed.');
                        }

                        ref.read(localActiveLanguageProvider.notifier).state = null;
                        try {
                          await ref.read(authProvider.notifier).signOut();
                        } catch (_) {}

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (context.mounted) {
                          context.go(SparkRouter.welcome);
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() => isDeleting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('We could not delete your account. Please try again.'),
                            ),
                          );
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Delete account'),
            ),
          ],
        ),
      ),
    ).whenComplete(confirmationController.dispose);
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeMode mode,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? SparkTheme.electricCyan.withValues(alpha: isDark ? 0.2 : 0.15)
                : (isDark ? SparkTheme.surfaceContainerLowest : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? SparkTheme.electricCyan
                  : (isDark ? SparkTheme.surfaceContainerHighest : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? SparkTheme.electricCyan
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark ? SparkTheme.surfaceCanvas : SparkTheme.lightCanvas,
      appBar: AppBar(
        backgroundColor: isDark ? SparkTheme.surfaceContainerLowest : SparkTheme.lightContainer,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: SparkTheme.text(context), size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(SparkRouter.welcome);
            }
          },
        ),
        title: Text(
          'Settings & Preferences',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: SparkTheme.text(context),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          children: [
            // Appearance & Theme Selector
            const _SettingsSectionLabel('APPEARANCE & THEME'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? SparkTheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? SparkTheme.surfaceContainerHighest : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        currentThemeMode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.wb_sunny_rounded,
                        color: SparkTheme.electricCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Interface Theme',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SparkTheme.text(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildThemeOption(
                        context: context,
                        mode: ThemeMode.dark,
                        icon: Icons.dark_mode_rounded,
                        label: 'Dark Mode',
                        isSelected: currentThemeMode == ThemeMode.dark,
                        onSelect: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
                      ),
                      const SizedBox(width: 8),
                      _buildThemeOption(
                        context: context,
                        mode: ThemeMode.light,
                        icon: Icons.wb_sunny_rounded,
                        label: 'Light Mode',
                        isSelected: currentThemeMode == ThemeMode.light,
                        onSelect: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
                      ),
                      const SizedBox(width: 8),
                      _buildThemeOption(
                        context: context,
                        mode: ThemeMode.system,
                        icon: Icons.settings_brightness_rounded,
                        label: 'System',
                        isSelected: currentThemeMode == ThemeMode.system,
                        onSelect: () => ref.read(themeModeProvider.notifier).state = ThemeMode.system,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cybernetic Profile & Quota Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? SparkTheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? SparkTheme.surfaceContainerHighest : const Color(0xFFE2E8F0),
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: SparkTheme.electricCyan.withValues(alpha: 0.35),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/symbols/sl_logo.jpg', fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? 'Learner Profile',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: SparkTheme.solarGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: SparkTheme.solarGold.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'UNLIMITED PRO PLAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: SparkTheme.solarGold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Speech Quota Energy Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SparkTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'AI SPEECH RECOGNITION QUOTA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: SparkTheme.electricCyan,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              '84% REMAINING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const LinearProgressIndicator(
                            value: 0.84,
                            minHeight: 6,
                            backgroundColor: Color(0xFF273647),
                            valueColor: AlwaysStoppedAnimation<Color>(SparkTheme.electricCyan),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '420 of 500 daily voice minutes available',
                          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Tutor Persona Selector
            const _SettingsSectionLabel('AI TUTOR MODEL PERSONA'),
            const SizedBox(height: 8),
            _buildPersonaTile(
              id: 'sparky',
              name: 'Sparky (Recommended)',
              desc: 'Playful, supportive & encouraging native conversationalist.',
              icon: Icons.bolt,
              color: SparkTheme.electricCyan,
            ),
            _buildPersonaTile(
              id: 'elena',
              name: 'Dr. Elena Vance',
              desc: 'Formal academic examiner for IELTS & CEFR simulation.',
              icon: Icons.school,
              color: SparkTheme.solarGold,
            ),
            _buildPersonaTile(
              id: 'mateo',
              name: 'Mateo (Colloquial)',
              desc: 'Street slang, idioms & rapid everyday speech.',
              icon: Icons.sports_bar,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 20),

            // Speech Cadence Control
            const _SettingsSectionLabel('SPEECH CADENCE & SPEED'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: SparkTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SparkTheme.surfaceContainerHighest),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Playback Speed',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: SparkTheme.electricCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_speechCadence.toStringAsFixed(2)}x',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: SparkTheme.electricCyan, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _speechCadence,
                    min: 0.75,
                    max: 1.25,
                    divisions: 4,
                    activeColor: SparkTheme.electricCyan,
                    inactiveColor: SparkTheme.surfaceContainerHighest,
                    onChanged: (val) => setState(() => _speechCadence = val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('0.75x (Slow)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      Text('1.0x (Natural)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      Text('1.25x (Fast)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sensory Feedback Toggles
            const _SettingsSectionLabel('SENSORY & AUDIO FEEDBACK'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: SparkTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SparkTheme.surfaceContainerHighest),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Haptic Vibration Feedback', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tactile response on card flips & grading', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    value: _hapticFeedback,
                    activeThumbColor: SparkTheme.electricCyan,
                    onChanged: (val) => setState(() => _hapticFeedback = val),
                  ),
                  const Divider(color: SparkTheme.surfaceContainerHighest, height: 1),
                  SwitchListTile(
                    title: const Text('Auto-Pronounce on Flip', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Play native audio when revealing card answer', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    value: _autoPlayAudio,
                    activeThumbColor: SparkTheme.electricCyan,
                    onChanged: (val) => setState(() => _autoPlayAudio = val),
                  ),
                  const Divider(color: SparkTheme.surfaceContainerHighest, height: 1),
                  SwitchListTile(
                    title: const Text('Audio Success Chimes', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Play subtle sound upon streak completion', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    value: _soundEffects,
                    activeThumbColor: SparkTheme.electricCyan,
                    onChanged: (val) => setState(() => _soundEffects = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Practice Audio Voice Tile
            const _SettingsSectionLabel('VOICE SYNTHESIS ENGINE'),
            const SizedBox(height: 8),
            const _VoiceSettingsTile(),
            const SizedBox(height: 20),

            // Privacy & Analytics
            const _SettingsSectionLabel('ANALYTICS & DIAGNOSTICS'),
            const SizedBox(height: 8),
            AnalyticsConsentTile(signedIn: user != null),
            const SizedBox(height: 20),

            // Legal Documents
            const _SettingsSectionLabel('LEGAL & COMPLIANCE'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: SparkTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SparkTheme.surfaceContainerHighest),
              ),
              child: Column(
                children: [
                  _ExternalLinkTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'User agreement, licensing, and usage terms',
                    uri: LegalConfig.termsOfServiceUri,
                    onOpen: _openExternalLink,
                  ),
                  const Divider(color: SparkTheme.surfaceContainerHighest, height: 1),
                  _ExternalLinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Data storage, encryption, and privacy standards',
                    uri: LegalConfig.privacyPolicyUri,
                    onOpen: _openExternalLink,
                  ),
                  const Divider(color: SparkTheme.surfaceContainerHighest, height: 1),
                  _ExternalLinkTile(
                    icon: Icons.mic_none_outlined,
                    title: 'AI & voice processing notice',
                    subtitle: 'Transient voice and AI model processing notice',
                    uri: LegalConfig.aiAndVoiceNoticeUri,
                    onOpen: _openExternalLink,
                  ),
                  const Divider(color: SparkTheme.surfaceContainerHighest, height: 1),
                  _ExternalLinkTile(
                    icon: Icons.analytics_outlined,
                    title: 'Analytics notice',
                    subtitle: 'Diagnostic telemetry and analytics privacy details',
                    uri: LegalConfig.analyticsNoticeDocument?.uri,
                    onOpen: _openExternalLink,
                  ),
                  const Divider(color: SparkTheme.surfaceContainerHighest, height: 1),
                  _ExternalLinkTile(
                    icon: Icons.help_outline,
                    title: 'Help & support',
                    subtitle: 'Contact support team & documentation',
                    uri: LegalConfig.supportUri,
                    onOpen: _openExternalLink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account & Data Management
            const _SettingsSectionLabel('YOUR DATA & ACCOUNT'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: SparkTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SparkTheme.surfaceContainerHighest),
              ),
              child: Column(
                children: [
                  _ExternalLinkTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Manage subscription',
                    subtitle: 'View active plan and billing settings',
                    uri: LegalConfig.subscriptionManagementUri,
                    onOpen: _openExternalLink,
                  ),
                  const Divider(color: SparkTheme.surfaceContainerHighest, height: 1),
                  _ExternalLinkTile(
                    icon: Icons.download_outlined,
                    title: 'Request a copy of your data',
                    subtitle: 'Export profile data and learning history',
                    uri: LegalConfig.dataExportUri,
                    onOpen: _openExternalLink,
                  ),
                  if (user != null) ...[
                    const Divider(color: SparkTheme.surfaceContainerHighest, height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      title: const Text('Delete account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Permanently purge your profile and learning data.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      onTap: () => _showDeleteAccountDialog(context, ref),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaTile({
    required String id,
    required String name,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTutorPersona == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : SparkTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : SparkTheme.surfaceContainerHighest,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
          ),
        ),
        subtitle: Text(
          desc,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: color, size: 20)
            : null,
        onTap: () => setState(() => _selectedTutorPersona = id),
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
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: SparkTheme.solarGold,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
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
  final Future<void> Function(BuildContext, Uri?, {required String label}) onOpen;

  @override
  Widget build(BuildContext context) {
    final isAvailable = uri != null;

    return ListTile(
      leading: Icon(icon, color: isAvailable ? SparkTheme.electricCyan : const Color(0xFF64748B)),
      title: Text(title, style: TextStyle(color: isAvailable ? Colors.white : const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))
          : null,
      trailing: Icon(
        isAvailable ? Icons.open_in_new_rounded : Icons.block_outlined,
        color: isAvailable ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        size: 18,
      ),
      onTap: () => onOpen(context, uri, label: title),
    );
  }
}

class _VoiceSettingsTile extends StatefulWidget {
  const _VoiceSettingsTile();

  @override
  State<_VoiceSettingsTile> createState() => _VoiceSettingsTileState();
}

class _VoiceSettingsTileState extends State<_VoiceSettingsTile> {
  late final TTSService _tts;

  @override
  void initState() {
    super.initState();
    _tts = TTSService();
    _tts.preference;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SparkTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SparkTheme.surfaceContainerHighest),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.record_voice_over_outlined, color: SparkTheme.electricCyan, size: 22),
              SizedBox(width: 12),
              Text(
                'Default Voice',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          SegmentedButton<VoicePreference>(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return SparkTheme.electricCyan;
                }
                return SparkTheme.surfaceCanvas;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return SparkTheme.surfaceCanvas;
                }
                return Colors.white70;
              }),
            ),
            segments: const [
              ButtonSegment(
                value: VoicePreference.system,
                label: Text('Auto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              ButtonSegment(
                value: VoicePreference.female,
                label: Text('Female', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              ButtonSegment(
                value: VoicePreference.male,
                label: Text('Male', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
            selected: {_tts.preference},
            showSelectedIcon: false,
            onSelectionChanged: (selection) async {
              final value = selection.first;
              await _tts.setPreference(value);
              if (mounted) setState(() {});
              await _tts.speak(
                value == VoicePreference.male
                    ? 'Male voice selected.'
                    : value == VoicePreference.female
                        ? 'Female voice selected.'
                        : 'Default voice selected.',
                'en',
              );
            },
          ),
        ],
      ),
    );
  }
}
