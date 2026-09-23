import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/social_identity.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../domain/football_entities.dart';
import 'football_preferences_controller.dart';

final class FootballPreferencesScreen extends ConsumerWidget {
  const FootballPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AhdashUtilityScaffold(
    title: 'تفضيلاتي الكروية',
    fallback: '/profile',
    headerHeight: 51,
    child: ref
        .watch(footballPreferencesProvider)
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const _FootballLoading(),
          error: (_, _) => _FootballError(
            onRetry: () => ref.invalidate(footballPreferencesProvider),
          ),
          data: (value) => _FootballPicker(value: value),
        ),
  );
}

final class _FootballPicker extends ConsumerStatefulWidget {
  const _FootballPicker({required this.value});

  final FootballView value;

  @override
  ConsumerState<_FootballPicker> createState() => _FootballPickerState();
}

final class _FootballPickerState extends ConsumerState<_FootballPicker> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.value.query);
  }

  @override
  void didUpdateWidget(covariant _FootballPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_search.text != widget.value.query) {
      _search.value = TextEditingValue(
        text: widget.value.query,
        selection: TextSelection.collapsed(offset: widget.value.query.length),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final controller = ref.read(footballPreferencesProvider.notifier);
    final league = value.leagues
        .where((item) => item.id == value.leagueId)
        .firstOrNull;
    final club = value.clubs
        .where((item) => item.id == value.clubId)
        .firstOrNull;
    // Scaffold consumes the inset before building its body, so the nested
    // MediaQuery reports zero while the platform view still knows the keyboard
    // is open. Use the view only to select the compact presentation; the
    // scaffold continues to own the actual inset and avoids double padding.
    final keyboard = View.of(context).viewInsets.bottom > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('football-keyboard-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: 12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (keyboard)
                  _SelectionStatus(league: league, club: club)
                else
                  _FootballHero(league: league, club: club),
                const SizedBox(height: 18),
                const _StepHeading(
                  step: '01',
                  title: 'اختر الدوري',
                  helper: 'حدد المسابقة التي تتابعها أكثر.',
                ),
                const SizedBox(height: 9),
                _LeagueRail(
                  leagues: value.leagues,
                  selectedId: value.leagueId,
                  enabled: !value.saving,
                  onSelect: controller.chooseLeague,
                ),
                const SizedBox(height: 19),
                const _StepHeading(
                  step: '02',
                  title: 'اختر ناديك',
                  helper: 'اختيار واحد ويمكن تغييره بأي وقت.',
                ),
                const SizedBox(height: 9),
                if (league == null)
                  const _SelectLeaguePrompt()
                else ...[
                  TextField(
                    key: const ValueKey('football-search-field'),
                    controller: _search,
                    enabled: !value.saving,
                    onChanged: controller.scheduleSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'ابحث داخل ${league.nameAr}',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.inkMuted,
                      ),
                      suffixIcon: value.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: value.saving
                                  ? null
                                  : () {
                                      _search.clear();
                                      controller.scheduleSearch('');
                                    },
                              icon: const Icon(Icons.close_rounded, size: 19),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: const BorderSide(color: AppColors.hairline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: const BorderSide(color: AppColors.hairline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: const BorderSide(
                          color: AppColors.palm,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  if (value.searching)
                    const _ClubGridLoading()
                  else if (value.clubs.isEmpty)
                    _FootballEmpty(
                      search: value.query.isNotEmpty,
                      onClear: value.query.isEmpty
                          ? null
                          : () {
                              _search.clear();
                              controller.scheduleSearch('');
                            },
                    )
                  else
                    _ClubGrid(
                      clubs: value.clubs,
                      selectedId: value.clubId,
                      enabled: !value.saving,
                      onSelect: (id) =>
                          controller.chooseClub(value.clubId == id ? null : id),
                    ),
                  const SizedBox(height: 13),
                  _VisibilityCard(
                    value: value.showPublicly,
                    enabled: !value.saving,
                    onChanged: controller.visibility,
                  ),
                ],
                if (value.message != null) ...[
                  const SizedBox(height: 10),
                  _FootballMessage(value.message!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        AhdashV10PrimaryButton(
          key: const ValueKey('football-save'),
          icon: Icons.check_rounded,
          label: value.canSave ? 'حفظ الاختيارات' : 'سجّل دخولك للحفظ',
          loading: value.saving,
          onPressed: value.canSave && !value.saving ? controller.save : null,
        ),
      ],
    );
  }
}

final class _FootballHero extends StatelessWidget {
  const _FootballHero({this.league, this.club});

  final FootballLeague? league;
  final FootballClub? club;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    final completed = club != null
        ? 2
        : league != null
        ? 1
        : 0;
    return Container(
      key: const ValueKey('football-hero'),
      constraints: BoxConstraints(minHeight: largeText ? 190 : 150),
      padding: const EdgeInsets.all(17),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF214B3B), Color(0xFF143127), Color(0xFF101914)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF356650)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ProgressPill(completed: completed),
                    const SizedBox(height: 10),
                    Text(
                      club?.nameAr ?? 'هويتك الكروية',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.paper0,
                        fontSize: 21,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      league?.nameAr ?? 'اختر الدوري ثم النادي.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.paper0.withValues(alpha: .7),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _FootballIdentityArtwork(),
            ],
          ),
        ],
      ),
    );
  }
}

final class _FootballIdentityArtwork extends StatelessWidget {
  const _FootballIdentityArtwork();

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('football-hero-artwork'),
    width: 102,
    height: 112,
    child: ExcludeSemantics(
      child: Image.asset(
        'assets/visuals/football_identity_crest_v1.png',
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.high,
        cacheWidth: 360,
      ),
    ),
  );
}

final class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.completed});

  final int completed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 2; index++) ...[
          Container(
            width: index < completed ? 14 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: index < completed
                  ? AppColors.primary
                  : AppColors.paper0.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          if (index == 0) const SizedBox(width: 4),
        ],
        const SizedBox(width: 7),
        Text(
          '$completed/2',
          textDirection: TextDirection.ltr,
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

final class _SelectionStatus extends StatelessWidget {
  const _SelectionStatus({this.league, this.club});

  final FootballLeague? league;
  final FootballClub? club;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('football-keyboard-status'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF5D7),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primary),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.sports_soccer_rounded,
          size: 17,
          color: AppColors.palm,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            club?.nameAr ?? league?.nameAr ?? 'ابدأ باختيار الدوري',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

final class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.step,
    required this.title,
    required this.helper,
  });

  final String step;
  final String title;
  final String helper;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          step,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 1),
            Text(
              helper,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _LeagueRail extends StatelessWidget {
  const _LeagueRail({
    required this.leagues,
    required this.selectedId,
    required this.enabled,
    required this.onSelect,
  });

  final List<FootballLeague> leagues;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (leagues.isEmpty) return const _FootballEmpty(search: false);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        key: const ValueKey('football-league-rail'),
        scrollDirection: Axis.horizontal,
        itemCount: leagues.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final league = leagues[index];
          final selected = league.id == selectedId;
          return Semantics(
            button: true,
            selected: selected,
            label: league.nameAr,
            child: Material(
              color: selected ? AppColors.ink : AppColors.paper1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: selected ? AppColors.ink : AppColors.hairline,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? () => onSelect(league.id) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AhdashClubBadge(
                        label: league.badgeText,
                        colorHex: league.primaryColor,
                        logoUrl: league.safeLogoUrl,
                        size: 26,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        league.nameAr,
                        style: TextStyle(
                          color: selected ? AppColors.paper0 : AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

final class _ClubGrid extends StatelessWidget {
  const _ClubGrid({
    required this.clubs,
    required this.selectedId,
    required this.enabled,
    required this.onSelect,
  });

  final List<FootballClub> clubs;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(14);
    final extent = scaled >= 22
        ? 158.0
        : scaled >= 18
        ? 142.0
        : 126.0;
    return GridView.builder(
      key: const ValueKey('football-club-grid'),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: clubs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: extent,
      ),
      itemBuilder: (_, index) {
        final club = clubs[index];
        return _ClubChoice(
          club: club,
          selected: selectedId == club.id,
          onTap: enabled ? () => onSelect(club.id) : null,
        );
      },
    );
  }
}

final class _ClubChoice extends StatelessWidget {
  const _ClubChoice({required this.club, required this.selected, this.onTap});

  final FootballClub club;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clubColor = ahdashHexColor(club.primaryColor);
    return Semantics(
      button: true,
      selected: selected,
      label: club.nameAr,
      child: Material(
        color: selected
            ? Color.alphaBlend(
                clubColor.withValues(alpha: .12),
                AppColors.paper0,
              )
            : AppColors.paper0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
          side: BorderSide(
            color: selected ? clubColor : AppColors.hairline,
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              PositionedDirectional(
                end: -18,
                bottom: -22,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: clubColor.withValues(alpha: .07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AhdashClubBadge(
                      label: club.badgeText,
                      colorHex: club.primaryColor,
                      logoUrl: club.safeLogoUrl,
                      size: 54,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      club.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                PositionedDirectional(
                  top: 9,
                  start: 9,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: clubColor,
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('football-visibility'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: AppColors.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إظهار النادي في ملفك',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 2),
              Text(
                'يمكن للأصدقاء رؤية اختيارك.',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeTrackColor: AppColors.primary,
        ),
      ],
    ),
  );
}

final class _SelectLeaguePrompt extends StatelessWidget {
  const _SelectLeaguePrompt();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('football-select-league-prompt'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.hairline),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.ink,
          child: Icon(Icons.sports_soccer_rounded, color: AppColors.primary),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'اختر دوريًا لعرض أنديته.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

final class _FootballEmpty extends StatelessWidget {
  const _FootballEmpty({required this.search, this.onClear});

  final bool search;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey(search ? 'football-search-empty' : 'football-empty'),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Column(
      children: [
        Icon(
          search ? Icons.search_off_rounded : Icons.sports_soccer_outlined,
          size: 30,
          color: AppColors.palm,
        ),
        const SizedBox(height: 7),
        Text(
          search ? 'لا توجد نتائج' : 'لا توجد دوريات منشورة الآن',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        if (onClear != null) ...[
          const SizedBox(height: 5),
          TextButton(onPressed: onClear, child: const Text('مسح البحث')),
        ],
      ],
    ),
  );
}

final class _ClubGridLoading extends StatelessWidget {
  const _ClubGridLoading();

  @override
  Widget build(BuildContext context) => GridView.builder(
    key: const ValueKey('football-clubs-loading'),
    shrinkWrap: true,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 4,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      mainAxisExtent: 118,
    ),
    itemBuilder: (_, _) => Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.paper1,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.paper3,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 70,
            height: 9,
            decoration: BoxDecoration(
              color: AppColors.paper3,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _FootballMessage extends StatelessWidget {
  const _FootballMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final success = message.contains('حُفظت');
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: success ? const Color(0xFFE9F5D7) : const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: success ? AppColors.primary : AppColors.danger,
          ),
        ),
        child: Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.info_outline_rounded,
              size: 18,
              color: success ? AppColors.palm : AppColors.danger,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _FootballLoading extends StatelessWidget {
  const _FootballLoading();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FootballHero(),
        const SizedBox(height: 18),
        Container(
          key: const ValueKey('football-loading'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paper1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.hairline),
          ),
          child: const Row(
            children: [
              SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'نجهّز الدوريات والأندية…',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _FootballError extends StatelessWidget {
  const _FootballError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      key: const ValueKey('football-error'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.paper1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.ink,
            child: Icon(
              Icons.cloud_off_rounded,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'تعذر تحميل الاختيارات',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'تحقق من الاتصال وحاول مرة أخرى.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

final class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.paper0.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(
      Offset(size.width * .48, size.height * .5),
      size.shortestSide * .22,
      line,
    );
    canvas.drawLine(
      Offset(size.width * .48, 0),
      Offset(size.width * .48, size.height),
      line,
    );
    canvas.drawCircle(
      Offset(size.width * .12, size.height * .18),
      58,
      Paint()..color = AppColors.primary.withValues(alpha: .045),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
