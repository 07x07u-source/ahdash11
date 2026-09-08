import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/domain/category.dart';
import '../../../shared/presentation/ahdash_image.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/editorial_v6.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../party/presentation/party_game_controller.dart';
import '../domain/category_discovery.dart';
import 'categories_controller.dart';

final class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

final class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchController = TextEditingController();
  String? _collectionId;
  var _favoritesOnly = false;
  var _mediaOnly = false;
  var _specialOnly = false;
  var _sort = CategorySort.editorial;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(partyGameControllerProvider.notifier).restore());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final configuredCollections =
        ref.watch(categoryCollectionsProvider).value ?? const [];
    final favorites = ref.watch(
      partyGameControllerProvider.select((value) => value.favoriteCategoryIds),
    );
    return BrandScaffold(
      body: AhdashEditorialCanvas(
        child: EditorialPageFrame(
          child: categories.when(
            loading: () => const Center(child: ElevenLoader(size: 42)),
            error: (_, _) => AppMessageState(
              icon: Icons.cloud_off_rounded,
              title: 'الأقسام ما وصلت',
              message: 'الاتصال ضعيف شوي، جرّب مرة ثانية.',
              actionLabel: 'إعادة المحاولة',
              onAction: () => ref.read(categoriesProvider.notifier).refresh(),
            ),
            data: (allCategories) =>
                _buildCatalog(allCategories, favorites, configuredCollections),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalog(
    List<QuizCategory> allCategories,
    Set<String> favorites,
    List<CategoryCollection> configuredCollections,
  ) {
    if (allCategories.isEmpty) {
      return const AppMessageState(
        icon: Icons.category_outlined,
        title: 'الأقسام بتنزل قريب',
        message: 'أول ما ينشر المحتوى بتلقاه هنا.',
      );
    }
    final collections = configuredCollections.isEmpty
        ? _collectionsFor(allCategories)
        : configuredCollections;
    final selectedCollection = collections
        .where((value) => value.id == _collectionId)
        .firstOrNull;
    final visible = const CategoryDiscoveryEngine().discover(
      categories: allCategories,
      favoriteIds: favorites,
      query: CategoryDiscoveryQuery(
        search: _searchController.text,
        collection: selectedCollection,
        favoritesOnly: _favoritesOnly,
        mediaOnly: _mediaOnly,
        specialOnly: _specialOnly,
        sort: _sort,
      ),
    );
    final featured = _featuredFrom(visible);
    final remaining = visible
        .where((value) => value.id != featured?.id)
        .toList(growable: false);
    return Column(
      children: [
        EditorialScreenHeader(
          kicker: 'مكتبة الأسئلة',
          title: 'اختر ملعب تحديك',
          leading: IconButton(
            tooltip: 'رجوع',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          actions: [
            IconButton(
              tooltip: 'قسم عشوائي',
              onPressed: () => _openRandom(allCategories, favorites),
              icon: const Icon(AhdashIcons.random),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.read(categoriesProvider.notifier).refresh(),
              icon: const Icon(AhdashIcons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DiscoveryToolbar(
          controller: _searchController,
          collections: collections,
          selectedCollectionId: _collectionId,
          favoritesOnly: _favoritesOnly,
          mediaOnly: _mediaOnly,
          specialOnly: _specialOnly,
          sort: _sort,
          resultCount: visible.length,
          onSearchChanged: (_) => setState(() {}),
          onCollectionChanged: (value) => setState(() => _collectionId = value),
          onFavoritesChanged: (value) => setState(() => _favoritesOnly = value),
          onMediaChanged: (value) => setState(() => _mediaOnly = value),
          onSpecialChanged: (value) => setState(() => _specialOnly = value),
          onSortChanged: (value) => setState(() => _sort = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: visible.isEmpty
              ? AppMessageState(
                  icon: AhdashIcons.search,
                  title: 'ما لقينا قسمًا مطابقًا',
                  message: 'جرّب كلمة بحث أخرى أو امسح بعض الفلاتر.',
                  actionLabel: 'مسح الفلاتر',
                  onAction: _clearFilters,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 760) {
                      return Column(
                        children: [
                          if (featured != null) ...[
                            SizedBox(
                              height: (constraints.maxHeight * 0.34).clamp(
                                150,
                                220,
                              ),
                              child: _FeaturedCategory(
                                category: featured,
                                favorite: favorites.contains(featured.id),
                                onFavorite: () => _toggleFavorite(featured.id),
                                onTap: () => _showPreview(featured),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          Expanded(
                            child: _CategoryGrid(
                              categories: remaining,
                              favorites: favorites,
                              onFavorite: _toggleFavorite,
                              onTap: _showPreview,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (featured != null) ...[
                          Expanded(
                            flex: 5,
                            child: _FeaturedCategory(
                              category: featured,
                              favorite: favorites.contains(featured.id),
                              onFavorite: () => _toggleFavorite(featured.id),
                              onTap: () => _showPreview(featured),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                        ],
                        Expanded(
                          flex: 7,
                          child: _CategoryGrid(
                            categories: remaining,
                            favorites: favorites,
                            onFavorite: _toggleFavorite,
                            onTap: _showPreview,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<CategoryCollection> _collectionsFor(List<QuizCategory> categories) {
    final audiences = categories.expand((value) => value.audiences).toSet();
    final regions = categories.expand((value) => value.regionCodes).toSet();
    return [
      for (final code in audiences.where((value) => value != 'general'))
        CategoryCollection(
          id: 'audience:$code',
          labelAr: _collectionLabel(code),
          audienceCodes: {code},
        ),
      for (final code in regions)
        CategoryCollection(
          id: 'region:$code',
          labelAr: _collectionLabel(code),
          regionCodes: {code},
        ),
    ];
  }

  String _collectionLabel(String code) => switch (code) {
    'kids' => 'للصغار',
    'family' => 'عائلية',
    'experts' => 'للمحترفين',
    'gulf' || 'gcc' => 'الخليج',
    'arab' || 'mena' => 'العالم العربي',
    'europe' => 'أوروبا',
    _ => code.replaceAll('_', ' '),
  };

  QuizCategory? _featuredFrom(List<QuizCategory> categories) =>
      categories
          .where((value) => value.featured || value.recommended)
          .firstOrNull ??
      categories.firstOrNull;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _collectionId = null;
      _favoritesOnly = false;
      _mediaOnly = false;
      _specialOnly = false;
      _sort = CategorySort.editorial;
    });
  }

  void _toggleFavorite(String id) =>
      ref.read(partyGameControllerProvider.notifier).toggleFavorite(id);

  void _openRandom(List<QuizCategory> categories, Set<String> favorites) {
    final picked = const CategoryDiscoveryEngine().pickRandom(
      categories: categories,
      count: 1,
      preferredIds: favorites,
    );
    if (picked.isNotEmpty) _showPreview(picked.first);
  }

  Future<void> _showPreview(QuizCategory category) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => _CategoryPreview(
          category: category,
          favorite: ref
              .read(partyGameControllerProvider)
              .favoriteCategoryIds
              .contains(category.id),
          onFavorite: () {
            _toggleFavorite(category.id);
            Navigator.pop(sheetContext);
          },
          onSolo: () {
            Navigator.pop(sheetContext);
            context.push(
              '/solo?categoryId=${Uri.encodeQueryComponent(category.id)}',
            );
          },
          onGroup: () {
            Navigator.pop(sheetContext);
            ref.read(partyGameControllerProvider.notifier).beginNewGame();
            context.push('/party/categories');
          },
        ),
      );
}

final class _DiscoveryToolbar extends StatelessWidget {
  const _DiscoveryToolbar({
    required this.controller,
    required this.collections,
    required this.selectedCollectionId,
    required this.favoritesOnly,
    required this.mediaOnly,
    required this.specialOnly,
    required this.sort,
    required this.resultCount,
    required this.onSearchChanged,
    required this.onCollectionChanged,
    required this.onFavoritesChanged,
    required this.onMediaChanged,
    required this.onSpecialChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final List<CategoryCollection> collections;
  final String? selectedCollectionId;
  final bool favoritesOnly;
  final bool mediaOnly;
  final bool specialOnly;
  final CategorySort sort;
  final int resultCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCollectionChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final ValueChanged<bool> onMediaChanged;
  final ValueChanged<bool> onSpecialChanged;
  final ValueChanged<CategorySort> onSortChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final search = TextField(
        controller: controller,
        onChanged: onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'ابحث باسم القسم أو الوسم…',
          prefixIcon: const Icon(AhdashIcons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: () {
                    controller.clear();
                    onSearchChanged('');
                  },
                  icon: const Icon(AhdashIcons.close),
                ),
        ),
      );
      final filters = SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            FilterChip(
              selected: favoritesOnly,
              onSelected: onFavoritesChanged,
              avatar: const Icon(AhdashIcons.favorite, size: 16),
              label: const Text('المفضلة'),
            ),
            const SizedBox(width: 6),
            FilterChip(
              selected: mediaOnly,
              onSelected: onMediaChanged,
              avatar: const Icon(AhdashIcons.image, size: 16),
              label: const Text('مرئية وصوتية'),
            ),
            const SizedBox(width: 6),
            FilterChip(
              selected: specialOnly,
              onSelected: onSpecialChanged,
              avatar: const Icon(AhdashIcons.premium, size: 16),
              label: const Text('ألعاب خاصة'),
            ),
            for (final collection in collections) ...[
              const SizedBox(width: 6),
              ChoiceChip(
                selected: selectedCollectionId == collection.id,
                onSelected: (selected) =>
                    onCollectionChanged(selected ? collection.id : null),
                label: Text(collection.labelAr),
              ),
            ],
          ],
        ),
      );
      final order = PopupMenuButton<CategorySort>(
        initialValue: sort,
        tooltip: 'ترتيب الأقسام',
        onSelected: onSortChanged,
        itemBuilder: (_) => const [
          PopupMenuItem(value: CategorySort.editorial, child: Text('تحريري')),
          PopupMenuItem(value: CategorySort.newest, child: Text('الأحدث')),
          PopupMenuItem(
            value: CategorySort.popular,
            child: Text('الأكثر لعبًا'),
          ),
          PopupMenuItem(
            value: CategorySort.recommended,
            child: Text('المقترحة'),
          ),
        ],
        child: AhdashBadge(
          label: '$resultCount قسم',
          color: context.ahdashColors.primary,
        ),
      );
      if (constraints.maxWidth < 680) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 48, child: search),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: filters),
                order,
              ],
            ),
          ],
        );
      }
      return SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(width: 300, child: search),
            const SizedBox(width: 10),
            Expanded(child: filters),
            const SizedBox(width: 8),
            order,
          ],
        ),
      );
    },
  );
}

final class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.favorites,
    required this.onFavorite,
    required this.onTap,
  });

  final List<QuizCategory> categories;
  final Set<String> favorites;
  final ValueChanged<String> onFavorite;
  final ValueChanged<QuizCategory> onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'كل الأقسام المطابقة ظاهرة في البطاقة المميزة.',
          style: TextStyle(color: context.ahdashColors.textMuted),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 440
            ? 2
            : 1;
        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            childAspectRatio: columns == 1 ? 2.1 : 1.46,
          ),
          itemBuilder: (_, index) {
            final category = categories[index];
            return _CategoryTile(
              category,
              favorite: favorites.contains(category.id),
              onFavorite: () => onFavorite(category.id),
              onTap: () => onTap(category),
            );
          },
        );
      },
    );
  }
}

final class _FeaturedCategory extends StatelessWidget {
  const _FeaturedCategory({
    required this.category,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final QuizCategory category;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => AhdashImage(
            imageUrl: category.imageUrl,
            alignment: category.focalAlignment,
            fallbackAsset: 'assets/visuals/eagle-eye-cover.png',
            aspectRatio: constraints.maxWidth / constraints.maxHeight,
            borderRadius: 0,
            semanticLabel: category.name,
          ),
        ),
        const DecoratedBox(decoration: BoxDecoration(gradient: _cardGradient)),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AhdashBadge(
                    label: 'اختيار مميز',
                    color: AppColors.gold,
                  ),
                  const Spacer(),
                  _FavoriteButton(favorite: favorite, onPressed: onFavorite),
                ],
              ),
              const Spacer(),
              Text(
                category.seasonLabel ?? 'تحدي أحدعش',
                style: const TextStyle(
                  color: Color(0xFFE8DCC8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFFFBF7EF),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                category.description.isEmpty
                    ? 'افتح المعاينة واعرف أنماط الأسئلة قبل اللعب.'
                    : category.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFDDCEB5), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _CategoryTile extends StatelessWidget {
  const _CategoryTile(
    this.category, {
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final QuizCategory category;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Stack(
      fit: StackFit.expand,
      children: [
        AhdashImage(
          imageUrl: category.imageUrl,
          alignment: category.focalAlignment,
          fallbackAsset: 'assets/visuals/eagle-eye-cover.png',
          aspectRatio: 1.55,
          borderRadius: 0,
          semanticLabel: category.name,
        ),
        const DecoratedBox(decoration: BoxDecoration(gradient: _cardGradient)),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.seasonLabel ?? (category.isNew ? 'جديد' : 'كرة القدم'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFDDCEB5), fontSize: 9),
              ),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFBF7EF),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (category.questionFormats.isNotEmpty)
                Text(
                  '${category.questionFormats.length} أنماط سؤال',
                  style: const TextStyle(color: Color(0xFFDDCEB5), fontSize: 8),
                ),
            ],
          ),
        ),
        PositionedDirectional(
          top: 7,
          end: 7,
          child: _FavoriteButton(favorite: favorite, onPressed: onFavorite),
        ),
      ],
    ),
  );
}

final class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.favorite, required this.onPressed});

  final bool favorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: favorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    iconSize: 18,
    icon: Icon(favorite ? AhdashIcons.favoriteSelected : AhdashIcons.favorite),
  );
}

final class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({
    required this.category,
    required this.favorite,
    required this.onFavorite,
    required this.onSolo,
    required this.onGroup,
  });

  final QuizCategory category;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onSolo;
  final VoidCallback onGroup;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: favorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                onPressed: onFavorite,
                icon: Icon(
                  favorite
                      ? AhdashIcons.favoriteSelected
                      : AhdashIcons.favorite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            category.description.isEmpty
                ? 'قسم جاهز للجولة الفردية أو ضمن ستة أقسام في اللعب الجماعي.'
                : category.description,
            style: TextStyle(color: context.ahdashColors.textSecondary),
          ),
          if (category.gameplayInstructions?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              category.gameplayInstructions!,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              AhdashBadge(
                label: category.accessTier == 'free' ? 'متاح' : 'ضمن الباقة',
                color: category.accessTier == 'free'
                    ? context.ahdashColors.primary
                    : AppColors.gold,
              ),
              for (final format in category.questionFormats.take(5))
                Chip(label: Text(_formatLabel(format))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGroup,
                  icon: const Icon(AhdashIcons.group),
                  label: const Text('ضمن جولة جماعية'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSolo,
                  icon: const Icon(AhdashIcons.play),
                  label: const Text('ابدأ فردي'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  String _formatLabel(String format) => switch (format) {
    'multiple_choice' => 'اختيارات',
    'true_false' => 'صح أو خطأ',
    'image' || 'image_crop' || 'image_blur' => 'صورة',
    'audio' => 'صوت',
    'video' => 'فيديو',
    'ordering' => 'ترتيب',
    'drawing' => 'رسم',
    'charades' => 'تمثيل',
    _ => 'إجابة مفتوحة',
  };
}

const _cardGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Colors.transparent, Color(0xED191714)],
  stops: [0.2, 1],
);
