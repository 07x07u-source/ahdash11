import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/services/app_error_reporter.dart';
import '../../../core/services/app_services.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../party/presentation/party_catalog_provider.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/premium_access.dart';
import 'premium_access_provider.dart';

final premiumControllerProvider =
    AsyncNotifierProvider<PremiumController, PremiumView>(
      PremiumController.new,
    );

enum PremiumOperation { idle, buying, restoring }

final class PremiumView {
  const PremiumView({
    this.plans = const [],
    this.status = const PremiumStatus(state: PremiumAccessState.inactive),
    this.access = const PremiumAccessResolution.inactive(),
    this.selected = PremiumPlanPeriod.monthly,
    this.operation = PremiumOperation.idle,
    this.message,
    this.available = false,
  });
  final List<PremiumPlan> plans;
  final PremiumStatus status;
  final PremiumAccessResolution access;
  final PremiumPlanPeriod selected;
  final PremiumOperation operation;
  final String? message;
  final bool available;
  bool get busy => operation != PremiumOperation.idle;
  bool get hasAccess => access.hasAccess || status.hasAccess;
  PremiumView copyWith({
    List<PremiumPlan>? plans,
    PremiumStatus? status,
    PremiumAccessResolution? access,
    PremiumPlanPeriod? selected,
    PremiumOperation? operation,
    String? message,
  }) => PremiumView(
    plans: plans ?? this.plans,
    status: status ?? this.status,
    access: access ?? this.access,
    selected: selected ?? this.selected,
    operation: operation ?? this.operation,
    message: message,
    available: available,
  );
}

class PremiumController extends AsyncNotifier<PremiumView> {
  var _epoch = 0;
  String? _account;
  @override
  Future<PremiumView> build() async {
    final epoch = ++_epoch;
    _account = null;
    final service = ref.watch(appServicesProvider).purchases;
    final user = await ref.watch(authControllerProvider.future);
    if (user == null || user.isGuest) {
      return const PremiumView(message: 'سجّل دخولك لعرض اشتراكك وخطط المتجر.');
    }
    _account = user.id;
    final access = await ref.watch(premiumAccessProvider.future);
    if (epoch != _epoch) return const PremiumView();
    if (!service.enabled) {
      return PremiumView(
        status: access.storeStatus,
        access: access,
        message: access.hasPromotionalAccess
            ? null
            : 'الاشتراك عبر المتجر غير متاح في هذه البيئة.',
      );
    }
    List<PremiumPlan> plans = const [];
    String? message;
    try {
      plans = await service.loadPlans();
    } on Object {
      message = 'تعذر تحميل الخطط. أعد المحاولة.';
    }
    return PremiumView(
      plans: plans,
      status: access.storeStatus,
      access: access,
      available: true,
      selected: plans.isEmpty ? PremiumPlanPeriod.monthly : plans.first.period,
      message: message,
    );
  }

  void select(PremiumPlanPeriod period) {
    final value = state.asData?.value;
    if (value == null ||
        value.busy ||
        !value.plans.any((p) => p.period == period)) {
      return;
    }
    state = AsyncData(value.copyWith(selected: period));
    _track('plan_selected', {'plan': period.name});
  }

  Future<bool> purchase() => _mutate(false);
  Future<bool> restore() => _mutate(true);
  Future<bool> _mutate(bool restoring) async {
    final value = state.asData?.value;
    final actor = ref.read(authControllerProvider).asData?.value;
    if (value == null ||
        value.busy ||
        !value.available ||
        actor == null ||
        actor.isGuest ||
        actor.id != _account ||
        (!restoring && (value.hasAccess || value.plans.isEmpty))) {
      return false;
    }
    final epoch = _epoch;
    state = AsyncData(
      value.copyWith(
        operation: restoring
            ? PremiumOperation.restoring
            : PremiumOperation.buying,
      ),
    );
    _track(restoring ? 'premium_restore_started' : 'purchase_started');
    final services = ref.read(appServicesProvider);
    try {
      final active = restoring
          ? await services.purchases.restorePurchases()
          : await services.purchases.purchasePlan(value.selected);
      final status = await services.purchases.loadStatus();
      if (!_valid(epoch, actor.id)) return false;
      final confirmed = active && status.hasAccess;
      final access = PremiumAccessResolution(
        storeStatus: status,
        promotional: value.access.promotional,
      );
      state = AsyncData(
        value.copyWith(
          status: status,
          access: access,
          operation: PremiumOperation.idle,
          message: confirmed
              ? (restoring ? 'استعدنا اشتراكك.' : 'تم تفعيل Premium.')
              : (restoring
                    ? 'لا يوجد اشتراك نشط لاستعادته.'
                    : 'لم يتأكد تفعيل الاشتراك. أعد التحقق من حالته.'),
        ),
      );
      _track(
        confirmed
            ? (restoring ? 'restore_success' : 'purchase_success')
            : 'premium_no_entitlement',
      );
      if (confirmed) {
        ref.invalidate(premiumAccessProvider);
        ref.invalidate(playerProfileProvider);
        ref.invalidate(partyEntitlementProvider);
        unawaited(
          ref
              .read(feedbackServiceProvider)
              .play(FeedbackCue.reward)
              .catchError((_) {}),
        );
      }
      return confirmed;
    } on Object catch (error) {
      if (!_valid(epoch, actor.id)) return false;
      final cancelled =
          error is PlatformException &&
          PurchasesErrorHelper.getErrorCode(error) ==
              PurchasesErrorCode.purchaseCancelledError;
      state = AsyncData(
        value.copyWith(
          operation: PremiumOperation.idle,
          message: cancelled
              ? 'أُلغيت عملية الشراء.'
              : 'تعذر إكمال العملية. تحقق من الاتصال وحاول مجددًا.',
        ),
      );
      _track(cancelled ? 'purchase_cancelled' : 'purchase_failed');
      if (error is Error) {
        unawaited(
          services.errors
              .report(
                severity: AppErrorSeverity.error,
                category: AppErrorCategory.purchase,
                feature: 'premium',
                screen: '/premium',
                error: StateError('Unexpected purchase integration failure'),
                context: {'operation': restoring ? 'restore' : 'purchase'},
              )
              .catchError((_) {}),
        );
      }
      return false;
    }
  }

  bool _valid(int epoch, String account) =>
      epoch == _epoch &&
      ref.read(authControllerProvider).asData?.value?.id == account;
  void _track(String event, [Map<String, Object>? fields]) => unawaited(
    ref
        .read(appServicesProvider)
        .analytics
        .log(event, fields)
        .catchError((_) {}),
  );
}
