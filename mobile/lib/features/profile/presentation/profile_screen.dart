import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/social_identity.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../premium/presentation/premium_access_provider.dart';
import '../domain/player_profile.dart';
import 'profile_controller.dart';

final class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    return AhdashUtilityScaffold(
      title: 'ملفي الكروي',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'الإعدادات',
          onPressed: () => context.push('/settings'),
        ),
      ],
      child: profile.when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AppMessageState(
          title: 'الملف غير متاح الآن',
          message: 'سجّل دخولك وتحقق من الاتصال لعرض بيانات حسابك.',
          actionLabel: 'أعد المحاولة',
          onAction: () => ref.invalidate(playerProfileProvider),
        ),
        data: (value) => _ProfileBody(
          profile: value,
          premium:
              value.isPremium ||
              (ref.watch(premiumAccessProvider).value?.hasAccess ?? false),
        ),
      ),
    );
  }
}

final class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.premium});
  final PlayerProfile profile;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final club = profile.showFootballPreferences
        ? profile.favoriteClubData
        : null;
    final league = profile.showFootballPreferences
        ? profile.favoriteLeagueData
        : null;
    final stats = _ProfileStats.from(profile);
    return ListView(
      key: const ValueKey('profile-scroll'),
      padding: const EdgeInsets.only(
        bottom: AhdashSizing.floatingDockContentInset,
      ),
      children: [
        _PlayerIdentityHero(profile: profile, premium: premium),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ProfileStatsRow(items: stats),
        ],
        const SizedBox(height: 14),
        _FootballIdentityCard(
          club: club,
          league: league,
          preferencesVisible: profile.showFootballPreferences,
          onTap: () => context.push('/football-preferences'),
        ),
        const SizedBox(height: 16),
        const _ProfileSectionTitle(
          title: 'مساحة اللعب',
          subtitle: 'فريقك، ترتيبك، ومنافساتك في مكان واحد',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ProfileDestinationCard(
                icon: Icons.leaderboard_outlined,
                label: 'الترتيب',
                accent: AppColors.primary,
                onTap: () => context.push('/ranking'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileDestinationCard(
                icon: Icons.groups_3_outlined,
                label: 'فريقي',
                accent: AppColors.gold,
                onTap: () => context.push('/teams'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _TournamentDestination(onTap: () => context.push('/tournaments')),
        const SizedBox(height: 8),
        _QuietDestinationRow(
          icon: Icons.block_outlined,
          label: 'اللاعبون المحظورون',
          onTap: () => context.push('/blocked-players'),
        ),
      ],
    );
  }
}

final class _PlayerIdentityHero extends StatelessWidget {
  const _PlayerIdentityHero({required this.profile, required this.premium});

  final PlayerProfile profile;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width <= 370;
    return Container(
      key: const ValueKey('profile-identity-hero'),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.paper3.withValues(alpha: .4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .1),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/visuals/profile_identity_arena_v1.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              excludeFromSemantics: true,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x11191714),
                    Color(0x99191714),
                    Color(0xFF191714),
                  ],
                  stops: [0, .46, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sports_soccer_rounded,
                      size: 15,
                      color: AppColors.brandLime,
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'هوية اللاعب',
                        style: TextStyle(
                          color: AppColors.paper0,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brandLime,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Text(
                        '11',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 64 : 74),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProfilePlayerAvatar(
                      imageUrl: profile.avatarUrl,
                      jerseyColorHex: profile.safeJerseyColor,
                      size: compact ? 72 : 80,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.publicName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 20 : 22,
                              height: 1.3,
                              color: AppColors.paper0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${profile.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.paper3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              _HeroChip(
                                icon: Icons.bolt_rounded,
                                label: 'المستوى ${profile.level}',
                              ),
                              if (premium)
                                const _HeroChip(
                                  icon: Icons.workspace_premium_rounded,
                                  label: 'Premium',
                                  highlighted: true,
                                ),
                            ],
                          ),
                        ],
                      ),
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

final class _ProfilePlayerAvatar extends ConsumerWidget {
  const _ProfilePlayerAvatar({
    required this.imageUrl,
    required this.jerseyColorHex,
    required this.size,
  });

  final String? imageUrl;
  final String? jerseyColorHex;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return AhdashPlayer11Avatar(
        imageUrl: imageUrl,
        jerseyColorHex: jerseyColorHex,
        size: size,
      );
    }
    final variant =
        ref.watch(appPreferencesProvider).value?.player11Variant ??
        Player11Variant.male;
    final jersey = ahdashHexColor(jerseyColorHex);
    final asset = switch (variant) {
      Player11Variant.male => 'assets/player11/player11-male-avatar.png',
      Player11Variant.female => 'assets/player11/player11-female-avatar.png',
    };
    return Semantics(
      container: true,
      image: true,
      label: 'هوية ${variant.labelAr}',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.ink,
          border: Border.all(color: jersey, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .34),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

final class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 7, 4),
    decoration: BoxDecoration(
      color: highlighted
          ? AppColors.gold
          : AppColors.paper0.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(99),
      border: highlighted
          ? null
          : Border.all(color: AppColors.paper0.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: highlighted ? AppColors.ink : AppColors.primary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: highlighted ? AppColors.ink : AppColors.paper0,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

final class _FootballIdentityCard extends StatelessWidget {
  const _FootballIdentityCard({
    required this.club,
    required this.league,
    required this.preferencesVisible,
    required this.onTap,
  });

  final ProfileFootballChoice? club;
  final ProfileFootballChoice? league;
  final bool preferencesVisible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.paper1,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.hairline),
      borderRadius: BorderRadius.circular(20),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 17),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'هويتي الكروية',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
                  decoration: BoxDecoration(
                    color: AppColors.paper0,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تعديل',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.edit_outlined, size: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.paper0,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                children: [
                  AhdashClubBadge(
                    label: club?.badgeText ?? club?.nameAr ?? '11',
                    colorHex: club?.primaryColor,
                    logoUrl:
                        club != null &&
                            const [
                              'licensed',
                              'custom',
                            ].contains(club!.visualStatus)
                        ? club!.logoUrl
                        : null,
                    size: 46,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club?.nameAr ??
                              (preferencesVisible
                                  ? 'اختر ناديك المفضل'
                                  : 'اختياراتك خاصة'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          league?.nameAr ??
                              (preferencesVisible
                                  ? 'خصص تجربتك الكروية'
                                  : 'يمكنك التحكم في ظهورها'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
      ),
    ],
  );
}

final class _ProfileDestinationCard extends StatelessWidget {
  const _ProfileDestinationCard({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.paper1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.hairline),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 78,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.ink),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
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

final class _TournamentDestination extends StatelessWidget {
  const _TournamentDestination({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.ink,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 12, 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 21,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بطولاتي',
                    style: TextStyle(
                      color: AppColors.paper0,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'تابع مشاركاتك ونتائجك',
                    style: TextStyle(color: AppColors.paper3, fontSize: 10),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.paper0.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.paper0,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _QuietDestinationRow extends StatelessWidget {
  const _QuietDestinationRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 12,
            color: AppColors.inkMuted,
          ),
        ],
      ),
    ),
  );
}

final class _ProfileStat {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;
}

abstract final class _ProfileStats {
  static List<_ProfileStat> from(PlayerProfile profile) => [
    if (profile.availableStats.contains('matches'))
      _ProfileStat(label: 'مباراة', value: '${profile.matches}'),
    if (profile.availableStats.contains('wins'))
      _ProfileStat(label: 'فوز', value: '${profile.wins}'),
    if (profile.availableStats.contains('tournaments_won'))
      _ProfileStat(label: 'بطولة', value: '${profile.tournamentsWon}'),
    if (profile.availableStats.contains('questions_answered'))
      _ProfileStat(label: 'إجابة', value: '${profile.questionsAnswered}'),
  ];
}

final class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({required this.items});

  final List<_ProfileStat> items;

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    child: Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0)
            Container(width: 1, height: 30, color: AppColors.hairline),
          Expanded(
            child: Column(
              children: [
                Text(
                  items[index].value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  items[index].label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
