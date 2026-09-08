final class QuestionHistoryEntry {
  const QuestionHistoryEntry({
    required this.questionId,
    required this.seenCount,
    required this.correctCount,
    required this.lastSeenAt,
  });

  final String questionId;
  final int seenCount;
  final int correctCount;
  final DateTime lastSeenAt;
}
