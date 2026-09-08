import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/domain/category.dart';
import '../../../shared/presentation/ahdash_image.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../match/domain/quiz_question.dart';
import '../../premium/presentation/premium_visuals.dart';
import '../domain/party_game.dart';
import 'party_catalog_provider.dart';
import 'party_game_controller.dart';
import 'party_gameplay_visuals.dart';
import 'party_setup_flow.dart';
import 'party_v2_ui.dart';

final class PartyCategorySelectionScreen extends ConsumerStatefulWidget {
  const PartyCategorySelectionScreen({
    this.initialFavoritesOnly = false,
    super.key,
  });

  final bool initialFavoritesOnly;

  @override
  ConsumerState<PartyCategorySelectionScreen> createState() =>
      _PartyCategorySelectionScreenState();
}

final class _PartyCategorySelectionScreenState
    extends ConsumerState<PartyCategorySelectionScreen> {
  final _search = TextEditingController();
  var _favoritesOnly = false;
  var _queryInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_queryInitialized) return;
    _queryInitialized = true;
    _favoritesOnly = widget.initialFavoritesOnly;
    if (GoRouter.maybeOf(context) != null) {
      _favoritesOnly =
          GoRouterState.of(context).uri.queryParameters['favorites'] == '1';
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(partyCatalogProvider);
    final premium = ref.watch(partyEntitlementProvider).value ?? false;
    final state = ref.watch(partyGameControllerProvider);
    final selectedCount = state.selectedCategoryIds.length;
    final playableIds = catalog.value
        ?.playableCategories(premium: premium)
        .map((category) => category.id)
        .toSet();
    final selectionReady =
        selectedCount == PartyGameRules.categoriesPerGame &&
        playableIds != null &&
        playableIds.containsAll(state.selectedCategoryIds);
    return PartyFlowScaffold(
      title: 'اختر فئاتك',
      subtitle: 'حدد مجالات الأسئلة لمجلسك',
      step: 1,
      onBack: () => context.go('/home'),
      footer: PartyPrimaryButton(
        label: selectionReady
            ? 'التالي'
            : 'اختر ${PartyGameRules.categoriesPerGame - selectedCount} فئات',
        icon: selectionReady ? Icons.arrow_back_rounded : null,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.ink,
        onPressed: selectionReady
            ? () => context.go(
                PartySetupFlowResolver.canonicalRoute(
                  ref.read(partyGameControllerProvider),
                ),
              )
            : null,
      ),
      child: catalog.when(
        loading: () => const Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 28),
              child: LoadingSkeleton(lines: 5),
            ),
            Center(
              child: SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          ],
        ),
        error: (_, _) =>
            _CatalogError(onRetry: () => ref.invalidate(partyCatalogProvider)),
        data: (value) {
          final rows = _filteredCategories(value, state);
          return Column(
            children: [
              _CategorySelectionStatus(selectedCount: selectedCount),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.paper1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: SizedBox(
                  height: context.v9Metrics.inputHeight,
                  child: TextField(
                    key: const ValueKey('party-category-search'),
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      suffixIcon: _search.text.isEmpty
                          ? const Icon(AhdashIcons.search, size: 19)
                          : IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      hintText: 'ابحث عن دوري، بطولة أو فئة...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: AppColors.ink,
                          width: 1.35,
                        ),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: rows.isEmpty
                    ? _CategoryEmptyState(
                        catalogEmpty: value.categories.isEmpty,
                        onClear: _search.text.isEmpty
                            ? null
                            : () {
                                _search.clear();
                                setState(() {});
                              },
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final metrics = context.v9Metrics;
                          if (metrics.portrait) {
                            return GridView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.only(bottom: 4),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    mainAxisExtent: 148,
                                  ),
                              itemCount: rows.length,
                              itemBuilder: (context, index) => _categoryTile(
                                context,
                                ref,
                                value,
                                state,
                                rows[index],
                                premium: premium,
                              ),
                            );
                          }
                          final compact = metrics.compact;
                          if (compact) {
                            final width = (constraints.maxWidth - 24) / 3;
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: rows.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) => SizedBox(
                                width: width,
                                child: _categoryTile(
                                  context,
                                  ref,
                                  value,
                                  state,
                                  rows[index],
                                  premium: premium,
                                  featured: true,
                                ),
                              ),
                            );
                          }
                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 210,
                                ),
                            itemCount: rows.length,
                            itemBuilder: (context, index) => _categoryTile(
                              context,
                              ref,
                              value,
                              state,
                              rows[index],
                              premium: premium,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryTile(
    BuildContext context,
    WidgetRef ref,
    PartyCatalog catalog,
    PartyGameState state,
    QuizCategory category, {
    required bool premium,
    bool featured = false,
  }) {
    final selectedIndex = state.selectedCategoryIds.indexOf(category.id);
    final locked =
        category.accessTier != 'free' && !category.freeRotation && !premium;
    return _CategoryTile(
      category: category,
      selectedIndex: selectedIndex,
      selectedColor: selectedIndex < 0
          ? null
          : Color(state.teams[selectedIndex < 3 ? 0 : 1].colorValue),
      favorite: state.favoriteCategoryIds.contains(category.id),
      isNew:
          category.isNew ||
          catalog.readyCategories.indexOf(category) >=
              math.max(0, catalog.readyCategories.length - 6),
      featured: featured,
      locked: locked,
      onFavorite: category.favoriteEligible
          ? () => ref
                .read(partyGameControllerProvider.notifier)
                .toggleFavorite(category.id)
          : null,
      onTap: locked
          ? () => unawaited(_showPremiumGate(context, category))
          : () => _toggleCategory(context, ref, category.id),
      onInfo: () => _showCategoryDetail(
        context,
        category,
        catalog.questions
            .where((question) => question.categoryId == category.id)
            .firstOrNull,
        playable: catalog.readyCategories.any((item) => item.id == category.id),
        locked: locked,
      ),
    );
  }

  List<QuizCategory> _filteredCategories(
    PartyCatalog catalog,
    PartyGameState state,
  ) {
    final query = _normalizeSearch(_search.text);
    final rows = catalog.readyCategories.where((category) {
      final searchable = _normalizeSearch(
        [
          category.name,
          category.description,
          category.slug,
          ...category.subcategories,
        ].join(' '),
      );
      return (query.isEmpty || searchable.contains(query)) &&
          (!_favoritesOnly || state.favoriteCategoryIds.contains(category.id));
    }).toList();
    return rows;
  }
}

final class _CategorySelectionStatus extends StatelessWidget {
  const _CategorySelectionStatus({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final complete = selectedCount == PartyGameRules.categoriesPerGame;
    return Semantics(
      liveRegion: true,
      label:
          '$selectedCount من ${PartyGameRules.categoriesPerGame} فئات مختارة',
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complete ? 'اكتملت التشكيلة' : 'اختيارات المجلس',
                            style: const TextStyle(
                              color: AppColors.paper0,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedCount < 3
                                ? 'أول ٣ فئات للفريق الأول'
                                : selectedCount < 6
                                ? 'أكمل ٣ فئات للفريق الثاني'
                                : '٦ فئات جاهزة • ٣ لكل فريق',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.paper3,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: complete ? AppColors.primary : AppColors.inkSoft,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: complete ? AppColors.ink : AppColors.paper3,
                        ),
                      ),
                      child: Text(
                        '${_setupArabicDigits(selectedCount)} / ٦',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: complete ? AppColors.ink : AppColors.paper0,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    for (
                      var index = 0;
                      index < PartyGameRules.categoriesPerGame;
                      index++
                    ) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : PartyV2Motion.page,
                          height: 4,
                          decoration: BoxDecoration(
                            color: index < selectedCount
                                ? index < 3
                                      ? const Color(0xFFE43D74)
                                      : const Color(0xFF1E874B)
                                : AppColors.inkSoft,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      if (index != PartyGameRules.categoriesPerGame - 1)
                        const SizedBox(width: 5),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Retains the established assistive/test phrase while the visible
          // counter uses localized Arabic numerals.
          Positioned.fill(
            child: Opacity(opacity: 0, child: Text('$selectedCount من 6')),
          ),
        ],
      ),
    );
  }
}

final class _CategoryEmptyState extends StatelessWidget {
  const _CategoryEmptyState({required this.catalogEmpty, this.onClear});

  final bool catalogEmpty;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 132,
            height: 78,
            child: PartyGameplayArtwork(
              scene: PartyGameplayArtworkScene.category,
              accent: const Color(0xFF7EB900),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            catalogEmpty
                ? 'لا توجد فئات منشورة بعد.'
                : 'ما لقينا فئة جاهزة بهذا البحث.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'جرّب اسم دوري أو بطولة أخرى.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
          if (onClear != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onClear, child: const Text('مسح البحث')),
          ],
        ],
      ),
    ),
  );
}

String _setupArabicDigits(int value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((digit) {
    final index = western.indexOf(digit);
    return index < 0 ? digit : eastern[index];
  }).join();
}

Future<void> _showPremiumGate(
  BuildContext context,
  QuizCategory category,
) async {
  final openPremium = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => PremiumCategoryGateCard(
      categoryName: category.name,
      onViewPremium: () => Navigator.pop(sheetContext, true),
      onBack: () => Navigator.pop(sheetContext, false),
    ),
  );
  if (openPremium == true && context.mounted) {
    await context.push('/premium');
  }
}

String _normalizeSearch(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
    .trim();

void _toggleCategory(BuildContext context, WidgetRef ref, String categoryId) {
  final state = ref.read(partyGameControllerProvider);
  final changed = ref
      .read(partyGameControllerProvider.notifier)
      .toggleCategory(categoryId);
  if (changed) {
    ref.read(feedbackServiceProvider).play(FeedbackCue.selection);
    return;
  }
  if (state.selectedCategoryIds.contains(categoryId) &&
      state.selectedCategoryIds.indexOf(categoryId) < 3 &&
      state.selectedCategoryIds.length > 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('أزيلوا اختيارات الفريق الثاني أولًا لتعديل الأول.'),
      ),
    );
  }
}

final class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selectedIndex,
    required this.selectedColor,
    required this.favorite,
    required this.isNew,
    required this.locked,
    required this.onFavorite,
    required this.onTap,
    required this.onInfo,
    this.featured = false,
  });

  final QuizCategory category;
  final int selectedIndex;
  final Color? selectedColor;
  final bool favorite;
  final bool isNew;
  final bool locked;
  final VoidCallback? onFavorite;
  final VoidCallback onTap;
  final VoidCallback onInfo;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex >= 0;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${category.name}${selected ? '، مختارة' : ''}${locked ? '، ضمن الباقة' : ''}',
      child: AnimatedScale(
        scale: selected && !reducedMotion ? 1.01 : 1,
        duration: reducedMotion ? Duration.zero : PartyV2Motion.page,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onInfo,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: reducedMotion ? Duration.zero : PartyV2Motion.page,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF4EBDD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppColors.ink
                      : locked
                      ? AppColors.gold
                      : const Color(0xFFD3C6B2),
                  width: selected
                      ? 1.6
                      : locked
                      ? 1.4
                      : 1,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x26191714),
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AhdashImage(
                          imageUrl: category.imageUrl,
                          alignment: category.focalAlignment,
                          fallbackWidget: _CategoryImageFallback(
                            category: category,
                          ),
                          aspectRatio: 16 / 9,
                          borderRadius: 0,
                          semanticLabel: category.name,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00191714), Color(0x5C191714)],
                            ),
                          ),
                        ),
                        if (locked)
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x14191714), Color(0xA6191714)],
                              ),
                            ),
                          ),
                        if (locked)
                          const PositionedDirectional(
                            top: 8,
                            start: 8,
                            child: PremiumCategoryBadge(compact: true),
                          ),
                        if (selected)
                          PositionedDirectional(
                            top: 8,
                            end: 8,
                            child: Container(
                              height: 26,
                              constraints: const BoxConstraints(minWidth: 30),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              decoration: BoxDecoration(
                                color: selectedColor ?? const Color(0xFF1E874B),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: AppColors.paper0,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                _setupArabicDigits(selectedIndex + 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        if (locked)
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.paper0.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(Icons.lock_rounded, size: 17),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFEAF3EC)
                          : locked
                          ? const Color(0xFFFFF4D8)
                          : const Color(0xFFF4EBDD),
                      border: Border(
                        bottom: BorderSide(
                          color: selected
                              ? selectedColor ?? const Color(0xFF1E874B)
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        if (!selected && onFavorite != null)
                          IconButton(
                            tooltip: favorite
                                ? 'إزالة من المفضلة'
                                : 'إضافة للمفضلة',
                            onPressed: onFavorite,
                            constraints: const BoxConstraints.tightFor(
                              width: 30,
                              height: 40,
                            ),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              favorite
                                  ? AhdashIcons.favoriteSelected
                                  : AhdashIcons.favorite,
                              size: 16,
                            ),
                          ),
                        SizedBox(width: selected ? 0 : 7),
                        Expanded(
                          child: Text(
                            category.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _CategoryImageFallback extends StatelessWidget {
  const _CategoryImageFallback({required this.category});

  final QuizCategory category;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: category.accentColor.withValues(alpha: 0.16),
    child: PartyGameplayArtwork(
      scene: PartyGameplayArtworkScene.category,
      accent: category.accentColor,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 18),
          child: Text(
            category.name.trim().isEmpty
                ? '١١'
                : category.name.trim().characters.first,
            style: TextStyle(
              color: context.ahdashColors.textPrimary,
              fontSize: context.v9Metrics.compact ? 34 : 52,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

void _showCategoryDetail(
  BuildContext context,
  QuizCategory category,
  QuizQuestion? sample, {
  required bool playable,
  required bool locked,
}) {
  final parentContext = context;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.9,
      child: PartyCategoryDetailPanel(
        category: category,
        sample: sample,
        playable: playable,
        locked: locked,
        onPremium: locked
            ? () {
                Navigator.pop(context);
                unawaited(_showPremiumGate(parentContext, category));
              }
            : null,
      ),
    ),
  );
}

final class PartyCategoryDetailPanel extends StatelessWidget {
  const PartyCategoryDetailPanel({
    required this.category,
    this.sample,
    this.playable,
    this.locked = false,
    this.onPremium,
    super.key,
  });

  final QuizCategory category;
  final QuizQuestion? sample;
  final bool? playable;
  final bool locked;
  final VoidCallback? onPremium;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PartyV2Canvas(
        motion: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 37),
          child: _CategoryDetails(
            category: category,
            playable: playable,
            locked: locked,
            onPremium: onPremium,
          ),
        ),
      ),
    );
  }
}

final class _CategoryDetails extends StatelessWidget {
  const _CategoryDetails({
    required this.category,
    required this.playable,
    required this.locked,
    required this.onPremium,
  });

  final QuizCategory category;
  final bool? playable;
  final bool locked;
  final VoidCallback? onPremium;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 820;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 6,
                      child: IconButton.outlined(
                        tooltip: 'عودة للفئات',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(AhdashIcons.back),
                      ),
                    ),
                    const Positioned.fill(
                      top: 13,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'تفاصيل الفئة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 10 : 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: compact ? 210 : 238,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AhdashImage(
                        imageUrl: category.imageUrl,
                        alignment: category.focalAlignment,
                        fallbackWidget: _CategoryImageFallback(
                          category: category,
                        ),
                        aspectRatio: 16 / 10,
                        borderRadius: 0,
                        semanticLabel: category.name,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00191714), Color(0xD1191714)],
                            stops: [0.34, 1],
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: 16,
                        end: 16,
                        bottom: 15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (locked)
                              const Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: PremiumCategoryBadge(compact: true),
                              ),
                            if (locked) const SizedBox(height: 7),
                            Text(
                              category.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.paper0,
                                fontSize: 30,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CategoryMetaPill(
                    icon: locked
                        ? Icons.lock_outline_rounded
                        : Icons.sports_soccer_rounded,
                    label: locked
                        ? 'متاحة عبر Premium'
                        : playable == false
                        ? 'غير جاهزة للعب الآن'
                        : 'جاهزة للعب',
                    accent: locked ? AppColors.gold : category.accentColor,
                  ),
                  if (category.seasonLabel?.isNotEmpty == true)
                    _CategoryMetaPill(
                      icon: Icons.calendar_today_rounded,
                      label: category.seasonLabel!,
                      accent: AppColors.inkMuted,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EBDD),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD3C6B2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'عن الفئة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.description.isEmpty
                              ? 'لا يتوفر وصف منشور لهذه الفئة.'
                              : category.description,
                          style: TextStyle(
                            color: context.ahdashColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(
                              Icons.dynamic_feed_outlined,
                              size: 16,
                              color: AppColors.inkMuted,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'عدد الأسئلة متغير',
                              style: TextStyle(
                                color: AppColors.inkSoft,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        if (category.gameplayInstructions?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Text(
                            category.gameplayInstructions!,
                            style: const TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PartyPrimaryButton(
                label: locked
                    ? 'عرض Premium'
                    : playable == false
                    ? 'العودة للفئات'
                    : 'تحديد هذه الفئة',
                icon: locked ? Icons.lock_open_rounded : Icons.check_rounded,
                backgroundColor: const Color(0xFFB6FF3B),
                foregroundColor: const Color(0xFF191714),
                onPressed: locked && onPremium != null
                    ? onPremium
                    : () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _CategoryMetaPill extends StatelessWidget {
  const _CategoryMetaPill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: accent.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: accent),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

final class PartyTeamSetupScreen extends ConsumerStatefulWidget {
  const PartyTeamSetupScreen({super.key});

  @override
  ConsumerState<PartyTeamSetupScreen> createState() =>
      _PartyTeamSetupScreenState();
}

final class _PartyTeamSetupScreenState
    extends ConsumerState<PartyTeamSetupScreen> {
  late final List<TextEditingController> _names;

  @override
  void initState() {
    super.initState();
    final teams = ref.read(partyGameControllerProvider).teams;
    _names = teams
        .map((team) => TextEditingController(text: team.name))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _names) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partyGameControllerProvider);
    final teamError = PartySetupValidation.teamError(state.teams);
    final firstTeam = _TeamStage(
      color: Color(state.teams[0].colorValue),
      child: _TeamLineEditor(
        index: 0,
        controller: _names[0],
        team: state.teams[0],
      ),
    );
    final secondTeam = _TeamStage(
      color: Color(state.teams[1].colorValue),
      child: _TeamLineEditor(
        index: 1,
        controller: _names[1],
        team: state.teams[1],
      ),
    );
    final versus = Center(
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 16),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EBDD),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD3C6B2)),
            ),
            child: const Text(
              'VS',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: Color(0xFFD6A12D),
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(child: Divider()),
        ],
      ),
    );
    return PartyFlowScaffold(
      title: 'تكوين الفرق',
      subtitle: 'وزع رفاق المجلس إلى فريقين',
      step: 2,
      onBack: () => context.go('/party/categories?review=1'),
      footer: PartyPrimaryButton(
        label: 'التالي',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.ink,
        onPressed: teamError == null ? _continueWithoutSplitter : null,
      ),
      child: ListView(
        key: const ValueKey('party-team-setup-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        children: [
          firstTeam,
          SizedBox(height: 56, child: versus),
          secondTeam,
          if (teamError != null) ...[
            const SizedBox(height: 10),
            Text(
              teamError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.ahdashColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextButton.icon(
            key: const ValueKey('party-use-splitter'),
            onPressed: teamError == null ? _continueWithSplitter : null,
            icon: const Icon(AhdashIcons.random),
            label: const Text('إضافة اللاعبين وتقسيمهم اختياريًا'),
          ),
        ],
      ),
    );
  }

  void _continueWithSplitter() {
    final error = ref
        .read(partyGameControllerProvider.notifier)
        .completeTeamSetup(useSplitter: true);
    if (error == null) {
      context.go(
        PartySetupFlowResolver.canonicalRoute(
          ref.read(partyGameControllerProvider),
        ),
      );
    }
  }

  void _continueWithoutSplitter() {
    final error = ref
        .read(partyGameControllerProvider.notifier)
        .completeTeamSetup(useSplitter: false);
    if (error == null) {
      context.go(
        PartySetupFlowResolver.canonicalRoute(
          ref.read(partyGameControllerProvider),
        ),
      );
    }
  }
}

final class _TeamStage extends StatelessWidget {
  const _TeamStage({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final spacious = constraints.maxHeight > 190;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4EBDD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD3C6B2)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacious ? 16 : 14,
            vertical: 10,
          ),
          child: Center(child: child),
        ),
      );
    },
  );
}

final class _TeamLineEditor extends StatelessWidget {
  const _TeamLineEditor({
    required this.index,
    required this.controller,
    required this.team,
  });

  final int index;
  final TextEditingController controller;
  final PartyTeam team;

  static const _teamColors = [
    0xFF2368A2,
    0xFFB63863,
    0xFF14805D,
    0xFFB77A00,
    0xFF7446A8,
  ];

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(team.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'الفريق ${index == 0 ? 'أ' : 'ب'}',
                maxLines: 1,
                style: TextStyle(
                  color: context.ahdashColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  index == 0 ? 'الفريق الأول' : 'الفريق الثاني',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: context.v9Metrics.inputHeight,
            child: TextField(
              key: ValueKey('party-team-name-$index'),
              controller: controller,
              maxLength: 24,
              onChanged: (value) => ref
                  .read(partyGameControllerProvider.notifier)
                  .updateTeam(index, name: value),
              style: Theme.of(context).textTheme.titleLarge,
              decoration: InputDecoration(
                hintText: 'اسم الفريق ${index + 1}',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              PopupMenuButton<int>(
                tooltip: 'تغيير لون الفريق',
                padding: EdgeInsets.zero,
                onSelected: (value) => ref
                    .read(partyGameControllerProvider.notifier)
                    .updateTeam(index, colorValue: value),
                itemBuilder: (_) => [
                  for (final value in _teamColors)
                    PopupMenuItem(
                      value: value,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(value),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
                child: SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(team.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'لون الفريق',
                style: TextStyle(
                  color: context.ahdashColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final class PartyTeamSplitterScreen extends ConsumerWidget {
  const PartyTeamSplitterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partyGameControllerProvider);
    final savedNames = state.splitterPlayers
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    return PartyTeamSplitterSheet(
      initialNames: savedNames.isNotEmpty
          ? savedNames
          : state.teams.expand((team) => team.players).toList(growable: false),
      fullScreen: true,
    );
  }
}

final class PartyTeamSplitterSheet extends ConsumerStatefulWidget {
  const PartyTeamSplitterSheet({
    this.initialNames = const [],
    this.fullScreen = false,
    super.key,
  });

  final List<String> initialNames;
  final bool fullScreen;

  @override
  ConsumerState<PartyTeamSplitterSheet> createState() =>
      _PartyTeamSplitterSheetState();
}

final class _PartyTeamSplitterSheetState
    extends ConsumerState<PartyTeamSplitterSheet> {
  late final TextEditingController _players;
  late final TextEditingController _newPlayer;
  var _editing = true;

  @override
  void initState() {
    super.initState();
    _players = TextEditingController(text: widget.initialNames.join('\n'));
    _newPlayer = TextEditingController();
    final setup = ref.read(partyGameControllerProvider);
    _editing =
        !(widget.fullScreen &&
            setup.splitterStatus == PartySplitterStatus.completed &&
            setup.teams.every((team) => team.players.isNotEmpty));
    _players.addListener(_saveInput);
  }

  @override
  void dispose() {
    _players.removeListener(_saveInput);
    _players.dispose();
    _newPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(partyGameControllerProvider).teams;
    final hasSplit = teams.any((team) => team.players.isNotEmpty);
    final showEditor = _editing || !hasSplit;
    final metrics = context.v9Metrics;
    if (widget.fullScreen && metrics.portrait) {
      return _buildPortraitScreen(context, teams, hasSplit: hasSplit);
    }
    return Material(
      color: Colors.transparent,
      child: PartyV2Canvas(
        motion: false,
        child: SafeArea(
          child: AnimatedPadding(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: widget.fullScreen
                                ? () => context.go('/party/teams?review=1')
                                : () => Navigator.maybePop(context),
                            tooltip: widget.fullScreen ? 'رجوع' : 'إغلاق',
                            icon: Icon(
                              widget.fullScreen
                                  ? Icons.arrow_back_rounded
                                  : Icons.close_rounded,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'تقسيم اللاعبين',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : PartyV2Motion.reveal,
                          child: showEditor
                              ? Center(
                                  key: const ValueKey('split-editor'),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 680,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'من يلعب الليلة؟',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: metrics.heroSize,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'اكتب كل اسم في سطر، وأحدعش يقسمهم على فريقين.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: context
                                                .ahdashColors
                                                .textSecondary,
                                            fontSize: metrics.bodySize,
                                          ),
                                        ),
                                        SizedBox(height: metrics.sectionGap),
                                        Expanded(
                                          child: TextField(
                                            key: const ValueKey(
                                              'party-splitter-player-input',
                                            ),
                                            controller: _players,
                                            expands: true,
                                            minLines: null,
                                            maxLines: null,
                                            textAlignVertical:
                                                TextAlignVertical.top,
                                            style: TextStyle(
                                              fontSize: metrics.bodySize,
                                              height: 1.65,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            decoration: const InputDecoration(
                                              labelText: 'أسماء اللاعبين',
                                              hintText:
                                                  'اكتب كل اسم في سطر مستقل',
                                              alignLabelWithHint: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Row(
                                  key: const ValueKey('split-result'),
                                  children: [
                                    Expanded(
                                      child: _SplitResult(
                                        team: teams[0],
                                        moveTooltip:
                                            'انقل إلى ${teams[1].name}',
                                        onMove: (name) =>
                                            _movePlayer(name, fromTeamIndex: 0),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 52,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'VS',
                                            textDirection: TextDirection.ltr,
                                            style: TextStyle(
                                              color: Color(0xFFD6A12D),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _splitTeams,
                                            tooltip: 'إعادة التقسيم',
                                            icon: const Icon(
                                              Icons.shuffle_rounded,
                                              size: 19,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                setState(() => _editing = true),
                                            tooltip: 'تعديل الأسماء',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 19,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: _SplitResult(
                                        team: teams[1],
                                        moveTooltip:
                                            'انقل إلى ${teams[0].name}',
                                        onMove: (name) =>
                                            _movePlayer(name, fromTeamIndex: 1),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (widget.fullScreen)
                            TextButton(
                              onPressed: _skip,
                              child: const Text('تخطي'),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PartyPrimaryButton(
                              label:
                                  widget.fullScreen && hasSplit && !showEditor
                                  ? 'تأكيد التقسيم'
                                  : hasSplit && !showEditor
                                  ? 'توزيع عشوائي جديد'
                                  : 'قسّم تلقائيًا',
                              icon: Icons.shuffle_rounded,
                              onPressed:
                                  widget.fullScreen && hasSplit && !showEditor
                                  ? _confirm
                                  : _splitTeams,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitScreen(
    BuildContext context,
    List<PartyTeam> teams, {
    required bool hasSplit,
  }) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final names = _playerNames;
    return Material(
      color: Colors.transparent,
      child: PartyV2Canvas(
        motion: false,
        child: SafeArea(
          child: AnimatedPadding(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'تقسيم اللاعبين',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'أدخل أسماء الربع ثم وزعهم عشوائيًا',
                              style: TextStyle(
                                color: context.ahdashColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: _skip,
                        tooltip: 'تخطي التقسيم والعودة',
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        SizedBox(
                          height: keyboardOpen
                              ? 8
                              : MediaQuery.sizeOf(context).width < 380
                              ? 140
                              : 147,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const ValueKey(
                                  'party-splitter-player-input',
                                ),
                                controller: _newPlayer,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _addPlayer(),
                                decoration: const InputDecoration(
                                  hintText: 'اكتب اسم لاعب جديد...',
                                  counterText: '',
                                ),
                                maxLength: 40,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox.square(
                              dimension: 52,
                              child: FilledButton(
                                onPressed: _addPlayer,
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: keyboardOpen
                                      ? const Color(0xFFA8FF2A)
                                      : const Color(0xFF1E874B),
                                ),
                                child: const Icon(Icons.add_rounded, size: 28),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final name in names)
                              InputChip(
                                label: Text(name),
                                padding: EdgeInsets.zero,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                onDeleted: () => _removePlayer(name),
                                deleteIcon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 15,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: names.length >= 2 ? _splitTeams : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E874B),
                            backgroundColor: const Color(0xFFECF5EF),
                            side: const BorderSide(color: Color(0xFF1E874B)),
                            minimumSize: Size.fromHeight(
                              MediaQuery.sizeOf(context).width < 380 ? 46 : 56,
                            ),
                          ),
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('توزيع اللاعبين عشوائيًا'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _PortraitSplitTeamCard(team: teams[1]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PortraitSplitTeamCard(team: teams[0]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          !keyboardOpen &&
                              MediaQuery.sizeOf(context).width >= 380
                          ? 27
                          : 0,
                    ),
                    child: PartyPrimaryButton(
                      label: hasSplit ? 'تأكيد التشكيلة' : 'قسّم تلقائيًا',
                      backgroundColor: MediaQuery.sizeOf(context).width < 380
                          ? const Color(0xFF1E874B)
                          : null,
                      foregroundColor: MediaQuery.sizeOf(context).width < 380
                          ? Colors.white
                          : null,
                      onPressed: hasSplit ? _confirm : _splitTeams,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> get _playerNames => _players.text
      .split('\n')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false);

  void _addPlayer() {
    final name = _newPlayer.text.trim();
    if (name.isEmpty || _playerNames.contains(name)) return;
    _players.text = [..._playerNames, name].join('\n');
    _newPlayer.clear();
    setState(() {});
  }

  void _removePlayer(String name) {
    _players.text = _playerNames.where((item) => item != name).join('\n');
    setState(() {});
  }

  void _splitTeams() {
    final split = ref
        .read(partyGameControllerProvider.notifier)
        .splitPlayers(_players.text.split('\n'));
    if (!split) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(partyGameControllerProvider).error ?? ''),
        ),
      );
      return;
    }
    ref.read(feedbackServiceProvider).play(FeedbackCue.ready);
    setState(() => _editing = false);
  }

  void _saveInput() {
    ref
        .read(partyGameControllerProvider.notifier)
        .updateSplitterPlayers(_players.text.split('\n'));
  }

  void _skip() {
    ref.read(partyGameControllerProvider.notifier).skipSplitter();
    context.go(
      PartySetupFlowResolver.canonicalRoute(
        ref.read(partyGameControllerProvider),
      ),
    );
  }

  void _confirm() {
    context.go(
      PartySetupFlowResolver.canonicalRoute(
        ref.read(partyGameControllerProvider),
      ),
    );
  }

  void _movePlayer(String name, {required int fromTeamIndex}) {
    final teams = ref.read(partyGameControllerProvider).teams;
    final first = [...teams[0].players];
    final second = [...teams[1].players];
    final source = fromTeamIndex == 0 ? first : second;
    final target = fromTeamIndex == 0 ? second : first;
    if (source.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يبقى لاعب واحد على الأقل في كل فريق.'),
        ),
      );
      return;
    }
    source.remove(name);
    target.add(name);
    ref.read(partyGameControllerProvider.notifier).assignPlayers(first, second);
  }
}

final class _PortraitSplitTeamCard extends StatelessWidget {
  const _PortraitSplitTeamCard({required this.team});

  final PartyTeam team;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      height: 120 + ((textScale - 1).clamp(0, 0.3) * 100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EBDD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.ahdashColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PartyTeamDot(color: Color(team.colorValue)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const Divider(height: 10),
          for (final player in team.players)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                player,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _SplitResult extends StatelessWidget {
  const _SplitResult({
    required this.team,
    required this.moveTooltip,
    required this.onMove,
  });

  final PartyTeam team;
  final String moveTooltip;
  final ValueChanged<String> onMove;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.ahdashColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      border: Border(
        bottom: BorderSide(color: Color(team.colorValue), width: 4),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.all(context.v9Metrics.compact ? 14 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PartyTeamDot(color: Color(team.colorValue)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Expanded(
            child: team.players.isEmpty
                ? Center(
                    child: Text(
                      'أضف الأسماء ثم اضغط «قسّم الفرق»',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.ahdashColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: team.players.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}'.padLeft(2, '0'),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: context.ahdashColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              team.players[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: moveTooltip,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => onMove(team.players[index]),
                            icon: const Icon(
                              Icons.swap_horiz_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

final class PartyHelperSelectionScreen extends ConsumerStatefulWidget {
  const PartyHelperSelectionScreen({super.key});

  @override
  ConsumerState<PartyHelperSelectionScreen> createState() =>
      _PartyHelperSelectionScreenState();
}

final class _PartyHelperSelectionScreenState
    extends ConsumerState<PartyHelperSelectionScreen> {
  var _teamIndex = 0;

  @override
  Widget build(BuildContext context) {
    final compactPortrait = MediaQuery.sizeOf(context).height < 820;
    final state = ref.watch(partyGameControllerProvider);
    final definitions =
        ref.watch(partyHelperCatalogProvider).value ??
        defaultPartyHelperDefinitions;
    final activeIds = definitions.map((definition) => definition.id).toSet();
    final ready =
        definitions.length >= PartyGameRules.helpersPerTeam &&
        state.teams.every(
          (team) =>
              team.selectedHelpers.length == PartyGameRules.helpersPerTeam &&
              activeIds.containsAll(team.selectedHelpers),
        );
    final team = state.teams[_teamIndex];
    return PartyFlowScaffold(
      title: 'اختر المساعدات',
      subtitle: 'لكل فريق ثلاث أدوات — وكل أداة مرة واحدة في الجولة',
      step: 3,
      onBack: () => context.go(
        state.splitterStatus == PartySplitterStatus.completed
            ? '/party/splitter?review=1'
            : '/party/teams?review=1',
      ),
      footer: Row(
        children: [
          Expanded(
            child: PartyPrimaryButton(
              label: 'التالي',
              icon: Icons.arrow_back_rounded,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.ink,
              onPressed: ready
                  ? () => context.go(
                      PartySetupFlowResolver.canonicalRoute(
                        ref.read(partyGameControllerProvider),
                        activeHelperIds: activeIds,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 976),
          child: Column(
            children: [
              SizedBox(
                height: compactPortrait ? 48 : 56,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _HelperTeamSwitcher(
                    teams: state.teams,
                    selectedIndex: _teamIndex,
                    onSelected: (value) => setState(() => _teamIndex = value),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  key: const ValueKey('party-helper-list'),
                  itemCount: definitions.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: compactPortrait ? 8 : 10),
                  itemBuilder: (context, index) {
                    final definition = definitions[index];
                    final selected = team.selectedHelpers.contains(
                      definition.id,
                    );
                    final enabled =
                        definition.id != PartyHelperId.bench ||
                        state.teams[1 - _teamIndex].players.isNotEmpty;
                    return _V10HelperCard(
                      definition: definition,
                      selected: selected,
                      enabled: enabled,
                      onTap: () {
                        final changed = ref
                            .read(partyGameControllerProvider.notifier)
                            .toggleHelper(_teamIndex, definition.id);
                        if (changed) {
                          ref
                              .read(feedbackServiceProvider)
                              .play(FeedbackCue.selection);
                        }
                      },
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
}

final class _HelperTeamSwitcher extends StatelessWidget {
  const _HelperTeamSwitcher({
    required this.teams,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<PartyTeam> teams;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF4EBDD),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.ink, width: 1.1),
    ),
    child: Row(
      children: [
        for (var index = 0; index < teams.length; index++)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              child: ColoredBox(
                color: index == selectedIndex
                    ? AppColors.ink
                    : Colors.transparent,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PartyTeamDot(color: Color(teams[index].colorValue)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${teams[index].name}  ${teams[index].selectedHelpers.length}/3',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ).copyWith(
                                color: index == selectedIndex
                                    ? AppColors.paper0
                                    : AppColors.ink,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

final class _V10HelperCard extends StatelessWidget {
  const _V10HelperCard({
    required this.definition,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PartyHelperDefinition definition;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compactPortrait = MediaQuery.sizeOf(context).height < 820;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.1;
    const selectedTone = Color(0xFF7EB900);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: definition.id.label,
      child: AnimatedScale(
        scale: selected && !reducedMotion ? 1.008 : 1,
        duration: reducedMotion ? Duration.zero : PartyV2Motion.page,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(17),
            child: AnimatedContainer(
              duration: reducedMotion ? Duration.zero : PartyV2Motion.page,
              height: compactPortrait
                  ? largeText
                        ? 74
                        : 68
                  : 78,
              padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 12, 8),
              decoration: BoxDecoration(
                color: !enabled
                    ? AppColors.paper2.withValues(alpha: 0.55)
                    : selected
                    ? const Color(0xFFEAF3EC)
                    : const Color(0xFFF4EBDD),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: selected ? AppColors.ink : const Color(0xFFD3C6B2),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x22191714),
                          offset: Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: compactPortrait ? 48 : 54,
                    height: compactPortrait ? 48 : 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.ink : AppColors.paper0,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.ink : AppColors.hairline,
                      ),
                    ),
                    child: AhdashPictogramView(
                      pictogram: partyHelperPictogram(
                        definition.id,
                        definition.iconKey,
                      ),
                      size: 29,
                      tone: !enabled
                          ? AhdashPictogramTone.muted
                          : selected
                          ? AhdashPictogramTone.achievement
                          : AhdashPictogramTone.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          definition.id.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          enabled
                              ? definition.description
                              : 'غير متاح لهذه التشكيلة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.ahdashColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: reducedMotion
                        ? Duration.zero
                        : PartyV2Motion.page,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? selectedTone : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: selected ? selectedTone : AppColors.hairline,
                      ),
                    ),
                    child: Text(
                      selected ? 'مختار' : 'اختر',
                      style: TextStyle(
                        color: selected ? AppColors.ink : AppColors.inkMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

AhdashPictogram partyHelperPictogram(PartyHelperId id, [String? iconKey]) =>
    switch (iconKey) {
      'looks_two' => AhdashPictogram.twoChances,
      'phone' => AhdashPictogram.callFriend,
      'trending_up' => AhdashPictogram.risk,
      'event_seat' => AhdashPictogram.bench,
      'redo' => AhdashPictogram.pass,
      _ => switch (id) {
        PartyHelperId.twoChances => AhdashPictogram.twoChances,
        PartyHelperId.callFriend => AhdashPictogram.callFriend,
        PartyHelperId.risk => AhdashPictogram.risk,
        PartyHelperId.bench => AhdashPictogram.bench,
        PartyHelperId.pass => AhdashPictogram.pass,
      },
    };

final class PartyReadyScreen extends ConsumerWidget {
  const PartyReadyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).height <= 390;
    final state = ref.watch(partyGameControllerProvider);
    final catalog = ref.watch(partyCatalogProvider).value;
    final premium = ref.watch(partyEntitlementProvider).value ?? false;
    final definitions =
        ref.watch(partyHelperCatalogProvider).value ??
        defaultPartyHelperDefinitions;
    final runtimeSettings =
        ref.watch(partyRuntimeSettingsProvider).value ??
        const PartyRuntimeSettings();
    final selectedCategories = state.selectedCategoryIds
        .map(
          (id) => catalog?.categories
              .where((category) => category.id == id)
              .firstOrNull,
        )
        .whereType<QuizCategory>()
        .toList();
    final readyError = catalog == null
        ? null
        : PartySetupValidation.readyError(
            hasSetupDraft: state.hasSetupDraft,
            teamSetupCompleted: state.teamSetupCompleted,
            splitterStatus: state.splitterStatus,
            selectedCategoryIds: state.selectedCategoryIds,
            playableCategoryIds: catalog
                .playableCategories(premium: premium)
                .map((category) => category.id)
                .toSet(),
            teams: state.teams,
            activeHelperIds: definitions
                .map((definition) => definition.id)
                .toSet(),
          );
    final canStart = !state.busy && catalog != null && readyError == null;

    Future<void> startGame() async {
      if (!canStart) return;
      final started = await ref
          .read(partyGameControllerProvider.notifier)
          .start(
            catalog.playableCategories(premium: premium),
            catalog.questions,
            definitions,
            runtimeSettings,
          );
      if (started && context.mounted) {
        unawaited(ref.read(feedbackServiceProvider).play(FeedbackCue.ready));
        context.go('/party/board');
      }
    }

    return PartyFlowScaffold(
      title: 'المجلس جاهز',
      subtitle: 'راجعوا اختيارات اللعبة ثم ابدأوا',
      step: 4,
      onBack: () => context.go('/party/helpers?review=1'),
      footer: context.v9Metrics.portrait
          ? PartyPrimaryButton(
              label: 'ابدأ اللعبة',
              icon: Icons.sports_soccer_rounded,
              busy: state.busy,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.ink,
              onPressed: canStart ? startGame : null,
            )
          : Row(
              children: [
                if (state.error != null || readyError != null)
                  Expanded(
                    child: Text(
                      state.error ?? readyError!,
                      style: TextStyle(
                        color: context.ahdashColors.error,
                        fontSize: 10,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                PartyPrimaryButton(
                  label: 'يلا نبدأ',
                  busy: state.busy,
                  onPressed: canStart ? startGame : null,
                ),
              ],
            ),
      child: context.v9Metrics.portrait
          ? SingleChildScrollView(
              child: _ReadyPortraitContent(
                teams: state.teams,
                categories: selectedCategories,
                definitions: definitions,
                error: state.error ?? readyError,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ReadyTeamLine(
                              team: state.teams[0],
                              definitions: definitions,
                            ),
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4EBDD),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD6A12D),
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'VS',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: Color(0xFFD6A12D),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _ReadyTeamLine(
                              team: state.teams[1],
                              definitions: definitions,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 5 : 9),
                SizedBox(
                  height: compact ? 48 : 64,
                  child: _ReadyCategoryRail(
                    categories: selectedCategories,
                    teams: state.teams,
                  ),
                ),
                SizedBox(height: compact ? 5 : 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '6 فئات • 36 سؤالًا • 100 / 200 / 300',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.ahdashColors.textSecondary,
                          fontSize: compact ? 13 : 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<int?>(
                        initialValue: state.timerSeconds,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'وقت السؤال',
                          isDense: true,
                        ),
                        items: PartyGameRules.timerOptions
                            .map(
                              (value) => DropdownMenuItem<int?>(
                                value: value,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    value == null
                                        ? 'بدون مؤقت'
                                        : '$value ثانية',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: ref
                            .read(partyGameControllerProvider.notifier)
                            .setTimer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

final class _ReadyPortraitContent extends StatelessWidget {
  const _ReadyPortraitContent({
    required this.teams,
    required this.categories,
    required this.definitions,
    required this.error,
  });

  final List<PartyTeam> teams;
  final List<QuizCategory> categories;
  final List<PartyHelperDefinition> definitions;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 8),
      _ReadyMatchHero(teams: teams),
      const SizedBox(height: 16),
      _ReadySummaryCard(
        teams: teams,
        categories: categories,
        definitions: definitions,
      ),
      if (error != null) ...[
        const SizedBox(height: 6),
        Text(
          error!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.ahdashColors.error,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ],
  );
}

final class _ReadyMatchHero extends StatelessWidget {
  const _ReadyMatchHero({required this.teams});

  final List<PartyTeam> teams;

  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.sizeOf(context).height < 820 ? 172 : 190,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF173F34),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.ink, width: 1.2),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const PartyGameplayArtwork(
          scene: PartyGameplayArtworkScene.ready,
          onDark: true,
          accent: AppColors.primary,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            children: [
              const Text(
                'صافرة البداية قريبة',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(
                    child: _ReadyTeamBadge(
                      team: teams[0],
                      label: 'أ',
                      onDark: true,
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.paper0,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 1.6),
                    ),
                    child: const Text(
                      'VS',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _ReadyTeamBadge(
                      team: teams[1],
                      label: 'ب',
                      onDark: true,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _ReadyTeamBadge extends StatelessWidget {
  const _ReadyTeamBadge({
    required this.team,
    required this.label,
    this.onDark = false,
  });

  final PartyTeam team;
  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(team.colorValue),
          shape: BoxShape.circle,
          border: Border.all(
            color: onDark ? AppColors.paper0 : const Color(0xFFD3C6B2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 7),
      Text(
        team.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: onDark ? AppColors.paper0 : AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

final class _ReadySummaryCard extends StatelessWidget {
  const _ReadySummaryCard({
    required this.teams,
    required this.categories,
    required this.definitions,
  });
  final List<PartyTeam> teams;
  final List<QuizCategory> categories;
  final List<PartyHelperDefinition> definitions;

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ملخص خيارات اللعبة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text(
          '٦ فئات • ٣٦ سؤالًا',
          style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in categories)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    category.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        const Divider(height: 32),
        const Text(
          'المساعدات المفعّلة',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        for (final team in teams) ...[
          const SizedBox(height: 12),
          Text(
            team.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final definition in definitions.where(
                (d) => team.selectedHelpers.contains(d.id),
              ))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AhdashPictogramView(
                      pictogram: partyHelperPictogram(
                        definition.id,
                        definition.iconKey,
                      ),
                      size: 16,
                      tone: AhdashPictogramTone.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      definition.id.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

final class _ReadyCategoryRail extends StatelessWidget {
  const _ReadyCategoryRail({required this.categories, required this.teams});

  final List<QuizCategory> categories;
  final List<PartyTeam> teams;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < categories.length; index++) ...[
        if (index > 0) const SizedBox(width: 5),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(teams[index < 3 ? 0 : 1].colorValue),
                  width: 3,
                ),
              ),
            ),
            child: Center(
              child: Text(
                categories[index].name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.v9Metrics.compact ? 13 : 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

final class _ReadyTeamLine extends StatelessWidget {
  const _ReadyTeamLine({required this.team, required this.definitions});

  final PartyTeam team;
  final List<PartyHelperDefinition> definitions;

  @override
  Widget build(BuildContext context) {
    final spacious = MediaQuery.sizeOf(context).height > 520;
    final short = MediaQuery.sizeOf(context).height <= 360;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AhdashPictogramView(
          pictogram: AhdashPictogram.teamsStep,
          color: Color(team.colorValue),
          scale: spacious
              ? AhdashPictogramScale.sectionIdentity
              : AhdashPictogramScale.inline,
        ),
        SizedBox(
          height: spacious
              ? 10
              : short
              ? 3
              : 5,
        ),
        Text(
          team.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style:
              (spacious
                      ? Theme.of(context).textTheme.displaySmall
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(
                    color: Color(team.colorValue),
                    fontSize: spacious
                        ? 34
                        : short
                        ? 22
                        : 24,
                    fontWeight: FontWeight.w900,
                  ),
        ),
        SizedBox(
          height: spacious
              ? 7
              : short
              ? 2
              : 4,
        ),
        Text(
          team.players.isEmpty ? 'اللعب باسم الفريق' : team.players.join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.ahdashColors.textMuted,
            fontSize: spacious ? 15 : 12,
          ),
        ),
        SizedBox(
          height: spacious
              ? 14
              : short
              ? 3
              : 6,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: team.selectedHelpers
                .map(
                  (helper) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacious ? 8 : 5),
                    child: Tooltip(
                      message:
                          definitions
                              .where((definition) => definition.id == helper)
                              .firstOrNull
                              ?.label ??
                          helper.label,
                      child: AhdashPictogramView(
                        pictogram: partyHelperPictogram(
                          helper,
                          definitions
                              .where((definition) => definition.id == helper)
                              .firstOrNull
                              ?.iconKey,
                        ),
                        scale: AhdashPictogramScale.inline,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

final class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 150,
            height: 86,
            child: PartyGameplayArtwork(
              scene: PartyGameplayArtworkScene.imageFallback,
              accent: AppColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تعذر تحميل الفئات الآن.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'تحقق من الاتصال ثم جرّب مرة أخرى.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          PartyPrimaryButton(label: 'إعادة المحاولة', onPressed: onRetry),
        ],
      ),
    ),
  );
}
