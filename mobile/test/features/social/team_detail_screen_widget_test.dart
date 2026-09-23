import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/domain/social_entities.dart';
import 'package:ahdash_11/features/social/presentation/social_team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fixtures/fake_social_repository.dart';
import '../../helpers/phase6_fixture.dart';

void main() {
  testWidgets(
    'owner sees one identity, real roster data and guarded code action',
    (tester) async {
      final gate = Completer<void>();
      final repository = FakeSocialRepository(inviteCode: 'SAQR-1100')
        ..rotateInviteCodeGate = gate;
      final router = await _pumpTeam(
        tester,
        team: _ownerTeam,
        repository: repository,
      );
      addTearDown(router.dispose);

      expect(find.text('صقور الجزيرة'), findsOneWidget);
      expect(find.byKey(const ValueKey('team-identity-hero')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('team-identity-artwork')),
        findsOneWidget,
      );
      expect(find.text('11'), findsNothing);
      expect(find.byKey(const ValueKey('team-invite-panel')), findsOneWidget);
      expect(find.text('700'), findsOneWidget);
      expect(find.byKey(const ValueKey('team-member-owner')), findsOneWidget);
      expect(find.byKey(const ValueKey('team-member-member')), findsOneWidget);
      expect(find.byKey(const ValueKey('team-leave-button')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('team-rotate-code')));
      await tester.pump();
      expect(repository.inviteCodeRotations, 1);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('team-rotate-code')),
            )
            .onPressed,
        isNull,
      );

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const ValueKey('team-invite-code-value')),
        findsOneWidget,
      );
      expect(find.text('SAQR-1100'), findsOneWidget);
      await tester.tap(find.text('إغلاق'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('team-rotate-code')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('member must confirm before leaving the team', (tester) async {
    final repository = FakeSocialRepository();
    final router = await _pumpTeam(
      tester,
      team: _memberTeam,
      repository: repository,
    );
    addTearDown(router.dispose);

    final leave = find.byKey(const ValueKey('team-leave-button'));
    await tester.scrollUntilVisible(
      leave,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(leave);
    await tester.pumpAndSettle();
    expect(find.text('مغادرة الفريق؟'), findsOneWidget);
    await tester.tap(find.text('البقاء'));
    await tester.pumpAndSettle();
    expect(repository.teamMemberRemovals, 0);

    await tester.tap(leave);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team-confirm-leave')));
    await tester.pumpAndSettle();
    expect(repository.teamMemberRemovals, 1);
    expect(find.byKey(const ValueKey('teams-home')), findsOneWidget);
  });
}

Future<GoRouter> _pumpTeam(
  WidgetTester tester, {
  required SocialTeamDetail team,
  required FakeSocialRepository repository,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  final router = GoRouter(
    initialLocation: '/teams/${team.id}',
    routes: [
      GoRoute(
        path: '/teams',
        builder: (_, _) => const Scaffold(
          key: ValueKey('teams-home'),
          body: SizedBox.expand(),
        ),
      ),
      GoRoute(
        path: '/teams/:teamId',
        builder: (_, state) =>
            SocialTeamScreen(teamId: state.pathParameters['teamId']!),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(phase6Config),
        appServicesProvider.overrideWithValue(const AppServices.noop()),
        appPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => const AppPreferences(reducedMotion: true),
        ),
        socialRepositoryProvider.overrideWithValue(repository),
        socialTeamDetailProvider.overrideWith((ref, id) async => team),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        builder: (_, child) => MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 47, bottom: 34),
            viewPadding: EdgeInsets.only(top: 47, bottom: 34),
            disableAnimations: true,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

const _ownerTeam = SocialTeamDetail(
  id: 'team-fixture',
  name: 'صقور الجزيرة',
  description: 'مجلس خاص لأعضاء الفريق.',
  primaryColor: '#5F8F0F',
  badgeSeed: '11',
  currentRole: 'owner',
  currentUserId: 'owner',
  members: [
    SocialTeamMember(
      userId: 'owner',
      displayName: 'سلمان الحربي',
      role: 'owner',
      level: 12,
      weeklyPoints: 420,
      rank: 1,
    ),
    SocialTeamMember(
      userId: 'member',
      displayName: 'خالد العتيبي',
      role: 'member',
      level: 8,
      weeklyPoints: 280,
      rank: 2,
    ),
  ],
  challenges: [],
  activity: [],
  weeklyMvp: null,
);

const _memberTeam = SocialTeamDetail(
  id: 'team-fixture',
  name: 'صقور الجزيرة',
  description: 'مجلس خاص لأعضاء الفريق.',
  primaryColor: '#5F8F0F',
  badgeSeed: '11',
  currentRole: 'member',
  currentUserId: 'member',
  members: [
    SocialTeamMember(
      userId: 'owner',
      displayName: 'سلمان الحربي',
      role: 'owner',
      level: 12,
      weeklyPoints: 420,
      rank: 1,
    ),
    SocialTeamMember(
      userId: 'member',
      displayName: 'خالد العتيبي',
      role: 'member',
      level: 8,
      weeklyPoints: 280,
      rank: 2,
    ),
  ],
  challenges: [],
  activity: [],
  weeklyMvp: null,
);
