import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/brand_identity.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../auth/domain/guest_capability_policy.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/presentation/capability_provider.dart';
import '../../party/presentation/party_game_controller.dart';
import '../../party/presentation/party_setup_flow.dart';
import '../../premium/presentation/premium_visuals.dart';
import '../../tournament/presentation/tournament_controller.dart';

final class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(partyGameControllerProvider.notifier).restore();
      // Do not load a previous account's tournament on the guest Home.
      if (ref
          .read(capabilityPolicyProvider)
          .allows(AppCapability.tournaments)) {
        ref.read(tournamentControllerProvider.notifier).restore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(capabilityPolicyProvider, (previous, next) {
      if (!(previous?.hasAccount ?? false) && next.hasAccount) {
        ref.read(tournamentControllerProvider.notifier).restore();
      }
    });
    final policy = ref.watch(capabilityPolicyProvider);
    final party = ref.watch(partyGameControllerProvider);
    final tournament = ref.watch(tournamentControllerProvider);
    final game = party.session;
    final resumeDraft = party.hasSetupDraft;
    final resumeGame = !resumeDraft && game != null && !game.isComplete;
    final hasPartyResume = resumeDraft || resumeGame;
    final resumeTournament =
        policy.allows(AppCapability.tournaments) &&
        (tournament.active?.canResume ?? false);
    final resumeLabel = hasPartyResume
        ? resumeDraft
              ? 'كمل الإعداد'
              : 'كمل لعبتك'
        : resumeTournament
        ? 'كمل البطولة'
        : null;
    final VoidCallback? resumeAction = resumeDraft
        ? () => context.go('/party/ready')
        : resumeGame
        ? () => context.go(PartySetupFlowResolver.routeForSession(game))
        : resumeTournament
        ? () => _open('/tournaments/bracket')
        : null;
    final gutter = AhdashV10Metrics.of(context).gutter;
    return Scaffold(
      backgroundColor: AppColors.paper0,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ListView(
                key: const ValueKey('home-scroll'),
                padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 16),
                children: [
                  _HomeHeader(policy: policy, onOpen: _open),
                  const SizedBox(height: 14),
                  _PartyHero(
                    canStart: party.restored,
                    resumeLabel: resumeLabel,
                    onStart: () => _requestNewGame(hasPartyResume),
                    onResume: resumeAction,
                  ),
                  const SizedBox(height: 12),
                  _PremiumDiscovery(
                    guest: !policy.hasAccount,
                    onTap: () => _open('/premium'),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('طرق اللعب'),
                  const SizedBox(height: 12),
                  _ModeTile(
                    title: 'أنشئ بطولة',
                    subtitle: 'نظّم الفرق واحسم البطل',
                    pictogram: AhdashPictogram.tournament,
                    accent: AppColors.gold,
                    visual: _ModeVisual.tournament,
                    status: policy.allows(AppCapability.tournaments)
                        ? null
                        : 'يتطلب حساب',
                    onTap: () => _open('/tournaments/create'),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ModeTile(
                            title: 'العب لحالك',
                            subtitle: 'تحدٍ فردي من ١١ سؤالًا',
                            pictogram: AhdashPictogram.questionStep,
                            visual: _ModeVisual.solo,
                            compact: true,
                            status: 'خيارات محدودة',
                            onTap: () => _open('/solo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModeTile(
                            title: 'تحدي فريق',
                            subtitle: 'فريقك ودعواتك وتحدياتك',
                            pictogram: AhdashPictogram.teamsStep,
                            visual: _ModeVisual.team,
                            compact: true,
                            status: policy.allows(AppCapability.teamChallenge)
                                ? null
                                : 'يتطلب حساب',
                            onTap: () => _open('/teams'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ModeTile(
                    title: 'ألعاب محفوظة',
                    subtitle: 'أرشيف الألعاب على هذا الجهاز',
                    pictogram: AhdashPictogram.emptyGames,
                    visual: _ModeVisual.saved,
                    status: policy.allows(AppCapability.savedGames)
                        ? null
                        : 'يتطلب حساب',
                    onTap: () => _open('/party/games'),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.hairline),
                  const SizedBox(height: 12),
                  const _SectionTitle('استكشف'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 0,
                    children: [
                      _DiscoverLink(
                        'الترتيب',
                        AhdashIcons.chart,
                        () => _open('/ranking'),
                      ),
                      _DiscoverLink(
                        'الأصدقاء',
                        AhdashIcons.group,
                        () => _open('/friends'),
                      ),
                      _DiscoverLink(
                        'طريقة اللعب',
                        AhdashIcons.help,
                        () => _open('/how-to-play'),
                      ),
                    ],
                  ),
                  if (!policy.hasAccount) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'اللعب المحلي متاح لك. الأصدقاء والبطولات وبيانات الحساب تحتاج تسجيل الدخول.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => context.push('/auth'),
                        child: const Text('سجّل دخولك وكمل معنا'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(String path) => openCapabilityDestination(context, ref, path);

  Future<void> _requestNewGame(bool canResume) async {
    if (canResume) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تبدؤون لعبة جديدة؟'),
          content: const Text(
            'ستبقى لعبتكم الحالية محفوظة حتى تُجهَّز الجولة الجديدة بنجاح.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ابدأوا'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    ref.read(partyGameControllerProvider.notifier).beginNewGame();
    if (mounted) context.go('/party/categories');
  }
}

final class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.policy, required this.onOpen});
  final GuestCapabilityPolicy policy;
  final ValueChanged<String> onOpen;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AhdashBrandLogo(width: 156, height: 44),
            ),
          ),
          IconButton(
            tooltip: policy.hasAccount ? 'حسابي' : 'تسجيل الدخول إلى حسابك',
            onPressed: () => onOpen('/profile'),
            icon: const Icon(AhdashIcons.profile, size: 24),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () => onOpen('/settings'),
            icon: const Icon(AhdashIcons.settings, size: 22),
          ),
        ],
      ),
      if (policy.hasAccount)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'حيّاك، ${policy.user!.username}',
            maxLines: 2,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.inkMuted,
            ),
          ),
        )
      else
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'ضيف • اللعب المحلي جاهز',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      const SizedBox(height: 12),
      const Divider(height: 1, color: AppColors.hairline),
    ],
  );
}

final class _PartyHero extends StatelessWidget {
  const _PartyHero({
    required this.canStart,
    required this.resumeLabel,
    required this.onStart,
    required this.onResume,
  });
  final bool canStart;
  final String? resumeLabel;
  final VoidCallback onStart;
  final VoidCallback? onResume;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 820;
    return Material(
      color: const Color(0xFF173F34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: AppColors.palm.withValues(alpha: .78)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('home-party-hero'),
        onTap: canStart ? onStart : null,
        child: Stack(
          children: [
            PositionedDirectional(
              top: -52,
              start: -28,
              child: Container(
                width: 174,
                height: 174,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const PositionedDirectional(
              top: 10,
              start: 14,
              child: Text(
                '١١',
                style: TextStyle(
                  color: Color(0x1FFFFFFF),
                  fontSize: 62,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'لعبة المجلس',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'لعبة جماعية',
                              style: TextStyle(
                                color: AppColors.paper0,
                                fontSize: 30,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'اختبر كرتك مع جماعتك',
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppColors.paper3,
                              ),
                            ),
                            if (resumeLabel != null && onResume != null) ...[
                              const SizedBox(height: 7),
                              InkWell(
                                onTap: onResume,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        AhdashIcons.undo,
                                        size: 15,
                                        color: AppColors.paper0,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          resumeLabel!,
                                          style: const TextStyle(
                                            color: AppColors.paper0,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        key: const ValueKey('home-motion-artwork'),
                        width: compact ? 130 : 148,
                        height: compact ? 114 : 128,
                        child: const ExcludeSemantics(
                          child: AhdashFootballArtwork(
                            scene: PremiumArtworkScene.homeGathering,
                            animateEntrance: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 13 : 16),
                  AhdashV10PrimaryButton(
                    key: const ValueKey('home-start-party'),
                    label: 'ابدأ لعبة',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: canStart ? onStart : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PremiumDiscovery extends StatelessWidget {
  const _PremiumDiscovery({required this.guest, required this.onTap});

  final bool guest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'أحدعش Premium، فئات حصرية ولعب بدون إعلانات',
    child: Material(
      key: const ValueKey('home-premium-discovery'),
      color: AppColors.paper1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5A3),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: .65),
                  ),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: AppColors.ink,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'أحدعش Premium',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        if (guest) const _StatusLabel('بعد تسجيل الدخول'),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'فئات حصرية · لعب بدون إعلانات',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.paper0,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 16),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

enum _ModeVisual { tournament, solo, team, saved }

final class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.pictogram,
    required this.onTap,
    required this.visual,
    this.status,
    this.compact = false,
    this.accent,
  });
  final String title, subtitle;
  final String? status;
  final AhdashPictogram pictogram;
  final _ModeVisual visual;
  final VoidCallback onTap;
  final bool compact;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    final surface = switch (visual) {
      _ModeVisual.tournament => const Color(0xFFFFF4D8),
      _ModeVisual.solo => AppColors.paper0,
      _ModeVisual.team => const Color(0xFFEAF3EC),
      _ModeVisual.saved => const Color(0xFFF0E5D2),
    };
    final iconSurface = switch (visual) {
      _ModeVisual.tournament => AppColors.gold,
      _ModeVisual.solo => AppColors.paper2,
      _ModeVisual.team => AppColors.primary.withValues(alpha: 0.55),
      _ModeVisual.saved => AppColors.paper0,
    };
    final icon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent ?? iconSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      alignment: Alignment.center,
      child: AhdashPictogramView(
        pictogram: pictogram,
        size: 23,
        color: AppColors.ink,
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.inkMuted,
          ),
        ),
        if (status != null) ...[
          const SizedBox(height: 8),
          _StatusLabel(status!),
        ],
      ],
    );
    return Semantics(
      button: true,
      label: status == 'يتطلب حساب' ? '$title، يتطلب حسابًا' : null,
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            visual == _ModeVisual.tournament ? 20 : 17,
          ),
          side: const BorderSide(color: AppColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              PositionedDirectional(
                top: 0,
                bottom: 0,
                start: 0,
                child: Container(
                  width: 4,
                  color: switch (visual) {
                    _ModeVisual.tournament => AppColors.gold,
                    _ModeVisual.solo => AppColors.ink,
                    _ModeVisual.team => AppColors.primary,
                    _ModeVisual.saved => AppColors.najdiClay,
                  },
                ),
              ),
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    width: compact ? 70 : 106,
                    child: CustomPaint(painter: _ModeBackdropPainter(visual)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [icon, const SizedBox(height: 12), copy],
                      )
                    : Row(
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(child: copy),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ModeBackdropPainter extends CustomPainter {
  const _ModeBackdropPainter(this.visual);

  final _ModeVisual visual;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    switch (visual) {
      case _ModeVisual.tournament:
        canvas.drawCircle(
          Offset(size.width * 0.62, size.height * 0.28),
          18,
          ink,
        );
        canvas.drawLine(
          Offset(size.width * 0.62, size.height * 0.46),
          Offset(size.width * 0.62, size.height * 0.78),
          ink,
        );
        canvas.drawLine(
          Offset(size.width * 0.32, size.height * 0.78),
          Offset(size.width * 0.9, size.height * 0.78),
          ink,
        );
      case _ModeVisual.solo:
        for (final radius in [12.0, 23.0, 34.0]) {
          canvas.drawCircle(
            Offset(size.width * 0.72, size.height * 0.28),
            radius,
            ink,
          );
        }
      case _ModeVisual.team:
        canvas.drawCircle(
          Offset(size.width * 0.35, size.height * 0.25),
          8,
          ink,
        );
        canvas.drawCircle(
          Offset(size.width * 0.78, size.height * 0.25),
          8,
          ink,
        );
        canvas.drawLine(
          Offset(size.width * 0.42, size.height * 0.48),
          Offset(size.width * 0.7, size.height * 0.48),
          ink,
        );
      case _ModeVisual.saved:
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                size.width * 0.2 + i * 7,
                size.height * 0.18 + i * 5,
                size.width * 0.6,
                size.height * 0.56,
              ),
              const Radius.circular(7),
            ),
            ink,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ModeBackdropPainter oldDelegate) =>
      oldDelegate.visual != visual;
}

final class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.paper2,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          height: 1.3,
          fontWeight: FontWeight.w500,
          color: AppColors.inkSoft,
        ),
      ),
    ),
  );
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
  );
}

final class _DiscoverLink extends StatelessWidget {
  const _DiscoverLink(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.inkSoft,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );
}
