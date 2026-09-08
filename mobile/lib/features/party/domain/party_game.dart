// ignore_for_file: sort_constructors_first

import 'dart:convert';

import '../../game/domain/game_rules.dart';
import '../../match/domain/quiz_question.dart';
import 'party_tournament_context.dart';

abstract final class PartyGameRules {
  static const categoriesPerGame = 6;
  static const questionsPerCategory = 6;
  static const helpersPerTeam = 3;
  static const defaultTimerSeconds = 60;
  static const timerOptions = <int?>[15, 20, 30, 45, 60, null];
  static const pointsByDifficulty = <QuestionDifficulty, int>{
    QuestionDifficulty.easy: 100,
    QuestionDifficulty.medium: 200,
    QuestionDifficulty.hard: 300,
    QuestionDifficulty.expert: 300,
  };
}

enum PartySplitterStatus { notRequested, requested, completed, skipped }

abstract final class PartySetupValidation {
  static String? teamError(List<PartyTeam> teams) {
    if (teams.length != 2 || teams.any((team) => team.name.trim().isEmpty)) {
      return 'اكتب اسمًا واضحًا لكل فريق.';
    }
    if (teams.any((team) => team.name.trim().runes.length > 24)) {
      return 'اسم الفريق يجب ألا يتجاوز 24 حرفًا.';
    }
    final normalized = teams
        .map(
          (team) =>
              team.name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase(),
        )
        .toList(growable: false);
    if (normalized[0] == normalized[1]) {
      return 'اختر اسمين مختلفين للفريقين.';
    }
    return null;
  }

  static String? readyError({
    required bool hasSetupDraft,
    required bool teamSetupCompleted,
    required PartySplitterStatus splitterStatus,
    required List<String> selectedCategoryIds,
    required Set<String> playableCategoryIds,
    required List<PartyTeam> teams,
    required Set<PartyHelperId> activeHelperIds,
  }) {
    if (!hasSetupDraft) {
      return 'ابدأ إعداد جولة جديدة أولًا.';
    }
    if (selectedCategoryIds.length != PartyGameRules.categoriesPerGame ||
        selectedCategoryIds.toSet().length !=
            PartyGameRules.categoriesPerGame) {
      return 'اختر 6 فئات مختلفة بالضبط.';
    }
    if (!playableCategoryIds.containsAll(selectedCategoryIds)) {
      return 'إحدى الفئات المختارة لم تعد جاهزة. ارجع واختر فئة متاحة.';
    }
    final invalidTeam = teamError(teams);
    if (invalidTeam != null) return invalidTeam;
    if (!teamSetupCompleted) {
      return 'أكمل إعداد الفريقين أولًا.';
    }
    if (splitterStatus == PartySplitterStatus.notRequested) {
      return 'حدد من إعداد الفريقين إن كنت تريد تقسيم اللاعبين.';
    }
    if (splitterStatus == PartySplitterStatus.requested) {
      return 'أكمل تقسيم اللاعبين أو تخطَّه.';
    }
    if (teams.any(
      (team) => team.selectedHelpers.length != PartyGameRules.helpersPerTeam,
    )) {
      return 'اختر 3 مساعدات لكل فريق.';
    }
    if (teams.any(
      (team) => !activeHelperIds.containsAll(team.selectedHelpers),
    )) {
      return 'تغيّر كتالوج المساعدات. ارجع واختر المساعدات المتاحة.';
    }
    for (var teamIndex = 0; teamIndex < teams.length; teamIndex++) {
      if (teams[teamIndex].selectedHelpers.contains(PartyHelperId.bench) &&
          teams[1 - teamIndex].players.isEmpty) {
        return 'مساعدة «استريح» تحتاج إلى لاعب واحد على الأقل في الفريق الخصم.';
      }
    }
    return null;
  }
}

enum PartyQuestionFormat {
  openAnswer,
  multipleChoice,
  trueFalse,
  image,
  imageCrop,
  imageBlur,
  audio,
  video,
  ordering,
  progressiveHints,
  drawing,
  charades,
  secretIdentity,
  numeric,
  year,
}

enum PartyHelperTiming { beforeQuestion, afterQuestion }

enum PartyHelperId { twoChances, callFriend, risk, bench, pass }

extension PartyHelperCopy on PartyHelperId {
  String get storageId => switch (this) {
    PartyHelperId.twoChances => 'two_chances',
    PartyHelperId.callFriend => 'call_friend',
    PartyHelperId.risk => 'risk',
    PartyHelperId.bench => 'bench',
    PartyHelperId.pass => 'pass',
  };

  String get label => switch (this) {
    PartyHelperId.twoChances => 'جاوب جوابين',
    PartyHelperId.callFriend => 'اتصال بصديق',
    PartyHelperId.risk => 'الحفرة',
    PartyHelperId.bench => 'استريح',
    PartyHelperId.pass => 'الفخ',
  };

  String get description => switch (this) {
    PartyHelperId.twoChances => 'قولوا إجابتين بدل إجابة واحدة',
    PartyHelperId.callFriend => 'خذوا مؤقتًا مستقلًا للاستعانة بصديق',
    PartyHelperId.risk => 'إجابة صحيحة تخصم قيمة السؤال من الخصم',
    PartyHelperId.bench => 'اختاروا لاعبًا من الخصم ليكون خارج هذا السؤال',
    PartyHelperId.pass => 'حوّلوا السؤال للخصم؛ الخطأ يخصم منه',
  };

  String get iconKey => switch (this) {
    PartyHelperId.twoChances => 'looks_two',
    PartyHelperId.callFriend => 'phone',
    PartyHelperId.risk => 'trending_up',
    PartyHelperId.bench => 'event_seat',
    PartyHelperId.pass => 'redo',
  };

  PartyHelperTiming get timing => this == PartyHelperId.risk
      ? PartyHelperTiming.beforeQuestion
      : PartyHelperTiming.afterQuestion;

  PartyHelperDefinition get defaultDefinition => PartyHelperDefinition(
    id: this,
    label: label,
    description: description,
    iconKey: iconKey,
    timing: timing,
    callFriendSeconds: this == PartyHelperId.callFriend ? 20 : null,
    correctMultiplier: this == PartyHelperId.risk ? 1 : null,
    wrongMultiplier: switch (this) {
      PartyHelperId.risk => 0,
      PartyHelperId.pass => -1,
      _ => null,
    },
  );
}

final class PartyHelperDefinition {
  const PartyHelperDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.iconKey,
    required this.timing,
    this.callFriendSeconds,
    this.correctMultiplier,
    this.wrongMultiplier,
  });

  factory PartyHelperDefinition.fromJson(Map<String, Object?> json) {
    final id = PartyHelperId.values
        .where((value) => value.storageId == json['id'])
        .firstOrNull;
    if (id == null) throw const FormatException('Unknown Party helper');
    final ruleConfig = switch (json['rule_config']) {
      final Map<Object?, Object?> value => value.cast<String, Object?>(),
      _ => const <String, Object?>{},
    };
    return PartyHelperDefinition(
      id: id,
      label: json['name_ar'] as String? ?? id.label,
      description: json['description_ar'] as String? ?? id.description,
      iconKey: json['icon_key'] as String? ?? id.iconKey,
      timing: json['timing'] == 'before_question'
          ? PartyHelperTiming.beforeQuestion
          : PartyHelperTiming.afterQuestion,
      callFriendSeconds: id == PartyHelperId.callFriend
          ? (ruleConfig['seconds'] as num?)?.toInt() ?? 20
          : null,
      correctMultiplier: id == PartyHelperId.risk
          ? (ruleConfig['correct_multiplier'] as num?)?.toInt() ?? 1
          : null,
      wrongMultiplier: id == PartyHelperId.risk || id == PartyHelperId.pass
          ? (ruleConfig['wrong_multiplier'] as num?)?.toInt() ??
                (id == PartyHelperId.risk ? 0 : -1)
          : null,
    );
  }

  final PartyHelperId id;
  final String label;
  final String description;
  final String iconKey;
  final PartyHelperTiming timing;
  final int? callFriendSeconds;
  final int? correctMultiplier;
  final int? wrongMultiplier;

  Map<String, Object?> toJson() => {
    'id': id.storageId,
    'name_ar': label,
    'description_ar': description,
    'icon_key': iconKey,
    'timing': timing == PartyHelperTiming.beforeQuestion
        ? 'before_question'
        : 'after_question',
    'rule_config': {
      if (callFriendSeconds != null) 'seconds': callFriendSeconds,
      if (correctMultiplier != null) 'correct_multiplier': correctMultiplier,
      if (wrongMultiplier != null) 'wrong_multiplier': wrongMultiplier,
    },
  };
}

final List<PartyHelperDefinition> defaultPartyHelperDefinitions = PartyHelperId
    .values
    .map((helper) => helper.defaultDefinition)
    .toList(growable: false);

final class PartyTeam {
  const PartyTeam({
    required this.name,
    required this.colorValue,
    this.players = const [],
    this.selectedHelpers = const {},
    this.usedHelpers = const {},
  });

  final String name;
  final int colorValue;
  final List<String> players;
  final Set<PartyHelperId> selectedHelpers;
  final Set<PartyHelperId> usedHelpers;

  PartyTeam copyWith({
    String? name,
    int? colorValue,
    List<String>? players,
    Set<PartyHelperId>? selectedHelpers,
    Set<PartyHelperId>? usedHelpers,
  }) => PartyTeam(
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    players: players ?? this.players,
    selectedHelpers: selectedHelpers ?? this.selectedHelpers,
    usedHelpers: usedHelpers ?? this.usedHelpers,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'color': colorValue,
    'players': players,
    'selected_helpers': selectedHelpers.map((value) => value.name).toList(),
    'used_helpers': usedHelpers.map((value) => value.name).toList(),
  };

  factory PartyTeam.fromJson(Map<String, Object?> json) => PartyTeam(
    name: json['name'] as String? ?? 'الفريق',
    colorValue: json['color'] as int? ?? 0xFF2368A2,
    players:
        (json['players'] as List?)?.whereType<String>().toList() ?? const [],
    selectedHelpers: _helperSet(json['selected_helpers']),
    usedHelpers: _helperSet(json['used_helpers']),
  );
}

Set<PartyHelperId> _helperSet(Object? source) => (source as List? ?? const [])
    .whereType<String>()
    .map(
      (name) =>
          PartyHelperId.values.where((value) => value.name == name).firstOrNull,
    )
    .whereType<PartyHelperId>()
    .toSet();

final class PartyQuestionSnapshot {
  const PartyQuestionSnapshot({
    required this.id,
    required this.categoryId,
    required this.text,
    required this.answer,
    required this.difficulty,
    required this.pointValue,
    required this.format,
    this.options = const [],
    this.alternativeAnswers = const [],
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.orderingItems = const [],
    this.hints = const [],
    this.pointDecayPerHint = 0,
    this.mechanicConfig = const {},
    this.explanation,
    this.used = false,
  });

  final String id;
  final String categoryId;
  final String text;
  final String answer;
  final QuestionDifficulty difficulty;
  final int pointValue;
  final PartyQuestionFormat format;
  final List<String> options;
  final List<String> alternativeAnswers;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final List<String> orderingItems;
  final List<String> hints;
  final int pointDecayPerHint;
  final Map<String, Object?> mechanicConfig;
  final String? explanation;
  final bool used;

  PartyQuestionSnapshot copyWith({bool? used}) => PartyQuestionSnapshot(
    id: id,
    categoryId: categoryId,
    text: text,
    answer: answer,
    difficulty: difficulty,
    pointValue: pointValue,
    format: format,
    options: options,
    alternativeAnswers: alternativeAnswers,
    imageUrl: imageUrl,
    audioUrl: audioUrl,
    videoUrl: videoUrl,
    orderingItems: orderingItems,
    hints: hints,
    pointDecayPerHint: pointDecayPerHint,
    mechanicConfig: mechanicConfig,
    explanation: explanation,
    used: used ?? this.used,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'category_id': categoryId,
    'text': text,
    'answer': answer,
    'difficulty': difficulty.name,
    'points': pointValue,
    'format': format.name,
    'options': options,
    'alternative_answers': alternativeAnswers,
    'image_url': imageUrl,
    'audio_url': audioUrl,
    'video_url': videoUrl,
    'ordering_items': orderingItems,
    'hints': hints,
    'point_decay_per_hint': pointDecayPerHint,
    'mechanic_config': mechanicConfig,
    'explanation': explanation,
    'used': used,
  };

  factory PartyQuestionSnapshot.fromJson(
    Map<String, Object?> json,
  ) => PartyQuestionSnapshot(
    id: json['id'] as String,
    categoryId: json['category_id'] as String,
    text: json['text'] as String,
    answer: json['answer'] as String,
    difficulty: QuestionDifficulty.values.byName(json['difficulty'] as String),
    pointValue: json['points'] as int,
    format: PartyQuestionFormat.values.byName(json['format'] as String),
    options:
        (json['options'] as List?)?.whereType<String>().toList() ?? const [],
    alternativeAnswers:
        (json['alternative_answers'] as List?)?.whereType<String>().toList() ??
        const [],
    imageUrl: json['image_url'] as String?,
    audioUrl: json['audio_url'] as String?,
    videoUrl: json['video_url'] as String?,
    orderingItems:
        (json['ordering_items'] as List?)?.whereType<String>().toList() ??
        const [],
    hints: (json['hints'] as List?)?.whereType<String>().toList() ?? const [],
    pointDecayPerHint: (json['point_decay_per_hint'] as num?)?.toInt() ?? 0,
    mechanicConfig: switch (json['mechanic_config']) {
      final Map<Object?, Object?> value => Map<String, Object?>.from(value),
      _ => const {},
    },
    explanation: json['explanation'] as String?,
    used: json['used'] as bool? ?? false,
  );
}

final class PartyCategorySnapshot {
  const PartyCategorySnapshot({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.ownerTeamIndex,
    required this.questions,
    this.imageUrl,
    this.focalX = 0.5,
    this.focalY = 0.5,
  });

  final String id;
  final String name;
  final int colorValue;
  final int ownerTeamIndex;
  final String? imageUrl;
  final double focalX;
  final double focalY;
  final List<PartyQuestionSnapshot> questions;

  PartyCategorySnapshot copyWith({List<PartyQuestionSnapshot>? questions}) =>
      PartyCategorySnapshot(
        id: id,
        name: name,
        colorValue: colorValue,
        ownerTeamIndex: ownerTeamIndex,
        questions: questions ?? this.questions,
        imageUrl: imageUrl,
        focalX: focalX,
        focalY: focalY,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'color': colorValue,
    'owner': ownerTeamIndex,
    'image_url': imageUrl,
    'focal_x': focalX,
    'focal_y': focalY,
    'questions': questions.map((value) => value.toJson()).toList(),
  };

  factory PartyCategorySnapshot.fromJson(Map<String, Object?> json) =>
      PartyCategorySnapshot(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['color'] as int,
        ownerTeamIndex: json['owner'] as int,
        imageUrl: json['image_url'] as String?,
        focalX: (json['focal_x'] as num?)?.toDouble() ?? 0.5,
        focalY: (json['focal_y'] as num?)?.toDouble() ?? 0.5,
        questions: (json['questions'] as List)
            .whereType<Map<String, Object?>>()
            .map(PartyQuestionSnapshot.fromJson)
            .toList(),
      );
}

final class PartyScoreEvent {
  const PartyScoreEvent({
    required this.questionId,
    required this.teamDeltas,
    required this.previousTurn,
    required this.createdAt,
    this.reason = 'احتساب سؤال',
  });

  final String questionId;
  final List<int> teamDeltas;
  final int previousTurn;
  final DateTime createdAt;
  final String reason;

  Map<String, Object?> toJson() => {
    'question_id': questionId,
    'deltas': teamDeltas,
    'previous_turn': previousTurn,
    'created_at': createdAt.toIso8601String(),
    'reason': reason,
  };

  factory PartyScoreEvent.fromJson(Map<String, Object?> json) =>
      PartyScoreEvent(
        questionId: json['question_id'] as String,
        teamDeltas: (json['deltas'] as List).whereType<int>().toList(),
        previousTurn: json['previous_turn'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        reason: json['reason'] as String? ?? 'احتساب سؤال',
      );
}

final class PartyGameSession {
  const PartyGameSession({
    required this.id,
    required this.teams,
    required this.categories,
    required this.timerSeconds,
    required this.createdAt,
    this.helperDefinitions = const [],
    this.scores = const [0, 0],
    this.turnTeamIndex = 0,
    this.answeringTeamIndex = 0,
    this.activeQuestionId,
    this.revealed = false,
    this.armedHelper,
    this.helperActionDetail,
    this.questionTimerStartedAt,
    this.questionTimerDurationSeconds,
    this.tieBreakerQuestion,
    this.tieBreakerStarted = false,
    this.scoreEvents = const [],
    this.completedAt,
    this.ruleConfig = GameRuleConfig.classicSession,
    this.stealActive = false,
    this.tournamentContext,
  });

  final String id;
  final List<PartyTeam> teams;
  final List<PartyCategorySnapshot> categories;
  final int? timerSeconds;
  final DateTime createdAt;
  final List<PartyHelperDefinition> helperDefinitions;
  final List<int> scores;
  final int turnTeamIndex;
  final int answeringTeamIndex;
  final String? activeQuestionId;
  final bool revealed;
  final PartyHelperId? armedHelper;
  final String? helperActionDetail;
  final DateTime? questionTimerStartedAt;
  final int? questionTimerDurationSeconds;
  final PartyQuestionSnapshot? tieBreakerQuestion;
  final bool tieBreakerStarted;
  final List<PartyScoreEvent> scoreEvents;
  final DateTime? completedAt;
  final GameRuleConfig ruleConfig;
  final bool stealActive;
  final PartyTournamentContext? tournamentContext;

  Iterable<PartyQuestionSnapshot> get questions =>
      categories.expand((value) => value.questions);
  PartyQuestionSnapshot? get activeQuestion => activeQuestionId == null
      ? null
      : questions.where((value) => value.id == activeQuestionId).firstOrNull ??
            (tieBreakerQuestion?.id == activeQuestionId
                ? tieBreakerQuestion
                : null);
  bool get regularBoardComplete => questions.every((value) => value.used);
  bool get isComplete =>
      regularBoardComplete &&
      (!tieBreakerStarted || tieBreakerQuestion?.used == true);
  PartyHelperDefinition helperDefinition(PartyHelperId helper) =>
      helperDefinitions
          .where((definition) => definition.id == helper)
          .firstOrNull ??
      helper.defaultDefinition;

  PartyGameSession copyWith({
    List<PartyTeam>? teams,
    List<PartyCategorySnapshot>? categories,
    List<PartyHelperDefinition>? helperDefinitions,
    int? timerSeconds,
    bool clearTimer = false,
    List<int>? scores,
    int? turnTeamIndex,
    int? answeringTeamIndex,
    String? activeQuestionId,
    bool clearActiveQuestion = false,
    bool? revealed,
    PartyHelperId? armedHelper,
    bool clearArmedHelper = false,
    String? helperActionDetail,
    bool clearHelperActionDetail = false,
    DateTime? questionTimerStartedAt,
    int? questionTimerDurationSeconds,
    bool clearQuestionTimer = false,
    PartyQuestionSnapshot? tieBreakerQuestion,
    bool? tieBreakerStarted,
    List<PartyScoreEvent>? scoreEvents,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    GameRuleConfig? ruleConfig,
    bool? stealActive,
    PartyTournamentContext? tournamentContext,
  }) => PartyGameSession(
    id: id,
    teams: teams ?? this.teams,
    categories: categories ?? this.categories,
    helperDefinitions: helperDefinitions ?? this.helperDefinitions,
    timerSeconds: clearTimer ? null : timerSeconds ?? this.timerSeconds,
    createdAt: createdAt,
    scores: scores ?? this.scores,
    turnTeamIndex: turnTeamIndex ?? this.turnTeamIndex,
    answeringTeamIndex: answeringTeamIndex ?? this.answeringTeamIndex,
    activeQuestionId: clearActiveQuestion
        ? null
        : activeQuestionId ?? this.activeQuestionId,
    revealed: revealed ?? this.revealed,
    armedHelper: clearArmedHelper ? null : armedHelper ?? this.armedHelper,
    helperActionDetail: clearHelperActionDetail
        ? null
        : helperActionDetail ?? this.helperActionDetail,
    questionTimerStartedAt: clearQuestionTimer
        ? null
        : questionTimerStartedAt ?? this.questionTimerStartedAt,
    questionTimerDurationSeconds: clearQuestionTimer
        ? null
        : questionTimerDurationSeconds ?? this.questionTimerDurationSeconds,
    tieBreakerQuestion: tieBreakerQuestion ?? this.tieBreakerQuestion,
    tieBreakerStarted: tieBreakerStarted ?? this.tieBreakerStarted,
    scoreEvents: scoreEvents ?? this.scoreEvents,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    ruleConfig: ruleConfig ?? this.ruleConfig,
    stealActive: stealActive ?? this.stealActive,
    tournamentContext: tournamentContext ?? this.tournamentContext,
  );

  String encode() => jsonEncode(toJson());
  Map<String, Object?> toJson() => {
    'id': id,
    'teams': teams.map((value) => value.toJson()).toList(),
    'categories': categories.map((value) => value.toJson()).toList(),
    'helper_definitions': helperDefinitions
        .map((value) => value.toJson())
        .toList(),
    'timer_seconds': timerSeconds,
    'created_at': createdAt.toIso8601String(),
    'scores': scores,
    'turn': turnTeamIndex,
    'answering_team': answeringTeamIndex,
    'active_question_id': activeQuestionId,
    'revealed': revealed,
    'armed_helper': armedHelper?.name,
    'helper_action_detail': helperActionDetail,
    'question_timer_started_at': questionTimerStartedAt?.toIso8601String(),
    'question_timer_duration_seconds': questionTimerDurationSeconds,
    'tie_breaker_question': tieBreakerQuestion?.toJson(),
    'tie_breaker_started': tieBreakerStarted,
    'score_events': scoreEvents.map((value) => value.toJson()).toList(),
    'completed_at': completedAt?.toIso8601String(),
    'rule_config': ruleConfig.toJson(),
    'steal_active': stealActive,
    'tournament_context': tournamentContext?.toJson(),
  };

  factory PartyGameSession.decode(String source) => PartyGameSession.fromJson(
    (jsonDecode(source) as Map).cast<String, Object?>(),
  );

  factory PartyGameSession.fromJson(
    Map<String, Object?> json,
  ) => PartyGameSession(
    id: json['id'] as String,
    teams: (json['teams'] as List)
        .whereType<Map<String, Object?>>()
        .map(PartyTeam.fromJson)
        .toList(),
    categories: (json['categories'] as List)
        .whereType<Map<String, Object?>>()
        .map(PartyCategorySnapshot.fromJson)
        .toList(),
    helperDefinitions: (json['helper_definitions'] as List? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(PartyHelperDefinition.fromJson)
        .toList(),
    timerSeconds: json['timer_seconds'] as int?,
    createdAt: DateTime.parse(json['created_at'] as String),
    scores: (json['scores'] as List).whereType<int>().toList(),
    turnTeamIndex: json['turn'] as int? ?? 0,
    answeringTeamIndex: json['answering_team'] as int? ?? 0,
    activeQuestionId: json['active_question_id'] as String?,
    revealed: json['revealed'] as bool? ?? false,
    armedHelper: switch (json['armed_helper']) {
      final String name =>
        PartyHelperId.values.where((value) => value.name == name).firstOrNull,
      _ => null,
    },
    helperActionDetail: json['helper_action_detail'] as String?,
    questionTimerStartedAt: DateTime.tryParse(
      json['question_timer_started_at'] as String? ?? '',
    ),
    questionTimerDurationSeconds:
        json['question_timer_duration_seconds'] as int?,
    tieBreakerQuestion: switch (json['tie_breaker_question']) {
      final Map<String, Object?> value => PartyQuestionSnapshot.fromJson(value),
      _ => null,
    },
    tieBreakerStarted: json['tie_breaker_started'] as bool? ?? false,
    scoreEvents: (json['score_events'] as List? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(PartyScoreEvent.fromJson)
        .toList(),
    completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
    ruleConfig: switch (json['rule_config']) {
      final Map<Object?, Object?> value => GameRuleConfig.fromJson(
        Map<String, Object?>.from(value),
      ),
      _ => GameRuleConfig.classicSession,
    },
    stealActive: json['steal_active'] as bool? ?? false,
    tournamentContext: switch (json['tournament_context']) {
      final Map<Object?, Object?> value => PartyTournamentContext.fromJson(
        Map<String, Object?>.from(value),
      ),
      _ => null,
    },
  );
}
