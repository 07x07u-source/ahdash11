import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/domain/category.dart';
import '../../../shared/presentation/ahdash_image.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../categories/presentation/categories_controller.dart';

final class SoloHomeScreen extends ConsumerStatefulWidget {
  const SoloHomeScreen({this.initialCategoryId, super.key});

  final String? initialCategoryId;

  @override
  ConsumerState<SoloHomeScreen> createState() => _SoloHomeScreenState();
}

final class _SoloHomeScreenState extends ConsumerState<SoloHomeScreen> {
  final _categorySearchController = TextEditingController();
  String _categoryQuery = '';
  int _selectedMode = 0;

  @override
  void dispose() {
    _categorySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final availableCategories = categories.asData?.value ?? const [];
    final filteredCategories = _filterCategories(availableCategories);
    return AhdashV10Page(
      title: 'اللعب لحالك',
      subtitle: 'جولتك، تركيزك، ونتيجتك على مقاسك',
      onBack: () => context.go('/play'),
      child: ListView(
        key: const ValueKey('solo-home-scroll'),
        padding: const EdgeInsets.only(
          bottom: AhdashSizing.floatingDockContentInset,
        ),
        children: [
          _SoloCommandHero(
            onStart: () {
              final suffix = widget.initialCategoryId == null
                  ? ''
                  : '?categoryId=${Uri.encodeQueryComponent(widget.initialCategoryId!)}';
              context.push('/solo/setup$suffix');
            },
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _SoloMetric(value: '11', label: 'سؤال في الجولة'),
              SizedBox(width: 8),
              _SoloMetric(value: '15ث', label: 'وقت الإجابة'),
              SizedBox(width: 8),
              _SoloMetric(value: '3', label: 'مستويات صعوبة'),
            ],
          ),
          const SizedBox(height: 22),
          const _SoloSectionHeading(
            title: 'اختر مزاج الجولة',
            subtitle: 'اضبط التفاصيل قبل أن تبدأ الإحماء',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SoloModeCard(
                  icon: Icons.bolt_rounded,
                  title: 'كلاسيكي',
                  subtitle: '11 سؤالًا متوازنًا',
                  selected: _selectedMode == 0,
                  onTap: () => setState(() => _selectedMode = 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SoloModeCard(
                  icon: Icons.speed_rounded,
                  title: 'تحدي السرعة',
                  subtitle: 'قريبًا في موسم جديد',
                  selected: _selectedMode == 1,
                  onTap: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تحدي السرعة قريبًا. ابدأ بالجولة الكلاسيكية الآن.',
                          ),
                        ),
                      );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: _SoloSectionHeading(
                  title: 'الأقسام المتاحة',
                  subtitle: 'اختر قسمًا الآن أو عدّل اختيارك في الإعداد',
                ),
              ),
              TextButton(
                onPressed: () => context.push('/categories'),
                child: const Text('كل الأقسام'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (availableCategories.isNotEmpty) ...[
            _SoloCategorySearchField(
              controller: _categorySearchController,
              onChanged: (value) => setState(() => _categoryQuery = value),
              onClear: () {
                _categorySearchController.clear();
                setState(() => _categoryQuery = '');
              },
            ),
            const SizedBox(height: 10),
          ],
          categories.when(
            loading: () => const _SoloLoadingStrip(),
            error: (_, _) => AppMessageState(
              icon: Icons.cloud_off_rounded,
              title: 'الأقسام غير متاحة الآن',
              message: 'يمكنك العودة والمحاولة مجددًا عند توفر الاتصال.',
              actionLabel: 'إعادة المحاولة',
              onAction: () => ref.read(categoriesProvider.notifier).refresh(),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const _SoloEmptyStrip();
              }
              if (filteredCategories.isEmpty) {
                return _SoloNoSearchResults(
                  query: _categoryQuery,
                  onClear: () {
                    _categorySearchController.clear();
                    setState(() => _categoryQuery = '');
                  },
                );
              }
              return SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredCategories.length.clamp(0, 8).toInt(),
                  separatorBuilder: (_, _) => const SizedBox(width: 9),
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    return _SoloCategoryPreview(
                      name: category.name,
                      imageUrl: category.imageUrl,
                      accent: category.accentColor,
                      selected: category.id == widget.initialCategoryId,
                      onTap: () => context.push(
                        '/solo/setup?categoryId=${Uri.encodeQueryComponent(category.id)}',
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          const _SoloJourneyCard(),
          const SizedBox(height: 12),
          const _SoloPromiseCard(),
        ],
      ),
    );
  }

  List<QuizCategory> _filterCategories(List<QuizCategory> items) {
    final query = _categoryQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where((item) => item.name.toString().toLowerCase().contains(query))
        .toList(growable: false);
  }
}

final class _SoloCommandHero extends StatelessWidget {
  const _SoloCommandHero({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    height: 202,
    decoration: BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(25),
      boxShadow: const [
        BoxShadow(
          color: Color(0x29191714),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const Image(
          image: AssetImage('assets/visuals/solo_training_hero.png'),
          fit: BoxFit.cover,
          alignment: Alignment(-.2, .02),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0x14191714), Color(0xF2191714)],
              stops: [.1, .85],
            ),
          ),
        ),
        PositionedDirectional(
          top: 15,
          start: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.paper0.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.paper0.withValues(alpha: .2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 5),
                Text(
                  'ملعبك الخاص',
                  style: TextStyle(
                    color: AppColors.paper0,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          start: 16,
          end: 16,
          bottom: 15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'خلّ تركيزك يتكلم',
                style: TextStyle(
                  color: AppColors.paper0,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'اختر الفئات والصعوبة ثم ابدأ سباقك مع الوقت.',
                style: TextStyle(color: AppColors.paper3, fontSize: 11),
              ),
              const SizedBox(height: 11),
              SizedBox(
                height: 42,
                child: FilledButton.icon(
                  key: const ValueKey('solo-home-start'),
                  onPressed: onStart,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('ابدأ جولة جديدة'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _SoloMetric extends StatelessWidget {
  const _SoloMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.paper1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 8.5),
          ),
        ],
      ),
    ),
  );
}

final class _SoloSectionHeading extends StatelessWidget {
  const _SoloSectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 10),
      ),
    ],
  );
}

final class _SoloModeCard extends StatelessWidget {
  const _SoloModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$title، $subtitle',
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 104,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.paper1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? AppColors.primary : AppColors.inkMuted,
                    size: 22,
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: selected ? AppColors.paper0 : AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.paper3 : AppColors.inkMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _SoloCategoryPreview extends StatelessWidget {
  const _SoloCategoryPreview({
    required this.name,
    required this.imageUrl,
    required this.accent,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final String? imageUrl;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 136,
    child: Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AhdashImage(
              imageUrl: imageUrl,
              aspectRatio: 1.35,
              fallbackWidget: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, AppColors.ink],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x10191714), Color(0xE6191714)],
                ),
              ),
            ),
            PositionedDirectional(
              start: 10,
              end: 10,
              bottom: 9,
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.paper0,
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              const PositionedDirectional(
                top: 8,
                end: 8,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

final class _SoloLoadingStrip extends StatelessWidget {
  const _SoloLoadingStrip();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 112,
    child: Center(child: CircularProgressIndicator()),
  );
}

final class _SoloCategorySearchField extends StatelessWidget {
  const _SoloCategorySearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('solo-category-search'),
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'ابحث عن قسمك المفضل',
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'مسح البحث',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
    ),
  );
}

final class _SoloNoSearchResults extends StatelessWidget {
  const _SoloNoSearchResults({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    child: Row(
      children: [
        const Icon(Icons.search_off_rounded, color: AppColors.inkMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'لا يوجد قسم مطابق لـ “$query”.',
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
          ),
        ),
        TextButton(onPressed: onClear, child: const Text('مسح')),
      ],
    ),
  );
}

final class _SoloJourneyCard extends StatelessWidget {
  const _SoloJourneyCard();

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    backgroundColor: AppColors.paper1,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'رحلة الجولة في ثلاث خطوات',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            _SoloJourneyStep(number: '١', title: 'اختر', subtitle: 'القسم'),
            _SoloJourneyDivider(),
            _SoloJourneyStep(number: '٢', title: 'جاوب', subtitle: 'بتركيز'),
            _SoloJourneyDivider(),
            _SoloJourneyStep(number: '٣', title: 'اعرف', subtitle: 'نتيجتك'),
          ],
        ),
      ],
    ),
  );
}

final class _SoloJourneyStep extends StatelessWidget {
  const _SoloJourneyStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 9),
        ),
      ],
    ),
  );
}

final class _SoloJourneyDivider extends StatelessWidget {
  const _SoloJourneyDivider();

  @override
  Widget build(BuildContext context) =>
      const Expanded(child: Divider(color: AppColors.hairline, thickness: 1));
}

final class _SoloEmptyStrip extends StatelessWidget {
  const _SoloEmptyStrip();

  @override
  Widget build(BuildContext context) => const AhdashV10Panel(
    child: Text(
      'ستظهر الأقسام المنشورة هنا عند جاهزية الكتالوج.',
      style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
    ),
  );
}

final class _SoloPromiseCard extends StatelessWidget {
  const _SoloPromiseCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.paper2,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.hairline),
    ),
    child: const Row(
      children: [
        Icon(Icons.auto_awesome_rounded, color: AppColors.palm),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'لا نملأ الجولة بأسئلة وهمية. إذا لم تتوفر حزمة منشورة، ستظهر لك الحالة بوضوح.',
            style: TextStyle(
              fontSize: 11,
              height: 1.55,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    ),
  );
}
