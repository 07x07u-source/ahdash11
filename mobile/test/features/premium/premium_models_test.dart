import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PremiumStatus access contract', () {
    for (final state in <PremiumAccessState>[
      PremiumAccessState.active,
      PremiumAccessState.cancelledActive,
      PremiumAccessState.gracePeriod,
      PremiumAccessState.billingIssue,
    ]) {
      test('$state keeps premium access', () {
        expect(PremiumStatus(state: state).hasAccess, isTrue);
      });
    }

    for (final state in <PremiumAccessState>[
      PremiumAccessState.inactive,
      PremiumAccessState.expired,
    ]) {
      test('$state does not grant premium access', () {
        expect(PremiumStatus(state: state).hasAccess, isFalse);
      });
    }
  });

  test('store-backed plan preserves the real localized price', () {
    const plan = PremiumPlan(
      period: PremiumPlanPeriod.yearly,
      identifier: r'$rc_annual',
      price: 'SAR 99.99',
      priceValue: 99.99,
      currencyCode: 'SAR',
      monthlyEquivalent: 'SAR 8.33',
    );

    expect(plan.price, 'SAR 99.99');
    expect(plan.currencyCode, 'SAR');
    expect(plan.monthlyEquivalent, 'SAR 8.33');
  });
}
