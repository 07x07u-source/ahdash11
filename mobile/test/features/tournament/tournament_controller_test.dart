import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/tournament/data/tournament_gateway.dart';
import 'package:ahdash_11/features/tournament/domain/tournament.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unavailable local cache cannot block tournament restore', () async {
    final database = AppDatabase(
      DatabaseConnection.delayed(Completer<DatabaseConnection>().future),
    );
    final container = _container(database, _FakeTournamentGateway());
    addTearDown(container.dispose);

    final controller = container.read(tournamentControllerProvider.notifier);
    await controller.restore();

    expect(container.read(tournamentControllerProvider).restored, isTrue);
    expect(await controller.readWizard(), isNull);
  });

  test(
    'uncertain create retries the same id after process recreation',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final gateway = _FakeTournamentGateway()..failCreate = true;
      var container = _container(database, gateway);
      var controller = container.read(tournamentControllerProvider.notifier);
      expect(
        await controller.create(
          name: 'كأس المحاولة',
          rules: const TournamentRules(capacity: 4),
        ),
        isNull,
      );
      final firstId = gateway.created.single.id;
      container.dispose();
      gateway.failCreate = false;
      container = _container(database, gateway);
      addTearDown(container.dispose);
      controller = container.read(tournamentControllerProvider.notifier);
      final created = await controller.create(
        name: 'كأس المحاولة',
        rules: const TournamentRules(capacity: 4),
      );
      expect(created?.id, firstId);
      expect(gateway.created.map((t) => t.id).toSet(), {firstId});
    },
  );

  test('double create tap submits only one request', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = _FakeTournamentGateway();
    final container = _container(database, gateway);
    addTearDown(container.dispose);
    final controller = container.read(tournamentControllerProvider.notifier);
    final calls = await Future.wait([
      controller.create(
        name: 'كأس ثابت',
        rules: const TournamentRules(capacity: 4),
      ),
      controller.create(
        name: 'كأس ثابت',
        rules: const TournamentRules(capacity: 4),
      ),
    ]);
    expect(calls.whereType<Tournament>(), hasLength(1));
    expect(gateway.created, hasLength(1));
  });

  test('production guest cannot silently create a local tournament', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = _FakeTournamentGateway();
    final container = _container(database, gateway, guest: true);
    addTearDown(container.dispose);
    expect(
      await container
          .read(tournamentControllerProvider.notifier)
          .create(name: 'كأس الضيف', rules: const TournamentRules(capacity: 4)),
      isNull,
    );
    expect(gateway.created, isEmpty);
    expect(container.read(tournamentControllerProvider).active, isNull);
  });

  test('wizard values and step persist using Drift', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = _container(database, _FakeTournamentGateway());
    addTearDown(container.dispose);
    final controller = container.read(tournamentControllerProvider.notifier);
    final draft = {
      'name': 'نهائي الحارة',
      'step': 1,
      'rules': const TournamentRules(capacity: 16).toJson(),
    };
    await controller.saveWizard(draft);
    final restored = await controller.readWizard();
    expect(restored?['name'], draft['name']);
    expect(restored?['step'], draft['step']);
    expect(restored?['rules'], draft['rules']);
    expect(restored?['id'], isNotEmpty);
  });

  test('remote bracket failure never promotes the local draft', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = _FakeTournamentGateway()..failSave = true;
    var container = _container(database, gateway);
    var controller = container.read(tournamentControllerProvider.notifier);

    expect(
      await controller.create(
        name: 'كأس الأمان',
        rules: const TournamentRules(capacity: 4),
      ),
      isNotNull,
    );
    for (final name in ['الصقور', 'المدرج', 'التكتيك', 'الأساطير']) {
      expect(await controller.addTeam(name), isTrue);
    }
    expect(await controller.generateBracket(), isFalse);
    expect(
      container.read(tournamentControllerProvider).active!.status,
      TournamentStatus.draft,
    );
    final firstAttemptIds = gateway.saved.single.matches
        .map((match) => match.id)
        .toList();

    container.dispose();
    gateway.failSave = false;
    container = _container(database, gateway);
    addTearDown(container.dispose);
    controller = container.read(tournamentControllerProvider.notifier);
    await controller.restore();
    expect(await controller.generateBracket(), isTrue);
    expect(
      gateway.saved.last.matches.map((match) => match.id),
      orderedEquals(firstAttemptIds),
    );
    expect(
      container.read(tournamentControllerProvider).active!.status,
      TournamentStatus.live,
    );
  });

  test('remote result failure leaves the ready match unchanged', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = _FakeTournamentGateway();
    final container = _container(database, gateway);
    addTearDown(container.dispose);
    final controller = container.read(tournamentControllerProvider.notifier);
    await controller.create(
      name: 'كأس النتائج',
      rules: const TournamentRules(capacity: 4),
    );
    for (final name in ['الصقور', 'المدرج', 'التكتيك', 'الأساطير']) {
      await controller.addTeam(name);
    }
    await controller.generateBracket(randomSeed: 5);
    final match = container
        .read(tournamentControllerProvider)
        .active!
        .matches
        .firstWhere((value) => value.status == TournamentMatchStatus.ready);

    gateway.failConfirm = true;
    expect(
      await controller.confirmResult(matchId: match.id, scoreA: 2, scoreB: 1),
      isFalse,
    );
    expect(
      container
          .read(tournamentControllerProvider)
          .active!
          .matches
          .firstWhere((value) => value.id == match.id)
          .status,
      TournamentMatchStatus.ready,
    );

    gateway.failConfirm = false;
    expect(
      await controller.confirmResult(matchId: match.id, scoreA: 2, scoreB: 1),
      isTrue,
    );
  });

  test('Party tournament context survives process recreation', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = _FakeTournamentGateway();
    var container = _container(database, gateway);
    var controller = container.read(tournamentControllerProvider.notifier);
    await controller.create(
      name: 'كأس Party',
      rules: const TournamentRules(capacity: 4),
    );
    for (final name in ['الصقور', 'المدرج', 'التكتيك', 'الأساطير']) {
      await controller.addTeam(name);
    }
    await controller.generateBracket(randomSeed: 4);
    final matchId = container
        .read(tournamentControllerProvider)
        .active!
        .matches
        .firstWhere((value) => value.status == TournamentMatchStatus.ready)
        .id;
    expect(await controller.selectPartyMatch(matchId), isTrue);
    container.dispose();

    container = _container(database, gateway);
    addTearDown(container.dispose);
    controller = container.read(tournamentControllerProvider.notifier);
    await controller.restore();
    expect(container.read(tournamentControllerProvider).partyMatchId, matchId);
  });
}

ProviderContainer _container(
  AppDatabase database,
  TournamentGateway gateway, {
  bool guest = false,
}) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      const AppConfig(
        environment: AppEnvironment.production,
        supabaseUrl: 'https://example.supabase.co',
        supabaseKey: 'test-key',
        firebaseEnabled: false,
        adMobEnabled: false,
        revenueCatAndroidKey: '',
        revenueCatIosKey: '',
      ),
    ),
    appDatabaseProvider.overrideWithValue(database),
    authControllerProvider.overrideWithBuild(
      (ref, notifier) async =>
          AuthUser(id: 'organizer', username: 'organizer', isGuest: guest),
    ),
    tournamentGatewayProvider.overrideWithValue(gateway),
  ],
);

final class _FakeTournamentGateway implements TournamentGateway {
  @override
  Future<String?> tournamentIdForMatch(String matchId) async => null;
  @override
  Future<Tournament?> loadTournament(String tournamentId) async => null;
  bool failSave = false;
  bool failConfirm = false;
  bool failCreate = false;
  final created = <Tournament>[];
  final saved = <Tournament>[];
  final confirmed = <TournamentMatch>[];

  @override
  Future<String?> createTournament(Tournament tournament) async {
    created.add(tournament);
    if (failCreate) throw StateError('Uncertain remote response');
    return null;
  }

  @override
  Future<void> saveBracket(Tournament tournament) async {
    saved.add(tournament);
    if (failSave) throw StateError('save failed');
  }

  @override
  Future<void> confirmResult({
    required String tournamentId,
    required TournamentMatch match,
  }) async {
    confirmed.add(match);
    if (failConfirm) throw StateError('confirm failed');
  }
}
