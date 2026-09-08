import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/app_services.dart';
import '../../../core/storage/app_database.dart';
import '../../../shared/domain/category.dart';
import '../../game/domain/game_rules.dart';
import '../../match/domain/quiz_question.dart';
import '../../match/presentation/question_repository_provider.dart';
import '../domain/party_game.dart';
import '../domain/party_game_engine.dart';
import '../domain/party_rule_engines.dart';
import '../domain/party_tournament_context.dart';
import 'party_catalog_provider.dart';

final partyGameControllerProvider =
    NotifierProvider<PartyGameController, PartyGameState>(
      PartyGameController.new,
    );

final class PartyGameState {
  const PartyGameState({
    this.selectedCategoryIds = const [],
    this.teams = const [
      PartyTeam(name: 'الفريق الأول', colorValue: 0xFF2368A2),
      PartyTeam(name: 'الفريق الثاني', colorValue: 0xFFB63863),
    ],
    this.timerSeconds = PartyGameRules.defaultTimerSeconds,
    this.teamSetupCompleted = false,
    this.splitterStatus = PartySplitterStatus.notRequested,
    this.splitterPlayers = const [],
    this.hasSetupDraft = false,
    this.favoriteCategoryIds = const {},
    this.session,
    this.history = const [],
    this.busy = false,
    this.error,
    this.restored = false,
    this.tournamentContext,
  });

  final List<String> selectedCategoryIds;
  final List<PartyTeam> teams;
  final int? timerSeconds;
  final bool teamSetupCompleted;
  final PartySplitterStatus splitterStatus;
  final List<String> splitterPlayers;
  final bool hasSetupDraft;
  final Set<String> favoriteCategoryIds;
  final PartyGameSession? session;
  final List<PartyGameSession> history;
  final bool busy;
  final String? error;
  final bool restored;
  final PartyTournamentContext? tournamentContext;

  PartyGameState copyWith({
    List<String>? selectedCategoryIds,
    List<PartyTeam>? teams,
    int? timerSeconds,
    bool clearTimer = false,
    bool? teamSetupCompleted,
    PartySplitterStatus? splitterStatus,
    List<String>? splitterPlayers,
    bool? hasSetupDraft,
    Set<String>? favoriteCategoryIds,
    PartyGameSession? session,
    bool clearSession = false,
    List<PartyGameSession>? history,
    bool? busy,
    String? error,
    bool clearError = false,
    bool? restored,
    PartyTournamentContext? tournamentContext,
  }) => PartyGameState(
    selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
    teams: teams ?? this.teams,
    timerSeconds: clearTimer ? null : timerSeconds ?? this.timerSeconds,
    teamSetupCompleted: teamSetupCompleted ?? this.teamSetupCompleted,
    splitterStatus: splitterStatus ?? this.splitterStatus,
    splitterPlayers: splitterPlayers ?? this.splitterPlayers,
    hasSetupDraft: hasSetupDraft ?? this.hasSetupDraft,
    favoriteCategoryIds: favoriteCategoryIds ?? this.favoriteCategoryIds,
    session: clearSession ? null : session ?? this.session,
    history: history ?? this.history,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    restored: restored ?? this.restored,
    tournamentContext: tournamentContext ?? this.tournamentContext,
  );
}

final class PartyGameController extends Notifier<PartyGameState> {
  static const _activeKey = 'party_active_game_v1';
  static const _historyKey = 'party_game_history_v1';
  static const _favoritesKey = 'party_favorite_categories_v1';
  static const _recentQuestionIdsKey = 'party_recent_question_ids_v1';
  static const _setupDraftKey = 'party_setup_draft_v2';
  Future<void>? _restoreTask;
  Future<void> _draftWrite = Future<void>.value();

  AppDatabase get _database => ref.read(appDatabaseProvider);

  @override
  PartyGameState build() => const PartyGameState();

  Future<void> restore() => _restoreTask ??= _restoreWithDeadline();

  Future<void> _restoreWithDeadline() async {
    try {
      await _restore().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      if (ref.mounted && !state.restored) {
        state = state.copyWith(
          restored: true,
          error: 'تعذر استعادة اللعبة المحفوظة. يمكنك بدء لعبة جديدة.',
        );
      }
    }
  }

  Future<void> _restore() async {
    if (state.restored) return;
    try {
      await _restoreFromStorage();
    } on Object {
      // A damaged/unavailable cache must not permanently disable the primary
      // Party action. Gameplay can continue in memory and persistence writes
      // are already best-effort.
      state = state.copyWith(
        restored: true,
        error: 'تعذر استعادة اللعبة المحفوظة. يمكنك بدء لعبة جديدة.',
      );
    }
  }

  Future<void> _restoreFromStorage() async {
    PartyGameSession? session;
    var history = <PartyGameSession>[];
    final encodedSession = await _database.readSetting(_activeKey);
    if (encodedSession != null && encodedSession.isNotEmpty) {
      try {
        session = PartyGameSession.decode(encodedSession);
      } catch (_) {
        session = null;
      }
    }
    final encodedHistory = await _database.readSetting(_historyKey);
    if (encodedHistory != null && encodedHistory.isNotEmpty) {
      try {
        history = (jsonDecode(encodedHistory) as List)
            .whereType<Map<Object?, Object?>>()
            .map(
              (value) =>
                  PartyGameSession.fromJson(Map<String, Object?>.from(value)),
            )
            .where((game) => game.isComplete)
            .toList(growable: false);
      } catch (_) {
        history = <PartyGameSession>[];
      }
    }
    final encodedFavorites = await _database.readSetting(_favoritesKey);
    final favorites = <String>{};
    if (encodedFavorites != null) {
      try {
        favorites.addAll(
          (jsonDecode(encodedFavorites) as List).whereType<String>(),
        );
      } catch (_) {
        // A corrupt preference must not block starting a game.
      }
    }
    var selectedCategoryIds = const <String>[];
    var teams = const [
      PartyTeam(name: 'الفريق الأول', colorValue: 0xFF2368A2),
      PartyTeam(name: 'الفريق الثاني', colorValue: 0xFFB63863),
    ];
    var timerSeconds = PartyGameRules.defaultTimerSeconds;
    var timerDisabled = false;
    var teamSetupCompleted = false;
    var splitterStatus = PartySplitterStatus.notRequested;
    var splitterPlayers = const <String>[];
    var hasSetupDraft = false;
    var tournamentContext = session?.tournamentContext;
    final encodedDraft = await _database.readSetting(_setupDraftKey);
    if (encodedDraft != null && encodedDraft.isNotEmpty) {
      try {
        final decoded = Map<String, Object?>.from(
          jsonDecode(encodedDraft) as Map,
        );
        if (decoded['version'] == 2) {
          tournamentContext = switch (decoded['tournament_context']) {
            final Map<Object?, Object?> value =>
              PartyTournamentContext.fromJson(Map<String, Object?>.from(value)),
            _ => null,
          };
          selectedCategoryIds =
              (decoded['selected_category_ids'] as List?)
                  ?.whereType<String>()
                  .toList(growable: false) ??
              const [];
          final decodedTeams =
              (decoded['teams'] as List?)
                  ?.whereType<Map<Object?, Object?>>()
                  .map(
                    (value) =>
                        PartyTeam.fromJson(Map<String, Object?>.from(value)),
                  )
                  .take(2)
                  .toList(growable: false) ??
              const [];
          if (decodedTeams.length == 2) teams = decodedTeams;
          timerDisabled = decoded['timer_seconds'] == null;
          timerSeconds =
              (decoded['timer_seconds'] as num?)?.toInt() ??
              PartyGameRules.defaultTimerSeconds;
          teamSetupCompleted = decoded['team_setup_completed'] == true;
          splitterStatus =
              PartySplitterStatus.values
                  .where((value) => value.name == decoded['splitter_status'])
                  .firstOrNull ??
              PartySplitterStatus.notRequested;
          splitterPlayers =
              (decoded['splitter_players'] as List?)
                  ?.whereType<String>()
                  .toList(growable: false) ??
              const [];
          hasSetupDraft = true;
        }
      } catch (_) {
        // Ignore an outdated or corrupt draft without touching a saved game.
      }
    }
    state = state.copyWith(
      selectedCategoryIds: selectedCategoryIds,
      teams: teams,
      timerSeconds: timerSeconds,
      clearTimer: timerDisabled,
      teamSetupCompleted: teamSetupCompleted,
      splitterStatus: splitterStatus,
      splitterPlayers: splitterPlayers,
      hasSetupDraft: hasSetupDraft,
      session: session,
      history: history,
      favoriteCategoryIds: favorites,
      restored: true,
      tournamentContext: tournamentContext,
    );
    unawaited(_mergeRemoteFavorites());
  }

  void beginNewGame() {
    state = PartyGameState(
      favoriteCategoryIds: state.favoriteCategoryIds,
      history: state.history,
      restored: state.restored,
      hasSetupDraft: true,
    );
    _queueDraftPersist();
    _track('party_setup_started');
    // Keep the persisted round until a replacement is generated successfully.
    // This prevents an accidental tap or a failed catalog request from
    // destroying a resumable 36-question session.
  }

  /// A repeated launch (including after process recreation) resumes the same
  /// draft/session. Never replace an unfinished game belonging to another match.
  Future<bool> beginTournamentGame({
    required PartyTournamentContext context,
    required List<PartyTeam> teams,
    required int timerSeconds,
    List<String> categoryIds = const [],
  }) async {
    await restore();
    if (state.busy) return false;
    if (context.sameMatch(state.tournamentContext)) return true;
    final previous = state.session;
    if ((previous != null && !previous.isComplete) ||
        (state.hasSetupDraft && state.tournamentContext != null)) {
      state = state.copyWith(error: 'أكمل الجولة الحالية قبل بدء مباراة أخرى.');
      return false;
    }
    if (teams.length != 2 || PartySetupValidation.teamError(teams) != null) {
      state = state.copyWith(error: 'تعذر تجهيز هويتي الفريقين للمباراة.');
      return false;
    }
    state = PartyGameState(
      teams: teams,
      selectedCategoryIds: categoryIds,
      timerSeconds: timerSeconds,
      teamSetupCompleted: true,
      splitterStatus: PartySplitterStatus.skipped,
      hasSetupDraft: true,
      tournamentContext: context,
      history: state.history,
      favoriteCategoryIds: state.favoriteCategoryIds,
      restored: true,
    );
    _queueDraftPersist();
    await _draftWrite;
    return true;
  }

  void beginRematch() {
    final current = state.session;
    if (current == null) {
      beginNewGame();
      return;
    }
    state = PartyGameState(
      teams: current.teams
          .map((team) => team.copyWith(usedHelpers: const {}))
          .toList(growable: false),
      timerSeconds: current.timerSeconds,
      favoriteCategoryIds: state.favoriteCategoryIds,
      history: state.history,
      restored: state.restored,
      teamSetupCompleted: true,
      splitterStatus: current.teams.any((team) => team.players.isNotEmpty)
          ? PartySplitterStatus.completed
          : PartySplitterStatus.skipped,
      splitterPlayers: current.teams
          .expand((team) => team.players)
          .toList(growable: false),
      hasSetupDraft: true,
    );
    _queueDraftPersist();
    _track('rematch_started');
    // Preserve the completed snapshot until the replacement round is ready.
  }

  bool toggleCategory(String id) {
    if (state.tournamentContext?.fixedCategoryIds.isNotEmpty == true) {
      return false;
    }
    final selected = [...state.selectedCategoryIds];
    if (selected.contains(id)) {
      // The first three slots belong to the first team.  Once the second
      // team has started, removing a first-team choice would shift ownership
      // of every later item in a flat list, so require the later slots to be
      // cleared first instead of silently transferring a category.
      if (selected.indexOf(id) < PartyGameRules.categoriesPerGame ~/ 2 &&
          selected.length > PartyGameRules.categoriesPerGame ~/ 2) {
        return false;
      }
      selected.remove(id);
    } else if (selected.length < PartyGameRules.categoriesPerGame) {
      selected.add(id);
    } else {
      return false;
    }
    state = state.copyWith(selectedCategoryIds: selected, clearError: true);
    _queueDraftPersist();
    _track('category_selected', {
      'category_id': id,
      'selected': selected.contains(id) ? 1 : 0,
      'selection_count': selected.length,
    });
    return true;
  }

  void setRandomCategories(List<String> ids) {
    if (state.tournamentContext?.fixedCategoryIds.isNotEmpty == true) return;
    state = state.copyWith(
      selectedCategoryIds: ids.take(PartyGameRules.categoriesPerGame).toList(),
      clearError: true,
    );
    _queueDraftPersist();
    _track('random_categories_used', {'category_count': ids.take(6).length});
  }

  void toggleFavorite(String id) {
    final favorites = {...state.favoriteCategoryIds};
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    state = state.copyWith(favoriteCategoryIds: favorites);
    unawaited(
      _database.putSetting(_favoritesKey, jsonEncode(favorites.toList())),
    );
    unawaited(_syncFavorite(id, favorites.contains(id)));
  }

  void updateTeam(
    int index, {
    String? name,
    int? colorValue,
    List<String>? players,
  }) {
    if (index < 0 || index > 1) return;
    if (state.tournamentContext != null && (name != null || players != null)) {
      return;
    }
    final teams = [...state.teams];
    teams[index] = teams[index].copyWith(
      name: name?.trim(),
      colorValue: colorValue,
      players: players,
    );
    state = state.copyWith(teams: teams, clearError: true);
    _queueDraftPersist();
  }

  String? completeTeamSetup({required bool useSplitter}) {
    if (state.tournamentContext != null && useSplitter) {
      return 'فرق البطولة ثابتة لهذه المباراة.';
    }
    final error = PartySetupValidation.teamError(state.teams);
    if (error != null) {
      state = state.copyWith(error: error);
      return error;
    }
    state = state.copyWith(
      teamSetupCompleted: true,
      splitterStatus: useSplitter
          ? PartySplitterStatus.requested
          : PartySplitterStatus.skipped,
      clearError: true,
    );
    _queueDraftPersist();
    _track('teams_completed', {'splitter_requested': useSplitter ? 1 : 0});
    return null;
  }

  void updateSplitterPlayers(List<String> names) {
    final clean = names.map((value) => value.trim()).toList(growable: false);
    state = state.copyWith(splitterPlayers: clean, clearError: true);
    _queueDraftPersist();
  }

  void skipSplitter() {
    state = state.copyWith(
      splitterStatus: PartySplitterStatus.skipped,
      clearError: true,
    );
    _queueDraftPersist();
  }

  bool splitPlayers(List<String> names, {int? seed}) {
    if (state.tournamentContext != null) return false;
    final clean = names
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (clean.length < 2) {
      state = state.copyWith(
        error: 'أضف لاعبين اثنين على الأقل حتى نقسمهم إلى فريقين.',
      );
      return false;
    }
    final normalized = clean
        .map((value) => value.toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
        .toSet();
    if (normalized.length != clean.length) {
      state = state.copyWith(error: 'كل لاعب يجب أن يظهر مرة واحدة فقط.');
      return false;
    }
    clean.shuffle(Random(seed));
    final first = <String>[];
    final second = <String>[];
    for (var index = 0; index < clean.length; index++) {
      (index.isEven ? first : second).add(clean[index]);
    }
    final teams = [...state.teams];
    teams[0] = teams[0].copyWith(players: first);
    teams[1] = teams[1].copyWith(players: second);
    state = state.copyWith(teams: teams, clearError: true);
    state = state.copyWith(
      splitterPlayers: clean,
      splitterStatus: PartySplitterStatus.completed,
    );
    _queueDraftPersist();
    _track('player_split_used', {'player_count': clean.length});
    return true;
  }

  bool assignPlayers(List<String> first, List<String> second) {
    final firstClean = first
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final secondClean = second
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (firstClean.isEmpty || secondClean.isEmpty) {
      state = state.copyWith(
        error: 'يجب أن يبقى لاعب واحد على الأقل في كل فريق.',
      );
      return false;
    }
    final allPlayers = [...firstClean, ...secondClean];
    final uniquePlayers = allPlayers
        .map((value) => value.toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
        .toSet();
    if (uniquePlayers.length != allPlayers.length) {
      state = state.copyWith(error: 'كل لاعب يجب أن يظهر مرة واحدة فقط.');
      return false;
    }
    final teams = [...state.teams];
    teams[0] = teams[0].copyWith(players: firstClean);
    teams[1] = teams[1].copyWith(players: secondClean);
    state = state.copyWith(teams: teams, clearError: true);
    state = state.copyWith(splitterStatus: PartySplitterStatus.completed);
    _queueDraftPersist();
    return true;
  }

  bool toggleHelper(int teamIndex, PartyHelperId helper) {
    if (teamIndex < 0 || teamIndex > 1) return false;
    if (helper == PartyHelperId.bench &&
        state.teams[1 - teamIndex].players.isEmpty) {
      return false;
    }
    final teams = [...state.teams];
    final selected = {...teams[teamIndex].selectedHelpers};
    if (selected.contains(helper)) {
      selected.remove(helper);
    } else if (selected.length < PartyGameRules.helpersPerTeam) {
      selected.add(helper);
    } else {
      return false;
    }
    teams[teamIndex] = teams[teamIndex].copyWith(selectedHelpers: selected);
    state = state.copyWith(teams: teams, clearError: true);
    _queueDraftPersist();
    _track('helper_selected', {
      'helper_id': helper.storageId,
      'team_index': teamIndex,
      'selected': selected.contains(helper) ? 1 : 0,
    });
    if (state.teams.every(
      (team) => team.selectedHelpers.length == PartyGameRules.helpersPerTeam,
    )) {
      _track('helpers_completed');
    }
    return true;
  }

  void setTimer(int? seconds) {
    state = state.copyWith(timerSeconds: seconds, clearTimer: seconds == null);
    _queueDraftPersist();
  }

  Future<bool> start(
    List<QuizCategory> categories,
    List<QuizQuestion> pool,
    List<PartyHelperDefinition> helperDefinitions,
    PartyRuntimeSettings runtimeSettings,
  ) async {
    if (state.busy || (!state.hasSetupDraft && state.session != null)) {
      return false;
    }
    final activeHelpers = helperDefinitions
        .map((definition) => definition.id)
        .toSet();
    final validationError = PartySetupValidation.readyError(
      hasSetupDraft: state.hasSetupDraft,
      teamSetupCompleted: state.teamSetupCompleted,
      splitterStatus: state.splitterStatus,
      selectedCategoryIds: state.selectedCategoryIds,
      playableCategoryIds: categories.map((category) => category.id).toSet(),
      teams: state.teams,
      activeHelperIds: activeHelpers,
    );
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return false;
    }
    _track('party_game_start_requested');
    state = state.copyWith(busy: true, clearError: true);
    try {
      final selected = state.selectedCategoryIds
          .map(
            (id) =>
                categories.where((category) => category.id == id).firstOrNull,
          )
          .whereType<QuizCategory>()
          .toList();
      final history = await ref.read(questionRepositoryProvider).loadHistory();
      final recentPartyIds = await _loadRecentPartyQuestionIds();
      var selectedPool = pool;
      if (ref.read(appConfigProvider).hasSupabase) {
        try {
          final exactPack = await fetchPartyQuestionPack(
            categoryIds: state.selectedCategoryIds,
          );
          if (exactPack.isNotEmpty) selectedPool = exactPack;
        } catch (_) {
          // The validated local cache remains a safe fallback for host mode.
        }
      }
      final session = const PartyGameEngine()
          .generate(
            categories: selected,
            pool: selectedPool,
            teams: state.teams,
            helperDefinitions: helperDefinitions,
            tieBreakerEnabled:
                state.tournamentContext?.tiebreakerEnabled ??
                runtimeSettings.tieBreakerEnabled,
            timerSeconds: state.timerSeconds,
            ruleConfig: runtimeSettings.rules,
            recentlySeen: {
              ...history.map((value) => value.questionId),
              ...recentPartyIds,
            },
          )
          .copyWith(tournamentContext: state.tournamentContext);
      await _draftWrite.catchError((_) {});
      await _persistStartedSession(session, state.history);
      state = state.copyWith(
        session: session,
        busy: false,
        hasSetupDraft: false,
      );
      _track('party_game_started', {
        'category_count': session.categories.length,
        'question_count': session.questions.length,
        'timer_enabled': session.timerSeconds == null ? 0 : 1,
      });
      return true;
    } on PartyGameGenerationException catch (error) {
      state = state.copyWith(busy: false, error: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        busy: false,
        error: 'تعذر تجهيز اللعبة. تحقق من الاتصال وحاول مرة أخرى.',
      );
      return false;
    }
  }

  bool chooseQuestion(String questionId) {
    final session = state.session;
    if (session == null || session.activeQuestionId != null) return false;
    final question = session.questions
        .where((value) => value.id == questionId)
        .firstOrNull;
    if (question == null || question.used) return false;
    _track('question_open_requested', {
      'question_format': question.format.name,
      'points': question.pointValue,
    });
    _setSession(
      session.copyWith(
        activeQuestionId: questionId,
        answeringTeamIndex: session.armedHelper == PartyHelperId.pass
            ? session.answeringTeamIndex
            : session.turnTeamIndex,
        stealActive: false,
        revealed: false,
        questionTimerStartedAt: session.armedHelper == PartyHelperId.callFriend
            ? DateTime.now()
            : session.timerSeconds == null
            ? null
            : DateTime.now(),
        questionTimerDurationSeconds:
            session.armedHelper == PartyHelperId.callFriend
            ? session
                      .helperDefinition(PartyHelperId.callFriend)
                      .callFriendSeconds ??
                  session.ruleConfig.callFriendSeconds
            : session.timerSeconds == null
            ? null
            : session.ruleConfig.primaryAnswerSeconds,
        clearQuestionTimer:
            session.timerSeconds == null &&
            session.armedHelper != PartyHelperId.callFriend,
      ),
    );
    unawaited(
      _recordRecentlySeen(
        questionId,
        gameId: session.id,
        categoryId: question.categoryId,
      ),
    );
    _track('question_opened', {
      'question_format': question.format.name,
      'points': question.pointValue,
    });
    return true;
  }

  bool useHelper(PartyHelperId helper, {String? actionDetail}) {
    final session = state.session;
    if (session == null) return false;
    if (!const PartyHelpEngine().canUse(session, helper)) return false;
    final teamIndex = session.turnTeamIndex;
    final team = session.teams[teamIndex];
    final helperDefinition = session.helperDefinition(helper);
    final teams = [...session.teams];
    teams[teamIndex] = team.copyWith(
      usedHelpers: {...team.usedHelpers, helper},
    );
    _setSession(
      session.copyWith(
        teams: teams,
        armedHelper: helper,
        helperActionDetail: actionDetail,
        answeringTeamIndex: helper == PartyHelperId.pass
            ? 1 - teamIndex
            : session.answeringTeamIndex,
        questionTimerStartedAt:
            helper == PartyHelperId.callFriend &&
                session.activeQuestionId != null
            ? DateTime.now()
            : null,
        questionTimerDurationSeconds:
            helper == PartyHelperId.callFriend &&
                session.activeQuestionId != null
            ? helperDefinition.callFriendSeconds ??
                  session.ruleConfig.callFriendSeconds
            : null,
      ),
    );
    _track('helper_used', {
      'helper_id': helper.storageId,
      'team_index': teamIndex,
    });
    return true;
  }

  bool revealAnswer() {
    final session = state.session;
    if (session == null || session.activeQuestion == null || session.revealed) {
      return false;
    }
    _setSession(session.copyWith(revealed: true, clearQuestionTimer: true));
    _track('answer_revealed', {
      'question_format': session.activeQuestion!.format.name,
      'points': session.activeQuestion!.pointValue,
    });
    return true;
  }

  /// Moves an unanswered question to the opponent for the configured steal
  /// window. The question remains hidden until the host explicitly reveals it.
  bool offerSteal() {
    final session = state.session;
    if (session == null ||
        session.activeQuestion == null ||
        session.revealed ||
        session.stealActive ||
        !session.ruleConfig.allowSteal ||
        session.armedHelper == PartyHelperId.pass) {
      return false;
    }
    final opponentIndex = 1 - session.turnTeamIndex;
    _setSession(
      session.copyWith(
        answeringTeamIndex: opponentIndex,
        stealActive: true,
        helperActionDetail:
            'فرصة خطف: ${session.teams[opponentIndex].name} يملك '
            '${session.ruleConfig.stealSeconds} ثوانٍ',
        questionTimerStartedAt: DateTime.now(),
        questionTimerDurationSeconds: session.ruleConfig.stealSeconds,
      ),
    );
    _track('steal_started', {
      'question_format': session.activeQuestion!.format.name,
      'answering_team_index': opponentIndex,
    });
    return true;
  }

  bool startTieBreaker() {
    final session = state.session;
    final question = session?.tieBreakerQuestion;
    if (session == null ||
        question == null ||
        session.tieBreakerStarted ||
        !session.regularBoardComplete ||
        session.scores[0] != session.scores[1]) {
      return false;
    }
    _setSession(
      session.copyWith(
        tieBreakerStarted: true,
        activeQuestionId: question.id,
        answeringTeamIndex: session.turnTeamIndex,
        stealActive: false,
        revealed: false,
        questionTimerStartedAt: session.timerSeconds == null
            ? null
            : DateTime.now(),
        questionTimerDurationSeconds: session.timerSeconds == null
            ? null
            : session.ruleConfig.primaryAnswerSeconds,
        clearQuestionTimer: session.timerSeconds == null,
        clearCompletedAt: true,
      ),
    );
    unawaited(
      _recordRecentlySeen(
        question.id,
        gameId: session.id,
        categoryId: question.categoryId,
      ),
    );
    _track('question_opened', {
      'question_format': question.format.name,
      'points': question.pointValue,
      'tie_breaker': 1,
    });
    return true;
  }

  bool award(int? teamIndex) {
    final session = state.session;
    final question = session?.activeQuestion;
    if (session == null || question == null || !session.revealed) return false;
    if (session.armedHelper == PartyHelperId.pass &&
        teamIndex != null &&
        teamIndex != session.answeringTeamIndex) {
      return false;
    }
    if (session.stealActive &&
        teamIndex != null &&
        teamIndex != session.answeringTeamIndex) {
      return false;
    }
    _track('score_award_requested', {
      'awarded_team_index': teamIndex ?? -1,
      'points': question.pointValue,
    });
    final deltas = const PartyScoreEngine().deltas(session, teamIndex);
    final isTieBreaker =
        session.tieBreakerStarted &&
        session.tieBreakerQuestion?.id == question.id;
    final categories = session.categories.map((category) {
      if (isTieBreaker) return category;
      if (category.id != question.categoryId) return category;
      return category.copyWith(
        questions: category.questions
            .map(
              (value) =>
                  value.id == question.id ? value.copyWith(used: true) : value,
            )
            .toList(),
      );
    }).toList();
    final event = PartyScoreEvent(
      questionId: question.id,
      teamDeltas: deltas,
      previousTurn: session.turnTeamIndex,
      createdAt: DateTime.now(),
      reason: switch (session.armedHelper) {
        PartyHelperId.risk =>
          teamIndex == session.turnTeamIndex
              ? 'إجابة صحيحة مع المخاطرة'
              : 'إجابة خاطئة مع المخاطرة',
        PartyHelperId.pass =>
          teamIndex == null
              ? 'الفخ: إجابة الفريق الآخر خاطئة'
              : 'الفخ: إجابة الفريق الآخر صحيحة',
        _ =>
          session.stealActive
              ? teamIndex == null
                    ? 'محاولة خطف خاطئة'
                    : 'خطف ناجح'
              : teamIndex == null
              ? 'إجابة خاطئة'
              : 'إجابة صحيحة',
      },
    );
    final tieBreakerQuestion = isTieBreaker
        ? session.tieBreakerQuestion?.copyWith(used: true)
        : session.tieBreakerQuestion;
    final regularBoardComplete = categories
        .expand((value) => value.questions)
        .every((value) => value.used);
    final complete =
        regularBoardComplete &&
        (!session.tieBreakerStarted || tieBreakerQuestion?.used == true);
    final nextTurn = const TurnEngine().nextTeam(
      turn: TurnSnapshot(
        activeTeamIndex: session.turnTeamIndex,
        answeringTeamIndex: session.answeringTeamIndex,
        phase: session.stealActive ? TurnPhase.steal : TurnPhase.reveal,
      ),
      awardedTeamIndex: teamIndex,
      rotation: session.ruleConfig.turnRotation,
    );
    final next = session.copyWith(
      categories: categories,
      scores: [session.scores[0] + deltas[0], session.scores[1] + deltas[1]],
      turnTeamIndex: nextTurn,
      answeringTeamIndex: nextTurn,
      clearActiveQuestion: true,
      revealed: false,
      clearArmedHelper: true,
      clearHelperActionDetail: true,
      clearQuestionTimer: true,
      stealActive: false,
      tieBreakerQuestion: tieBreakerQuestion,
      scoreEvents: [...session.scoreEvents, event],
      completedAt: complete ? DateTime.now() : null,
      clearCompletedAt: !complete,
    );
    _setSession(next);
    _track('score_awarded', {
      'awarded_team_index': teamIndex ?? -1,
      'points': question.pointValue,
    });
    _track('question_completed', {
      'question_format': question.format.name,
      'awarded_team_index': teamIndex ?? -1,
    });
    if (next.isComplete) {
      _track('party_game_completed', {
        'question_count': next.scoreEvents.length,
        'tied': next.scores[0] == next.scores[1] ? 1 : 0,
      });
    }
    return true;
  }

  bool undoLastScore() {
    final session = state.session;
    if (session == null || session.scoreEvents.isEmpty) return false;
    final event = session.scoreEvents.last;
    final categories = session.categories
        .map(
          (category) => category.copyWith(
            questions: category.questions
                .map(
                  (question) => question.id == event.questionId
                      ? question.copyWith(used: false)
                      : question,
                )
                .toList(),
          ),
        )
        .toList();
    _setSession(
      session.copyWith(
        categories: categories,
        scores: [
          session.scores[0] - event.teamDeltas[0],
          session.scores[1] - event.teamDeltas[1],
        ],
        turnTeamIndex: event.previousTurn,
        answeringTeamIndex: event.previousTurn,
        scoreEvents: session.scoreEvents.sublist(
          0,
          session.scoreEvents.length - 1,
        ),
        clearCompletedAt: true,
      ),
    );
    return true;
  }

  Future<void> clearCompletedGame() async {
    state = state.copyWith(clearSession: true);
    await _database.putSetting(_activeKey, '');
  }

  void _setSession(PartyGameSession session) {
    final withoutCurrent = state.history
        .where((game) => game.id != session.id)
        .toList(growable: false);
    final history = session.isComplete
        ? [session, ...withoutCurrent].take(30).toList(growable: false)
        : withoutCurrent;
    state = state.copyWith(session: session, history: history);
    unawaited(_persist(session, history));
  }

  void _track(String event, [Map<String, Object>? parameters]) {
    unawaited(ref.read(appServicesProvider).analytics.log(event, parameters));
  }

  void _queueDraftPersist() {
    if (!state.hasSetupDraft) {
      state = state.copyWith(hasSetupDraft: true);
    }
    final encoded = jsonEncode({
      'version': 2,
      'selected_category_ids': state.selectedCategoryIds,
      'teams': state.teams.map((team) => team.toJson()).toList(growable: false),
      'timer_seconds': state.timerSeconds,
      'team_setup_completed': state.teamSetupCompleted,
      'splitter_status': state.splitterStatus.name,
      'splitter_players': state.splitterPlayers,
      'tournament_context': state.tournamentContext?.toJson(),
    });
    final database = _database;
    _draftWrite = _draftWrite
        .catchError((_) {})
        .then((_) => database.putSetting(_setupDraftKey, encoded))
        .catchError((_) {});
  }

  Future<void> _persist(
    PartyGameSession session,
    List<PartyGameSession> history,
  ) async {
    final database = _database;
    try {
      await database.putSetting(_activeKey, session.encode());
      await database.putSetting(
        _historyKey,
        jsonEncode(
          history.map((game) => game.toJson()).toList(growable: false),
        ),
      );
    } catch (_) {
      // Gameplay remains available if local persistence is temporarily closed.
    }
  }

  Future<void> _persistStartedSession(
    PartyGameSession session,
    List<PartyGameSession> history,
  ) => _database.transaction(() async {
    await _database.putSetting(_activeKey, session.encode());
    await _database.putSetting(
      _historyKey,
      jsonEncode(history.map((game) => game.toJson()).toList(growable: false)),
    );
    await _database.putSetting(_setupDraftKey, '');
  });

  Future<Set<String>> _loadRecentPartyQuestionIds() async {
    final source = await _database.readSetting(_recentQuestionIdsKey);
    if (source == null || source.isEmpty) return <String>{};
    try {
      return (jsonDecode(source) as List).whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _recordRecentlySeen(
    String questionId, {
    required String gameId,
    required String categoryId,
  }) async {
    final database = _database;
    final accountId = ref.read(appConfigProvider).hasSupabase
        ? Supabase.instance.client.auth.currentUser?.id
        : null;
    try {
      final source = await database.readSetting(_recentQuestionIdsKey);
      final ids = <String>[];
      if (source != null && source.isNotEmpty) {
        try {
          ids.addAll((jsonDecode(source) as List).whereType<String>());
        } catch (_) {
          // A corrupt local preference is safely replaced below.
        }
      }
      ids
        ..remove(questionId)
        ..insert(0, questionId);
      await database.putSetting(
        _recentQuestionIdsKey,
        jsonEncode(ids.take(500).toList(growable: false)),
      );
      await database.recordQuestionUsage(
        id: '$gameId:$questionId',
        questionId: questionId,
        accountId: accountId,
        gameId: gameId,
        categoryId: categoryId,
        usedAt: DateTime.now().toUtc(),
      );
    } catch (_) {
      // Usage tracking is best-effort and must never interrupt an active game.
    }
  }

  Future<void> _mergeRemoteFavorites() async {
    if (!ref.read(appConfigProvider).hasSupabase) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      final rows = await Supabase.instance.client
          .from('party_category_favorites')
          .select('category_id')
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 4));
      final favorites = {...state.favoriteCategoryIds};
      favorites.addAll(
        rows
            .whereType<Map<String, Object?>>()
            .map((row) => row['category_id'])
            .whereType<String>(),
      );
      await _database.putSetting(_favoritesKey, jsonEncode(favorites.toList()));
      if (ref.mounted) {
        state = state.copyWith(favoriteCategoryIds: favorites);
      }
    } catch (_) {
      // Local favorites stay usable if the device is offline or migration is
      // not yet applied.
    }
  }

  Future<void> _syncFavorite(String categoryId, bool favorite) async {
    if (!ref.read(appConfigProvider).hasSupabase) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      if (favorite) {
        await client.from('party_category_favorites').upsert({
          'user_id': user.id,
          'category_id': categoryId,
        });
      } else {
        await client
            .from('party_category_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('category_id', categoryId);
      }
    } catch (_) {
      // Local state is authoritative until the next successful sync.
    }
  }
}
