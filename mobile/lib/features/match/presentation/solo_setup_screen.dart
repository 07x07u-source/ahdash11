import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/domain/category.dart';
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
    title: 'جهّز تحديك',
    subtitle: '${widget.gameType.titleAr} · إعدادات يدعمها المحرك الحالي',
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
          data: (categories) => categories.isEmpty
              ? const AppMessageState(
                  icon: Icons.sports_soccer_rounded,
                  title: 'لا توجد أقسام متاحة الآن',
                  message: 'ستظهر هنا الأقسام المنشورة الجاهزة للعب.',
                )
              : _body(categories),
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'اختر الأقسام',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                Text('${_selectedCategories.length} محدد'),
              ],
            ),
            const SizedBox(height: 8),
            for (final category in categories) ...[
              AhdashV10Panel(
                selected: _selectedCategories.contains(category.id),
                semanticLabel:
                    '${category.name}، ${_selectedCategories.contains(category.id) ? 'محدد' : 'غير محدد'}',
                onTap: () => _toggle(category.id),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: category.accentColor.withValues(
                        alpha: .18,
                      ),
                      child: const Icon(Icons.sports_soccer_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (_selectedCategories.contains(category.id))
                      const Icon(Icons.check_circle_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            AhdashV10Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'صعوبة الأسئلة',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in QuestionDifficulty.values)
                        ChoiceChip(
                          label: Text(value.arabicLabel),
                          selected: _difficulty == value,
                          onSelected: (_) =>
                              setState(() => _difficulty = value),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const AhdashV10Panel(
              semanticLabel: 'عدد الأسئلة المدعوم 11',
              child: Row(
                children: [
                  Text(
                    '11',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('سؤالًا في الجولة الحالية')),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      if (_selectedCategories.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'اختر قسمًا واحدًا على الأقل.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      AhdashV10PrimaryButton(
        key: const ValueKey('solo-start-primary'),
        label: 'ابدأ التحدي',
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
