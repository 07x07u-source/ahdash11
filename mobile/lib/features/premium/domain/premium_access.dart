import '../../../core/services/purchase_service.dart';

enum PremiumAccessSource { none, store, voucher, both }

final class PromotionalPremiumEntitlement {
  const PromotionalPremiumEntitlement({required this.active, this.expiresAt});

  const PromotionalPremiumEntitlement.inactive()
    : active = false,
      expiresAt = null;

  PromotionalPremiumEntitlement.fromJson(Map<String, Object?> json)
    : active = json['active'] == true,
      expiresAt = DateTime.tryParse('${json['expires_at'] ?? ''}')?.toUtc();

  final bool active;
  final DateTime? expiresAt;

  bool isActiveAt(DateTime instant) {
    final expiry = expiresAt;
    return active && expiry != null && expiry.isAfter(instant.toUtc());
  }
}

final class PremiumAccessResolution {
  const PremiumAccessResolution({
    required this.storeStatus,
    this.promotional = const PromotionalPremiumEntitlement.inactive(),
  });

  const PremiumAccessResolution.inactive()
    : storeStatus = const PremiumStatus(state: PremiumAccessState.inactive),
      promotional = const PromotionalPremiumEntitlement.inactive();

  final PremiumStatus storeStatus;
  final PromotionalPremiumEntitlement promotional;

  bool get hasStoreAccess => storeStatus.hasAccess;
  bool get hasPromotionalAccess =>
      promotional.isActiveAt(DateTime.now().toUtc());
  bool get hasAccess => hasStoreAccess || hasPromotionalAccess;
  bool get adsAllowed => !hasAccess;

  PremiumAccessSource get source =>
      switch ((hasStoreAccess, hasPromotionalAccess)) {
        (true, true) => PremiumAccessSource.both,
        (true, false) => PremiumAccessSource.store,
        (false, true) => PremiumAccessSource.voucher,
        _ => PremiumAccessSource.none,
      };
}

enum PremiumVoucherType { monthlyPromo, annualPromo }

enum PremiumVoucherRedemptionStatus {
  redeemed,
  invalid,
  used,
  expired,
  disabled,
  unavailable,
}

final class PremiumVoucherRedemption {
  const PremiumVoucherRedemption({
    required this.status,
    this.type,
    this.redeemedAt,
    this.expiresAt,
  });

  factory PremiumVoucherRedemption.fromJson(Map<String, Object?> json) {
    final type = switch ('${json['voucher_type'] ?? ''}') {
      'monthly_promo' => PremiumVoucherType.monthlyPromo,
      'annual_promo' => PremiumVoucherType.annualPromo,
      _ => null,
    };
    final status = switch ('${json['status'] ?? ''}') {
      'redeemed' => PremiumVoucherRedemptionStatus.redeemed,
      'used' => PremiumVoucherRedemptionStatus.used,
      'expired' => PremiumVoucherRedemptionStatus.expired,
      'disabled' => PremiumVoucherRedemptionStatus.disabled,
      _ => PremiumVoucherRedemptionStatus.invalid,
    };
    return PremiumVoucherRedemption(
      status: status,
      type: type,
      redeemedAt: DateTime.tryParse('${json['redeemed_at'] ?? ''}')?.toUtc(),
      expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}')?.toUtc(),
    );
  }

  final PremiumVoucherRedemptionStatus status;
  final PremiumVoucherType? type;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;

  bool get succeeded => status == PremiumVoucherRedemptionStatus.redeemed;
}
