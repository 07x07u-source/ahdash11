import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/v10_portrait.dart';

final class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

final class _PlayScreenState extends ConsumerState<PlayScreen> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper0,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: ListView(
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'نوع المنافسة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: IconButton(
                          onPressed: () => context.go('/home'),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.paper1,
                            minimumSize: const Size.square(36),
                            maximumSize: const Size.square(36),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(minHeight: 220),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E874B),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF39A765),
                            child: Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'نمط الجولة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اختر كيف ودك تلعب، ثم نجهّز لك الجولة المناسبة.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _continue,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('ابدأ اللعب الآن'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CompetitionCard(
                        selected: _selected == 0,
                        icon: Icons.groups_2_outlined,
                        title: 'تحدي الفرق',
                        subtitle: 'اللعبة الجماعية',
                        onTap: () => setState(() => _selected = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CompetitionCard(
                        selected: _selected == 1,
                        icon: Icons.person_outline_rounded,
                        title: 'اللعب الفردي',
                        subtitle: 'اختبر معلوماتك',
                        onTap: () => setState(() => _selected = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'أونلاين (قريبًا)',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const AhdashV10Panel(
                  semanticLabel: 'مباراة عشوائية سريعة، قريبًا وغير متاحة',
                  child: Row(
                    children: [
                      Icon(Icons.public_off_rounded, color: AppColors.muted),
                      SizedBox(width: 12),
                      Expanded(child: Text('مباراة عشوائية سريعة')),
                      Chip(label: Text('قريبًا')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _continue() =>
      context.push(_selected == 0 ? '/party/categories' : '/solo');
}

final class _CompetitionCard extends StatelessWidget {
  const _CompetitionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    selected: selected,
    onTap: onTap,
    semanticLabel: '$title، $subtitle',
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 112),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: selected ? const Color(0xFF1E874B) : AppColors.ink),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
