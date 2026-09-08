import 'package:purchases_flutter/purchases_flutter.dart';

enum PremiumPlanPeriod { monthly, yearly }

enum PremiumAccessState {
  inactive,
  active,
  cancelledActive,
  gracePeriod,
  billingIssue,
  expired,
}

final class PremiumPlan {
  const PremiumPlan({
    required this.period,
    required this.identifier,
    required this.price,
    required this.priceValue,
    required this.currencyCode,
    this.monthlyEquivalent,
  });

  final PremiumPlanPeriod period;
  final String identifier;
  final String price;
  final double priceValue;
  final String currencyCode;
  final String? monthlyEquivalent;
}

final class PremiumStatus {
  const PremiumStatus({
    required this.state,
    this.expiresAt,
    this.managementUrl,
  });

  final PremiumAccessState state;
  final DateTime? expiresAt;
  final Uri? managementUrl;
  bool get hasAccess => switch (state) {
    PremiumAccessState.active ||
    PremiumAccessState.cancelledActive ||
    PremiumAccessState.gracePeriod ||
    PremiumAccessState.billingIssue => true,
    _ => false,
  };
}

abstract interface class PurchaseService {
  bool get enabled;
  Future<void> initialize();
  Future<bool> isPremium();
  Future<bool> purchasePremium();
  Future<List<PremiumPlan>> loadPlans();
  Future<PremiumStatus> loadStatus();
  Future<bool> purchasePlan(PremiumPlanPeriod period);
  Future<bool> restorePurchases();
  Future<void> identify(String userId);
  Future<void> signOut();
}

final class NoopPurchaseService implements PurchaseService {
  const NoopPurchaseService();

  @override
  bool get enabled => false;

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isPremium() async => false;

  @override
  Future<bool> purchasePremium() async => false;

  @override
  Future<List<PremiumPlan>> loadPlans() async => const [];

  @override
  Future<PremiumStatus> loadStatus() async =>
      const PremiumStatus(state: PremiumAccessState.inactive);

  @override
  Future<bool> purchasePlan(PremiumPlanPeriod period) async => false;

  @override
  Future<bool> restorePurchases() async => false;

  @override
  Future<void> signOut() async {}
}

final class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService(this.apiKey, this.entitlementId);

  final String apiKey;
  final String entitlementId;

  @override
  bool get enabled => true;

  @override
  Future<void> identify(String userId) async {
    await Purchases.logIn(userId);
  }

  @override
  Future<void> initialize() {
    return Purchases.configure(PurchasesConfiguration(apiKey));
  }

  @override
  Future<bool> isPremium() async {
    return (await loadStatus()).hasAccess;
  }

  @override
  Future<bool> purchasePremium() async {
    return purchasePlan(PremiumPlanPeriod.monthly);
  }

  @override
  Future<List<PremiumPlan>> loadPlans() async {
    final offerings = await Purchases.getOfferings();
    final offering = offerings.current;
    if (offering == null) return const [];
    final plans = <PremiumPlan>[];
    void addPlan(Package? package, PremiumPlanPeriod period) {
      if (package == null) return;
      final product = package.storeProduct;
      plans.add(
        PremiumPlan(
          period: period,
          identifier: package.identifier,
          price: product.priceString,
          priceValue: product.price,
          currencyCode: product.currencyCode,
          monthlyEquivalent: period == PremiumPlanPeriod.yearly
              ? product.pricePerMonthString
              : null,
        ),
      );
    }

    addPlan(offering.monthly, PremiumPlanPeriod.monthly);
    addPlan(offering.annual, PremiumPlanPeriod.yearly);
    return plans;
  }

  @override
  Future<PremiumStatus> loadStatus() async {
    final info = await Purchases.getCustomerInfo();
    final entitlement = info.entitlements.all[entitlementId];
    final managementUrl = info.managementURL == null
        ? null
        : Uri.tryParse(info.managementURL!);
    if (entitlement == null) {
      return PremiumStatus(
        state: PremiumAccessState.inactive,
        managementUrl: managementUrl,
      );
    }
    final expiry = DateTime.tryParse(entitlement.expirationDate ?? '');
    if (!entitlement.isActive) {
      return PremiumStatus(
        state: PremiumAccessState.expired,
        expiresAt: expiry,
        managementUrl: managementUrl,
      );
    }
    final state = entitlement.billingIssueDetectedAt != null
        ? PremiumAccessState.billingIssue
        : !entitlement.willRenew || entitlement.unsubscribeDetectedAt != null
        ? PremiumAccessState.cancelledActive
        : PremiumAccessState.active;
    return PremiumStatus(
      state: state,
      expiresAt: expiry,
      managementUrl: managementUrl,
    );
  }

  @override
  Future<bool> purchasePlan(PremiumPlanPeriod period) async {
    final offerings = await Purchases.getOfferings();
    final offering = offerings.current;
    if (offering == null) return false;
    final package = period == PremiumPlanPeriod.yearly
        ? offering.annual
        : offering.monthly;
    if (package == null) return false;
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo.entitlements.active.containsKey(entitlementId);
  }

  @override
  Future<bool> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.containsKey(entitlementId);
  }

  @override
  Future<void> signOut() => Purchases.logOut();
}
