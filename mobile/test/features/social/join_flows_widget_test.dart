import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/domain/social_entities.dart';
import 'package:ahdash_11/features/social/presentation/social_join_team_screen.dart';
import 'package:ahdash_11/features/tournament/data/tournament_registration_repository.dart';
import 'package:ahdash_11/features/tournament/domain/tournament.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_join_screen.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_registrations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('team join link is usable in portrait', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: _JoinTestApp(
          child: SocialJoinTeamScreen(initialCode: 'A11TEAM'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('social-team-join-code')),
    );
    expect(field.controller?.text, 'A11TEAM');
    expect(find.text('مراجعة والانضمام'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tournament join link is usable in landscape', (tester) async {
    tester.view
      ..physicalSize = const Size(844, 390)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialHubProvider.overrideWith(
            (ref) async => const SocialHub(team: null, invites: []),
          ),
        ],
        child: const _JoinTestApp(
          child: TournamentJoinScreen(
            initialCode: 'A11CUP',
            initialPlayersPerTeam: 4,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('tournament-join-code')),
    );
    expect(field.controller?.text, 'A11CUP');
    expect(find.text('فريق جديد للبطولة'), findsOneWidget);
    expect(find.text('مراجعة وإرسال الطلب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('organizer registration review stays usable in portrait', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    final tournament = Tournament(
      id: 'tournament-id',
      name: 'بطولة الأصدقاء',
      organizerId: 'organizer-id',
      rules: const TournamentRules(capacity: 8, playersPerTeam: 4),
      status: TournamentStatus.registration,
      teams: const [],
      matches: const [],
      createdAt: DateTime.utc(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentControllerProvider.overrideWithBuild(
            (ref, notifier) =>
                TournamentState(active: tournament, restored: true),
          ),
          pendingTournamentRegistrationsProvider(tournament.id).overrideWith(
            (ref) async => const [
              TournamentRegistrationRequest(
                id: 'registration-id',
                teamName: 'فريق العاصمة',
                roster: [
                  {'display_name': 'أحمد'},
                  {'display_name': 'نواف'},
                  {'display_name': 'سلمان'},
                  {'display_name': 'ريان'},
                ],
                createdAt: null,
              ),
            ],
          ),
        ],
        child: const _JoinTestApp(child: TournamentRegistrationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('فريق العاصمة'), findsOneWidget);
    expect(find.text('قبول'), findsOneWidget);
    expect(find.text('رفض'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _JoinTestApp extends StatelessWidget {
  const _JoinTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => testApp(child);
}
