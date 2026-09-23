import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../domain/premium_access.dart';
import 'premium_controller.dart';
import 'premium_visuals.dart';

final class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AhdashUtilityScaffold(
    title: 'أحدعش Premium',
    child: ref
        .watch(premiumControllerProvider)
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const PremiumLoadingView(),
          error: (_, _) => _PremiumError(
            onRetry: () => ref.invalidate(premiumControllerProvider),
          ),
          data: (value) {
            final controller = ref.read(premiumControllerProvider.notifier);
            return PremiumContentView(
              value: value,
              onSelect: controller.select,
              onPurchase: controller.purchase,
              onRestore: controller.restore,
              showVoucherEntry: ref
                  .watch(appConfigProvider)
                  .premiumVouchersAvailable,
              onVoucher: () => context.push('/premium/voucher'),
              onManage:
                  !value.access.hasStoreAccess ||
                      value.status.managementUrl == null
                  ? null
                  : () => _openManagement(value.status.managementUrl!),
            );
          },
        ),
  );

  Future<void> _openManagement(Uri uri) async {
    if (uri.scheme == 'https') {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Pure presentation surface used by the live controller and visual-state tests.
final class PremiumContentView extends StatelessWidget {
  const PremiumContentView({
    required this.value,
    required this.onSelect,
    required this.onPurchase,
    required this.onRestore,
    this.showVoucherEntry = false,
    this.onVoucher,
    this.onManage,
    super.key,
  });

  final PremiumView value;
  final ValueChanged<PremiumPlanPeriod> onSelect;
  final Future<bool> Function() onPurchase;
  final Future<bool> Function() onRestore;
  final bool showVoucherEntry;
  final VoidCallback? onVoucher;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final active = value.hasAccess;
    final canPurchase = value.available && value.plans.isNotEmpty && !active;
    final selectedPlan = value.plans
        .where((plan) => plan.period == value.selected)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('premium-scroll'),
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PremiumHero(active: active),
                const SizedBox(height: 12),
                if (active) ...[
                  _ActiveSubscriberPanel(
                    status: value.status,
                    access: value.access,
                    busy: value.busy,
                    onManage: onManage,
                  ),
                  const SizedBox(height: 12),
                ],
                const _PremiumBenefits(),
                if (!active) ...[
                  const SizedBox(height: 14),
                  _PlanSelector(value: value, onSelect: onSelect),
                ],
                if (value.message != null) ...[
                  const SizedBox(height: 10),
                  _InlineMessage(value.message!),
                ],
                const SizedBox(height: 12),
                _PremiumUtilities(
                  busy: value.busy,
                  available: value.available,
                  restoring: value.operation == PremiumOperation.restoring,
                  showVoucher: showVoucherEntry && onVoucher != null,
                  onVoucher: onVoucher,
                  onRestore: onRestore,
                ),
              ],
            ),
          ),
        ),
        if (canPurchase) ...[
          const SizedBox(height: 10),
          _PremiumPurchaseDock(
            plan: selectedPlan ?? value.plans.first,
            buying: value.operation == PremiumOperation.buying,
            onPurchase: value.busy ? null : onPurchase,
          ),
        ],
      ],
    );
  }
}

final class PremiumLoadingView extends StatelessWidget {
  const PremiumLoadingView({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PremiumHero(active: false),
        const SizedBox(height: 14),
        Container(
          key: const ValueKey('premium-packages-loading'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paper1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.hairline),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'نجهّز خطط المتجر…',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _PlanSkeleton()),
                  SizedBox(width: 10),
                  Expanded(child: _PlanSkeleton()),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1);
    final width = media.size.width;
    final heroHeight = switch ((textScale, width)) {
      (>= 1.3, <= 360) => 260.0,
      (>= 1.3, < 420) => 238.0,
      (>= 1.3, _) => 224.0,
      (>= 1.2, <= 360) => 238.0,
      (>= 1.2, < 420) => 218.0,
      (>= 1.2, _) => 204.0,
      (_, <= 360) => 208.0,
      (_, < 420) => 196.0,
      _ => 188.0,
    };
    return Container(
      key: const ValueKey('premium-hero'),
      height: heroHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.ink),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PositionedDirectional(
            top: 10,
            bottom: 10,
            end: 0,
            width: 148,
            child: ExcludeSemantics(
              child: Image.asset(
                'assets/visuals/premium_membership_passes_v1.png',
                key: const ValueKey('premium-hero-artwork'),
                fit: BoxFit.contain,
                alignment: AlignmentDirectional.centerEnd,
                filterQuality: FilterQuality.high,
                cacheWidth: 440,
              ),
            ),
          ),
          const PositionedDirectional(
            top: 0,
            bottom: 0,
            start: 0,
            width: 5,
            child: ColoredBox(color: AppColors.gold),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 17, 126, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  active ? 'عضويتك فعّالة' : 'تجربة أهدأ',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Premium',
                  style: TextStyle(
                    color: AppColors.paper0,
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'فئات أكثر. إعلانات أقل.',
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.paper2,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _PremiumBenefits extends StatelessWidget {
  const _PremiumBenefits();

  @override
  Widget build(BuildContext context) {
    final vertical = MediaQuery.textScalerOf(context).scale(14) > 18;
    const categories = _BenefitCard(
      scene: PremiumArtworkScene.categories,
      title: 'فئات حصرية',
      description: 'محتوى إضافي للعضوية.',
    );
    const noAds = _BenefitCard(
      scene: PremiumArtworkScene.noAds,
      title: 'بدون إعلانات',
      description: 'لعب متواصل بلا فواصل.',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'مزايا العضوية',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (vertical) ...[
          categories,
          const SizedBox(height: 9),
          noAds,
        ] else
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: categories),
              SizedBox(width: 10),
              Expanded(child: noAds),
            ],
          ),
      ],
    );
  }
}

final class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.scene,
    required this.title,
    required this.description,
  });

  final PremiumArtworkScene scene;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 136),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: scene == PremiumArtworkScene.categories
          ? const Color(0xFFFFF4DA)
          : const Color(0xFFEAF5D7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumBenefitVisual(scene: scene),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: const TextStyle(
            fontSize: 10,
            height: 1.35,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    ),
  );
}

final class _PlanSelector extends StatelessWidget {
  const _PlanSelector({required this.value, required this.onSelect});

  final PremiumView value;
  final ValueChanged<PremiumPlanPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    if (value.plans.isEmpty) {
      return Container(
        key: const ValueKey('premium-packages-unavailable'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4DA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold.withValues(alpha: .6)),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.ink,
              child: Icon(Icons.storefront_outlined, color: AppColors.gold),
            ),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الخطط غير متاحة الآن',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'يمكنك إعادة المحاولة أو استعادة اشتراك سابق.',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final monthly = _plan(PremiumPlanPeriod.monthly);
    final yearly = _plan(PremiumPlanPeriod.yearly);
    final vertical = MediaQuery.textScalerOf(context).scale(14) > 18;
    final monthlyCard = monthly == null
        ? null
        : _PlanCard(
            plan: monthly,
            selected: value.selected == PremiumPlanPeriod.monthly,
            busy: value.busy,
            onTap: () => onSelect(PremiumPlanPeriod.monthly),
          );
    final yearlyCard = yearly == null
        ? null
        : _PlanCard(
            plan: yearly,
            selected: value.selected == PremiumPlanPeriod.yearly,
            busy: value.busy,
            emphasized: true,
            onTap: () => onSelect(PremiumPlanPeriod.yearly),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اختر خطتك',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (vertical) ...[
          ?monthlyCard,
          if (monthlyCard != null && yearlyCard != null)
            const SizedBox(height: 9),
          ?yearlyCard,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (monthlyCard != null) Expanded(child: monthlyCard),
              if (monthlyCard != null && yearlyCard != null)
                const SizedBox(width: 10),
              if (yearlyCard != null) Expanded(child: yearlyCard),
            ],
          ),
      ],
    );
  }

  PremiumPlan? _plan(PremiumPlanPeriod period) =>
      value.plans.where((plan) => plan.period == period).firstOrNull;
}

final class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.busy,
    required this.onTap,
    this.emphasized = false,
  });

  final PremiumPlan plan;
  final bool selected;
  final bool busy;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final yearly = plan.period == PremiumPlanPeriod.yearly;
    return Semantics(
      button: true,
      selected: selected,
      label: '${yearly ? 'اشتراك سنوي' : 'اشتراك شهري'}، ${plan.price}',
      child: Material(
        key: ValueKey('premium-plan-${plan.period.name}'),
        color: selected ? AppColors.ink : AppColors.paper0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? (emphasized ? AppColors.gold : AppColors.palm)
                : emphasized
                ? AppColors.gold.withValues(alpha: .5)
                : AppColors.hairline,
            width: selected ? 1.7 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 19,
                          color: selected
                              ? (emphasized
                                    ? AppColors.gold
                                    : AppColors.primary)
                              : AppColors.ink,
                        ),
                        const Spacer(),
                        if (yearly)
                          Flexible(
                            child: Text(
                              'اشتراك سنوي',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: selected
                                    ? AppColors.paper2
                                    : AppColors.inkMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      yearly ? 'سنوي' : 'شهري',
                      style: TextStyle(
                        color: selected ? AppColors.paper0 : AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        plan.price,
                        style: TextStyle(
                          color: selected
                              ? (emphasized
                                    ? AppColors.gold
                                    : AppColors.primary)
                              : AppColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      yearly ? 'كل سنة' : 'كل شهر',
                      style: TextStyle(
                        fontSize: 10,
                        color: selected ? AppColors.paper2 : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: Container(
                    height: 4,
                    color: emphasized ? AppColors.gold : AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ActiveSubscriberPanel extends StatelessWidget {
  const _ActiveSubscriberPanel({
    required this.status,
    required this.access,
    required this.busy,
    required this.onManage,
  });

  final PremiumStatus status;
  final PremiumAccessResolution access;
  final bool busy;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('premium-active-subscriber'),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [Color(0xFF243025), Color(0xFF151814)],
      ),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.gold.withValues(alpha: .72)),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 58,
          height: 50,
          child: AhdashFootballArtwork(
            scene: PremiumArtworkScene.unlockedCategories,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Premium مفعّل',
                style: TextStyle(
                  color: AppColors.paper0,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusLabel(status, access),
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.paper2,
                ),
              ),
            ],
          ),
        ),
        if (onManage != null)
          OutlinedButton(
            onPressed: busy ? null : onManage,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: BorderSide(color: AppColors.gold.withValues(alpha: .7)),
              padding: const EdgeInsets.symmetric(horizontal: 11),
            ),
            child: const Text('إدارة'),
          ),
      ],
    ),
  );
}

final class _PremiumUtilities extends StatelessWidget {
  const _PremiumUtilities({
    required this.busy,
    required this.available,
    required this.restoring,
    required this.showVoucher,
    required this.onVoucher,
    required this.onRestore,
  });

  final bool busy;
  final bool available;
  final bool restoring;
  final bool showVoucher;
  final VoidCallback? onVoucher;
  final Future<bool> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    final vertical = MediaQuery.textScalerOf(context).scale(14) > 18;
    final restore = OutlinedButton.icon(
      key: const ValueKey('premium-restore'),
      onPressed: busy || !available ? null : () => onRestore(),
      icon: restoring
          ? const SizedBox.square(
              dimension: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.restore_rounded, size: 18),
      label: Text(restoring ? 'جارٍ الاستعادة…' : 'استعادة المشتريات'),
    );
    final voucher = OutlinedButton.icon(
      key: const ValueKey('premium-voucher-entry'),
      onPressed: busy ? null : onVoucher,
      icon: const Icon(Icons.confirmation_number_outlined, size: 18),
      label: const Text('استخدام قسيمة'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'خيارات أخرى',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        if (!showVoucher)
          restore
        else if (vertical) ...[
          voucher,
          const SizedBox(height: 8),
          restore,
        ] else
          Row(
            children: [
              Expanded(child: voucher),
              const SizedBox(width: 8),
              Expanded(child: restore),
            ],
          ),
      ],
    );
  }
}

final class _PremiumPurchaseDock extends StatelessWidget {
  const _PremiumPurchaseDock({
    required this.plan,
    required this.buying,
    required this.onPurchase,
  });

  final PremiumPlan plan;
  final bool buying;
  final Future<bool> Function()? onPurchase;

  @override
  Widget build(BuildContext context) {
    final vertical = MediaQuery.textScalerOf(context).scale(14) > 18;
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          plan.period == PremiumPlanPeriod.yearly
              ? 'الخطة السنوية'
              : 'الخطة الشهرية',
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        const Text(
          'جاهزة للاشتراك',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ],
    );
    final button = SizedBox(
      height: 52,
      child: FilledButton.icon(
        key: const ValueKey('premium-subscribe'),
        onPressed: buying || onPurchase == null ? null : () => onPurchase!(),
        icon: buying
            ? const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.ink,
                ),
              )
            : const Icon(Icons.lock_open_rounded, size: 19),
        label: Text(buying ? 'جارٍ إتمام الشراء…' : 'اشترك الآن'),
      ),
    );
    return Container(
      key: const ValueKey('premium-purchase-dock'),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.paper1,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 4,
                    bottom: 7,
                  ),
                  child: summary,
                ),
                button,
              ],
            )
          : Row(
              children: [
                Expanded(child: summary),
                const SizedBox(width: 10),
                SizedBox(width: 168, child: button),
              ],
            ),
    );
  }
}

final class _PremiumError extends StatelessWidget {
  const _PremiumError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      key: const ValueKey('premium-error'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: .6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.ink,
            child: Icon(
              Icons.wifi_off_rounded,
              color: AppColors.gold,
              size: 27,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'تعذر تحميل الاشتراك',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'تحقق من الاتصال وحاول مرة أخرى.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

final class _InlineMessage extends StatelessWidget {
  const _InlineMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.inkMuted,
        fontSize: 12,
        height: 1.4,
      ),
    ),
  );
}

final class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    height: 112,
    decoration: BoxDecoration(
      color: AppColors.paper2,
      borderRadius: BorderRadius.circular(17),
    ),
    padding: const EdgeInsets.all(13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(42),
        const Spacer(),
        _bar(76),
        const SizedBox(height: 8),
        _bar(54),
      ],
    ),
  );

  Widget _bar(double width) => Container(
    width: width,
    height: 9,
    decoration: BoxDecoration(
      color: AppColors.paper3,
      borderRadius: BorderRadius.circular(99),
    ),
  );
}

String _statusLabel(PremiumStatus status, PremiumAccessResolution access) {
  if (access.source == PremiumAccessSource.voucher) {
    return 'مفعّل عبر قسيمة ترويجية غير متجددة.';
  }
  if (access.source == PremiumAccessSource.both) {
    return 'اشتراك المتجر نشط مع قسيمة ترويجية مرتبطة بالحساب.';
  }
  return switch (status.state) {
    PremiumAccessState.cancelledActive =>
      'العضوية متاحة حتى نهاية الفترة المدفوعة.',
    PremiumAccessState.billingIssue || PremiumAccessState.gracePeriod =>
      'العضوية متاحة حاليًا. راجع وسيلة الدفع في المتجر.',
    _ => 'اشتراكك نشط حسب المتجر.',
  };
}
