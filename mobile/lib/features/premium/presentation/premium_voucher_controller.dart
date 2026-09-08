import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/feedback_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../party/presentation/party_catalog_provider.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/premium_voucher_repository.dart';
import '../domain/premium_access.dart';
import 'premium_access_provider.dart';

final premiumVoucherControllerProvider =
    NotifierProvider<PremiumVoucherController, PremiumVoucherView>(
      PremiumVoucherController.new,
    );

enum PremiumVoucherOperation { idle, validating, success, failure }

final class PremiumVoucherView {
  const PremiumVoucherView({
    this.operation = PremiumVoucherOperation.idle,
    this.redemption,
    this.message,
  });

  final PremiumVoucherOperation operation;
  final PremiumVoucherRedemption? redemption;
  final String? message;
  bool get busy => operation == PremiumVoucherOperation.validating;
  bool get succeeded => operation == PremiumVoucherOperation.success;
}

final class PremiumVoucherController extends Notifier<PremiumVoucherView> {
  var _requestEpoch = 0;

  @override
  PremiumVoucherView build() => const PremiumVoucherView();

  void reset() {
    _requestEpoch++;
    state = const PremiumVoucherView();
  }

  Future<bool> redeem(String code) async {
    if (state.busy) return false;
    final user = await ref.read(authControllerProvider.future);
    if (user == null || user.isGuest) {
      state = const PremiumVoucherView(
        operation: PremiumVoucherOperation.failure,
        message: 'سجّل دخولك لاستخدام قسيمة Premium.',
      );
      return false;
    }

    final epoch = ++_requestEpoch;
    state = const PremiumVoucherView(
      operation: PremiumVoucherOperation.validating,
    );
    try {
      final result = await ref
          .read(premiumVoucherRepositoryProvider)
          .redeem(code);
      if (epoch != _requestEpoch) return false;
      final message = _messageFor(result.status);
      state = PremiumVoucherView(
        operation: result.succeeded
            ? PremiumVoucherOperation.success
            : PremiumVoucherOperation.failure,
        redemption: result,
        message: message,
      );
      if (result.succeeded) {
        ref.invalidate(premiumAccessProvider);
        ref.invalidate(partyEntitlementProvider);
        ref.invalidate(playerProfileProvider);
        unawaited(
          ref
              .read(feedbackServiceProvider)
              .play(FeedbackCue.reward)
              .catchError((_) {}),
        );
      }
      return result.succeeded;
    } catch (_) {
      if (epoch != _requestEpoch) return false;
      state = const PremiumVoucherView(
        operation: PremiumVoucherOperation.failure,
        message: 'تعذر التحقق من القسيمة، حاول مرة أخرى.',
      );
      return false;
    }
  }

  String _messageFor(PremiumVoucherRedemptionStatus status) => switch (status) {
    PremiumVoucherRedemptionStatus.redeemed =>
      'تم تفعيل مزايا Premium باستخدام القسيمة.',
    PremiumVoucherRedemptionStatus.used => 'تم استخدام هذه القسيمة مسبقًا.',
    PremiumVoucherRedemptionStatus.expired => 'انتهت صلاحية هذه القسيمة.',
    PremiumVoucherRedemptionStatus.disabled => 'هذه القسيمة غير متاحة.',
    PremiumVoucherRedemptionStatus.unavailable =>
      'استخدام القسائم غير متاح حاليًا.',
    PremiumVoucherRedemptionStatus.invalid => 'القسيمة غير صالحة.',
  };
}
