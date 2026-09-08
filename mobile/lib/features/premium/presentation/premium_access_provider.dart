import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_services.dart';
import '../../../core/services/purchase_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/premium_voucher_repository.dart';
import '../domain/premium_access.dart';

final premiumAccessProvider = FutureProvider<PremiumAccessResolution>((
  ref,
) async {
  final user = await ref.watch(authControllerProvider.future);
  if (user == null || user.isGuest) {
    return const PremiumAccessResolution.inactive();
  }

  final purchases = ref.watch(appServicesProvider).purchases;
  final vouchers = ref.watch(premiumVoucherRepositoryProvider);
  var storeStatus = const PremiumStatus(state: PremiumAccessState.inactive);
  var promotional = const PromotionalPremiumEntitlement.inactive();

  if (purchases.enabled) {
    try {
      await purchases.identify(user.id);
      storeStatus = await purchases.loadStatus();
    } catch (_) {
      // One provider outage must not erase access confirmed by the other.
    }
  }
  if (vouchers.isAvailable) {
    try {
      promotional = await vouchers.loadAccess();
    } catch (_) {
      // Voucher lookup fails closed without affecting store entitlement.
    }
  }

  final resolution = PremiumAccessResolution(
    storeStatus: storeStatus,
    promotional: promotional,
  );
  final expiry = promotional.expiresAt;
  if (promotional.active && expiry != null) {
    final remaining = expiry.difference(DateTime.now().toUtc());
    if (remaining > Duration.zero) {
      final expiryTimer = Timer(remaining, ref.invalidateSelf);
      ref.onDispose(expiryTimer.cancel);
    }
  }
  return resolution;
});
