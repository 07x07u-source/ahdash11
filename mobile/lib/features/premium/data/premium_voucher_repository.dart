import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/premium_access.dart';

final premiumVoucherRepositoryProvider = Provider<PremiumVoucherRepository>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  return PremiumVoucherRepository(
    gateway: config.hasSupabase
        ? SupabasePremiumVoucherGateway(Supabase.instance.client)
        : null,
    redemptionEnabled: config.premiumVouchersAvailable,
  );
});

abstract interface class PremiumVoucherGateway {
  Future<Map<String, Object?>> loadAccess();
  Future<Map<String, Object?>> redeem(String normalizedCode);
}

final class SupabasePremiumVoucherGateway implements PremiumVoucherGateway {
  const SupabasePremiumVoucherGateway(this.client);

  final SupabaseClient client;

  @override
  Future<Map<String, Object?>> loadAccess() async =>
      _object(await client.rpc<Object?>('get_my_premium_access'));

  @override
  Future<Map<String, Object?>> redeem(String normalizedCode) async => _object(
    await client.rpc<Object?>(
      'redeem_premium_voucher',
      params: {'p_code': normalizedCode},
    ),
  );

  static Map<String, Object?> _object(Object? value) => switch (value) {
    final Map<Object?, Object?> map => Map<String, Object?>.from(map),
    _ => const {},
  };
}

final class PremiumVoucherRepository {
  const PremiumVoucherRepository({
    required PremiumVoucherGateway? gateway,
    required this.redemptionEnabled,
  }) : _gateway = gateway;

  final PremiumVoucherGateway? _gateway;
  final bool redemptionEnabled;

  bool get isAvailable => _gateway != null;

  Future<PromotionalPremiumEntitlement> loadAccess() async {
    final gateway = _gateway;
    if (gateway == null) {
      return const PromotionalPremiumEntitlement.inactive();
    }
    return PromotionalPremiumEntitlement.fromJson(await gateway.loadAccess());
  }

  Future<PremiumVoucherRedemption> redeem(String code) async {
    final gateway = _gateway;
    if (!redemptionEnabled || gateway == null) {
      return const PremiumVoucherRedemption(
        status: PremiumVoucherRedemptionStatus.unavailable,
      );
    }
    final normalized = normalizeVoucherCode(code);
    if (normalized.length != 24) {
      return const PremiumVoucherRedemption(
        status: PremiumVoucherRedemptionStatus.invalid,
      );
    }
    return PremiumVoucherRedemption.fromJson(await gateway.redeem(normalized));
  }

  static String normalizeVoucherCode(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  static String formatVoucherCode(String value) {
    final normalized = normalizeVoucherCode(value);
    final groups = <String>[];
    for (var index = 0; index < normalized.length; index += 4) {
      groups.add(
        normalized.substring(index, (index + 4).clamp(0, normalized.length)),
      );
    }
    return groups.join('-');
  }
}
