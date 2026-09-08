enum AhdashGameMode { solo, group, tournamentMatch }

enum TurnRotation { alternate, winnerKeepsTurn, manual }

enum TurnPhase { choosing, primaryAnswer, steal, reveal, resolved, paused }

final class GameRuleConfig {
  const GameRuleConfig({
    this.primaryAnswerSeconds = 60,
    this.stealSeconds = 10,
    this.allowSteal = true,
    this.turnRotation = TurnRotation.alternate,
    this.incorrectPenalty = 0,
    this.stealRewardMultiplier = 1,
    this.stealWrongPenaltyMultiplier = 0,
    this.pitOpponentPenaltyMultiplier = -1,
    this.trapCorrectRewardMultiplier = 1,
    this.trapWrongPenaltyMultiplier = -1,
    this.callFriendSeconds = 20,
    this.scoreValues = const [100, 200, 300],
  }) : assert(primaryAnswerSeconds > 0),
       assert(stealSeconds > 0),
       assert(callFriendSeconds > 0);

  factory GameRuleConfig.fromJson(Map<String, Object?> json) => GameRuleConfig(
    primaryAnswerSeconds:
        (json['primary_answer_seconds'] as num?)?.toInt() ?? 60,
    stealSeconds: (json['steal_seconds'] as num?)?.toInt() ?? 10,
    allowSteal: json['allow_steal'] as bool? ?? true,
    turnRotation:
        TurnRotation.values
            .where((value) => value.name == json['turn_rotation'])
            .firstOrNull ??
        TurnRotation.alternate,
    incorrectPenalty: (json['incorrect_penalty'] as num?)?.toInt() ?? 0,
    stealRewardMultiplier:
        (json['steal_reward_multiplier'] as num?)?.toInt() ?? 1,
    stealWrongPenaltyMultiplier:
        (json['steal_wrong_penalty_multiplier'] as num?)?.toInt() ?? 0,
    pitOpponentPenaltyMultiplier:
        (json['pit_opponent_penalty_multiplier'] as num?)?.toInt() ?? -1,
    trapCorrectRewardMultiplier:
        (json['trap_correct_reward_multiplier'] as num?)?.toInt() ?? 1,
    trapWrongPenaltyMultiplier:
        (json['trap_wrong_penalty_multiplier'] as num?)?.toInt() ?? -1,
    callFriendSeconds: (json['call_friend_seconds'] as num?)?.toInt() ?? 20,
    scoreValues:
        (json['score_values'] as List?)
            ?.whereType<num>()
            .map((value) => value.toInt())
            .where((value) => value > 0)
            .toList(growable: false) ??
        const [100, 200, 300],
  );

  static const classicSession = GameRuleConfig();

  final int primaryAnswerSeconds;
  final int stealSeconds;
  final bool allowSteal;
  final TurnRotation turnRotation;
  final int incorrectPenalty;
  final int stealRewardMultiplier;
  final int stealWrongPenaltyMultiplier;
  final int pitOpponentPenaltyMultiplier;
  final int trapCorrectRewardMultiplier;
  final int trapWrongPenaltyMultiplier;
  final int callFriendSeconds;
  final List<int> scoreValues;

  GameRuleConfig copyWith({
    int? primaryAnswerSeconds,
    int? stealSeconds,
    bool? allowSteal,
    TurnRotation? turnRotation,
    int? incorrectPenalty,
    int? stealRewardMultiplier,
    int? stealWrongPenaltyMultiplier,
    int? pitOpponentPenaltyMultiplier,
    int? trapCorrectRewardMultiplier,
    int? trapWrongPenaltyMultiplier,
    int? callFriendSeconds,
    List<int>? scoreValues,
  }) => GameRuleConfig(
    primaryAnswerSeconds: primaryAnswerSeconds ?? this.primaryAnswerSeconds,
    stealSeconds: stealSeconds ?? this.stealSeconds,
    allowSteal: allowSteal ?? this.allowSteal,
    turnRotation: turnRotation ?? this.turnRotation,
    incorrectPenalty: incorrectPenalty ?? this.incorrectPenalty,
    stealRewardMultiplier: stealRewardMultiplier ?? this.stealRewardMultiplier,
    stealWrongPenaltyMultiplier:
        stealWrongPenaltyMultiplier ?? this.stealWrongPenaltyMultiplier,
    pitOpponentPenaltyMultiplier:
        pitOpponentPenaltyMultiplier ?? this.pitOpponentPenaltyMultiplier,
    trapCorrectRewardMultiplier:
        trapCorrectRewardMultiplier ?? this.trapCorrectRewardMultiplier,
    trapWrongPenaltyMultiplier:
        trapWrongPenaltyMultiplier ?? this.trapWrongPenaltyMultiplier,
    callFriendSeconds: callFriendSeconds ?? this.callFriendSeconds,
    scoreValues: scoreValues ?? this.scoreValues,
  );

  Map<String, Object?> toJson() => {
    'primary_answer_seconds': primaryAnswerSeconds,
    'steal_seconds': stealSeconds,
    'allow_steal': allowSteal,
    'turn_rotation': turnRotation.name,
    'incorrect_penalty': incorrectPenalty,
    'steal_reward_multiplier': stealRewardMultiplier,
    'steal_wrong_penalty_multiplier': stealWrongPenaltyMultiplier,
    'pit_opponent_penalty_multiplier': pitOpponentPenaltyMultiplier,
    'trap_correct_reward_multiplier': trapCorrectRewardMultiplier,
    'trap_wrong_penalty_multiplier': trapWrongPenaltyMultiplier,
    'call_friend_seconds': callFriendSeconds,
    'score_values': scoreValues,
  };
}

enum GameRulePresetId { classic, quick, family, kids, untimed, competitive }

final class GameRulePreset {
  const GameRulePreset({
    required this.id,
    required this.nameAr,
    required this.descriptionAr,
    required this.rules,
  });

  final GameRulePresetId id;
  final String nameAr;
  final String descriptionAr;
  final GameRuleConfig rules;

  static const defaults = [
    GameRulePreset(
      id: GameRulePresetId.classic,
      nameAr: 'جلسة كلاسيكية',
      descriptionAr: 'دقيقة للإجابة وعشر ثوانٍ للخطف',
      rules: GameRuleConfig.classicSession,
    ),
    GameRulePreset(
      id: GameRulePresetId.quick,
      nameAr: 'جلسة سريعة',
      descriptionAr: 'إيقاع أسرع للجلسات القصيرة',
      rules: GameRuleConfig(primaryAnswerSeconds: 30, stealSeconds: 7),
    ),
    GameRulePreset(
      id: GameRulePresetId.family,
      nameAr: 'عائلية',
      descriptionAr: 'وقت أطول ودون عقوبة على الخطأ',
      rules: GameRuleConfig(primaryAnswerSeconds: 75, stealSeconds: 15),
    ),
    GameRulePreset(
      id: GameRulePresetId.kids,
      nameAr: 'أطفال',
      descriptionAr: 'وقت هادئ مع قيم نقاط مبسطة',
      rules: GameRuleConfig(
        primaryAnswerSeconds: 90,
        stealSeconds: 15,
        allowSteal: false,
        scoreValues: [50, 100, 150],
      ),
    ),
    GameRulePreset(
      id: GameRulePresetId.untimed,
      nameAr: 'بدون مؤقت',
      descriptionAr: 'المضيف ينقل الجولة يدويًا',
      rules: GameRuleConfig(allowSteal: false),
    ),
    GameRulePreset(
      id: GameRulePresetId.competitive,
      nameAr: 'تنافسية',
      descriptionAr: 'خطف سريع وعقوبة للفخ الخاطئ',
      rules: GameRuleConfig(
        primaryAnswerSeconds: 45,
        stealSeconds: 8,
        stealWrongPenaltyMultiplier: -1,
      ),
    ),
  ];
}

final class TurnSnapshot {
  const TurnSnapshot({
    required this.activeTeamIndex,
    required this.answeringTeamIndex,
    required this.phase,
    this.startedAt,
    this.durationSeconds,
    this.pausedRemainingSeconds,
  });

  final int activeTeamIndex;
  final int answeringTeamIndex;
  final TurnPhase phase;
  final DateTime? startedAt;
  final int? durationSeconds;
  final int? pausedRemainingSeconds;

  int? remainingSeconds(DateTime now) {
    if (phase == TurnPhase.paused) return pausedRemainingSeconds;
    if (startedAt == null || durationSeconds == null) return null;
    final elapsed = now.difference(startedAt!).inSeconds;
    return (durationSeconds! - elapsed).clamp(0, durationSeconds!);
  }

  TurnSnapshot copyWith({
    int? activeTeamIndex,
    int? answeringTeamIndex,
    TurnPhase? phase,
    DateTime? startedAt,
    int? durationSeconds,
    int? pausedRemainingSeconds,
    bool clearPaused = false,
  }) => TurnSnapshot(
    activeTeamIndex: activeTeamIndex ?? this.activeTeamIndex,
    answeringTeamIndex: answeringTeamIndex ?? this.answeringTeamIndex,
    phase: phase ?? this.phase,
    startedAt: startedAt ?? this.startedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    pausedRemainingSeconds: clearPaused
        ? null
        : pausedRemainingSeconds ?? this.pausedRemainingSeconds,
  );
}

final class TurnEngine {
  const TurnEngine();

  TurnSnapshot startQuestion({
    required int activeTeamIndex,
    required GameRuleConfig rules,
    required DateTime now,
    bool timed = true,
  }) => TurnSnapshot(
    activeTeamIndex: activeTeamIndex,
    answeringTeamIndex: activeTeamIndex,
    phase: TurnPhase.primaryAnswer,
    startedAt: timed ? now : null,
    durationSeconds: timed ? rules.primaryAnswerSeconds : null,
  );

  TurnSnapshot expire(
    TurnSnapshot turn, {
    required GameRuleConfig rules,
    required DateTime now,
  }) {
    if (turn.phase == TurnPhase.primaryAnswer && rules.allowSteal) {
      return TurnSnapshot(
        activeTeamIndex: turn.activeTeamIndex,
        answeringTeamIndex: 1 - turn.activeTeamIndex,
        phase: TurnPhase.steal,
        startedAt: now,
        durationSeconds: rules.stealSeconds,
      );
    }
    return turn.copyWith(phase: TurnPhase.reveal, startedAt: now);
  }

  TurnSnapshot pause(TurnSnapshot turn, DateTime now) {
    if (turn.phase != TurnPhase.primaryAnswer &&
        turn.phase != TurnPhase.steal) {
      return turn;
    }
    return turn.copyWith(
      phase: TurnPhase.paused,
      pausedRemainingSeconds: turn.remainingSeconds(now),
    );
  }

  TurnSnapshot resume(TurnSnapshot turn, DateTime now) {
    if (turn.phase != TurnPhase.paused) return turn;
    final remaining = turn.pausedRemainingSeconds;
    return TurnSnapshot(
      activeTeamIndex: turn.activeTeamIndex,
      answeringTeamIndex: turn.answeringTeamIndex,
      phase: turn.answeringTeamIndex == turn.activeTeamIndex
          ? TurnPhase.primaryAnswer
          : TurnPhase.steal,
      startedAt: remaining == null ? null : now,
      durationSeconds: remaining,
    );
  }

  int nextTeam({
    required TurnSnapshot turn,
    required int? awardedTeamIndex,
    required TurnRotation rotation,
  }) => switch (rotation) {
    TurnRotation.alternate => 1 - turn.activeTeamIndex,
    TurnRotation.winnerKeepsTurn =>
      awardedTeamIndex == turn.activeTeamIndex
          ? turn.activeTeamIndex
          : 1 - turn.activeTeamIndex,
    TurnRotation.manual => turn.activeTeamIndex,
  };
}
