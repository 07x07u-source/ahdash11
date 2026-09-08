import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/premium/data/premium_voucher_repository.dart';
import 'package:ahdash_11/features/premium/domain/premium_access.dart';
import 'package:ahdash_11/features/premium/presentation/premium_voucher_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/v10_feature_fixtures.dart';

void main() {
  group('Premium voucher repository', () {
    test('normalizes and formats a high-entropy human-readable code', () {
      const raw = 'ab12 cd34-ef56 7890-abcd ef12';
      expect(
        PremiumVoucherRepository.normalizeVoucherCode(raw),
        'AB12CD34EF567890ABCDEF12',
      );
      expect(
        PremiumVoucherRepository.formatVoucherCode(raw),
        'AB12-CD34-EF56-7890-ABCD-EF12',
      );
    });

    for (final scenario in <String, PremiumVoucherRedemptionStatus>{
      'invalid': PremiumVoucherRedemptionStatus.invalid,
      'used': PremiumVoucherRedemptionStatus.used,
      'expired': PremiumVoucherRedemptionStatus.expired,
      'disabled': PremiumVoucherRedemptionStatus.disabled,
    }.entries) {
      test('${scenario.key} voucher maps to a safe result', () async {
        final repository = PremiumVoucherRepository(
          gateway: _StaticGateway({'status': scenario.key}),
          redemptionEnabled: true,
        );
        final result = await repository.redeem('AB12-CD34-EF56-7890-ABCD-EF12');
        expect(result.status, scenario.value);
        expect(result.succeeded, isFalse);
      });
    }

    test('valid monthly voucher preserves server timestamps', () async {
      final repository = PremiumVoucherRepository(
        gateway: _StaticGateway(const {
          'status': 'redeemed',
          'voucher_type': 'monthly_promo',
          'redeemed_at': '2026-09-07T10:00:00Z',
          'expires_at': '2026-10-07T10:00:00Z',
        }),
        redemptionEnabled: true,
      );
      final result = await repository.redeem('AB12-CD34-EF56-7890-ABCD-EF12');
      expect(result.succeeded, isTrue);
      expect(result.type, PremiumVoucherType.monthlyPromo);
      expect(result.expiresAt, DateTime.utc(2026, 10, 7, 10));
    });

    test('valid annual voucher is non-recurring domain access', () async {
      final result = await PremiumVoucherRepository(
        gateway: _StaticGateway(const {
          'status': 'redeemed',
          'voucher_type': 'annual_promo',
          'expires_at': '2027-09-07T10:00:00Z',
        }),
        redemptionEnabled: true,
      ).redeem('AB12-CD34-EF56-7890-ABCD-EF12');
      expect(result.type, PremiumVoucherType.annualPromo);
      expect(result.succeeded, isTrue);
    });

    test('feature gate fails closed before contacting the server', () async {
      final gateway = _StaticGateway(const {'status': 'redeemed'});
      final result = await PremiumVoucherRepository(
        gateway: gateway,
        redemptionEnabled: false,
      ).redeem('AB12-CD34-EF56-7890-ABCD-EF12');
      expect(result.status, PremiumVoucherRedemptionStatus.unavailable);
      expect(gateway.calls, 0);
    });

    test(
      'concurrent one-time redemption produces exactly one success',
      () async {
        final repository = PremiumVoucherRepository(
          gateway: _AtomicGateway(),
          redemptionEnabled: true,
        );
        final results = await Future.wait([
          repository.redeem('AB12-CD34-EF56-7890-ABCD-EF12'),
          repository.redeem('AB12-CD34-EF56-7890-ABCD-EF12'),
        ]);
        expect(results.where((value) => value.succeeded), hasLength(1));
        expect(
          results.where(
            (value) => value.status == PremiumVoucherRedemptionStatus.used,
          ),
          hasLength(1),
        );
      },
    );
  });

  group('central Premium access resolver model', () {
    const activeStore = PremiumStatus(state: PremiumAccessState.active);
    const inactiveStore = PremiumStatus(state: PremiumAccessState.inactive);
    final promo = PromotionalPremiumEntitlement(
      active: true,
      expiresAt: DateTime.utc(2100),
    );
    const noPromo = PromotionalPremiumEntitlement.inactive();

    test('store entitlement grants access', () {
      final value = PremiumAccessResolution(
        storeStatus: activeStore,
        promotional: noPromo,
      );
      expect(value.source, PremiumAccessSource.store);
      expect(value.adsAllowed, isFalse);
    });

    test('promotional entitlement grants categories and removes ads', () {
      final value = PremiumAccessResolution(
        storeStatus: inactiveStore,
        promotional: promo,
      );
      expect(value.source, PremiumAccessSource.voucher);
      expect(value.hasAccess, isTrue);
      expect(value.adsAllowed, isFalse);
    });

    test('both sources remain active without duplicating benefits', () {
      final value = PremiumAccessResolution(
        storeStatus: activeStore,
        promotional: promo,
      );
      expect(value.source, PremiumAccessSource.both);
      expect(value.hasAccess, isTrue);
    });

    test('neither source fails closed', () {
      const value = PremiumAccessResolution(
        storeStatus: inactiveStore,
        promotional: noPromo,
      );
      expect(value.source, PremiumAccessSource.none);
      expect(value.adsAllowed, isTrue);
    });

    test('expired promotional state cannot override an inactive store', () {
      final value = PremiumAccessResolution(
        storeStatus: inactiveStore,
        promotional: PromotionalPremiumEntitlement(
          active: true,
          expiresAt: DateTime.utc(2020),
        ),
      );
      expect(value.hasPromotionalAccess, isFalse);
      expect(value.hasAccess, isFalse);
      expect(value.adsAllowed, isTrue);
    });

    test('expired promotional state cannot override an active store', () {
      final value = PremiumAccessResolution(
        storeStatus: activeStore,
        promotional: PromotionalPremiumEntitlement(
          active: true,
          expiresAt: DateTime.utc(2020),
        ),
      );
      expect(value.hasPromotionalAccess, isFalse);
      expect(value.hasStoreAccess, isTrue);
      expect(value.hasAccess, isTrue);
      expect(value.source, PremiumAccessSource.store);
      expect(value.adsAllowed, isFalse);
    });

    test('promotional state without server expiry fails closed', () {
      const value = PremiumAccessResolution(
        storeStatus: inactiveStore,
        promotional: PromotionalPremiumEntitlement(active: true),
      );
      expect(value.hasPromotionalAccess, isFalse);
      expect(value.hasAccess, isFalse);
    });
  });

  test('Guest redemption is rejected before any protected mutation', () async {
    final gateway = _StaticGateway(const {'status': 'redeemed'});
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => V10FeatureFixtures.guest,
        ),
        premiumVoucherRepositoryProvider.overrideWithValue(
          PremiumVoucherRepository(gateway: gateway, redemptionEnabled: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(
      await container
          .read(premiumVoucherControllerProvider.notifier)
          .redeem('AB12-CD34-EF56-7890-ABCD-EF12'),
      isFalse,
    );
    expect(gateway.calls, 0);
  });
}

final class _StaticGateway implements PremiumVoucherGateway {
  _StaticGateway(this.result);
  final Map<String, Object?> result;
  int calls = 0;

  @override
  Future<Map<String, Object?>> loadAccess() async => const {'active': false};

  @override
  Future<Map<String, Object?>> redeem(String normalizedCode) async {
    calls++;
    return result;
  }
}

final class _AtomicGateway implements PremiumVoucherGateway {
  var _redeemed = false;

  @override
  Future<Map<String, Object?>> loadAccess() async => const {'active': false};

  @override
  Future<Map<String, Object?>> redeem(String normalizedCode) async {
    await Future<void>.delayed(Duration.zero);
    if (_redeemed) return const {'status': 'used'};
    _redeemed = true;
    return const {
      'status': 'redeemed',
      'voucher_type': 'monthly_promo',
      'expires_at': '2026-10-07T10:00:00Z',
    };
  }
}
