import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/services/game_streak_service.dart';
import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/brand_identity.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../auth/domain/guest_capability_policy.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/presentation/capability_provider.dart';
import '../../party/presentation/party_catalog_provider.dart';
import '../../party/presentation/party_game_controller.dart';
import '../../party/presentation/party_setup_flow.dart';
import '../../tournament/presentation/tournament_controller.dart';
import 'streak_milestone_celebration.dart';

final class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  var _streakCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_recordTodayAndCelebrate());
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _streakCheckStarted = false;
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_recordTodayAndCelebrate());
    }
  }

  Future<void> _recordTodayAndCelebrate() async {
    if (_streakCheckStarted) return;
    _streakCheckStarted = true;
    final streak = ref.read(gameStreakProvider.notifier);
    await streak.recordToday();
    if (!mounted) return;
    final milestone = await streak.claimPendingMilestone();
    if (!mounted || milestone == null) return;

    final current = ref.read(gameStreakProvider).value;
    await ref.read(feedbackServiceProvider).play(FeedbackCue.reward);
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'إنجاز سلسلة الأيام',
      barrierColor: Colors.transparent,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.emphasized,
      pageBuilder: (dialogContext, _, _) => StreakMilestoneCelebration(
        days: milestone,
        emoji: current?.safeEmoji ?? defaultGameStreakEmoji,
        onContinue: () =>
            Navigator.of(dialogContext, rootNavigator: true).pop(),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.enterCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.paper0, Color(0xFFF8F2E7), AppColors.paper0],
            stops: [0, .58, 1],
          ),
        ),
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ListView(
                  key: const ValueKey('home-scroll'),
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    12,
                    gutter,
                    AhdashSizing.floatingDockContentInset,
                  ),
                  children: [
                    _HomeHeader(policy: policy, onOpen: _open),
                    if (MediaQuery.sizeOf(context).height >= 500) ...[
                      const SizedBox(height: 14),
                      const _HomeStreakCard(),
                      const SizedBox(height: 12),
                    ],
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
                    const _PlayModesHeader(),
                    const SizedBox(height: 12),
                    _ModeTile(
                      title: 'أنشئ بطولة',
                      subtitle: 'نظّم الفرق واحسم البطل',
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
                    const SizedBox(height: 10),
                    _DiscoverLink(
                      'طريقة اللعب',
                      AhdashIcons.help,
                      () => _open('/how-to-play'),
                      subtitle: 'القواعد والمساعدات وخطوات الجولة',
                    ),
                    if (!policy.hasAccount) ...[
                      const SizedBox(height: 12),
                      _GuestAccountNudge(onTap: () => context.push('/auth')),
                    ],
                  ],
                ),
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
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width <= 360;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .54),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: .76)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10191714),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: -54,
                start: -42,
                child: Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .09),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AhdashBrandLogo(
                            width: compact ? 130 : 144,
                            height: 42,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.paper0.withValues(alpha: .82),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.hairline.withValues(alpha: .78),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HomeHeaderAction(
                              tooltip: policy.hasAccount
                                  ? 'حسابي'
                                  : 'تسجيل الدخول إلى حسابك',
                              onPressed: () => onOpen('/profile'),
                              icon: AhdashIcons.profile,
                            ),
                            _HomeHeaderAction(
                              key: const ValueKey('home-notifications-action'),
                              tooltip: 'الإشعارات',
                              onPressed: () => onOpen('/notifications'),
                              icon: AhdashIcons.notifications,
                              emphasized: true,
                            ),
                            _HomeHeaderAction(
                              tooltip: 'الإعدادات',
                              onPressed: () => onOpen('/settings'),
                              icon: AhdashIcons.settings,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .32),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .68),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .2),
                            shape: BoxShape.circle,
                          ),
                          child: ExcludeSemantics(
                            child: Image.asset(
                              'assets/visuals/home_welcome_wave_emoji.png',
                              key: const ValueKey('home-welcome-emoji'),
                              width: 19,
                              height: 19,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                policy.hasAccount
                                    ? 'حيّاك، ${policy.user!.username}'
                                    : 'حيّاك كضيف',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.2,
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                policy.hasAccount
                                    ? 'جهّز جماعتك وابدأ اللعب'
                                    : 'اللعب المحلي جاهز لك',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  height: 1.25,
                                  color: AppColors.inkMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _HomeHeaderAction extends StatelessWidget {
  const _HomeHeaderAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.emphasized = false,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      backgroundColor: emphasized
          ? AppColors.primary.withValues(alpha: .18)
          : Colors.transparent,
      foregroundColor: AppColors.ink,
      hoverColor: AppColors.primary.withValues(alpha: .12),
      highlightColor: AppColors.primary.withValues(alpha: .18),
      shape: const CircleBorder(),
    ),
    icon: Icon(icon, size: emphasized ? 20 : 19),
  );
}

final class _HomeStreakCard extends ConsumerWidget {
  const _HomeStreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak =
        ref.watch(gameStreakProvider).value ?? const GameStreakState();
    final premium = ref.watch(partyEntitlementProvider).value ?? false;
    final hasStreak = streak.days > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('home-streak-card'),
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openEmojiPicker(context, ref, premium, streak),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.ink.withValues(alpha: .1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0E191714),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                key: const ValueKey('home-streak-emoji'),
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ink, width: 1.1),
                ),
                child: Text(
                  premium ? streak.safeEmoji : defaultGameStreakEmoji,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 25, height: 1),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasStreak ? 'سلسلتك مستمرة' : 'ابدأ سلسلتك اليومية',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasStreak
                          ? '${streak.days} ${streak.days == 1 ? 'يوم' : 'أيام'} متتالية • ادخل والعب كل يوم'
                          : 'ادخل اللعبة اليوم لتحصل على أول شعلة',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                premium ? AhdashIcons.settings : AhdashIcons.lock,
                size: 17,
                color: premium ? AppColors.ink : AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEmojiPicker(
    BuildContext context,
    WidgetRef ref,
    bool premium,
    GameStreakState streak,
  ) async {
    if (!premium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختيار الإيموجي متاح للمشتركين فقط.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.paper0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'اختر إيموجي سلسلتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'إيموجيات أصلية تظهر بمظهر iPhone على أجهزة Apple.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final emoji in gameStreakEmojiOptions)
                      Semantics(
                        button: true,
                        selected: emoji == streak.safeEmoji,
                        label: 'إيموجي $emoji',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            ref
                                .read(gameStreakProvider.notifier)
                                .setEmoji(emoji, premium: premium);
                            Navigator.pop(sheetContext);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: emoji == streak.safeEmoji
                                  ? AppColors.primary.withValues(alpha: .22)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: emoji == streak.safeEmoji
                                    ? AppColors.ink
                                    : AppColors.ink.withValues(alpha: .12),
                                width: emoji == streak.safeEmoji ? 1.6 : 1,
                              ),
                            ),
                            child: Text(
                              emoji,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 28, height: 1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      color: const Color(0xFF123E32),
      elevation: 2,
      shadowColor: AppColors.ink.withValues(alpha: .3),
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
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: .32),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'لعبة المجلس',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 11,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.15,
                                  ),
                                ),
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
                        width: compact ? 124 : 142,
                        height: compact ? 116 : 132,
                        child: _HomePartyArtwork(
                          reducedMotion: MediaQuery.disableAnimationsOf(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 13 : 16),
                  _HomePrimaryCta(
                    key: const ValueKey('home-start-party'),
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

final class _HomePartyArtwork extends StatelessWidget {
  const _HomePartyArtwork({required this.reducedMotion});

  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: reducedMotion ? Duration.zero : AppMotion.launch,
    curve: AppMotion.enterCurve,
    tween: Tween<double>(begin: reducedMotion ? 1 : 0, end: 1),
    child: ExcludeSemantics(
      child: Image.asset(
        'assets/visuals/home_party_hero_ahdash.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    ),
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - value)),
        child: Transform.scale(scale: .94 + (.06 * value), child: child),
      ),
    ),
  );
}

final class _HomePrimaryCta extends StatelessWidget {
  const _HomePrimaryCta({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: .42),
        disabledForegroundColor: AppColors.ink.withValues(alpha: .55),
        elevation: onPressed == null ? 0 : 2,
        shadowColor: AppColors.ink.withValues(alpha: .34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0xFF09261E), width: 1.15),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              'ابدأ لعبة',
              style: TextStyle(
                fontSize: 16,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: onPressed == null
                    ? AppColors.ink.withValues(alpha: .5)
                    : AppColors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: AppColors.paper0,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _PremiumDiscovery extends StatelessWidget {
  const _PremiumDiscovery({required this.guest, required this.onTap});

  final bool guest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'أحدعش Premium، فئات حصرية وبدون إعلانات',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          key: const ValueKey('home-premium-discovery'),
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .48),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: .62),
                width: 1.1,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: .18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ink, width: 1.1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.coffee,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'أحدعش ',
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'PREMIUM',
                                        style: TextStyle(
                                          color: AppColors.coffee,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .75,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 7),
                              if (guest) const _PremiumGuestLabel(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'فئات حصرية  •  بدون إعلانات',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.25,
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ink, width: 1.1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _PremiumGuestLabel extends StatelessWidget {
  const _PremiumGuestLabel();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.ink.withValues(alpha: .2)),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      child: Text(
        'بعد تسجيل الدخول',
        style: TextStyle(
          color: AppColors.inkMuted,
          fontSize: 9,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

enum _ModeVisual { tournament, solo, team, saved }

final class _PlayModesHeader extends StatelessWidget {
  const _PlayModesHeader();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 4,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'طرق اللعب',
              style: TextStyle(
                fontSize: 20,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'اختر التجربة اللي تناسب جوّك',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paper1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.hairline),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            '٤ خيارات',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}

final class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.visual,
    this.status,
    this.compact = false,
  });
  final String title, subtitle;
  final String? status;
  final _ModeVisual visual;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = switch (visual) {
      _ModeVisual.tournament => const Color(0xFFFFF8E9),
      _ModeVisual.solo => const Color(0xFFF8F4EC),
      _ModeVisual.team => const Color(0xFFF1FAF3),
      _ModeVisual.saved => const Color(0xFFF6EEE2),
    };
    final accentColor = switch (visual) {
      _ModeVisual.tournament => AppColors.gold,
      _ModeVisual.solo => AppColors.primary,
      _ModeVisual.team => const Color(0xFF4B8DE8),
      _ModeVisual.saved => AppColors.najdiClay,
    };
    final borderColor = switch (visual) {
      _ModeVisual.tournament => const Color(0xFFDAB15B),
      _ModeVisual.solo => AppColors.ink.withValues(alpha: .18),
      _ModeVisual.team => const Color(0xFFAFCFBA),
      _ModeVisual.saved => const Color(0xFFC6AA84),
    };
    final asset = switch (visual) {
      _ModeVisual.tournament => 'assets/visuals/home_mode_tournament.png',
      _ModeVisual.solo => 'assets/visuals/home_mode_solo.png',
      _ModeVisual.team => 'assets/visuals/home_mode_team.png',
      _ModeVisual.saved => 'assets/visuals/home_mode_saved.png',
    };
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    Widget artwork(double size) => ExcludeSemantics(
      child: Image.asset(
        asset,
        key: ValueKey('home-mode-${visual.name}-artwork'),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        cacheWidth: (size * pixelRatio).ceil(),
      ),
    );
    final titleWidget = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 16 : 18,
        height: 1.2,
        fontWeight: FontWeight.w900,
      ),
    );
    final subtitleWidget = Text(
      subtitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 12,
        height: 1.4,
        color: AppColors.inkMuted,
        fontWeight: FontWeight.w500,
      ),
    );
    final arrow = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink.withValues(alpha: .22)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.arrow_forward_rounded,
        size: 17,
        color: AppColors.ink,
      ),
    );
    final content = compact
        ? Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: artwork(72)),
                const SizedBox(height: 6),
                titleWidget,
                const SizedBox(height: 3),
                subtitleWidget,
                const SizedBox(height: 9),
                Row(
                  children: [
                    if (status != null) Flexible(child: _StatusLabel(status!)),
                    const Spacer(),
                    arrow,
                  ],
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      titleWidget,
                      const SizedBox(height: 4),
                      subtitleWidget,
                      if (status != null) ...[
                        const SizedBox(height: 8),
                        _StatusLabel(status!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                artwork(88),
                const SizedBox(width: 4),
                arrow,
              ],
            ),
          );
    return Semantics(
      button: true,
      label: status == 'يتطلب حساب' ? '$title، يتطلب حسابًا' : null,
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                PositionedDirectional(
                  top: compact ? -28 : -42,
                  end: compact ? -28 : -18,
                  child: Container(
                    width: compact ? 112 : 142,
                    height: compact ? 112 : 142,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: .055),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  start: 0,
                  child: Container(width: 3, color: accentColor),
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final locked = label == 'يتطلب حساب';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: locked
            ? AppColors.ink.withValues(alpha: .065)
            : AppColors.gold.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: locked
              ? AppColors.ink.withValues(alpha: .1)
              : AppColors.gold.withValues(alpha: .28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.tune_rounded,
              size: 11,
              color: AppColors.inkSoft,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

final class _DiscoverLink extends StatelessWidget {
  const _DiscoverLink(this.label, this.icon, this.onPressed, {this.subtitle});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.ink.withValues(alpha: .18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 12, 9),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 1.1),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.ink),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle case final value?) ...[
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 10.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class _GuestAccountNudge extends StatelessWidget {
  const _GuestAccountNudge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'سجّل الدخول لحفظ تقدمك وفتح مزايا الحساب',
    child: Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.ink.withValues(alpha: .18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 1.1),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.bookmark_added_outlined,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'احفظ تقدمك وكمل وقت ما تبي',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'سجّل الدخول لفتح البطولات وبيانات الحساب.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.35,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .7),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 1.1),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
