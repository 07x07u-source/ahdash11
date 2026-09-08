import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/app_error_reporter.dart';
import '../../../core/services/app_services.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/storage/app_database.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../party/presentation/party_game_controller.dart';
import '../data/tournament_gateway.dart';
import '../domain/tournament.dart';
import '../domain/tournament_engine.dart';

final tournamentControllerProvider =
    NotifierProvider<TournamentController, TournamentState>(
      TournamentController.new,
    );

final class TournamentState {
  const TournamentState({
    this.active,
    this.history = const [],
    this.restored = false,
    this.busy = false,
    this.error,
    this.partyMatchId,
  });

  final Tournament? active;
  final List<Tournament> history;
  final bool restored;
  final bool busy;
  final String? error;
  final String? partyMatchId;

  TournamentState copyWith({
    Tournament? active,
    bool clearActive = false,
    List<Tournament>? history,
    bool? restored,
    bool? busy,
    String? error,
    bool clearError = false,
    String? partyMatchId,
    bool clearPartyMatch = false,
  }) => TournamentState(
    active: clearActive ? null : active ?? this.active,
    history: history ?? this.history,
    restored: restored ?? this.restored,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    partyMatchId: clearPartyMatch ? null : partyMatchId ?? this.partyMatchId,
  );
}

class TournamentController extends Notifier<TournamentState> {
  static const _activeKey = 'tournament_active_v1';
  static const _historyKey = 'tournament_history_v1';
  static const _partyContextKey = 'tournament_party_context_v1';
  static const _pendingBracketKey = 'tournament_pending_bracket_v2';
  static const _pendingCreateKey = 'tournament_pending_create_v2';
  static const _wizardKey = 'tournament_wizard_v2';
  final _engine = TournamentEngine();
  Future<void>? _restoreTask;
  Tournament? _pendingBracket;
  Tournament? _pendingCreate;
  String? _wizardId;
  Future<void> _wizardWrite = Future<void>.value();

  bool get canManage {
    final config = ref.read(appConfigProvider);
    if (!config.hasSupabase) {
      return config.environment == AppEnvironment.development;
    }
    final auth = ref.read(authControllerProvider).value;
    return auth != null &&
        !auth.isGuest &&
        (state.active == null || state.active!.organizerId == auth.id);
  }

  Future<Map<String, Object?>?> readWizard() async {
    String? encoded;
    try {
      encoded = await _database
          .readSetting(_wizardKey)
          .timeout(const Duration(seconds: 5));
    } on Object {
      return null;
    }
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final draft = Map<String, Object?>.from(jsonDecode(encoded) as Map);
      _wizardId = draft['id'] as String?;
      return draft;
    } on Object {
      return null;
    }
  }

  Future<void> saveWizard(Map<String, Object?> draft) {
    final encoded = jsonEncode({
      ...draft,
      'id': _wizardId ??= const Uuid().v4(),
    });
    return _wizardWrite = _wizardWrite
        .catchError((_) {})
        .then((_) => _database.putSetting(_wizardKey, encoded));
  }

  AppDatabase get _database => ref.read(appDatabaseProvider);

  @override
  TournamentState build() => const TournamentState();

  Future<void> restore() => _restoreTask ??= _restoreWithDeadline();

  Future<void> _restoreWithDeadline() async {
    try {
      await _restore().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      if (ref.mounted && !state.restored) {
        state = state.copyWith(restored: true);
      }
    }
  }

  Future<void> _restore() async {
    if (state.restored) return;
    Tournament? active;
    var history = <Tournament>[];
    String? partyMatchId;
    try {
      final pendingCreate = await _database.readSetting(_pendingCreateKey);
      if (pendingCreate != null && pendingCreate.isNotEmpty) {
        _pendingCreate = Tournament.decode(pendingCreate);
      }
      final encoded = await _database.readSetting(_activeKey);
      if (encoded != null && encoded.isNotEmpty) {
        active = Tournament.decode(encoded);
      }
      final encodedHistory = await _database.readSetting(_historyKey);
      if (encodedHistory != null) {
        history = (jsonDecode(encodedHistory) as List)
            .whereType<Map<Object?, Object?>>()
            .map(
              (value) => Tournament.fromJson(Map<String, Object?>.from(value)),
            )
            .toList(growable: false);
      }
      final encodedPartyContext = await _database.readSetting(_partyContextKey);
      if (encodedPartyContext != null &&
          encodedPartyContext.isNotEmpty &&
          active != null) {
        final context = Map<String, Object?>.from(
          jsonDecode(encodedPartyContext) as Map,
        );
        final candidate = context['match_id'] as String?;
        if (context['tournament_id'] == active.id &&
            active.matches.any(
              (match) =>
                  match.id == candidate &&
                  (match.status == TournamentMatchStatus.ready ||
                      match.status == TournamentMatchStatus.live),
            )) {
          partyMatchId = candidate;
        }
      }
      final encodedPendingBracket = await _database.readSetting(
        _pendingBracketKey,
      );
      if (encodedPendingBracket != null && encodedPendingBracket.isNotEmpty) {
        final pending = Tournament.decode(encodedPendingBracket);
        if (active != null &&
            active.canDraw &&
            _sameTeamDraft(active, pending)) {
          _pendingBracket = pending;
        }
      }
    } on Object {
      // Local cache corruption must not stop the user from creating a bracket.
    }
    state = state.copyWith(
      active: active,
      history: history,
      restored: true,
      partyMatchId: partyMatchId,
      clearPartyMatch: partyMatchId == null,
    );
    if (active != null && ref.read(appConfigProvider).hasSupabase) {
      await refresh();
    }
  }

  Future<bool> refresh({String? tournamentId}) async {
    final id = tournamentId ?? state.active?.id;
    if (id == null || !ref.read(appConfigProvider).hasSupabase) return true;
    try {
      final remote = await ref
          .read(tournamentGatewayProvider)
          .loadTournament(id);
      if (remote == null) throw StateError('Unavailable');
      final cached = state.active;
      // Manually entered teams are staged locally until the safe bracket RPC
      // commits them. Never overwrite approved server roster identities.
      final merged = cached?.id == remote.id && remote.canEdit
          ? remote.copyWith(
              teams: [
                ...remote.teams,
                ...cached!.teams.where(
                  (team) =>
                      team.registrationStatus == null &&
                      !remote.teams.any((value) => value.id == team.id),
                ),
              ],
            )
          : remote;
      state = state.copyWith(active: merged, clearError: true);
      await _persist();
      return true;
    } on Object {
      state = state.copyWith(
        error:
            'تعذر تحديث البطولة. المعروض نسخة محفوظة؛ يتطلب الحفظ اتصالًا بالخادم.',
      );
      return false;
    }
  }

  Future<Tournament?> create({
    required String name,
    required TournamentRules rules,
  }) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await restore();
      final auth = await ref.read(authControllerProvider.future);
      _requireAuthority(auth, creating: true);
      final previous = _pendingCreate;
      if (previous != null &&
          (previous.name != name.trim() ||
              jsonEncode(previous.rules.toJson()) !=
                  jsonEncode(rules.toJson()))) {
        throw const TournamentRuleException(
          'أعد محاولة الإنشاء بالقيم السابقة أولًا للتحقق من نتيجة الحفظ.',
        );
      }
      var tournament =
          previous ??
          _engine.create(
            name: name,
            organizerId: auth?.id ?? 'local-organizer',
            rules: rules,
            tournamentId: (await readWizard())?['id'] as String?,
          );
      _pendingCreate = tournament;
      await _database.putSetting(_pendingCreateKey, tournament.encode());
      if (_requiresRemote(auth)) {
        final inviteCode = await ref
            .read(tournamentGatewayProvider)
            .createTournament(tournament);
        tournament = tournament.copyWith(
          inviteCode: inviteCode,
          clearInviteCode: inviteCode == null,
        );
      }
      state = state.copyWith(
        active: tournament,
        clearError: true,
        clearPartyMatch: true,
      );
      await _persist();
      await _clearPendingBracket();
      await _persistPartyContext();
      await _wizardWrite;
      await _database.putSetting(_wizardKey, '');
      await _database.putSetting(_pendingCreateKey, '');
      _pendingCreate = null;
      _wizardId = null;
      state = state.copyWith(busy: false);
      _confirmedFeedback('tournament_created', FeedbackCue.ready);
      return state.active ?? tournament;
    } on TournamentRuleException catch (error) {
      state = state.copyWith(busy: false, error: error.message);
      return null;
    } on Object catch (error) {
      _reportUnexpected(error, 'create');
      state = state.copyWith(
        busy: false,
        error:
            'لم نتأكد من إنشاء البطولة. أعد المحاولة بنفس القيم؛ سيُستخدم نفس المعرّف.',
      );
      return null;
    }
  }

  Future<bool> addTeam(String name, {List<String> players = const []}) async {
    if (state.busy) return false;
    final active = state.active;
    if (active == null) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      _requireAuthority(await ref.read(authControllerProvider.future));
      if (_pendingBracket != null) {
        throw const TournamentRuleException(
          'تحقق من نتيجة القرعة السابقة بإعادة المحاولة قبل تعديل الفرق.',
        );
      }
      final updated = _engine.addTeam(active, name: name, players: players);
      state = state.copyWith(active: updated, clearError: true);
      await _persist();
      await _clearPendingBracket();
      state = state.copyWith(busy: false);
      return true;
    } on TournamentRuleException catch (error) {
      state = state.copyWith(busy: false, error: error.message);
      return false;
    } on Object {
      state = state.copyWith(busy: false, error: 'تعذر حفظ مسودة الفريق.');
      return false;
    }
  }

  Future<bool> generateBracket({int? randomSeed}) async {
    if (state.busy) return false;
    final active = state.active;
    if (active == null) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      _requireAuthority(await ref.read(authControllerProvider.future));
      final updated =
          _pendingBracket != null && _sameTeamDraft(active, _pendingBracket!)
          ? _pendingBracket!
          : _engine.generateBracket(
              active,
              randomSeed: randomSeed ?? _stableSeed(active.id),
            );
      _pendingBracket = updated;
      await _database.putSetting(_pendingBracketKey, updated.encode());
      final auth = await ref.read(authControllerProvider.future);
      if (_requiresRemote(auth)) {
        await ref.read(tournamentGatewayProvider).saveBracket(updated);
      }
      state = state.copyWith(active: updated, busy: false, clearError: true);
      await _persist();
      await _clearPendingBracket();
      _confirmedFeedback('tournament_draw_completed', FeedbackCue.ready);
      return true;
    } on TournamentRuleException catch (error) {
      state = state.copyWith(busy: false, error: error.message);
      return false;
    } on Object catch (error) {
      _reportUnexpected(error, 'draw');
      state = state.copyWith(
        busy: false,
        error:
            'تعذر تثبيت القرعة بأمان. لم تبدأ البطولة؛ تحقق من تحديث الخادم وحاول مجددًا.',
      );
      return false;
    }
  }

  Future<bool> confirmResult({
    required String matchId,
    required int scoreA,
    required int scoreB,
    String? winnerId,
    String? partySessionId,
  }) async {
    if (state.busy) return false;
    final active = state.active;
    if (active == null) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      _requireAuthority(await ref.read(authControllerProvider.future));
      if (partySessionId != null) {
        final session = ref.read(partyGameControllerProvider).session;
        final context = session?.tournamentContext;
        final sourceMatch = active.matches
            .where((match) => match.id == matchId)
            .firstOrNull;
        if (session == null ||
            !session.isComplete ||
            session.id != partySessionId ||
            context?.tournamentId != active.id ||
            context?.matchId != matchId ||
            context?.teamAId != sourceMatch?.teamAId ||
            context?.teamBId != sourceMatch?.teamBId ||
            session.scores[0] != scoreA ||
            session.scores[1] != scoreB ||
            scoreA == scoreB) {
          throw const TournamentRuleException(
            'نتيجة Party لا تطابق هذه المباراة أو لم تُحسم بعد.',
          );
        }
      }
      final updated = _engine.confirmResult(
        active,
        matchId: matchId,
        scoreA: scoreA,
        scoreB: scoreB,
        winnerId: winnerId,
        partySessionId: partySessionId,
      );
      final updatedMatch = updated.matches.firstWhere(
        (match) => match.id == matchId,
      );
      final auth = await ref.read(authControllerProvider.future);
      if (_requiresRemote(auth)) {
        await ref
            .read(tournamentGatewayProvider)
            .confirmResult(tournamentId: updated.id, match: updatedMatch);
      }
      final history = updated.status == TournamentStatus.completed
          ? [updated, ...state.history.where((value) => value.id != updated.id)]
          : state.history;
      state = state.copyWith(
        active: updated,
        history: history,
        busy: false,
        clearError: true,
      );
      await _persist();
      final wasConfirmed = active.matches.any(
        (match) => match.id == matchId && match.confirmedAt != null,
      );
      if (!wasConfirmed) {
        _confirmedFeedback(
          'tournament_result_confirmed',
          updated.hasConfirmedChampion ? FeedbackCue.win : FeedbackCue.correct,
        );
        if (updated.hasConfirmedChampion) {
          _track('tournament_completed');
        }
      }
      return true;
    } on TournamentRuleException catch (error) {
      state = state.copyWith(busy: false, error: error.message);
      return false;
    } on Object catch (error) {
      _reportUnexpected(error, 'confirm_result');
      state = state.copyWith(
        busy: false,
        error: 'تعذر اعتماد النتيجة على الخادم. بقيت المباراة دون تغيير.',
      );
      return false;
    }
  }

  Future<bool> undoResult(String matchId) async {
    final active = state.active;
    if (active == null) return false;
    try {
      _requireAuthority(await ref.read(authControllerProvider.future));
      if (ref.read(appConfigProvider).hasSupabase) {
        throw const TournamentRuleException(
          'التراجع عن النتائج غير متاح من هذا الإصدار.',
        );
      }
      final updated = _engine.undoResult(active, matchId);
      state = state.copyWith(
        active: updated,
        history: state.history
            .where((value) => value.id != updated.id)
            .toList(),
        clearError: true,
      );
      await _persist();
      return true;
    } on TournamentRuleException catch (error) {
      state = state.copyWith(error: error.message);
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  void _track(String event) {
    unawaited(
      ref.read(appServicesProvider).analytics.log(event).catchError((_) {}),
    );
  }

  void _confirmedFeedback(String event, FeedbackCue cue) {
    _track(event);
    unawaited(ref.read(feedbackServiceProvider).play(cue).catchError((_) {}));
  }

  void _reportUnexpected(Object error, String operation) {
    if (error is! Error) return;
    unawaited(
      ref
          .read(appServicesProvider)
          .errors
          .report(
            severity: AppErrorSeverity.error,
            category: AppErrorCategory.unexpectedState,
            feature: 'tournament',
            error: StateError('Unexpected tournament operation failure'),
            screen: '/tournaments',
            context: {
              'operation': operation,
              'state': state.active?.status.name,
            },
          )
          .catchError((_) {}),
    );
  }

  Future<bool> selectPartyMatch(String matchId) async {
    try {
      _requireAuthority(await ref.read(authControllerProvider.future));
    } on TournamentRuleException catch (error) {
      state = state.copyWith(error: error.message);
      return false;
    }
    final rules = state.active?.rules;
    if (rules != null &&
        (!rules.helpersEnabled ||
            (rules.categoryIds.isNotEmpty && rules.categoryIds.length != 6))) {
      state = state.copyWith(
        error:
            'قواعد هذه البطولة لا تتوافق مع إعداد Party الحالي. يمكن تسجيل نتيجة خارجية بواسطة المنظم.',
      );
      return false;
    }
    final match = state.active?.matches
        .where((value) => value.id == matchId)
        .firstOrNull;
    if (match == null ||
        !match.hasBothTeams ||
        (match.status != TournamentMatchStatus.ready &&
            match.status != TournamentMatchStatus.live)) {
      state = state.copyWith(error: 'هذه المباراة ليست جاهزة بعد.');
      return false;
    }
    state = state.copyWith(partyMatchId: matchId, clearError: true);
    await _persistPartyContext();
    return true;
  }

  Future<void> clearPartyMatch() async {
    state = state.copyWith(clearPartyMatch: true);
    await _persistPartyContext();
  }

  Future<void> restoreMatch(String matchId) async {
    await restore();
    if (state.active?.matches.any((match) => match.id == matchId) == true ||
        !ref.read(appConfigProvider).hasSupabase) {
      return;
    }
    try {
      final id = await ref
          .read(tournamentGatewayProvider)
          .tournamentIdForMatch(matchId);
      if (id != null) await refresh(tournamentId: id);
    } on Object {
      state = state.copyWith(
        error: 'تعذر تحميل رابط المباراة. تحقق من الاتصال والصلاحية.',
      );
    }
  }

  Future<void> _persist() async {
    final active = state.active;
    if (active != null) await _database.putSetting(_activeKey, active.encode());
    await _database.putSetting(
      _historyKey,
      jsonEncode(state.history.map((value) => value.toJson()).toList()),
    );
  }

  bool _requiresRemote(AuthUser? auth) =>
      ref.read(appConfigProvider).hasSupabase;

  void _requireAuthority(AuthUser? auth, {bool creating = false}) {
    final config = ref.read(appConfigProvider);
    if (!config.hasSupabase &&
        config.environment == AppEnvironment.development) {
      return;
    }
    if (!config.hasSupabase || auth == null || auth.isGuest) {
      throw const TournamentRuleException(
        'يلزم تسجيل الدخول واتصال بخادم البطولة.',
      );
    }
    if (!creating && state.active?.organizerId != auth.id) {
      throw const TournamentRuleException(
        'هذا الإجراء متاح لمنظم البطولة فقط.',
      );
    }
    if (creating &&
        _pendingCreate != null &&
        _pendingCreate!.organizerId != auth.id) {
      throw const TournamentRuleException('مسودة الإنشاء تخص حسابًا آخر.');
    }
  }

  Future<void> _persistPartyContext() async {
    final active = state.active;
    final matchId = state.partyMatchId;
    await _database.putSetting(
      _partyContextKey,
      active == null || matchId == null
          ? ''
          : jsonEncode({'tournament_id': active.id, 'match_id': matchId}),
    );
  }

  Future<void> _clearPendingBracket() async {
    _pendingBracket = null;
    await _database.putSetting(_pendingBracketKey, '');
  }

  bool _sameTeamDraft(Tournament draft, Tournament candidate) {
    if (draft.id != candidate.id ||
        draft.rules.capacity != candidate.rules.capacity ||
        draft.teams.length != candidate.teams.length) {
      return false;
    }
    for (final team in draft.teams) {
      final matching = candidate.teams
          .where((value) => value.id == team.id)
          .firstOrNull;
      if (matching == null ||
          matching.name != team.name ||
          matching.approved != team.approved ||
          !_sameStrings(matching.players, team.players)) {
        return false;
      }
    }
    return true;
  }

  bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  int _stableSeed(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}
