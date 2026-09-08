import 'dart:math';

import 'package:uuid/uuid.dart';

import 'tournament.dart';

final class TournamentRuleException implements Exception {
  const TournamentRuleException(this.message);
  final String message;
  @override
  String toString() => message;
}

final class TournamentEngine {
  TournamentEngine({String Function()? idFactory})
    : _id = idFactory ?? const Uuid().v4;

  final String Function() _id;

  static String? tournamentNameError(String value) =>
      value.trim().length < 3 || value.trim().length > 60
      ? 'اسم البطولة يجب أن يكون بين 3 و60 حرفًا.'
      : null;

  Tournament create({
    required String name,
    required String organizerId,
    required TournamentRules rules,
    DateTime? now,
    String? tournamentId,
  }) {
    final cleanName = name.trim();
    final nameError = tournamentNameError(cleanName);
    if (nameError != null) {
      throw TournamentRuleException(nameError);
    }
    if (!TournamentRules.supportedCapacities.contains(rules.capacity) ||
        !TournamentRules.supportedPlayerCounts.contains(rules.playersPerTeam) ||
        rules.timerSeconds < 10 ||
        rules.timerSeconds > 120 ||
        rules.categoryIds.toSet().length != rules.categoryIds.length) {
      throw const TournamentRuleException('إعدادات البطولة غير مدعومة.');
    }
    return Tournament(
      id: tournamentId ?? _id(),
      name: cleanName,
      organizerId: organizerId,
      rules: rules,
      status: rules.visibility == TournamentVisibility.public
          ? TournamentStatus.registration
          : TournamentStatus.draft,
      teams: const [],
      matches: const [],
      createdAt: now ?? DateTime.now().toUtc(),
      inviteCode: rules.visibility == TournamentVisibility.private
          ? null
          : _id().replaceAll('-', '').substring(0, 8).toUpperCase(),
    );
  }

  Tournament addTeam(
    Tournament tournament, {
    required String name,
    List<String> players = const [],
  }) {
    if (!tournament.canEdit) {
      throw const TournamentRuleException(
        'لا يمكن تعديل الفرق بعد بدء البطولة.',
      );
    }
    final cleanName = name.trim();
    if (cleanName.length < 2 || cleanName.length > 40) {
      throw const TournamentRuleException(
        'اسم الفريق يجب أن يكون بين حرفين و40 حرفًا.',
      );
    }
    if (tournament.teams.length >= tournament.rules.capacity) {
      throw const TournamentRuleException('اكتمل عدد الفرق في البطولة.');
    }
    if (tournament.teams.any(
      (team) => team.name.toLowerCase() == cleanName.toLowerCase(),
    )) {
      throw const TournamentRuleException('اسم الفريق مستخدم في هذه البطولة.');
    }
    final cleanPlayers = players
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (cleanPlayers.length > tournament.rules.playersPerTeam) {
      throw const TournamentRuleException('عدد اللاعبين يتجاوز إعداد الفريق.');
    }
    if (cleanPlayers.any((name) => name.length > 50) ||
        cleanPlayers.map((name) => name.toLowerCase()).toSet().length !=
            cleanPlayers.length) {
      throw const TournamentRuleException('تحقق من أسماء اللاعبين دون تكرار.');
    }
    final occupiedPlayers = tournament.teams
        .expand((team) => team.players)
        .map((value) => value.toLowerCase())
        .toSet();
    if (cleanPlayers.any(
      (value) => occupiedPlayers.contains(value.toLowerCase()),
    )) {
      throw const TournamentRuleException(
        'لا يمكن تسجيل اللاعب في أكثر من فريق.',
      );
    }
    return tournament.copyWith(
      teams: [
        ...tournament.teams,
        TournamentTeam(id: _id(), name: cleanName, players: cleanPlayers),
      ],
    );
  }

  Tournament generateBracket(Tournament tournament, {int? randomSeed}) {
    if ((!tournament.canEdit && tournament.status != TournamentStatus.ready) ||
        tournament.matches.isNotEmpty) {
      throw const TournamentRuleException('تم تثبيت القرعة مسبقًا.');
    }
    final approved = tournament.teams.where((team) => team.approved).toList();
    if (approved.length < 2) {
      throw const TournamentRuleException(
        'تحتاج البطولة إلى فريقين على الأقل.',
      );
    }
    if (approved.length > tournament.rules.capacity) {
      throw const TournamentRuleException('عدد الفرق يتجاوز سعة البطولة.');
    }
    final ordered = [...approved];
    if (tournament.rules.seeding == TournamentSeeding.draw) {
      ordered.shuffle(Random(randomSeed));
    } else {
      ordered.sort((a, b) => (a.seed ?? 999).compareTo(b.seed ?? 999));
    }
    final seeded = [
      for (var index = 0; index < ordered.length; index++)
        ordered[index].copyWith(seed: index + 1),
    ];
    final slots = _seedOrder(tournament.rules.capacity)
        .map<String?>(
          (seed) => seed <= seeded.length ? seeded[seed - 1].id : null,
        )
        .toList();
    final rounds = log(tournament.rules.capacity) ~/ ln2;
    final matches = <TournamentMatch>[];
    final ids = <List<String>>[];
    for (var round = 1; round <= rounds; round++) {
      final count = tournament.rules.capacity >> round;
      ids.add(List.generate(count, (_) => _id()));
    }
    for (var round = 1; round <= rounds; round++) {
      final count = tournament.rules.capacity >> round;
      for (var position = 0; position < count; position++) {
        final isFirst = round == 1;
        final teamA = isFirst ? slots[position * 2] : null;
        final teamB = isFirst ? slots[position * 2 + 1] : null;
        final nextId = round < rounds ? ids[round][position ~/ 2] : null;
        matches.add(
          TournamentMatch(
            id: ids[round - 1][position],
            round: round,
            position: position,
            status: teamA != null && teamB != null
                ? TournamentMatchStatus.ready
                : TournamentMatchStatus.pending,
            teamAId: teamA,
            teamBId: teamB,
            nextMatchId: nextId,
            nextSlot: nextId == null ? null : position % 2,
          ),
        );
      }
    }
    final result = tournament.copyWith(
      teams: [...seeded, ...tournament.teams.where((team) => !team.approved)],
      matches: matches,
      status: TournamentStatus.live,
      clearChampion: true,
    );
    return _settleByes(result);
  }

  Tournament confirmResult(
    Tournament tournament, {
    required String matchId,
    required int scoreA,
    required int scoreB,
    String? winnerId,
    String? partySessionId,
    DateTime? now,
  }) {
    final match = tournament.matches
        .where((value) => value.id == matchId)
        .firstOrNull;
    if (match?.status == TournamentMatchStatus.completed &&
        match?.scoreA == scoreA &&
        match?.scoreB == scoreB &&
        (winnerId == null || winnerId == match?.winnerId) &&
        match?.partySessionId == partySessionId) {
      return tournament;
    }
    if (tournament.status != TournamentStatus.live ||
        match == null ||
        (match.status != TournamentMatchStatus.ready &&
            match.status != TournamentMatchStatus.live) ||
        !match.hasBothTeams) {
      throw const TournamentRuleException(
        'المباراة غير جاهزة لاعتماد النتيجة.',
      );
    }
    if (scoreA < 0 || scoreB < 0) {
      throw const TournamentRuleException('النتيجة لا تقبل أرقامًا سالبة.');
    }
    final resolvedWinner =
        winnerId ??
        (scoreA > scoreB
            ? match.teamAId
            : scoreB > scoreA
            ? match.teamBId
            : null);
    if (resolvedWinner == null) {
      throw const TournamentRuleException(
        'التعادل يحتاج سؤالًا فاصلًا قبل الاعتماد.',
      );
    }
    if (resolvedWinner != match.teamAId && resolvedWinner != match.teamBId) {
      throw const TournamentRuleException('الفائز ليس طرفًا في المباراة.');
    }
    if ((scoreA > scoreB && resolvedWinner != match.teamAId) ||
        (scoreB > scoreA && resolvedWinner != match.teamBId) ||
        (scoreA == scoreB && !tournament.rules.tiebreakerEnabled)) {
      throw const TournamentRuleException(
        'الفائز لا يطابق النتيجة أو قاعدة التعادل.',
      );
    }
    final updated = match.copyWith(
      status: TournamentMatchStatus.completed,
      scoreA: scoreA,
      scoreB: scoreB,
      winnerId: resolvedWinner,
      partySessionId: partySessionId,
      confirmedAt: now ?? DateTime.now().toUtc(),
    );
    var result = tournament.copyWith(
      matches: tournament.matches
          .map((value) => value.id == matchId ? updated : value)
          .toList(),
    );
    result = _advance(result, updated);
    return _settleByes(result);
  }

  Tournament undoResult(Tournament tournament, String matchId) {
    final match = tournament.matches
        .where((value) => value.id == matchId)
        .firstOrNull;
    if (match == null || match.status != TournamentMatchStatus.completed) {
      throw const TournamentRuleException('لا توجد نتيجة معتمدة للتراجع عنها.');
    }
    if (match.nextMatchId != null) {
      final dependent = tournament.matches.firstWhere(
        (value) => value.id == match.nextMatchId,
      );
      if (dependent.status == TournamentMatchStatus.completed ||
          dependent.status == TournamentMatchStatus.live) {
        throw const TournamentRuleException(
          'لا يمكن التراجع بعد لعب المباراة التالية.',
        );
      }
    }
    final reset = match.copyWith(
      status: TournamentMatchStatus.ready,
      clearScore: true,
      clearWinner: true,
      clearConfirmation: true,
    );
    final matches = tournament.matches.map((value) {
      if (value.id == reset.id) return reset;
      if (value.id != match.nextMatchId) return value;
      return match.nextSlot == 0
          ? value.copyWith(
              clearTeamA: true,
              status: TournamentMatchStatus.pending,
            )
          : value.copyWith(
              clearTeamB: true,
              status: TournamentMatchStatus.pending,
            );
    }).toList();
    return tournament.copyWith(
      status: TournamentStatus.live,
      matches: matches,
      clearChampion: true,
    );
  }

  Tournament _settleByes(Tournament tournament) {
    var result = tournament;
    var changed = true;
    while (changed) {
      changed = false;
      for (final candidate in result.matches) {
        final match = result.matches.firstWhere(
          (value) => value.id == candidate.id,
        );
        if (match.status != TournamentMatchStatus.pending) continue;
        if (match.round > 1) {
          final feeders = result.matches
              .where((value) => value.nextMatchId == match.id)
              .toList(growable: false);
          final feedersSettled =
              feeders.length == 2 &&
              feeders.every(
                (value) =>
                    value.status == TournamentMatchStatus.completed ||
                    value.status == TournamentMatchStatus.bye,
              );
          if (!feedersSettled) continue;
        }
        final hasA = match.teamAId != null;
        final hasB = match.teamBId != null;
        if (hasA && hasB) {
          result = result.copyWith(
            matches: result.matches
                .map(
                  (value) => value.id == match.id
                      ? value.copyWith(status: TournamentMatchStatus.ready)
                      : value,
                )
                .toList(),
          );
          changed = true;
        } else {
          final bye = match.copyWith(
            status: TournamentMatchStatus.bye,
            winnerId: match.teamAId ?? match.teamBId,
          );
          result = result.copyWith(
            matches: result.matches
                .map((value) => value.id == match.id ? bye : value)
                .toList(),
          );
          result = _advance(result, bye);
          changed = true;
        }
      }
    }
    return result;
  }

  Tournament _advance(Tournament tournament, TournamentMatch match) {
    if (match.nextMatchId == null) {
      return tournament.copyWith(
        status: TournamentStatus.completed,
        championTeamId: match.winnerId,
      );
    }
    final matches = tournament.matches.map((value) {
      if (value.id != match.nextMatchId) return value;
      final next = match.nextSlot == 0
          ? value.copyWith(teamAId: match.winnerId)
          : value.copyWith(teamBId: match.winnerId);
      return next.hasBothTeams
          ? next.copyWith(status: TournamentMatchStatus.ready)
          : next;
    }).toList();
    return tournament.copyWith(matches: matches);
  }

  List<int> _seedOrder(int size) {
    var order = <int>[1, 2];
    for (var bracket = 4; bracket <= size; bracket *= 2) {
      order = [
        for (final seed in order) ...[seed, bracket + 1 - seed],
      ];
    }
    return order;
  }
}
