import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/core/services/analytics_service.dart';

void main() {
  test('AnalyticsService singleton instance can be instantiated', () {
    final service1 = AnalyticsService();
    final service2 = AnalyticsService();
    expect(identical(service1, service2), isTrue);
  });
}
