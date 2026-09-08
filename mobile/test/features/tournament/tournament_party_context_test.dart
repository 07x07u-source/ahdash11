import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/domain/party_tournament_context.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_flow.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/party_phase4_fixture.dart';

const source = PartyTournamentContext(
  tournamentId: 'cup',
  matchId: 'match',
  teamAId: 'a',
  teamBId: 'b',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('session source survives encode, copy, and tiebreak state', () {
    final session = phase4BoardSession.copyWith(tournamentContext: source);
    final decoded = PartyGameSession.decode(
      session.copyWith(tieBreakerStarted: true).encode(),
    );
    expect(source.sameMatch(decoded.tournamentContext), isTrue);
    expect(decoded.id, session.id);
    expect(
      PartyGameSession.decode(phase4BoardSession.encode()).tournamentContext,
      isNull,
    );
  });

  test(
    'tournament setup restores teams and source and does not restart on repeat launch',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      var container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      var controller = container.read(partyGameControllerProvider.notifier);
      expect(
        await controller.beginTournamentGame(
          context: source,
          teams: phase4Teams,
          timerSeconds: 30,
        ),
        isTrue,
      );
      controller.updateTeam(0, name: 'Wrong team', players: ['Other']);
      expect(
        container.read(partyGameControllerProvider).teams.first.name,
        phase4Teams.first.name,
      );
      expect(controller.splitPlayers(['One', 'Two']), isFalse);
      container.dispose();
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);
      controller = container.read(partyGameControllerProvider.notifier);
      await controller.restore();
      expect(
        source.sameMatch(
          container.read(partyGameControllerProvider).tournamentContext,
        ),
        isTrue,
      );
      expect(
        await controller.beginTournamentGame(
          context: source,
          teams: phase4Teams,
          timerSeconds: 60,
        ),
        isTrue,
      );
      expect(container.read(partyGameControllerProvider).timerSeconds, 30);
    },
  );

  test(
    'saved active session resumes exact id without regenerating the board',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final session = phase4BoardSession.copyWith(tournamentContext: source);
      await database.putSetting('party_active_game_v1', session.encode());
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);
      final controller = container.read(partyGameControllerProvider.notifier);
      expect(
        await controller.beginTournamentGame(
          context: source,
          teams: phase4Teams,
          timerSeconds: 30,
        ),
        isTrue,
      );
      final state = container.read(partyGameControllerProvider);
      expect(state.session?.id, session.id);
      expect(state.session?.scores, session.scores);
      expect(PartySetupFlowResolver.canonicalRoute(state), '/party/board');
      expect(
        await controller.beginTournamentGame(
          context: const PartyTournamentContext(
            tournamentId: 'cup',
            matchId: 'other',
            teamAId: 'c',
            teamBId: 'd',
          ),
          teams: phase4Teams,
          timerSeconds: 30,
        ),
        isFalse,
      );
      expect(
        container.read(partyGameControllerProvider).session?.id,
        session.id,
      );
    },
  );
}
