enum QuestionReportReason {
  incorrectAnswer,
  typo,
  wrongImage,
  wrongCategory,
  outdated,
  duplicate,
  mediaProblem,
  other;

  String get storageKey => switch (this) {
    QuestionReportReason.incorrectAnswer => 'incorrect_answer',
    QuestionReportReason.typo => 'typo',
    QuestionReportReason.wrongImage => 'wrong_image',
    QuestionReportReason.wrongCategory => 'wrong_category',
    QuestionReportReason.outdated => 'outdated',
    QuestionReportReason.duplicate => 'duplicate',
    QuestionReportReason.mediaProblem => 'media_problem',
    QuestionReportReason.other => 'other',
  };

  String get labelAr => switch (this) {
    QuestionReportReason.incorrectAnswer => 'الإجابة غير صحيحة',
    QuestionReportReason.typo => 'خطأ إملائي',
    QuestionReportReason.wrongImage => 'الصورة غير صحيحة',
    QuestionReportReason.wrongCategory => 'الفئة غير مناسبة',
    QuestionReportReason.outdated => 'المعلومة قديمة',
    QuestionReportReason.duplicate => 'السؤال مكرر',
    QuestionReportReason.mediaProblem => 'مشكلة في الوسائط',
    QuestionReportReason.other => 'سبب آخر',
  };

  String get backendReason => switch (this) {
    QuestionReportReason.incorrectAnswer => 'wrong_answer',
    QuestionReportReason.typo => 'unclear',
    QuestionReportReason.wrongImage ||
    QuestionReportReason.mediaProblem => 'wrong_image',
    QuestionReportReason.duplicate => 'duplicate',
    QuestionReportReason.wrongCategory ||
    QuestionReportReason.outdated ||
    QuestionReportReason.other => 'other',
  };

  static QuestionReportReason fromStorage(String value) =>
      values.where((reason) => reason.storageKey == value).firstOrNull ??
      QuestionReportReason.other;
}

final class QuestionReportDraft {
  const QuestionReportDraft({
    required this.id,
    required this.questionId,
    required this.gameId,
    required this.reason,
    required this.createdAt,
    required this.appVersion,
    this.comment,
    this.userId,
  });

  factory QuestionReportDraft.fromJson(Map<String, Object?> json) =>
      QuestionReportDraft(
        id: '${json['id']}',
        questionId: '${json['question_id']}',
        gameId: '${json['game_id']}',
        reason: QuestionReportReason.fromStorage('${json['reason']}'),
        comment: json['comment'] as String?,
        userId: json['user_id'] as String?,
        createdAt:
            DateTime.tryParse('${json['created_at']}') ??
            DateTime.now().toUtc(),
        appVersion: '${json['app_version'] ?? ''}',
      );

  final String id;
  final String questionId;
  final String gameId;
  final QuestionReportReason reason;
  final String? comment;
  final String? userId;
  final DateTime createdAt;
  final String appVersion;

  Map<String, Object?> toJson() => {
    'id': id,
    'question_id': questionId,
    'game_id': gameId,
    'reason': reason.storageKey,
    'comment': comment,
    'user_id': userId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'app_version': appVersion,
  };
}

enum QuestionReportSubmitStatus {
  sent,
  queued,
  duplicate,
  authenticationRequired,
}
