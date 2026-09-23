import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/v10_portrait.dart';

final class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

final class _PlayScreenState extends ConsumerState<PlayScreen> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) => AhdashV10Page(
    title: 'نوع المنافسة',
    subtitle: 'اختر أسلوب الجولة، والباقي علينا',
    onBack: () => context.go('/home'),
    child: ListView(
      key: const ValueKey('play-mode-scroll'),
      padding: const EdgeInsets.only(
        bottom: AhdashSizing.floatingDockContentInset,
      ),
      children: [
        _CompetitionHero(onStart: _continue),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CompetitionCard(
                selected: _selected == 0,
                icon: Icons.groups_2_rounded,
                eyebrow: 'للمجلس',
                title: 'تحدي الفرق',
                subtitle: 'فريقان · جهاز واحد',
                onTap: () => setState(() => _selected = 0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompetitionCard(
                selected: _selected == 1,
                icon: Icons.person_rounded,
                eyebrow: 'لك وحدك',
                title: 'اللعب الفردي',
                subtitle: 'اختبر معلوماتك',
                onTap: () => setState(() => _selected = 1),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  void _continue() =>
      context.push(_selected == 0 ? '/party/categories' : '/solo');
}

final class _CompetitionHero extends StatelessWidget {
  const _CompetitionHero({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 820;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Container(
      height: largeText ? 220 : (compact ? 190 : 202),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/visuals/solo_competition_hero.png'),
              fit: BoxFit.cover,
              alignment: Alignment(0, .08),
              filterQuality: FilterQuality.medium,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x08191714), Color(0xD9191714)],
                  stops: [.34, 1],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 13,
            start: 13,
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(9, 5, 8, 5),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: .74),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: AppColors.paper0.withValues(alpha: .2),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stadium_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'بوابة اللعب',
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
                  'الملعب ينتظر اختيارك',
                  style: TextStyle(
                    color: AppColors.paper0,
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'اجمع ربعك أو ادخل تحديًا فرديًا على مزاجك.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.paper3, fontSize: 11),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text(
                      'ابدأ اللعب الآن',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
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

final class _CompetitionCard extends StatelessWidget {
  const _CompetitionCard({
    required this.selected,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$title، $subtitle',
    child: Material(
      color: selected ? AppColors.ink : AppColors.paper1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.hairline,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 150 : 128,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.paper2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: AppColors.ink),
                    ),
                    const Spacer(),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: selected ? AppColors.paper3 : AppColors.inkMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.paper0 : AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.paper3 : AppColors.inkMuted,
                    fontSize: 10,
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
