import '../../game/domain/game_mode.dart';
import '../../game/domain/question_mechanics.dart';

enum QuestionType {
  text,
  image,
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

enum QuestionFormat {
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

enum QuestionDifficulty {
  easy,
  medium,
  hard,
  expert;

  String get arabicLabel => switch (this) {
    QuestionDifficulty.easy => 'سهل',
    QuestionDifficulty.medium => 'متوسط',
    QuestionDifficulty.hard => 'صعب',
    QuestionDifficulty.expert => 'خبير',
  };
}

final class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.categoryId,
    required this.difficulty,
    this.type = QuestionType.text,
    this.imageUrl,
    this.subcategoryId,
    this.tags = const [],
    this.player,
    this.club,
    this.gameType = GameType.classic,
    this.format = QuestionFormat.openAnswer,
    this.correctAnswer,
    this.alternativeAnswers = const [],
    this.explanation,
    this.pointValue,
    this.audioUrl,
    this.videoUrl,
    this.acceptedTolerance,
    this.numericAnswer,
    this.orderingItems = const [],
    this.correctOrder = const [],
    this.hints = const [],
    this.pointDecayPerHint = 0,
    this.mechanicConfig = const {},
  }) : assert(correctOptionIndex >= 0),
       assert(correctOptionIndex < (gameType == GameType.trueFalse ? 2 : 4));

  factory QuizQuestion.fromJson(Map<String, Object?> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions.whereType<String>().toList(growable: false)
        : const <String>[];
    final gameType =
        GameTypeCopy.fromSlug(
          (json['gameplay_type'] ?? json['game_type']) as String? ?? 'classic',
        ) ??
        GameType.classic;
    final format = _parseQuestionFormat(
      json['question_format'] as String?,
      gameType,
      json['question_type'] as String?,
    );
    final correctAnswer = json['correct_answer'] as String?;
    final normalizedOptions =
        options.isEmpty &&
            !_requiresFixedOptions(format) &&
            correctAnswer != null
        ? <String>[correctAnswer]
        : options;
    final expectedOptionCount = gameType == GameType.trueFalse ? 2 : 4;
    if (_requiresFixedOptions(format) &&
        normalizedOptions.length != expectedOptionCount) {
      throw FormatException(
        '${gameType.slug} questions must contain exactly '
        '$expectedOptionCount options',
      );
    }
    final correctIndex = json['correct_option_index'] as int? ?? 0;
    if (correctIndex < 0 || correctIndex >= normalizedOptions.length) {
      throw const FormatException('Correct option index is outside options');
    }
    return QuizQuestion(
      id: json['id']! as String,
      text: json['question_text']! as String,
      options: normalizedOptions,
      correctOptionIndex: correctIndex,
      categoryId: json['category_id']! as String,
      subcategoryId: json['subcategory_id'] as String?,
      imageUrl: json['image_url'] as String?,
      type: _parseQuestionType(json['question_type'] as String?, format),
      difficulty: QuestionDifficulty.values.firstWhere(
        (value) => value.name == json['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
      player: json['player'] as String?,
      club: json['club'] as String?,
      gameType: gameType,
      format: format,
      correctAnswer: correctAnswer,
      alternativeAnswers:
          (json['alternative_answers'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      explanation: json['explanation'] as String?,
      pointValue: json['point_value'] as int?,
      audioUrl: json['audio_url'] as String?,
      videoUrl: json['video_url'] as String?,
      acceptedTolerance: (json['accepted_tolerance'] as num?)?.toDouble(),
      numericAnswer: json['numeric_answer'] as num?,
      orderingItems:
          (json['ordering_items'] as List?)?.whereType<String>().toList() ??
          const [],
      correctOrder:
          (json['correct_order'] as List?)?.whereType<String>().toList() ??
          const [],
      hints: (json['hints'] as List?)?.whereType<String>().toList() ?? const [],
      pointDecayPerHint: (json['point_decay_per_hint'] as num?)?.toInt() ?? 0,
      mechanicConfig: switch (json['mechanic_config']) {
        final Map<Object?, Object?> value => Map<String, Object?>.from(value),
        _ => const {},
      },
    );
  }

  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final String categoryId;
  final String? subcategoryId;
  final QuestionDifficulty difficulty;
  final QuestionType type;
  final String? imageUrl;
  final List<String> tags;
  final String? player;
  final String? club;
  final GameType gameType;
  final QuestionFormat format;
  final String? correctAnswer;
  final List<String> alternativeAnswers;
  final String? explanation;
  final int? pointValue;
  final String? audioUrl;
  final String? videoUrl;
  final double? acceptedTolerance;
  final num? numericAnswer;
  final List<String> orderingItems;
  final List<String> correctOrder;
  final List<String> hints;
  final int pointDecayPerHint;
  final Map<String, Object?> mechanicConfig;

  AhdashQuestionType get mechanicType => switch (format) {
    QuestionFormat.multipleChoice => AhdashQuestionType.multipleChoice,
    QuestionFormat.trueFalse => AhdashQuestionType.trueFalse,
    QuestionFormat.image => AhdashQuestionType.image,
    QuestionFormat.imageCrop => AhdashQuestionType.imageCrop,
    QuestionFormat.imageBlur => AhdashQuestionType.imageBlur,
    QuestionFormat.audio => AhdashQuestionType.audio,
    QuestionFormat.video => AhdashQuestionType.video,
    QuestionFormat.ordering => AhdashQuestionType.ordering,
    QuestionFormat.progressiveHints => AhdashQuestionType.progressiveHints,
    QuestionFormat.drawing => AhdashQuestionType.drawing,
    QuestionFormat.charades => AhdashQuestionType.charades,
    QuestionFormat.secretIdentity => AhdashQuestionType.secretIdentity,
    QuestionFormat.numeric => AhdashQuestionType.numeric,
    QuestionFormat.year => AhdashQuestionType.year,
    QuestionFormat.openAnswer => AhdashQuestionType.text,
  };

  PublicQuestion toPublic({DateTime? serverDeadline}) => PublicQuestion(
    id: id,
    text: text,
    options: options,
    optionIds: List.generate(options.length, (index) => '$id-option-$index'),
    categoryId: categoryId,
    difficulty: difficulty,
    imageUrl: imageUrl,
    serverDeadline: serverDeadline,
    gameType: gameType.slug,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'question_text': text,
    'options': options,
    'correct_option_index': correctOptionIndex,
    'category_id': categoryId,
    'subcategory_id': subcategoryId,
    'difficulty': difficulty.name,
    'question_type': _questionTypeStorageKey(type),
    'image_url': imageUrl,
    'tags': tags,
    'player': player,
    'club': club,
    'gameplay_type': gameType.slug,
    'question_format': switch (format) {
      QuestionFormat.openAnswer => 'open_answer',
      QuestionFormat.multipleChoice => 'multiple_choice',
      QuestionFormat.trueFalse => 'true_false',
      QuestionFormat.image => 'image',
      QuestionFormat.imageCrop => 'image_crop',
      QuestionFormat.imageBlur => 'image_blur',
      QuestionFormat.audio => 'audio',
      QuestionFormat.video => 'video',
      QuestionFormat.ordering => 'ordering',
      QuestionFormat.progressiveHints => 'progressive_hints',
      QuestionFormat.drawing => 'drawing',
      QuestionFormat.charades => 'charades',
      QuestionFormat.secretIdentity => 'secret_identity',
      QuestionFormat.numeric => 'numeric',
      QuestionFormat.year => 'year',
    },
    'correct_answer': correctAnswer,
    'alternative_answers': alternativeAnswers,
    'explanation': explanation,
    'point_value': pointValue,
    'audio_url': audioUrl,
    'video_url': videoUrl,
    'accepted_tolerance': acceptedTolerance,
    'numeric_answer': numericAnswer,
    'ordering_items': orderingItems,
    'correct_order': correctOrder,
    'hints': hints,
    'point_decay_per_hint': pointDecayPerHint,
    'mechanic_config': mechanicConfig,
  };
}

QuestionFormat _parseQuestionFormat(
  String? value,
  GameType gameType,
  String? mediaType,
) => switch (value) {
  'open_answer' => QuestionFormat.openAnswer,
  'true_false' => QuestionFormat.trueFalse,
  'image' => QuestionFormat.image,
  'image_crop' => QuestionFormat.imageCrop,
  'image_blur' => QuestionFormat.imageBlur,
  'audio' => QuestionFormat.audio,
  'video' => QuestionFormat.video,
  'ordering' => QuestionFormat.ordering,
  'progressive_hints' => QuestionFormat.progressiveHints,
  'drawing' => QuestionFormat.drawing,
  'charades' => QuestionFormat.charades,
  'secret_identity' => QuestionFormat.secretIdentity,
  'numeric' => QuestionFormat.numeric,
  'year' => QuestionFormat.year,
  'multiple_choice' => QuestionFormat.multipleChoice,
  _ when mediaType == 'audio' => QuestionFormat.audio,
  _ when mediaType == 'video' => QuestionFormat.video,
  _ when mediaType == 'image' => QuestionFormat.image,
  _ when gameType == GameType.trueFalse => QuestionFormat.trueFalse,
  _ => QuestionFormat.multipleChoice,
};

bool _requiresFixedOptions(QuestionFormat format) =>
    format == QuestionFormat.multipleChoice ||
    format == QuestionFormat.trueFalse;

QuestionType _parseQuestionType(String? value, QuestionFormat format) =>
    switch (value) {
      'image' => QuestionType.image,
      'audio' => QuestionType.audio,
      'video' => QuestionType.video,
      'ordering' => QuestionType.ordering,
      'progressive_hints' => QuestionType.progressiveHints,
      'drawing' => QuestionType.drawing,
      'charades' => QuestionType.charades,
      'secret_identity' => QuestionType.secretIdentity,
      'numeric' => QuestionType.numeric,
      'year' => QuestionType.year,
      _ => switch (format) {
        QuestionFormat.image ||
        QuestionFormat.imageCrop ||
        QuestionFormat.imageBlur => QuestionType.image,
        QuestionFormat.audio => QuestionType.audio,
        QuestionFormat.video => QuestionType.video,
        QuestionFormat.ordering => QuestionType.ordering,
        QuestionFormat.progressiveHints => QuestionType.progressiveHints,
        QuestionFormat.drawing => QuestionType.drawing,
        QuestionFormat.charades => QuestionType.charades,
        QuestionFormat.secretIdentity => QuestionType.secretIdentity,
        QuestionFormat.numeric => QuestionType.numeric,
        QuestionFormat.year => QuestionType.year,
        _ => QuestionType.text,
      },
    };

String _questionTypeStorageKey(QuestionType type) => switch (type) {
  QuestionType.progressiveHints => 'progressive_hints',
  QuestionType.secretIdentity => 'secret_identity',
  _ => type.name,
};

/// Network-safe DTO. It intentionally has no correct-option field.
final class PublicQuestion {
  const PublicQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.optionIds,
    required this.categoryId,
    required this.difficulty,
    this.imageUrl,
    this.serverDeadline,
    this.serverNow,
    this.roundIndex = 1,
    this.durationMs = 15000,
    this.gameType = 'classic',
  });

  factory PublicQuestion.fromJson(Map<String, Object?> json) {
    final rawOptions = ((json['options'] as List?) ?? const <Object?>[])
        .cast<Object?>();
    final optionMaps = rawOptions.whereType<Map<String, Object?>>().toList(
      growable: false,
    );
    final optionTexts = optionMaps.isNotEmpty
        ? optionMaps
              .map((option) => option['text']! as String)
              .toList(growable: false)
        : rawOptions.whereType<String>().toList(growable: false);
    final optionIds = optionMaps.isNotEmpty
        ? optionMaps
              .map((option) => option['id']! as String)
              .toList(growable: false)
        : const <String>[];
    return PublicQuestion(
      id: (json['match_question_id'] ?? json['id'])! as String,
      text: json['question_text']! as String,
      options: optionTexts,
      optionIds: optionIds,
      categoryId: json['category_id']! as String,
      difficulty: QuestionDifficulty.values.firstWhere(
        (value) => value.name == json['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      imageUrl: json['image_url'] as String?,
      serverDeadline: DateTime.tryParse(
        ((json['server_deadline'] ?? json['closes_at']) as String?) ?? '',
      ),
      serverNow: DateTime.tryParse((json['server_now'] as String?) ?? ''),
      roundIndex: json['sequence_number'] as int? ?? 1,
      durationMs: json['duration_ms'] as int? ?? 15000,
      gameType: json['game_type'] as String? ?? 'classic',
    );
  }

  final String id;
  final String text;
  final List<String> options;
  final List<String> optionIds;
  final String categoryId;
  final QuestionDifficulty difficulty;
  final String? imageUrl;
  final DateTime? serverDeadline;
  final DateTime? serverNow;
  final int roundIndex;
  final int durationMs;
  final String gameType;
}

final class AnswerReveal {
  const AnswerReveal({
    required this.questionId,
    required this.correctOptionId,
    required this.answers,
  });

  final String questionId;
  final String correctOptionId;
  final List<Map<String, Object?>> answers;
}
