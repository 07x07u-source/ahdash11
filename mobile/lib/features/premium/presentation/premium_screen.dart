import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
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
          error: (_, _) => AppMessageState(
            title: 'تعذر تحميل الاشتراك',
            message: 'تحقق من الاتصال وأعد المحاولة.',
            actionLabel: 'أعد المحاولة',
            onAction: () => ref.invalidate(premiumControllerProvider),
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
                if (showVoucherEntry && onVoucher != null) ...[
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.hairline)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 9),
                        child: Text(
                          'خيارات الاشتراك',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.hairline)),
                    ],
                  ),
                  TextButton.icon(
                    key: const ValueKey('premium-voucher-entry'),
                    onPressed: value.busy ? null : onVoucher,
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('عندك رمز؟ استخدام قسيمة'),
                  ),
                ],
                const SizedBox(height: 4),
                TextButton.icon(
                  key: const ValueKey('premium-restore'),
                  onPressed: value.busy || !value.available
                      ? null
                      : () => onRestore(),
                  icon: value.operation == PremiumOperation.restoring
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_rounded, size: 18),
                  label: Text(
                    value.operation == PremiumOperation.restoring
                        ? 'جارٍ الاستعادة…'
                        : 'استعادة المشتريات',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (canPurchase) ...[
          const SizedBox(height: 10),
          AhdashV10PrimaryButton(
            key: const ValueKey('premium-subscribe'),
            icon: Icons.lock_open_rounded,
            label: value.operation == PremiumOperation.buying
                ? 'جارٍ إتمام الشراء…'
                : 'اشترك الآن',
            loading: value.operation == PremiumOperation.buying,
            onPressed: value.busy ? null : () => onPurchase(),
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
      (>= 1.3, <= 360) => 350.0,
      (>= 1.3, < 420) => 315.0,
      (>= 1.3, _) => 290.0,
      (>= 1.2, <= 360) => 330.0,
      (>= 1.2, < 420) => 300.0,
      (>= 1.2, _) => 280.0,
      (_, <= 360) => 250.0,
      (_, < 420) => 230.0,
      _ => 220.0,
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
            top: 0,
            bottom: 0,
            end: 0,
            width: 184,
            child: ExcludeSemantics(
              child: AhdashFootballArtwork(
                scene: active
                    ? PremiumArtworkScene.unlockedCategories
                    : PremiumArtworkScene.premium,
                animateEntrance: true,
              ),
            ),
          ),
          PositionedDirectional(
            top: -54,
            start: -42,
            child: Container(
              width: 158,
              height: 158,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .08),
              ),
            ),
          ),
          const PositionedDirectional(
            start: 16,
            bottom: -18,
            child: Text(
              '١١',
              style: TextStyle(
                color: Color(0x18FFFFFF),
                fontSize: 82,
                height: 1,
                fontWeight: FontWeight.w900,
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
            padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 166, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'AHDASH / PREMIUM 11',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 9,
                    letterSpacing: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Premium مفعّل',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  const PremiumCategoryBadge(),
                const SizedBox(height: 8),
                const Text(
                  'أحدعش\nPremium',
                  style: TextStyle(
                    color: AppColors.paper0,
                    fontSize: 28,
                    height: 0.98,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'فئات حصرية، ولعب متواصل بدون فواصل إعلانية',
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'داخل Premium',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            child: _BenefitCard(
              scene: PremiumArtworkScene.categories,
              title: 'فئات حصرية',
              description: 'الوصول إلى الفئات المخصصة لمشتركي Premium',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _BenefitCard(
              scene: PremiumArtworkScene.noAds,
              title: 'بدون إعلانات',
              description: 'استمتع باللعب بدون إعلانات',
            ),
          ),
        ],
      ),
    ],
  );
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
          ? AppColors.paper1
          : AppColors.paper2,
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
          color: AppColors.paper1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.hairline),
        ),
        child: const Row(
          children: [
            Icon(Icons.storefront_outlined, color: AppColors.inkMuted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'الأسعار غير متاحة من المتجر الآن',
                style: TextStyle(color: AppColors.inkMuted),
              ),
            ),
          ],
        ),
      );
    }
    final monthly = _plan(PremiumPlanPeriod.monthly);
    final yearly = _plan(PremiumPlanPeriod.yearly);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اختر اشتراكك',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (monthly != null)
              Expanded(
                child: _PlanCard(
                  plan: monthly,
                  selected: value.selected == PremiumPlanPeriod.monthly,
                  busy: value.busy,
                  onTap: () => onSelect(PremiumPlanPeriod.monthly),
                ),
              ),
            if (monthly != null && yearly != null) const SizedBox(width: 10),
            if (yearly != null)
              Expanded(
                child: _PlanCard(
                  plan: yearly,
                  selected: value.selected == PremiumPlanPeriod.yearly,
                  busy: value.busy,
                  emphasized: true,
                  onTap: () => onSelect(PremiumPlanPeriod.yearly),
                ),
              ),
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
        color: selected ? const Color(0xFFFFF4D8) : AppColors.paper0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? (emphasized ? AppColors.gold : AppColors.palm)
                : AppColors.hairline,
            width: selected ? 1.7 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Stack(
            children: [
              PositionedDirectional(
                end: -2,
                bottom: -13,
                child: Text(
                  yearly ? '١٢' : '١',
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: .055),
                    fontSize: 62,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
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
                        ),
                        const Spacer(),
                        if (yearly)
                          const Flexible(
                            child: Text(
                              'اشتراك سنوي',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      yearly ? 'سنوي' : 'شهري',
                      style: const TextStyle(
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      yearly ? 'كل سنة' : 'كل شهر',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.inkMuted,
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
      color: const Color(0xFFEAF3EC),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                _statusLabel(status, access),
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (onManage != null)
          TextButton(
            onPressed: busy ? null : onManage,
            child: const Text('إدارة'),
          ),
      ],
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
