import 'dart:convert';

enum TournamentStatus { draft, registration, ready, live, completed, cancelled }

enum TournamentVisibility { private, invite, public }

enum TournamentSeeding { draw, manual }

enum TournamentMatchStatus { pending, ready, live, completed, bye, cancelled }

final class TournamentRules {
  const TournamentRules({
    required this.capacity,
    this.playersPerTeam = 1,
    this.visibility = TournamentVisibility.private,
    this.seeding = TournamentSeeding.draw,
    this.categoryIds = const [],
    this.timerSeconds = 30,
    this.helpersEnabled = true,
    this.tiebreakerEnabled = true,
  }) : assert(
         capacity == 4 ||
             capacity == 8 ||
             capacity == 16 ||
             capacity == 32 ||
             capacity == 64,
       ),
       assert(playersPerTeam >= 1 && playersPerTeam <= 8);

  factory TournamentRules.fromJson(Map<String, Object?> json) =>
      TournamentRules(
        capacity: (json['capacity'] as num?)?.toInt() ?? 8,
        playersPerTeam: (json['players_per_team'] as num?)?.toInt() ?? 1,
        visibility: TournamentVisibility.values.byName(
          json['visibility'] as String? ?? 'private',
        ),
        seeding: TournamentSeeding.values.byName(
          json['seeding'] as String? ?? 'draw',
        ),
        categoryIds: (json['category_ids'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        timerSeconds: (json['timer_seconds'] as num?)?.toInt() ?? 30,
        helpersEnabled: json['helpers_enabled'] as bool? ?? true,
        tiebreakerEnabled: json['tiebreaker_enabled'] as bool? ?? true,
      );

  final int capacity;
  static const supportedCapacities = [4, 8, 16, 32, 64];
  static const supportedPlayerCounts = [1, 2, 3, 4, 5, 6, 7, 8];
  final int playersPerTeam;
  final TournamentVisibility visibility;
  final TournamentSeeding seeding;
  final List<String> categoryIds;
  final int timerSeconds;
  final bool helpersEnabled;
  final bool tiebreakerEnabled;

  Map<String, Object?> toJson() => {
    'capacity': capacity,
    'players_per_team': playersPerTeam,
    'visibility': visibility.name,
    'seeding': seeding.name,
    'category_ids': categoryIds,
    'timer_seconds': timerSeconds,
    'helpers_enabled': helpersEnabled,
    'tiebreaker_enabled': tiebreakerEnabled,
  };
}

final class TournamentTeam {
  const TournamentTeam({
    required this.id,
    required this.name,
    this.players = const [],
    this.seed,
    this.approved = true,
    this.roster = const [],
    this.ownerUserId,
    this.registrationStatus,
  });

  factory TournamentTeam.fromJson(Map<String, Object?> json) => TournamentTeam(
    id: json['id'] as String,
    name: json['name'] as String,
    players: (json['players'] as List? ?? const []).whereType<String>().toList(
      growable: false,
    ),
    seed: (json['seed'] as num?)?.toInt(),
    approved: json['approved'] as bool? ?? true,
    roster: (json['roster'] as List? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(),
    ownerUserId: json['owner_user_id'] as String?,
    registrationStatus: json['registration_status'] as String?,
  );

  final String id;
  final String name;
  final List<String> players;
  final int? seed;
  final bool approved;

  /// Original server identities, including user_id and captain role.
  final List<Map<String, Object?>> roster;
  final String? ownerUserId;
  final String? registrationStatus;

  TournamentTeam copyWith({int? seed, bool? approved}) => TournamentTeam(
    id: id,
    name: name,
    players: players,
    seed: seed ?? this.seed,
    approved: approved ?? this.approved,
    roster: roster,
    ownerUserId: ownerUserId,
    registrationStatus: registrationStatus,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'players': players,
    'seed': seed,
    'approved': approved,
    'roster': roster,
    'owner_user_id': ownerUserId,
    'registration_status': registrationStatus,
  };
}

final class TournamentMatch {
  const TournamentMatch({
    required this.id,
    required this.round,
    required this.position,
    required this.status,
    this.teamAId,
    this.teamBId,
    this.scoreA,
    this.scoreB,
    this.winnerId,
    this.nextMatchId,
    this.nextSlot,
    this.partySessionId,
    this.confirmedAt,
  });

  factory TournamentMatch.fromJson(Map<String, Object?> json) =>
      TournamentMatch(
        id: json['id'] as String,
        round: (json['round'] as num).toInt(),
        position: (json['position'] as num).toInt(),
        status: TournamentMatchStatus.values.byName(json['status'] as String),
        teamAId: json['team_a_id'] as String?,
        teamBId: json['team_b_id'] as String?,
        scoreA: (json['score_a'] as num?)?.toInt(),
        scoreB: (json['score_b'] as num?)?.toInt(),
        winnerId: json['winner_id'] as String?,
        nextMatchId: json['next_match_id'] as String?,
        nextSlot: (json['next_slot'] as num?)?.toInt(),
        partySessionId: json['party_session_id'] as String?,
        confirmedAt: DateTime.tryParse('${json['confirmed_at'] ?? ''}'),
      );

  final String id;
  final int round;
  final int position;
  final TournamentMatchStatus status;
  final String? teamAId;
  final String? teamBId;
  final int? scoreA;
  final int? scoreB;
  final String? winnerId;
  final String? nextMatchId;
  final int? nextSlot;
  final String? partySessionId;
  final DateTime? confirmedAt;

  bool get hasBothTeams => teamAId != null && teamBId != null;

  TournamentMatch copyWith({
    TournamentMatchStatus? status,
    String? teamAId,
    bool clearTeamA = false,
    String? teamBId,
    bool clearTeamB = false,
    int? scoreA,
    bool clearScore = false,
    int? scoreB,
    String? winnerId,
    bool clearWinner = false,
    String? partySessionId,
    DateTime? confirmedAt,
    bool clearConfirmation = false,
  }) => TournamentMatch(
    id: id,
    round: round,
    position: position,
    status: status ?? this.status,
    teamAId: clearTeamA ? null : teamAId ?? this.teamAId,
    teamBId: clearTeamB ? null : teamBId ?? this.teamBId,
    scoreA: clearScore ? null : scoreA ?? this.scoreA,
    scoreB: clearScore ? null : scoreB ?? this.scoreB,
    winnerId: clearWinner ? null : winnerId ?? this.winnerId,
    nextMatchId: nextMatchId,
    nextSlot: nextSlot,
    partySessionId: partySessionId ?? this.partySessionId,
    confirmedAt: clearConfirmation ? null : confirmedAt ?? this.confirmedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'round': round,
    'position': position,
    'status': status.name,
    'team_a_id': teamAId,
    'team_b_id': teamBId,
    'score_a': scoreA,
    'score_b': scoreB,
    'winner_id': winnerId,
    'next_match_id': nextMatchId,
    'next_slot': nextSlot,
    'party_session_id': partySessionId,
    'confirmed_at': confirmedAt?.toUtc().toIso8601String(),
  };
}

final class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.organizerId,
    required this.rules,
    required this.status,
    required this.teams,
    required this.matches,
    required this.createdAt,
    this.inviteCode,
    this.championTeamId,
  });

  factory Tournament.fromJson(Map<String, Object?> json) => Tournament(
    id: json['id'] as String,
    name: json['name'] as String,
    organizerId: json['organizer_id'] as String,
    rules: TournamentRules.fromJson(
      Map<String, Object?>.from(json['rules'] as Map<Object?, Object?>),
    ),
    status: TournamentStatus.values.byName(json['status'] as String),
    teams: (json['teams'] as List? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(
          (value) => TournamentTeam.fromJson(Map<String, Object?>.from(value)),
        )
        .toList(growable: false),
    matches: (json['matches'] as List? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(
          (value) => TournamentMatch.fromJson(Map<String, Object?>.from(value)),
        )
        .toList(growable: false),
    createdAt: DateTime.parse(json['created_at'] as String),
    inviteCode: json['invite_code'] as String?,
    championTeamId: json['champion_team_id'] as String?,
  );

  final String id;
  final String name;
  final String organizerId;
  final TournamentRules rules;
  final TournamentStatus status;
  final List<TournamentTeam> teams;
  final List<TournamentMatch> matches;
  final DateTime createdAt;
  final String? inviteCode;
  final String? championTeamId;

  bool get canEdit =>
      status == TournamentStatus.draft ||
      status == TournamentStatus.registration;
  bool get canResume => status == TournamentStatus.live;
  bool get canDraw =>
      (canEdit || status == TournamentStatus.ready) &&
      matches.isEmpty &&
      teams.where((team) => team.approved).length >= 2 &&
      teams.where((team) => team.approved).length <= rules.capacity;

  TournamentMatch? get finalMatch =>
      matches.where((match) => match.nextMatchId == null).singleOrNull;

  bool get hasConfirmedChampion =>
      status == TournamentStatus.completed &&
      championTeamId != null &&
      team(championTeamId) != null &&
      finalMatch?.status == TournamentMatchStatus.completed &&
      finalMatch?.winnerId == championTeamId &&
      finalMatch?.confirmedAt != null;
  TournamentTeam? team(String? id) =>
      id == null ? null : teams.where((value) => value.id == id).firstOrNull;

  Tournament copyWith({
    TournamentStatus? status,
    List<TournamentTeam>? teams,
    List<TournamentMatch>? matches,
    String? inviteCode,
    bool clearInviteCode = false,
    String? championTeamId,
    bool clearChampion = false,
  }) => Tournament(
    id: id,
    name: name,
    organizerId: organizerId,
    rules: rules,
    status: status ?? this.status,
    teams: teams ?? this.teams,
    matches: matches ?? this.matches,
    createdAt: createdAt,
    inviteCode: clearInviteCode ? null : inviteCode ?? this.inviteCode,
    championTeamId: clearChampion
        ? null
        : championTeamId ?? this.championTeamId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'organizer_id': organizerId,
    'rules': rules.toJson(),
    'status': status.name,
    'teams': teams.map((value) => value.toJson()).toList(),
    'matches': matches.map((value) => value.toJson()).toList(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'invite_code': inviteCode,
    'champion_team_id': championTeamId,
  };

  String encode() => jsonEncode(toJson());
  static Tournament decode(String source) =>
      Tournament.fromJson(Map<String, Object?>.from(jsonDecode(source) as Map));
}
