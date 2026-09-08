import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/features/game/domain/game_mode.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/domain/party_game_engine.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'score, turns, undo, used board cells and restart restore are durable',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final container = _container(database);
      final controller = container.read(partyGameControllerProvider.notifier);
      controller.beginNewGame();
      controller.setRandomCategories(
        _categories.map((value) => value.id).toList(),
      );
      expect(controller.completeTeamSetup(useSplitter: false), isNull);
      for (final helper in const [
        PartyHelperId.risk,
        PartyHelperId.pass,
        PartyHelperId.twoChances,
      ]) {
        expect(controller.toggleHelper(0, helper), isTrue);
        expect(controller.toggleHelper(1, helper), isTrue);
      }
      expect(
        await controller.start(
          _categories,
          _pool,
          defaultPartyHelperDefinitions,
          const PartyRuntimeSettings(),
        ),
        isTrue,
      );

      final first = container
          .read(partyGameControllerProvider)
          .session!
          .questions
          .first;
      expect(controller.chooseQuestion(first.id), isTrue);
      expect(controller.chooseQuestion(first.id), isFalse);
      controller.revealAnswer();
      expect(controller.award(0), isTrue);
      var session = container.read(partyGameControllerProvider).session!;
      expect(session.scores, [first.pointValue, 0]);
      expect(session.turnTeamIndex, 1);
      expect(controller.chooseQuestion(first.id), isFalse);

      expect(controller.undoLastScore(), isTrue);
      session = container.read(partyGameControllerProvider).session!;
      expect(session.scores, [0, 0]);
      expect(session.turnTeamIndex, 0);
      expect(controller.chooseQuestion(first.id), isTrue);
      expect(controller.useHelper(PartyHelperId.pass), isTrue);
      controller.revealAnswer();
      expect(controller.award(0), isFalse);
      expect(controller.award(null), isTrue);
      session = container.read(partyGameControllerProvider).session!;
      expect(session.scores, [0, -first.pointValue]);
      expect(session.turnTeamIndex, 1);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      container.dispose();
      final restoredContainer = _container(database);
      addTearDown(restoredContainer.dispose);
      await restoredContainer
          .read(partyGameControllerProvider.notifier)
          .restore();
      final restored = restoredContainer
          .read(partyGameControllerProvider)
          .session!;
      expect(restored.scores, session.scores);
      expect(restored.turnTeamIndex, session.turnTeamIndex);
      expect(
        restored.questions.firstWhere((value) => value.id == first.id).used,
        isTrue,
      );
    },
  );

  test('automatic split is fair and manual reassignment stays valid', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = _container(database);
    addTearDown(container.dispose);
    final controller = container.read(partyGameControllerProvider.notifier);

    expect(
      controller.splitPlayers(const [
        'سلمان',
        'نواف',
        'فيصل',
        'تركي',
        'خالد',
      ], seed: 11),
      isTrue,
    );
    var teams = container.read(partyGameControllerProvider).teams;
    expect((teams[0].players.length - teams[1].players.length).abs(), 1);
    expect(
      {...teams[0].players, ...teams[1].players},
      {'سلمان', 'نواف', 'فيصل', 'تركي', 'خالد'},
    );

    final moved = teams[0].players.last;
    expect(
      controller.assignPlayers(
        teams[0].players.sublist(0, teams[0].players.length - 1),
        [...teams[1].players, moved],
      ),
      isTrue,
    );
    teams = container.read(partyGameControllerProvider).teams;
    expect(teams[1].players, contains(moved));
    expect(controller.assignPlayers(const [], teams[1].players), isFalse);
  });

  test(
    'an unanswered turn enters a ten-second opponent steal window',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final container = _container(database);
      addTearDown(container.dispose);
      final controller = container.read(partyGameControllerProvider.notifier);
      controller.beginNewGame();
      controller.setRandomCategories(
        _categories.map((value) => value.id).toList(),
      );
      expect(controller.completeTeamSetup(useSplitter: false), isNull);
      for (final helper in const [
        PartyHelperId.risk,
        PartyHelperId.pass,
        PartyHelperId.twoChances,
      ]) {
        controller.toggleHelper(0, helper);
        controller.toggleHelper(1, helper);
      }
      expect(
        await controller.start(
          _categories,
          _pool,
          defaultPartyHelperDefinitions,
          const PartyRuntimeSettings(),
        ),
        isTrue,
      );
      final question = container
          .read(partyGameControllerProvider)
          .session!
          .questions
          .first;
      expect(controller.chooseQuestion(question.id), isTrue);
      expect(controller.offerSteal(), isTrue);
      var session = container.read(partyGameControllerProvider).session!;
      expect(session.stealActive, isTrue);
      expect(session.answeringTeamIndex, 1);
      expect(session.questionTimerDurationSeconds, 10);
      expect(controller.offerSteal(), isFalse);
      controller.revealAnswer();
      expect(controller.award(0), isFalse);
      expect(controller.award(1), isTrue);
      session = container.read(partyGameControllerProvider).session!;
      expect(session.scores, [0, question.pointValue]);
    },
  );

  test(
    'setup draft v2 restores without replacing the legacy active key',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final firstContainer = _container(database);
      final controller = firstContainer.read(
        partyGameControllerProvider.notifier,
      );
      controller.beginNewGame();
      controller.setRandomCategories(
        _categories.map((category) => category.id).toList(growable: false),
      );
      controller.updateTeam(0, name: 'الصقور');
      controller.updateTeam(1, name: 'النجوم');
      expect(controller.completeTeamSetup(useSplitter: true), isNull);
      expect(
        controller.splitPlayers(const ['سلمان', 'نواف', 'فيصل'], seed: 7),
        isTrue,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      firstContainer.dispose();

      final restoredContainer = _container(database);
      addTearDown(restoredContainer.dispose);
      await restoredContainer
          .read(partyGameControllerProvider.notifier)
          .restore();
      final restored = restoredContainer.read(partyGameControllerProvider);
      expect(restored.hasSetupDraft, isTrue);
      expect(restored.selectedCategoryIds, hasLength(6));
      expect(restored.teamSetupCompleted, isTrue);
      expect(restored.splitterStatus, PartySplitterStatus.completed);
      expect(restored.teams.map((team) => team.name), ['الصقور', 'النجوم']);
      expect(restored.teams.expand((team) => team.players).toSet(), {
        'سلمان',
        'نواف',
        'فيصل',
      });
    },
  );

  test('Start is single-submit and failure preserves the setup', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = _container(database);
    addTearDown(container.dispose);
    final controller = container.read(partyGameControllerProvider.notifier);
    controller.beginNewGame();
    controller.setRandomCategories(
      _categories.map((category) => category.id).toList(growable: false),
    );
    expect(controller.completeTeamSetup(useSplitter: false), isNull);
    for (final helper in const [
      PartyHelperId.risk,
      PartyHelperId.pass,
      PartyHelperId.twoChances,
    ]) {
      controller.toggleHelper(0, helper);
      controller.toggleHelper(1, helper);
    }

    final failed = await controller.start(
      _categories,
      _pool.take(1).toList(growable: false),
      defaultPartyHelperDefinitions,
      const PartyRuntimeSettings(),
    );
    expect(failed, isFalse);
    expect(
      container.read(partyGameControllerProvider).selectedCategoryIds,
      hasLength(6),
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(await database.readSetting('party_setup_draft_v2'), isNot(isEmpty));

    final firstStart = controller.start(
      _categories,
      _pool,
      defaultPartyHelperDefinitions,
      const PartyRuntimeSettings(),
    );
    final rapidSecondStart = controller.start(
      _categories,
      _pool,
      defaultPartyHelperDefinitions,
      const PartyRuntimeSettings(),
    );
    expect(await rapidSecondStart, isFalse);
    expect(await firstStart, isTrue);
    expect(await database.readSetting('party_setup_draft_v2'), isEmpty);
  });

  test('reveal and score operations reject duplicate submissions', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final session = const PartyGameEngine()
        .generate(
          categories: _categories,
          pool: _pool,
          teams: _gameplayTeams,
          seed: 19,
        )
        .copyWith(activeQuestionId: 'controller-c0-easy-0');
    final container = _containerWithSession(database, session);
    addTearDown(container.dispose);
    final controller = container.read(partyGameControllerProvider.notifier);

    expect(controller.revealAnswer(), isTrue);
    expect(controller.revealAnswer(), isFalse);
    expect(controller.award(0), isTrue);
    expect(controller.award(0), isFalse);

    final result = container.read(partyGameControllerProvider).session!;
    expect(result.scoreEvents, hasLength(1));
    expect(result.scores[0], session.activeQuestion!.pointValue);
  });

  test(
    'all five helpers use persisted domain effects and prerequisites',
    () async {
      final base = const PartyGameEngine().generate(
        categories: _categories,
        pool: _pool,
        teams: _gameplayTeams,
        seed: 23,
      );

      Future<PartyGameSession> activate(
        PartyHelperId helper, {
        String? detail,
      }) async {
        final database = AppDatabase(NativeDatabase.memory());
        final needsQuestion =
            helper.defaultDefinition.timing == PartyHelperTiming.afterQuestion;
        final initial = needsQuestion
            ? base.copyWith(activeQuestionId: base.questions.first.id)
            : base;
        final container = _containerWithSession(database, initial);
        final controller = container.read(partyGameControllerProvider.notifier);
        expect(controller.useHelper(helper, actionDetail: detail), isTrue);
        expect(controller.useHelper(helper, actionDetail: detail), isFalse);
        final result = container.read(partyGameControllerProvider).session!;
        await Future<void>.delayed(Duration.zero);
        container.dispose();
        await database.close();
        return result;
      }

      final risk = await activate(PartyHelperId.risk);
      expect(risk.armedHelper, PartyHelperId.risk);
      expect(risk.teams.first.usedHelpers, contains(PartyHelperId.risk));

      final twoChances = await activate(PartyHelperId.twoChances);
      expect(twoChances.armedHelper, PartyHelperId.twoChances);

      final callFriend = await activate(PartyHelperId.callFriend);
      expect(callFriend.questionTimerDurationSeconds, 20);
      expect(callFriend.questionTimerStartedAt, isNotNull);

      final bench = await activate(PartyHelperId.bench, detail: 'نواف');
      expect(bench.helperActionDetail, 'نواف');

      final pass = await activate(PartyHelperId.pass);
      expect(pass.answeringTeamIndex, 1);
      expect(pass.teams.first.usedHelpers, contains(PartyHelperId.pass));
    },
  );

  test('an unavailable local cache does not disable starting Party', () async {
    final storageGate = Completer<DatabaseConnection>();
    final database = AppDatabase(
      DatabaseConnection.delayed(storageGate.future),
    );
    final container = _container(database);
    addTearDown(() async {
      container.dispose();
      if (!storageGate.isCompleted) {
        storageGate.complete(DatabaseConnection(NativeDatabase.memory()));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await database.close();
    });

    await expectLater(
      container.read(partyGameControllerProvider.notifier).restore(),
      completes,
    );

    final state = container.read(partyGameControllerProvider);
    expect(state.restored, isTrue);
    expect(state.error, contains('بدء لعبة جديدة'));
  });

  test(
    'corrupt saved Party payloads fail closed without invented sessions',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.putSetting('party_active_game_v1', '{not valid json');
      await database.putSetting('party_game_history_v1', '{also not a list}');
      await database.putSetting('party_setup_draft_v2', '[]');

      final container = _container(database);
      addTearDown(container.dispose);
      await container.read(partyGameControllerProvider.notifier).restore();

      final state = container.read(partyGameControllerProvider);
      expect(state.restored, isTrue);
      expect(state.session, isNull);
      expect(state.history, isEmpty);
      expect(state.hasSetupDraft, isFalse);
    },
  );

  test(
    'missing saved Party state restores as a deliberate empty state',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final container = _container(database);
      addTearDown(container.dispose);

      await container.read(partyGameControllerProvider.notifier).restore();

      final state = container.read(partyGameControllerProvider);
      expect(state.restored, isTrue);
      expect(state.session, isNull);
      expect(state.history, isEmpty);
      expect(state.hasSetupDraft, isFalse);
    },
  );
}

ProviderContainer _container(AppDatabase database) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      const AppConfig(
        environment: AppEnvironment.development,
        supabaseUrl: '',
        supabaseKey: '',
        firebaseEnabled: false,
        adMobEnabled: false,
        revenueCatAndroidKey: '',
        revenueCatIosKey: '',
      ),
    ),
    appDatabaseProvider.overrideWithValue(database),
  ],
);

ProviderContainer _containerWithSession(
  AppDatabase database,
  PartyGameSession session,
) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      const AppConfig(
        environment: AppEnvironment.development,
        supabaseUrl: '',
        supabaseKey: '',
        firebaseEnabled: false,
        adMobEnabled: false,
        revenueCatAndroidKey: '',
        revenueCatIosKey: '',
      ),
    ),
    appDatabaseProvider.overrideWithValue(database),
    partyGameControllerProvider.overrideWithBuild(
      (ref, notifier) => PartyGameState(session: session, restored: true),
    ),
  ],
);

const _gameplayTeams = [
  PartyTeam(
    name: 'الصقور',
    colorValue: 0xFF4B8DE8,
    players: ['سلمان'],
    selectedHelpers: {
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
      PartyHelperId.risk,
      PartyHelperId.bench,
      PartyHelperId.pass,
    },
  ),
  PartyTeam(
    name: 'النجوم',
    colorValue: 0xFFE84B8A,
    players: ['نواف'],
    selectedHelpers: {
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
      PartyHelperId.risk,
      PartyHelperId.bench,
      PartyHelperId.pass,
    },
  ),
];

final _categories = List.generate(
  6,
  (index) => QuizCategory(
    id: 'controller-c$index',
    name: 'قسم $index',
    description: '',
    iconName: 'sports_soccer',
    accentColor: const Color(0xFF2368A2),
  ),
);

final _pool = [
  for (final category in _categories)
    for (final difficulty in const [
      QuestionDifficulty.easy,
      QuestionDifficulty.medium,
      QuestionDifficulty.hard,
    ])
      for (var index = 0; index < 2; index++)
        QuizQuestion(
          id: '${category.id}-${difficulty.name}-$index',
          text: 'سؤال ${category.id} ${difficulty.name} $index',
          options: const ['الإجابة', 'ب', 'ج', 'د'],
          correctOptionIndex: 0,
          categoryId: category.id,
          difficulty: difficulty,
          gameType: GameType.classic,
          format: QuestionFormat.openAnswer,
          correctAnswer: 'الإجابة',
        ),
];
