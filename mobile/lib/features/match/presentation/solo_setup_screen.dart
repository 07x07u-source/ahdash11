import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/domain/category.dart';
import '../../../shared/presentation/ahdash_image.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../game/domain/game_mode.dart';
import '../domain/quiz_question.dart';
import '../domain/solo_opponent.dart';
import 'solo_match_controller.dart';

final class SoloSetupScreen extends ConsumerStatefulWidget {
  const SoloSetupScreen({
    this.gameType = GameType.classic,
    this.initialCategoryId,
    super.key,
  });

  final GameType gameType;
  final String? initialCategoryId;

  @override
  ConsumerState<SoloSetupScreen> createState() => _SoloSetupScreenState();
}

final class _SoloSetupScreenState extends ConsumerState<SoloSetupScreen> {
  static const _supportedQuestionCount = 11;
  final _selectedCategories = <String>{};
  QuestionDifficulty _difficulty = QuestionDifficulty.medium;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId?.isNotEmpty == true) {
      _selectedCategories.add(widget.initialCategoryId!);
    }
  }

  @override
  Widget build(BuildContext context) => AhdashV10Page(
    title: 'التحدي الفردي',
    subtitle: '${widget.gameType.titleAr} · جولة مصممة على مزاجك',
    onBack: () => context.canPop() ? context.pop() : context.go('/play'),
    child: ref
        .watch(categoriesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppMessageState(
            icon: Icons.sports_soccer_rounded,
            title: 'تعذر تحميل الأقسام',
            message: 'لا يمكن بدء جولة بلا أسئلة منشورة.',
            actionLabel: 'إعادة المحاولة',
            onAction: () => ref.read(categoriesProvider.notifier).refresh(),
          ),
          data: (categories) =>
              categories.isEmpty ? const _SoloEmptyState() : _body(categories),
        ),
  );

  Widget _body(List<QuizCategory> categories) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ListView(
          key: const ValueKey('solo-setup-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _SoloRoundHero(
              gameType: widget.gameType,
              questionCount: _supportedQuestionCount,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر الأقسام',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'تقدر تجمع أكثر من قسم',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _SelectionCount(count: _selectedCategories.length),
              ],
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = _selectedCategories.contains(category.id);
                  return _SoloCategoryCard(
                    category: category,
                    selected: selected,
                    onTap: () => _toggle(category.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'مستوى الصعوبة',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (
                  var index = 0;
                  index < QuestionDifficulty.values.length;
                  index++
                ) ...[
                  if (index > 0) const SizedBox(width: 7),
                  Expanded(
                    child: _DifficultyOption(
                      value: QuestionDifficulty.values[index],
                      selected: _difficulty == QuestionDifficulty.values[index],
                      onTap: () => setState(
                        () => _difficulty = QuestionDifficulty.values[index],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
      if (_selectedCategories.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 15,
                color: AppColors.inkMuted,
              ),
              SizedBox(width: 5),
              Text(
                'اختر قسمًا واحدًا على الأقل.',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      AhdashV10PrimaryButton(
        key: const ValueKey('solo-start-primary'),
        label: 'ابدأ التحدي',
        icon: Icons.arrow_back_rounded,
        onPressed: _selectedCategories.isEmpty ? null : _start,
      ),
      const SizedBox(height: 12),
    ],
  );

  void _toggle(String id) => setState(() {
    if (!_selectedCategories.remove(id)) _selectedCategories.add(id);
  });

  void _start() {
    final request = SoloMatchRequest(
      categoryIds: {..._selectedCategories},
      difficulty: _difficulty,
      questionCount: _supportedQuestionCount,
      opponentLevel: SoloOpponentLevel.medium,
      gameType: widget.gameType,
    );
    unawaited(ref.read(soloMatchControllerProvider.notifier).start(request));
    context.go('/solo/match');
  }
}

final class _SoloRoundHero extends StatelessWidget {
  const _SoloRoundHero({required this.gameType, required this.questionCount});

  final GameType gameType;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 820;
    return Container(
      height: compact ? 142 : 152,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .13),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/visuals/solo_training_hero.png'),
              fit: BoxFit.cover,
              alignment: Alignment(-.22, .02),
              filterQuality: FilterQuality.medium,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x16191714), Color(0xF2191714)],
                  stops: [.1, .82],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 14,
            start: 14,
            end: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'جولتك.. تركيزك.. نتيجتك',
                  style: TextStyle(
                    color: AppColors.paper0,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'اختيارات قليلة، وتحدٍ كروي صافي.',
                  style: TextStyle(color: AppColors.paper3, fontSize: 10),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HeroFact(
                      icon: Icons.help_outline_rounded,
                      label: '$questionCount سؤال',
                    ),
                    _HeroFact(
                      icon: Icons.sports_soccer_rounded,
                      label: gameType.titleAr,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 7, 5),
    decoration: BoxDecoration(
      color: AppColors.paper0.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.paper0.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.paper0,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

final class _SelectionCount extends StatelessWidget {
  const _SelectionCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: count == 0 ? AppColors.paper1 : AppColors.ink,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: count == 0 ? AppColors.hairline : AppColors.ink,
      ),
    ),
    child: Text(
      '$count محدد',
      style: TextStyle(
        color: count == 0 ? AppColors.inkMuted : AppColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

final class _SoloCategoryCard extends StatelessWidget {
  const _SoloCategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final QuizCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${category.name}، ${selected ? 'محدد' : 'غير محدد'}',
    child: Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AhdashImage(
                imageUrl: category.imageUrl,
                aspectRatio: 1.22,
                alignment: category.focalAlignment,
                borderRadius: 0,
                fallbackWidget: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [category.accentColor, AppColors.ink],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sports_soccer_rounded,
                      color: AppColors.paper0,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x10191714), Color(0xF0191714)],
                  ),
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.paper0,
                ),
              ),
              PositionedDirectional(
                start: 10,
                end: 10,
                bottom: 9,
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.paper0,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _DifficultyOption extends StatelessWidget {
  const _DifficultyOption({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final QuestionDifficulty value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'صعوبة ${value.arabicLabel}',
    child: Material(
      color: selected ? AppColors.ink : AppColors.paper1,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.hairline,
            ),
          ),
          child: Text(
            value.arabicLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.paper0 : AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

final class _SoloEmptyState extends StatelessWidget {
  const _SoloEmptyState();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 16),
    children: [
      Container(
        height: 210,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: const Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: AssetImage('assets/visuals/solo_training_hero.png'),
              fit: BoxFit.cover,
              alignment: Alignment(-.2, 0),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00191714), Color(0xD9191714)],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Icon(Icons.schedule_rounded, color: AppColors.palm, size: 30),
      const SizedBox(height: 10),
      const Text(
        'لا توجد أقسام متاحة الآن',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 5),
      const Text(
        'ستظهر هنا الأقسام المنشورة الجاهزة للعب.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
      ),
    ],
  );
}
