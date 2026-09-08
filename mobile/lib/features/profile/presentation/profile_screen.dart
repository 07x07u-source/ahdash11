import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
    return ListView(
      key: const ValueKey('profile-scroll'),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.ink),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: 126,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(child: _PitchBanner()),
                    const PositionedDirectional(
                      top: 14,
                      start: 16,
                      child: Text(
                        'PLAYER CARD / 11',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          letterSpacing: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AhdashPlayer11Avatar(
                      imageUrl: profile.avatarUrl,
                      jerseyColorHex: profile.safeJerseyColor,
                      size: 80,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Text(
                      profile.publicName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.3,
                        color: AppColors.paper0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${profile.username}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: AppColors.paper3),
                    ),
                    if (premium) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_outlined, size: 15),
                            SizedBox(width: 4),
                            Text(
                              'Premium مفعّل',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AhdashV10Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ناديّ المفضل',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  AhdashClubBadge(
                    label: club?.badgeText ?? club?.nameAr ?? '11',
                    colorHex: club?.primaryColor,
                    logoUrl:
                        club != null &&
                            const [
                              'licensed',
                              'custom',
                            ].contains(club.visualStatus)
                        ? club.logoUrl
                        : null,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club?.nameAr ??
                              (profile.showFootballPreferences
                                  ? 'لم تحدد ناديًا بعد'
                                  : 'اختياراتك خاصة'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (league != null)
                          Text(
                            league.nameAr,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push('/football-preferences'),
                child: const Text('إدارة تفضيلاتي الكروية'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AhdashV10Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ربعك وفريقك',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              _SocialDestinationRow(
                icon: Icons.people_alt_outlined,
                label: 'الأصدقاء والطلبات',
                onTap: () => context.push('/friends'),
              ),
              _SocialDestinationRow(
                icon: Icons.groups_3_outlined,
                label: 'فريقي',
                onTap: () => context.push('/teams'),
              ),
              _SocialDestinationRow(
                icon: Icons.block_outlined,
                label: 'اللاعبون المحظورون',
                onTap: () => context.push('/blocked-players'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.push('/tournaments'),
          child: const Text('بطولاتي'),
        ),
      ],
    );
  }
}

final class _SocialDestinationRow extends StatelessWidget {
  const _SocialDestinationRow({
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
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
        ],
      ),
    ),
  );
}

final class _PitchBanner extends StatelessWidget {
  const _PitchBanner();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PitchPainter(), child: const SizedBox.expand());
}

final class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.ink);
    final line = Paint()
      ..color = AppColors.paper3.withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final field = Rect.fromLTWH(42, 10, size.width - 84, size.height + 28);
    canvas.drawRect(field, line);
    canvas.drawLine(
      Offset(size.width / 2, field.top),
      Offset(size.width / 2, field.bottom),
      line,
    );
    canvas.drawCircle(Offset(size.width / 2, field.center.dy), 19, line);
    for (final x in [field.left, field.right]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, field.center.dy),
          width: 42,
          height: 48,
        ),
        line,
      );
    }
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .28),
      36,
      Paint()..color = AppColors.primary.withValues(alpha: .14),
    );
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .78),
      28,
      Paint()..color = AppColors.gold.withValues(alpha: .14),
    );
    final route = Path()
      ..moveTo(size.width * .08, size.height * .78)
      ..quadraticBezierTo(
        size.width * .32,
        size.height * .5,
        size.width * .48,
        size.height * .72,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
