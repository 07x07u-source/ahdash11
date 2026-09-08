import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/brand_identity.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/currency_widgets.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/landscape_layout.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/store_item.dart';
import 'store_controller.dart';

enum _StoreFilter { featured, newItems, owned, category }

final class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

final class _StoreScreenState extends ConsumerState<StoreScreen> {
  _StoreFilter _filter = _StoreFilter.featured;
  StoreCategory? _category;
  var _premiumBusy = false;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(storeCatalogProvider);
    final profile = ref.watch(playerProfileProvider).value;
    ref.listen(storeActionProvider, (previous, next) {
      if (next.status == previous?.status ||
          next.isBusy ||
          next.status == StoreActionStatus.idle) {
        return;
      }
      if (next.status == StoreActionStatus.success ||
          next.status == StoreActionStatus.alreadyOwned) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message ?? 'تمت العملية بنجاح.')),
        );
      }
    });
    final metrics = LandscapeMetrics.of(context);
    final isPortrait =
        MediaQuery.sizeOf(context).height > MediaQuery.sizeOf(context).width;
    final compactLandscape = !isPortrait && metrics.height <= 412;
    return BrandScaffold(
      appBar: AppBar(
        title: const Text('متجر أحدعش'),
        actions: [
          IconButton(
            tooltip: 'استخدام كود هدية',
            onPressed: () => _redeemGift(context),
            icon: const Icon(Icons.card_giftcard_rounded),
          ),
          if (MediaQuery.sizeOf(context).width >= 520)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: AhdashCoinBalance(
                balance: profile?.coins ?? 0,
                compact: true,
                onTap: () => context.push('/wallet'),
              ),
            )
          else
            IconButton(
              tooltip: 'الرصيد: ${profile?.coins ?? 0} كوين',
              onPressed: () => context.push('/wallet'),
              icon: const Icon(Icons.monetization_on_rounded),
            ),
        ],
      ),
      body: AhdashGameWorld(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(metrics.gutter),
            child: catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: GamePanel(
                  onTap: () => ref.invalidate(storeCatalogProvider),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AhdashIcon(AhdashGlyph.premium, size: 52),
                      Text('تعذر تحميل المتجر'),
                      Text('اضغط لإعادة المحاولة.'),
                    ],
                  ),
                ),
              ),
              data: (value) {
                final items = _filterItems(value.items);
                final catalogPanel = _StoreCatalogPanel(
                  filter: _filter,
                  category: _category,
                  items: items,
                  columns: isPortrait ? 2 : 4,
                  onRefresh: () => ref.invalidate(storeCatalogProvider),
                  onFilterChanged: (filter) => setState(() {
                    _filter = filter;
                    if (filter != _StoreFilter.category) _category = null;
                  }),
                  onCategoryChanged: (category) => setState(() {
                    _filter = _StoreFilter.category;
                    _category = category;
                  }),
                  onProduct: (item) => _showProduct(context, item),
                );
                if (isPortrait) {
                  return ListView(
                    children: [
                      SizedBox(
                        height: 300,
                        child: _StoreHero(
                          balance: profile?.coins ?? 0,
                          onWallet: () => context.push('/wallet'),
                        ),
                      ),
                      SizedBox(height: metrics.panelGap),
                      _PremiumPanel(
                        enabled: ref
                            .read(appServicesProvider)
                            .purchases
                            .enabled,
                        busy: _premiumBusy,
                        onPurchase: () => _premium(context, restore: false),
                        onRestore: () => _premium(context, restore: true),
                      ),
                      if (!value.remoteBacked) ...[
                        SizedBox(height: metrics.panelGap),
                        const _CatalogNotice(),
                      ],
                      SizedBox(height: metrics.panelGap),
                      SizedBox(height: 650, child: catalogPanel),
                    ],
                  );
                }
                return AccessibilityViewport(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: compactLandscape
                            ? _StoreCompactRail(
                                balance: profile?.coins ?? 0,
                                premiumEnabled: ref
                                    .read(appServicesProvider)
                                    .purchases
                                    .enabled,
                                premiumBusy: _premiumBusy,
                                onWallet: () => context.push('/wallet'),
                                onPremium: () =>
                                    _premium(context, restore: false),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: _StoreHero(
                                      balance: profile?.coins ?? 0,
                                      onWallet: () => context.push('/wallet'),
                                    ),
                                  ),
                                  SizedBox(height: metrics.panelGap),
                                  _PremiumPanel(
                                    enabled: ref
                                        .read(appServicesProvider)
                                        .purchases
                                        .enabled,
                                    busy: _premiumBusy,
                                    onPurchase: () =>
                                        _premium(context, restore: false),
                                    onRestore: () =>
                                        _premium(context, restore: true),
                                  ),
                                  if (!value.remoteBacked)
                                    const _CatalogNotice(),
                                ],
                              ),
                      ),
                      SizedBox(width: metrics.panelGap),
                      Expanded(flex: 8, child: catalogPanel),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<StoreItem> _filterItems(List<StoreItem> items) => switch (_filter) {
    _StoreFilter.featured =>
      items.where((item) => item.isFeatured).toList(growable: false),
    _StoreFilter.newItems =>
      items.where((item) => item.isNew).toList(growable: false),
    _StoreFilter.owned =>
      items.where((item) => item.isOwned).toList(growable: false),
    _StoreFilter.category =>
      items
          .where((item) => _category == null || item.category == _category)
          .toList(growable: false),
  };

  Future<void> _showProduct(BuildContext context, StoreItem item) async {
    ref.read(storeActionProvider.notifier).clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ProductSheet(item: item),
    );
  }

  Future<void> _premium(BuildContext context, {required bool restore}) async {
    final purchases = ref.read(appServicesProvider).purchases;
    if (!purchases.enabled || _premiumBusy) return;
    setState(() => _premiumBusy = true);
    try {
      final active = restore
          ? await purchases.restorePurchases()
          : await purchases.purchasePremium();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              active
                  ? 'تم تفعيل 11 Premium.'
                  : restore
                  ? 'لم نجد اشتراكًا نشطًا لاستعادته.'
                  : 'لم تكتمل عملية الشراء.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح متجر الاشتراك الآن.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _premiumBusy = false);
      }
    }
  }

  Future<void> _redeemGift(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استلام هدية'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'كود الهدية',
            hintText: 'AHDASH-XXXX',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('استلام'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty || !context.mounted) return;
    if (!ref.read(appConfigProvider).hasSupabase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('استلام الهدية يحتاج اتصالًا بالخادم.')),
      );
      return;
    }
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول لاستلام الهدية.')),
      );
      return;
    }
    try {
      final response = await client.rpc<Object?>(
        'redeem_gift_code',
        params: {'p_code': code},
      );
      if (!context.mounted) return;
      final row = response is Map<Object?, Object?>
          ? Map<String, Object?>.from(response)
          : const <String, Object?>{};
      final product = row['product_name_ar'] as String?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product == null
                ? 'تم استلام الهدية.'
                : 'تمت إضافة $product لمقتنياتك.',
          ),
        ),
      );
      ref.invalidate(storeCatalogProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكود غير متاح أو استُخدم مسبقًا.')),
      );
    }
  }
}

final class _StoreCompactRail extends StatelessWidget {
  const _StoreCompactRail({
    required this.balance,
    required this.premiumEnabled,
    required this.premiumBusy,
    required this.onWallet,
    required this.onPremium,
  });

  final int balance;
  final bool premiumEnabled;
  final bool premiumBusy;
  final VoidCallback onWallet;
  final VoidCallback onPremium;

  @override
  Widget build(BuildContext context) => GamePanel(
    tone: GameSurfaceTone.gold,
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            AhdashBrandLogo.mark(height: 30),
            Spacer(),
            AhdashIcon(AhdashGlyph.premium, size: 28),
          ],
        ),
        const Spacer(),
        Text('مظهرك. بصمتك.', style: Theme.of(context).textTheme.titleLarge),
        const Text(
          'هوية أصلية للاعبك وفريقك.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        AhdashCoinBalance(balance: balance, compact: true, onTap: onWallet),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: premiumEnabled && !premiumBusy ? onPremium : null,
            child: Text(premiumBusy ? 'جارٍ الاتصال…' : '11 Premium'),
          ),
        ),
      ],
    ),
  );
}

final class _StoreCatalogPanel extends StatelessWidget {
  const _StoreCatalogPanel({
    required this.filter,
    required this.category,
    required this.items,
    required this.columns,
    required this.onRefresh,
    required this.onFilterChanged,
    required this.onCategoryChanged,
    required this.onProduct,
  });

  final _StoreFilter filter;
  final StoreCategory? category;
  final List<StoreItem> items;
  final int columns;
  final VoidCallback onRefresh;
  final ValueChanged<_StoreFilter> onFilterChanged;
  final ValueChanged<StoreCategory> onCategoryChanged;
  final ValueChanged<StoreItem> onProduct;

  @override
  Widget build(BuildContext context) => GamePanel(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompactSectionTitle(
          eyebrow: 'عناصر تجميلية فقط',
          title: 'اختر مظهرك',
          trailing: IconButton(
            tooltip: 'تحديث',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _PrimaryFilters(value: filter, onChanged: onFilterChanged),
        const SizedBox(height: 4),
        Wrap(
          spacing: 5,
          runSpacing: 3,
          children: StoreCategory.values
              .map(
                (value) => ChoiceChip(
                  selected:
                      filter == _StoreFilter.category && category == value,
                  label: Text(value.labelAr),
                  onSelected: (_) => onCategoryChanged(value),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: GamePagedList<StoreItem>(
            items: items,
            pageSize: 4,
            columns: columns,
            aspectRatio: columns == 2 ? 0.62 : 0.72,
            empty: const Center(child: Text('لا توجد عناصر في هذا التصنيف.')),
            itemBuilder: (_, item, _) =>
                _ProductCard(item: item, onTap: () => onProduct(item)),
          ),
        ),
      ],
    ),
  );
}

final class _PremiumPanel extends StatelessWidget {
  const _PremiumPanel({
    required this.enabled,
    required this.busy,
    required this.onPurchase,
    required this.onRestore,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) => GamePanel(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('11 Premium', style: Theme.of(context).textTheme.titleLarge),
        Text(
          enabled
              ? 'اشتراك منفصل عن متجر الكوينز وتديره خدمة RevenueCat الحالية.'
              : 'الاشتراك غير مفعّل في إعدادات هذه النسخة.',
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: enabled && !busy ? onPurchase : null,
                child: Text(busy ? 'جارٍ الاتصال…' : 'عرض الاشتراك'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: enabled && !busy ? onRestore : null,
              child: const Text('استعادة'),
            ),
          ],
        ),
      ],
    ),
  );
}

final class _StoreHero extends StatelessWidget {
  const _StoreHero({required this.balance, required this.onWallet});

  final int balance;
  final VoidCallback onWallet;

  @override
  Widget build(BuildContext context) => GamePanel(
    tone: GameSurfaceTone.gold,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            AhdashBrandLogo.mark(height: 34),
            Spacer(),
            AhdashIcon(AhdashGlyph.premium),
          ],
        ),
        const Spacer(),
        AhdashIcon(
          AhdashGlyph.profile,
          size: 58,
          color: context.ahdashColors.gold,
          active: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'مظهرك. بصمتك.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Text('كوّن هوية لاعبك وفريقك بعناصر أصلية.', maxLines: 2),
        const Spacer(),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AhdashCoinBalance(balance: balance),
            TextButton(onPressed: onWallet, child: const Text('سجل المحفظة')),
          ],
        ),
      ],
    ),
  );
}

final class _CatalogNotice extends StatelessWidget {
  const _CatalogNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: context.ahdashColors.gold.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      border: Border.all(
        color: context.ahdashColors.gold.withValues(alpha: 0.3),
      ),
    ),
    child: const Text(
      'المعاينة متاحة الآن. يلزم اتصال وتسجيل دخول لتنفيذ شراء آمن.',
      textAlign: TextAlign.center,
    ),
  );
}

final class _PrimaryFilters extends StatelessWidget {
  const _PrimaryFilters({required this.value, required this.onChanged});

  final _StoreFilter value;
  final ValueChanged<_StoreFilter> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<_StoreFilter>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(value: _StoreFilter.featured, label: Text('المميز')),
      ButtonSegment(value: _StoreFilter.newItems, label: Text('الجديد')),
      ButtonSegment(value: _StoreFilter.owned, label: Text('مقتنياتي')),
    ],
    selected: {value == _StoreFilter.category ? _StoreFilter.featured : value},
    onSelectionChanged: (values) => onChanged(values.first),
  );
}

final class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.onTap});

  final StoreItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${item.name}، ${item.rarity.labelAr}، ${item.priceCoins} كوين',
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProductArtwork(item: item, cacheWidth: 520),
                  PositionedDirectional(
                    top: AppSpacing.xs,
                    start: AppSpacing.xs,
                    child: _StatusBadge(item: item),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final price = item.isOwned
                      ? Text(
                          item.isEquipped ? 'مستخدم' : 'مملوك',
                          style: TextStyle(
                            color: context.ahdashColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : AhdashCoinPrice(amount: item.priceCoins, compact: true);
                  if (constraints.maxHeight < 60) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          price,
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.rarity.labelAr,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            price,
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item});
  final StoreItem item;

  @override
  Widget build(BuildContext context) {
    final text = item.isEquipped
        ? 'مستخدم'
        : item.isOwned
        ? 'مملوك'
        : item.isNew
        ? 'جديد'
        : item.rarity.labelAr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xDD0B0F14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

final class _ProductSheet extends ConsumerWidget {
  const _ProductSheet({required this.item});
  final StoreItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(storeCatalogProvider).value;
    final matches = catalog?.items.where((value) => value.id == item.id);
    final current = matches != null && matches.isNotEmpty
        ? matches.first
        : item;
    final action = ref.watch(storeActionProvider);
    final profile = ref.watch(playerProfileProvider).value;
    final insufficient = action.status == StoreActionStatus.insufficientCoins;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.hero),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: _ProductArtwork(item: current, cacheWidth: 900),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  current.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (!current.isOwned) AhdashCoinPrice(amount: current.priceCoins),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${current.category.labelAr} • ${current.rarity.labelAr}',
            style: TextStyle(
              color: context.ahdashColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(current.description),
          const SizedBox(height: AppSpacing.sm),
          Text(
            current.category.locationAr,
            style: TextStyle(color: context.ahdashColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Text('رصيدك'),
              const Spacer(),
              AhdashCoinBalance(balance: profile?.coins ?? 0, compact: true),
            ],
          ),
          if (insufficient) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineState(
              asset: 'assets/images/states/insufficient_coins.webp',
              message: action.message ?? 'رصيدك لا يكفي.',
            ),
          ] else if (action.status == StoreActionStatus.offline ||
              action.status == StoreActionStatus.error ||
              action.status == StoreActionStatus.unavailable) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              action.message ?? 'تعذر إكمال العملية.',
              style: TextStyle(color: context.ahdashColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: action.isBusy || current.isEquipped
                  ? null
                  : () {
                      final controller = ref.read(storeActionProvider.notifier);
                      if (action.canRetry) {
                        unawaited(controller.retry());
                      } else if (current.isOwned) {
                        unawaited(controller.equip(current));
                      } else {
                        unawaited(controller.purchase(current));
                      }
                    },
              child: Text(
                action.isBusy
                    ? 'جارٍ التأكيد الآمن…'
                    : current.isEquipped
                    ? 'مستخدم الآن'
                    : action.canRetry
                    ? 'إعادة المحاولة الآمنة'
                    : current.isOwned
                    ? 'استخدم هذا المظهر'
                    : 'شراء بـ ${current.priceCoins} كوين',
              ),
            ),
          ),
          if (action.status == StoreActionStatus.success) ...[
            const SizedBox(height: AppSpacing.md),
            const _InlineState(
              asset: 'assets/images/states/purchase_success.webp',
              message: 'تم التأكيد من الخادم وأصبح العنصر في مقتنياتك.',
            ),
          ],
        ],
      ),
    );
  }
}

final class _InlineState extends StatelessWidget {
  const _InlineState({required this.asset, required this.message});
  final String asset;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: context.ahdashColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: Image.asset(asset, width: 72, height: 64, fit: BoxFit.cover),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

final class _ProductArtwork extends StatelessWidget {
  const _ProductArtwork({required this.item, required this.cacheWidth});

  final StoreItem item;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final local = Image.asset(
      item.previewAsset,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
    );
    return Semantics(
      image: true,
      label: 'معاينة ${item.name}',
      child: item.imageUrl == null
          ? local
          : CachedNetworkImage(
              imageUrl: item.imageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: cacheWidth,
              placeholder: (_, _) => local,
              errorWidget: (_, _, _) => local,
            ),
    );
  }
}
