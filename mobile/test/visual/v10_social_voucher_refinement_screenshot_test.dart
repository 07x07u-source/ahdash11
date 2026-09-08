import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/auth/presentation/auth_gate.dart';
import 'package:ahdash_11/features/premium/domain/premium_access.dart';
import 'package:ahdash_11/features/premium/presentation/premium_access_provider.dart';
import 'package:ahdash_11/features/premium/presentation/premium_controller.dart';
import 'package:ahdash_11/features/premium/presentation/premium_screen.dart';
import 'package:ahdash_11/features/premium/presentation/premium_voucher_controller.dart';
import 'package:ahdash_11/features/premium/presentation/premium_voucher_screen.dart';
import 'package:ahdash_11/features/profile/domain/player_profile.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:ahdash_11/features/profile/presentation/profile_screen.dart';
import 'package:ahdash_11/features/ranking/domain/leaderboard_entry.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_controller.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_screen.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/domain/social_entities.dart';
import 'package:ahdash_11/features/social/presentation/blocked_players_screen.dart';
import 'package:ahdash_11/features/social/presentation/friends_screen.dart';
import 'package:ahdash_11/features/social/presentation/social_team_screen.dart';
import 'package:ahdash_11/shared/presentation/utility_v9.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fake_social_repository.dart';
import '../fixtures/v10_feature_fixtures.dart';
import '../helpers/test_app.dart';

const _boundary = ValueKey('test-app-boundary');
const _primary = Size(390, 844);
const _compact = Size(360, 800);
const _account = AuthUser(
  id: 'fixture-account',
  username: 'fixture_player_11',
  isGuest: false,
);

void main() {
  setUpAll(() async {
    final font = FontLoader('ThmanyahSans');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      font.addFont(
        rootBundle.load('assets/fonts/thmanyah/thmanyahsans-$weight.otf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('capture friends primary and compact', (tester) async {
    for (final frame in const [
      ('social/friends_primary_390x844.png', _primary),
      ('social/friends_compact_360x800.png', _compact),
    ]) {
      await _pump(
        tester,
        screen: const FriendsScreen(),
        size: frame.$2,
        dashboard: Future.value(V10FeatureFixtures.populatedFriendsDashboard),
      );
      await _settle(tester);
      await _capture(tester, frame.$1);
    }
  });

  testWidgets('capture friends empty loading and error', (tester) async {
    await _pump(
      tester,
      screen: const FriendsScreen(),
      dashboard: Future.value(V10FeatureFixtures.emptyFriendsDashboard),
    );
    await _settle(tester);
    await _capture(tester, 'social/friends_empty_390x844.png');

    await _pump(
      tester,
      screen: const FriendsScreen(),
      dashboard: Completer<Map<String, Object?>>().future,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'social/friends_loading_390x844.png');

    final errorRepository = FakeSocialRepository()
      ..dashboardError = StateError('deterministic fixture error');
    await _pump(
      tester,
      screen: const FriendsScreen(),
      repository: errorRepository,
    );
    await _settle(tester);
    await _capture(tester, 'social/friends_error_390x844.png');
  });

  testWidgets('capture friend search results and relationship states', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.emptyFriendsDashboard,
      searchResults: V10FeatureFixtures.friendSearchResults,
    );
    await _pump(tester, screen: const FriendsScreen(), repository: repository);
    await _settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      'لاعب',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await _capture(tester, 'social/friends_search_results_390x844.png');
    await _capture(tester, 'social/add_friend_available_390x844.png');
    await _capture(tester, 'social/already_friend_390x844.png');
  });

  testWidgets('capture friend search keyboard and no results', (tester) async {
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.emptyFriendsDashboard,
      searchResults: const [],
    );
    await _pump(
      tester,
      screen: const FriendsScreen(),
      repository: repository,
      insets: const EdgeInsets.only(bottom: 300),
    );
    await _settle(tester);
    final field = find.byKey(const ValueKey('friends-search-field'));
    await tester.enterText(field, 'لاعب غير موجود');
    await tester.showKeyboard(field);
    await tester.pump(const Duration(milliseconds: 500));
    await _capture(tester, 'social/friends_search_keyboard_390x844.png');
    await _capture(tester, 'social/friends_no_results_390x844.png');
  });

  testWidgets('capture search loading and server error', (tester) async {
    final waiting = Completer<void>();
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.emptyFriendsDashboard,
    )..searchGate = waiting;
    await _pump(tester, screen: const FriendsScreen(), repository: repository);
    await _settle(tester);
    final field = find.byKey(const ValueKey('friends-search-field'));
    await tester.enterText(field, 'بحث');
    await tester.pump(const Duration(milliseconds: 500));
    await _capture(tester, 'social/friends_search_loading_390x844.png');
    waiting.complete();
    await _settle(tester);

    repository.searchError = StateError('deterministic search failure');
    await tester.enterText(field, 'خطأ');
    await tester.pump(const Duration(milliseconds: 500));
    await _capture(tester, 'social/friends_search_error_390x844.png');
  });

  testWidgets('capture friend added confirmation and block dialog', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.populatedFriendsDashboard,
      searchResults: const [
        {
          'user_id': 'fixture-added',
          'display_name': 'صديق مضاف',
          'username': 'fixture_added',
          'relationship': 'friend',
        },
      ],
    );
    await _pump(tester, screen: const FriendsScreen(), repository: repository);
    await _settle(tester);
    final field = find.byKey(const ValueKey('friends-search-field'));
    await tester.enterText(field, 'صديق');
    await tester.pump(const Duration(milliseconds: 500));
    await _capture(tester, 'social/friend_added_390x844.png');

    await _pump(
      tester,
      screen: const FriendsScreen(),
      repository: repository,
      dashboard: Future.value(const {
        'inbox': <Object?>[],
        'outbox': <Object?>[],
        'friends': <Object?>[
          <String, Object?>{
            'user_id': 'fixture-friend-a',
            'display_name': 'صديق الاختبار',
            'username': 'fixture_friend_a',
          },
        ],
      }),
    );
    await _settle(tester);
    final menu = find.byType(PopupMenuButton<String>).first;
    await tester.drag(
      find.byKey(const ValueKey('friends-keyboard-scroll')),
      const Offset(0, -260),
    );
    await _settle(tester);
    await tester.tap(menu);
    await _settle(tester);
    await tester.tap(find.text('حظر اللاعب'));
    await _settle(tester);
    expect(find.text('حظر اللاعب؟'), findsOneWidget);
    await _capture(tester, 'social/block_confirmation_390x844.png');
  });

  testWidgets('capture blocked populated empty and unblock busy', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      blockedPlayers: V10FeatureFixtures.blockedPlayers,
    );
    await _pump(
      tester,
      screen: const BlockedPlayersScreen(),
      repository: repository,
      blocked: Future.value(V10FeatureFixtures.blockedPlayers),
    );
    await _settle(tester);
    await _capture(tester, 'social/blocked_players_populated_390x844.png');

    final waiting = Completer<void>();
    repository.unblockGate = waiting;
    await tester.tap(find.text('فك الحظر'));
    await tester.pump(const Duration(milliseconds: 100));
    await _capture(tester, 'social/unblock_state_390x844.png');
    waiting.complete();
    await _settle(tester);

    await _pump(
      tester,
      screen: const BlockedPlayersScreen(),
      repository: FakeSocialRepository(),
      blocked: Future.value(const []),
    );
    await _settle(tester);
    await _capture(tester, 'social/blocked_players_empty_390x844.png');
  });

  testWidgets('capture team ranking and profile social surfaces', (
    tester,
  ) async {
    await _pump(
      tester,
      screen: const SocialTeamScreen(teamId: 'fixture-team'),
      team: Future.value(_team),
    );
    await _settle(tester);
    await _capture(tester, 'social/team_detail_390x844.png');

    await _pump(
      tester,
      screen: const RankingScreen(),
      ranking: Future.value(V10FeatureFixtures.ranking),
    );
    await _settle(tester);
    await _capture(tester, 'social/ranking_390x844.png');

    await _pump(tester, screen: const ProfileScreen());
    await _settle(tester);
    await tester.drag(
      find.byKey(const ValueKey('profile-scroll')),
      const Offset(0, -520),
    );
    await _settle(tester);
    await _capture(tester, 'social/profile_social_connection_390x844.png');
  });

  testWidgets('capture Premium voucher entry and active entitlement', (
    tester,
  ) async {
    await _pump(
      tester,
      screen: _premiumContent(
        PremiumView(plans: _plans, available: true),
        showVoucher: true,
      ),
    );
    await _settle(tester);
    await _capture(tester, 'voucher/premium_voucher_entry_390x844.png');

    await _pump(
      tester,
      screen: _premiumContent(
        PremiumView(
          access: PremiumAccessResolution(
            storeStatus: PremiumStatus(state: PremiumAccessState.inactive),
            promotional: PromotionalPremiumEntitlement(
              active: true,
              expiresAt: DateTime.utc(2100),
            ),
          ),
        ),
        showVoucher: true,
      ),
    );
    await _settle(tester);
    expect(find.byKey(const ValueKey('premium-subscribe')), findsNothing);
    await _capture(tester, 'voucher/premium_active_via_voucher_390x844.png');
  });

  for (final state in const [
    ('voucher/voucher_form_390x844.png', PremiumVoucherView()),
    (
      'voucher/voucher_validating_390x844.png',
      PremiumVoucherView(operation: PremiumVoucherOperation.validating),
    ),
    (
      'voucher/voucher_invalid_390x844.png',
      PremiumVoucherView(
        operation: PremiumVoucherOperation.failure,
        message: 'القسيمة غير صالحة.',
      ),
    ),
    (
      'voucher/voucher_used_390x844.png',
      PremiumVoucherView(
        operation: PremiumVoucherOperation.failure,
        message: 'تم استخدام هذه القسيمة مسبقًا.',
      ),
    ),
  ]) {
    testWidgets('capture ${state.$1}', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        screen: _voucherContent(state.$2, controller: controller),
      );
      if (state.$2.busy) {
        await tester.pump(const Duration(milliseconds: 300));
      } else {
        await _settle(tester);
      }
      await _capture(tester, state.$1);
    });
  }

  testWidgets('capture voucher typing with keyboard', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      screen: _voucherContent(
        const PremiumVoucherView(),
        controller: controller,
      ),
      insets: const EdgeInsets.only(bottom: 300),
    );
    await _settle(tester);
    final field = find.byKey(const ValueKey('premium-voucher-field'));
    await tester.enterText(field, 'ABCD1234EFGH5678IJKL9012');
    await tester.showKeyboard(field);
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'voucher/voucher_typing_390x844.png');
  });

  for (final state in const [
    (
      'voucher/voucher_success_monthly_390x844.png',
      PremiumVoucherType.monthlyPromo,
    ),
    (
      'voucher/voucher_success_annual_390x844.png',
      PremiumVoucherType.annualPromo,
    ),
  ]) {
    testWidgets('capture ${state.$1}', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        screen: _voucherContent(
          PremiumVoucherView(
            operation: PremiumVoucherOperation.success,
            message: 'تم التفعيل بتأكيد الخادم.',
            redemption: PremiumVoucherRedemption(
              status: PremiumVoucherRedemptionStatus.redeemed,
              type: state.$2,
              redeemedAt: DateTime.utc(2026, 9, 7, 12),
              expiresAt: state.$2 == PremiumVoucherType.monthlyPromo
                  ? DateTime.utc(2026, 10, 7, 12)
                  : DateTime.utc(2027, 9, 7, 12),
            ),
          ),
          controller: controller,
        ),
      );
      await _settle(tester);
      await _capture(tester, state.$1);
    });
  }

  testWidgets('capture voucher guest auth gate', (tester) async {
    await _pump(
      tester,
      screen: const AuthGateScreen(destination: '/premium/voucher'),
      user: V10FeatureFixtures.guest,
    );
    await _settle(tester);
    await _capture(tester, 'voucher/voucher_auth_gate_guest_390x844.png');
  });

  testWidgets('voucher form fits the full responsive and text-scale matrix', (
    tester,
  ) async {
    for (final size in const [
      Size(360, 800),
      Size(390, 844),
      Size(393, 852),
      Size(412, 915),
      Size(430, 932),
    ]) {
      for (final scale in const [1.0, 1.2, 1.3]) {
        final controller = TextEditingController();
        await _pump(
          tester,
          screen: _voucherContent(
            const PremiumVoucherView(),
            controller: controller,
          ),
          size: size,
          textScale: scale,
        );
        await _settle(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: '${size.width}x${size.height} at $scale',
        );
        controller.dispose();
      }
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget screen,
  Size size = _primary,
  double textScale = 1,
  EdgeInsets insets = EdgeInsets.zero,
  AuthUser user = _account,
  FakeSocialRepository? repository,
  Future<Map<String, Object?>>? dashboard,
  Future<List<Map<String, Object?>>>? blocked,
  Future<SocialTeamDetail>? team,
  Future<List<LeaderboardEntry>>? ranking,
  Future<PlayerProfile>? profile,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..viewInsets = FakeViewPadding(bottom: insets.bottom);
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio()
      ..resetViewInsets();
  });
  final social =
      repository ??
      FakeSocialRepository(
        dashboard: V10FeatureFixtures.populatedFriendsDashboard,
        blockedPlayers: V10FeatureFixtures.blockedPlayers,
      );
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authControllerProvider.overrideWithBuild((ref, notifier) async => user),
        socialRepositoryProvider.overrideWithValue(social),
        friendsDashboardProvider.overrideWith(
          (ref) => dashboard ?? social.loadFriendDashboard(),
        ),
        blockedPlayersProvider.overrideWith(
          (ref) => blocked ?? social.loadBlockedPlayers(),
        ),
        socialTeamDetailProvider.overrideWith(
          (ref, teamId) => team ?? Future.value(_team),
        ),
        leaderboardProvider.overrideWith(
          (ref) => ranking ?? Future.value(V10FeatureFixtures.ranking),
        ),
        playerProfileProvider.overrideWith(
          (ref) => profile ?? Future.value(phase6Profile),
        ),
        premiumAccessProvider.overrideWith(
          (ref) async => const PremiumAccessResolution.inactive(),
        ),
      ],
      child: testApp(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            padding: insets.bottom > 0
                ? const EdgeInsets.only(top: 47)
                : const EdgeInsets.only(top: 47, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
            viewInsets: insets,
            disableAnimations: true,
          ),
          child: screen,
        ),
        theme: AppTheme.light,
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
  expect(tester.takeException(), isNull);
}

Widget _premiumContent(PremiumView value, {required bool showVoucher}) =>
    AhdashUtilityScaffold(
      title: 'أحدعش Premium',
      child: PremiumContentView(
        value: value,
        showVoucherEntry: showVoucher,
        onVoucher: () {},
        onSelect: (_) {},
        onPurchase: () async => false,
        onRestore: () async => false,
      ),
    );

Widget _voucherContent(
  PremiumVoucherView value, {
  required TextEditingController controller,
}) => AhdashUtilityScaffold(
  title: 'استخدام قسيمة Premium',
  child: PremiumVoucherContentView(
    value: value,
    codeController: controller,
    onRedeem: () async => false,
    onDone: () {},
  ),
);

Future<void> _capture(WidgetTester tester, String relativePath) async {
  const output = String.fromEnvironment('SOCIAL_VOUCHER_VISUAL_DIR');
  if (output.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundary),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$output/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

const _plans = [
  PremiumPlan(
    period: PremiumPlanPeriod.monthly,
    identifier: 'fixture-monthly',
    price: '١٢٫٩٩ ر.س.',
    priceValue: 12.99,
    currencyCode: 'SAR',
  ),
  PremiumPlan(
    period: PremiumPlanPeriod.yearly,
    identifier: 'fixture-annual',
    price: '٩٩٫٩٩ ر.س.',
    priceValue: 99.99,
    currencyCode: 'SAR',
  ),
];

const _team = SocialTeamDetail(
  id: 'fixture-team',
  name: 'صقور الجزيرة',
  description: 'مجلس خاص لأعضاء الفريق.',
  primaryColor: '#5F8F0F',
  badgeSeed: '11',
  currentRole: 'owner',
  currentUserId: 'fixture-account',
  members: [
    SocialTeamMember(
      userId: 'fixture-account',
      displayName: 'سلمان الحربي',
      role: 'owner',
      level: 1,
      weeklyPoints: 420,
      rank: 1,
    ),
    SocialTeamMember(
      userId: 'fixture-member',
      displayName: 'خالد العتيبي',
      role: 'member',
      level: 1,
      weeklyPoints: 280,
      rank: 2,
    ),
  ],
  challenges: [],
  activity: [],
  weeklyMvp: null,
);
