import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/core/services/revenuecat_service.dart';

void main() {
  test('RevenueCatService singleton instance can be instantiated', () {
    final service1 = RevenueCatService();
    final service2 = RevenueCatService();
    expect(identical(service1, service2), isTrue);
  });

  test('BillingAccessState enum values are properly defined', () {
    expect(BillingAccessState.values, contains(BillingAccessState.ready));
    expect(BillingAccessState.values, contains(BillingAccessState.legalLinksMissing));
    expect(BillingAccessState.values, contains(BillingAccessState.recoverableAccountRequired));
    expect(BillingAccessState.values, contains(BillingAccessState.billingDisabled));
    expect(BillingAccessState.values, contains(BillingAccessState.platformUnavailable));
    expect(BillingAccessState.values, contains(BillingAccessState.configurationUnavailable));
  });

  test('BillingPurchaseResult enum values are properly defined', () {
    expect(BillingPurchaseResult.values, contains(BillingPurchaseResult.serverVerified));
    expect(BillingPurchaseResult.values, contains(BillingPurchaseResult.awaitingServerVerification));
    expect(BillingPurchaseResult.values, contains(BillingPurchaseResult.notCompleted));
    expect(BillingPurchaseResult.values, contains(BillingPurchaseResult.unavailable));
  });

  test('Default platform configuration returns false without environment keys', () {
    final service = RevenueCatService();
    expect(service.isPlatformConfigured, isFalse);
  });
}
