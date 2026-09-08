import 'dart:convert';
import 'dart:math';

enum AhdashQuestionType {
  text,
  multipleChoice,
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
  trueFalse;

  static AhdashQuestionType fromStorage(String? value) => switch (value) {
    'multiple_choice' => AhdashQuestionType.multipleChoice,
    'image' => AhdashQuestionType.image,
    'image_crop' => AhdashQuestionType.imageCrop,
    'image_blur' => AhdashQuestionType.imageBlur,
    'audio' => AhdashQuestionType.audio,
    'video' => AhdashQuestionType.video,
    'ordering' => AhdashQuestionType.ordering,
    'progressive_hints' => AhdashQuestionType.progressiveHints,
    'drawing' => AhdashQuestionType.drawing,
    'charades' => AhdashQuestionType.charades,
    'secret_identity' => AhdashQuestionType.secretIdentity,
    'numeric' => AhdashQuestionType.numeric,
    'year' => AhdashQuestionType.year,
    'true_false' => AhdashQuestionType.trueFalse,
    _ => AhdashQuestionType.text,
  };

  String get storageKey => switch (this) {
    AhdashQuestionType.multipleChoice => 'multiple_choice',
    AhdashQuestionType.imageCrop => 'image_crop',
    AhdashQuestionType.imageBlur => 'image_blur',
    AhdashQuestionType.progressiveHints => 'progressive_hints',
    AhdashQuestionType.secretIdentity => 'secret_identity',
    AhdashQuestionType.trueFalse => 'true_false',
    _ => name,
  };
}

final class QuestionMechanicSpec {
  const QuestionMechanicSpec({
    required this.type,
    required this.hostEvaluated,
    required this.requiresMedia,
    required this.privateReveal,
    required this.interactive,
  });

  final AhdashQuestionType type;
  final bool hostEvaluated;
  final bool requiresMedia;
  final bool privateReveal;
  final bool interactive;
}

abstract final class QuestionMechanicRegistry {
  static final Map<AhdashQuestionType, QuestionMechanicSpec> _specs = {
    for (final type in AhdashQuestionType.values)
      type: QuestionMechanicSpec(
        type: type,
        hostEvaluated: const {
          AhdashQuestionType.text,
          AhdashQuestionType.image,
          AhdashQuestionType.imageCrop,
          AhdashQuestionType.imageBlur,
          AhdashQuestionType.audio,
          AhdashQuestionType.video,
          AhdashQuestionType.progressiveHints,
          AhdashQuestionType.drawing,
          AhdashQuestionType.charades,
          AhdashQuestionType.secretIdentity,
          AhdashQuestionType.year,
        }.contains(type),
        requiresMedia: const {
          AhdashQuestionType.image,
          AhdashQuestionType.imageCrop,
          AhdashQuestionType.imageBlur,
          AhdashQuestionType.audio,
          AhdashQuestionType.video,
        }.contains(type),
        privateReveal: const {
          AhdashQuestionType.drawing,
          AhdashQuestionType.charades,
          AhdashQuestionType.secretIdentity,
        }.contains(type),
        interactive: const {
          AhdashQuestionType.multipleChoice,
          AhdashQuestionType.ordering,
          AhdashQuestionType.progressiveHints,
          AhdashQuestionType.drawing,
          AhdashQuestionType.numeric,
          AhdashQuestionType.year,
          AhdashQuestionType.trueFalse,
        }.contains(type),
      ),
  };

  static QuestionMechanicSpec forType(AhdashQuestionType type) => _specs[type]!;

  static Set<AhdashQuestionType> get supportedTypes =>
      Set.unmodifiable(_specs.keys);
}

final class ProgressiveHintState {
  const ProgressiveHintState({
    required this.hints,
    required this.basePoints,
    required this.pointDecayPerHint,
    this.revealedCount = 1,
  }) : assert(revealedCount >= 0);

  final List<String> hints;
  final int basePoints;
  final int pointDecayPerHint;
  final int revealedCount;

  List<String> get visibleHints =>
      hints.take(revealedCount).toList(growable: false);
  bool get canRevealMore => revealedCount < hints.length;
  int get availablePoints =>
      max(0, basePoints - (max(0, revealedCount - 1) * pointDecayPerHint));

  ProgressiveHintState revealNext() => canRevealMore
      ? ProgressiveHintState(
          hints: hints,
          basePoints: basePoints,
          pointDecayPerHint: pointDecayPerHint,
          revealedCount: revealedCount + 1,
        )
      : this;
}

final class DrawingPoint {
  const DrawingPoint(this.x, this.y);
  final double x;
  final double y;

  Map<String, Object?> toJson() => {'x': x, 'y': y};
}

final class DrawingStroke {
  const DrawingStroke({
    required this.points,
    required this.colorValue,
    required this.width,
    this.eraser = false,
  });

  final List<DrawingPoint> points;
  final int colorValue;
  final double width;
  final bool eraser;
}

final class DrawingSession {
  const DrawingSession({this.strokes = const []});
  final List<DrawingStroke> strokes;

  DrawingSession add(DrawingStroke stroke) =>
      DrawingSession(strokes: [...strokes, stroke]);
  DrawingSession undo() => strokes.isEmpty
      ? this
      : DrawingSession(strokes: strokes.sublist(0, strokes.length - 1));
  DrawingSession clear() => const DrawingSession();
}

enum SecretRevealState { hidden, ready, visible, concealed }

final class SecretIdentityAssignment {
  const SecretIdentityAssignment({
    required this.publicCode,
    required this.identity,
    this.state = SecretRevealState.hidden,
  });

  final String publicCode;
  final String identity;
  final SecretRevealState state;

  SecretIdentityAssignment copyWith({SecretRevealState? state}) =>
      SecretIdentityAssignment(
        publicCode: publicCode,
        identity: identity,
        state: state ?? this.state,
      );
}

final class SecretIdentityEngine {
  const SecretIdentityEngine();

  SecretIdentityAssignment create(String identity, {int? seed}) {
    final random = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final bytes = List.generate(18, (_) => random.nextInt(256));
    final code = base64UrlEncode(bytes).replaceAll('=', '');
    return SecretIdentityAssignment(publicCode: code, identity: identity);
  }

  SecretIdentityAssignment reveal(SecretIdentityAssignment assignment) =>
      assignment.state == SecretRevealState.ready
      ? assignment.copyWith(state: SecretRevealState.visible)
      : assignment;

  SecretIdentityAssignment conceal(SecretIdentityAssignment assignment) =>
      assignment.copyWith(state: SecretRevealState.concealed);
}

enum CharadesPhase { hidden, ready, acting, success, failed }

final class CharadesSession {
  const CharadesSession({
    required this.secret,
    required this.durationSeconds,
    this.phase = CharadesPhase.hidden,
    this.startedAt,
  });

  final String secret;
  final int durationSeconds;
  final CharadesPhase phase;
  final DateTime? startedAt;

  CharadesSession ready() => CharadesSession(
    secret: secret,
    durationSeconds: durationSeconds,
    phase: CharadesPhase.ready,
  );

  CharadesSession start(DateTime now) => phase != CharadesPhase.ready
      ? this
      : CharadesSession(
          secret: secret,
          durationSeconds: durationSeconds,
          phase: CharadesPhase.acting,
          startedAt: now,
        );

  CharadesSession finish({required bool success}) => CharadesSession(
    secret: secret,
    durationSeconds: durationSeconds,
    phase: success ? CharadesPhase.success : CharadesPhase.failed,
    startedAt: startedAt,
  );
}
