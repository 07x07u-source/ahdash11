import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/social_identity.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import 'football_preferences_controller.dart';

final class FootballPreferencesScreen extends ConsumerWidget {
  const FootballPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AhdashUtilityScaffold(
    title: 'تفضيلاتي الكروية',
    fallback: '/profile',
    headerHeight: 51,
    actions: const [Icon(Icons.search_rounded)],
    child: ref
        .watch(footballPreferencesProvider)
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppMessageState(
            title: 'الاختيارات غير متاحة الآن',
            message: 'تحقق من الاتصال لعرض الدوريات والأندية المنشورة.',
            actionLabel: 'أعد المحاولة',
            onAction: () => ref.invalidate(footballPreferencesProvider),
          ),
          data: (value) => _FootballPicker(value: value),
        ),
  );
}

final class _FootballPicker extends ConsumerWidget {
  const _FootballPicker({required this.value});

  final FootballView value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(footballPreferencesProvider.notifier);
    final league = value.leagues
        .where((item) => item.id == value.leagueId)
        .firstOrNull;
    final itemCount = league == null
        ? value.leagues.length
        : value.clubs.length;
    return SingleChildScrollView(
      key: const ValueKey('football-keyboard-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 35,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: value.leagues.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final item = value.leagues[index];
                final selected = item.id == value.leagueId;
                return ChoiceChip(
                  label: Text(item.nameAr),
                  selected: selected,
                  onSelected: value.saving
                      ? null
                      : (_) => controller.chooseLeague(item.id),
                  selectedColor: const Color(0xFF1E874B),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF1E874B)
                        : AppColors.hairline,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: TextFormField(
              key: const ValueKey('football-search-field'),
              initialValue: value.query,
              enabled: !value.saving && league != null,
              onChanged: controller.scheduleSearch,
              decoration: const InputDecoration(
                hintText: 'ابحث عن ناديك المفضل...',
                prefixIcon: Icon(Icons.search, color: AppColors.muted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'اختر أنديتك المفضلة للمتابعة والتحدي',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (value.searching)
            const SizedBox(
              height: 238,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (itemCount == 0)
            SizedBox(
              height: 238,
              child: Center(
                child: Text(
                  league == null
                      ? 'لا توجد دوريات منشورة حاليًا.'
                      : 'ما لقينا ناديًا بهذا الاسم. جرّب بحثًا آخر.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent:
                    MediaQuery.sizeOf(context).width >=
                        MediaQuery.sizeOf(context).height
                    ? 120
                    : 115,
              ),
              itemBuilder: (_, index) {
                final id = league == null
                    ? value.leagues[index].id
                    : value.clubs[index].id;
                final name = league == null
                    ? value.leagues[index].nameAr
                    : value.clubs[index].nameAr;
                final badge = league == null
                    ? value.leagues[index].badgeText
                    : value.clubs[index].badgeText;
                final color = league == null
                    ? value.leagues[index].primaryColor
                    : value.clubs[index].primaryColor;
                final logo = league == null
                    ? value.leagues[index].safeLogoUrl
                    : value.clubs[index].safeLogoUrl;
                final selected = league != null && value.clubId == id;
                return _Choice(
                  label: name,
                  badge: badge,
                  color: color,
                  logo: logo,
                  selected: selected,
                  onTap: value.saving
                      ? null
                      : league == null
                      ? () => controller.chooseLeague(id)
                      : () => controller.chooseClub(selected ? null : id),
                );
              },
            ),
          if (value.message != null) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(value.message!, textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(height: 16),
          AhdashV10PrimaryButton(
            label: value.canSave ? 'حفظ التفضيلات الكروية' : 'سجّل دخولك للحفظ',
            loading: value.saving,
            onPressed: value.canSave ? controller.save : null,
          ),
        ],
      ),
    );
  }
}

final class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.badge,
    required this.color,
    required this.logo,
    required this.selected,
    required this.onTap,
  });

  final String label, badge, color;
  final String? logo;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: AhdashV10Panel(
          selected: selected,
          backgroundColor: Colors.white,
          selectedBackgroundColor: const Color(0xFFE8F7EE),
          selectedBorderColor: const Color(0xFF1E874B),
          onTap: onTap,
          semanticLabel: label,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 55,
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: logo == null
                    ? const Icon(Icons.shield_outlined, size: 28)
                    : AhdashClubBadge(
                        label: badge,
                        colorHex: color,
                        logoUrl: logo,
                        size: 42,
                      ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.ink : AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
      if (selected)
        const PositionedDirectional(
          top: 10,
          start: 10,
          child: CircleAvatar(
            radius: 9,
            backgroundColor: Color(0xFF1E874B),
            child: Icon(Icons.check, color: Colors.white, size: 13),
          ),
        ),
    ],
  );
}
