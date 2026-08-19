import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/legal_config.dart';
import '../../core/services/revenuecat_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = true;
  bool _billingAvailable = false;
  BillingAccessState _billingAccess = BillingAccessState.billingDisabled;
  List<Package> _packages = [];

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final revenueCatService = ref.read(revenueCatServiceProvider);
    final billingAccess = await revenueCatService.billingAccessState();
    final offerings = billingAccess == BillingAccessState.ready
        ? await revenueCatService.getOfferings()
        : const <Offering>[];
    if (!mounted) return;
    setState(() {
      _billingAccess = billingAccess;
      _billingAvailable =
          billingAccess == BillingAccessState.ready &&
          revenueCatService.isInitialized;
      _packages = offerings.isNotEmpty
          ? offerings.first.availablePackages
          : const [];
      _isLoading = false;
    });
  }

  Future<void> _purchasePackage(Package package) async {
    final service = ref.read(revenueCatServiceProvider);
    final billingAccess = await service.billingAccessState();
    if (!mounted) return;
    if (billingAccess != BillingAccessState.ready) {
      _showBillingUnavailableMessage(billingAccess);
      return;
    }
    setState(() => _isLoading = true);
    final result = await service.purchasePackage(package);

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case BillingPurchaseResult.serverVerified:
        ref.invalidate(isPremiumProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spark Premium is now active.')),
        );
        Navigator.pop(context);
        break;
      case BillingPurchaseResult.awaitingServerVerification:
        ref.invalidate(isPremiumProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your purchase is being verified securely. Premium access will activate after server confirmation.',
            ),
          ),
        );
        break;
      case BillingPurchaseResult.unavailable:
        _showBillingUnavailableMessage(await service.billingAccessState());
        break;
      case BillingPurchaseResult.notCompleted:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase was not completed.')),
        );
        break;
    }
  }

  Future<void> _restorePurchases() async {
    final service = ref.read(revenueCatServiceProvider);
    final billingAccess = await service.billingAccessState();
    if (!mounted) return;
    if (billingAccess != BillingAccessState.ready) {
      _showBillingUnavailableMessage(billingAccess);
      return;
    }
    setState(() => _isLoading = true);
    final result = await service.restorePurchases();

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case BillingPurchaseResult.serverVerified:
        ref.invalidate(isPremiumProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully.')),
        );
        Navigator.pop(context);
        break;
      case BillingPurchaseResult.awaitingServerVerification:
        ref.invalidate(isPremiumProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your restored purchase is being verified securely. Please check again shortly.',
            ),
          ),
        );
        break;
      case BillingPurchaseResult.unavailable:
        _showBillingUnavailableMessage(await service.billingAccessState());
        break;
      case BillingPurchaseResult.notCompleted:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No purchase could be restored.')),
        );
        break;
    }
  }

  Future<void> _openLegalLink(Uri? uri) async {
    if (uri == null) {
      _showLegalConfigurationMessage();
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not open that legal link.')),
      );
    }
  }

  void _showLegalConfigurationMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Purchases are unavailable until this build has live Terms and Privacy links.',
        ),
      ),
    );
  }

  void _showBillingUnavailableMessage(BillingAccessState access) {
    final message = switch (access) {
      BillingAccessState.legalLinksMissing =>
        'Purchases are unavailable until this build has live Terms and Privacy links.',
      BillingAccessState.recoverableAccountRequired =>
        'Create or sign in to a confirmed, recoverable account before making or restoring purchases.',
      BillingAccessState.billingDisabled =>
        'Purchases are not enabled for this build.',
      BillingAccessState.platformUnavailable =>
        'Purchases are unavailable on this platform or build configuration.',
      BillingAccessState.configurationUnavailable =>
        'Purchases are temporarily unavailable. Please try again later.',
      BillingAccessState.ready => 'Purchases are currently unavailable.',
    };
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _billingUnavailableDescription() {
    return switch (_billingAccess) {
      BillingAccessState.legalLinksMissing =>
        'Purchases are disabled in this build until live Terms of Service and Privacy Policy links are configured.',
      BillingAccessState.recoverableAccountRequired =>
        'Purchases and restoration require a confirmed, recoverable account. Anonymous accounts can continue using free learning features.',
      BillingAccessState.billingDisabled =>
        'Purchases are not enabled for this build. No charge can be made.',
      BillingAccessState.platformUnavailable =>
        'Purchases are unavailable on this platform or build configuration.',
      BillingAccessState.configurationUnavailable =>
        'Purchases are temporarily unavailable. Please try again later.',
      BillingAccessState.ready =>
        'No purchase packages are currently available. Please try again later.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legalLinksReady = LegalConfig.hasRequiredPurchaseLinks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade'),
        actions: [
          TextButton(
            onPressed: legalLinksReady && _billingAvailable && !_isLoading
                ? _restorePurchases
                : null,
            child: const Text('Restore'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Spark Premium',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Premium access is enabled only after server verification.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Feature list
                  _buildFeatureRow(
                    context,
                    Icons.verified_user,
                    'Server entitlement verification',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.restore,
                    'Purchase restoration on supported stores',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.lock_outline,
                    'No device-only premium grants',
                  ),

                  const SizedBox(height: 48),

                  if (!legalLinksReady)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Purchases are disabled in this build until live Terms of Service and Privacy Policy links are configured.',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (_packages.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _billingUnavailableDescription(),
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._packages.map((package) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          onPressed: () => _purchasePackage(package),
                          child: Text(
                            '${package.storeProduct.title} - ${package.storeProduct.priceString}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  if (legalLinksReady)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _openLegalLink(LegalConfig.termsOfServiceUri),
                          child: const Text('Terms of Service'),
                        ),
                        TextButton(
                          onPressed: () =>
                              _openLegalLink(LegalConfig.privacyPolicyUri),
                          child: const Text('Privacy Policy'),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Add real HTTPS Terms of Service and Privacy Policy URLs at build time to enable purchases.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}
