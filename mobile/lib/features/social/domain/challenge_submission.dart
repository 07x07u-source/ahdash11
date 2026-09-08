import 'package:uuid/uuid.dart';

final class ChallengeSubmission {
  const ChallengeSubmission({
    required this.optionId,
    required this.idempotencyKey,
    required this.clientSequence,
  });

  final String? optionId;
  final String idempotencyKey;
  final int clientSequence;
}

final class ChallengeSubmissionTracker {
  ChallengeSubmissionTracker({String Function()? keyFactory})
    : _keyFactory = keyFactory ?? const Uuid().v4;

  final String Function() _keyFactory;
  ChallengeSubmission? _pending;
  var _clientSequence = 0;

  ChallengeSubmission? get pending => _pending;

  ChallengeSubmission begin({
    required String attemptId,
    required String questionId,
    required String? optionId,
  }) {
    final existing = _pending;
    if (existing != null) return existing;
    final sequence = ++_clientSequence;
    return _pending = ChallengeSubmission(
      optionId: optionId,
      idempotencyKey: '$attemptId:$questionId:$sequence:${_keyFactory()}',
      clientSequence: sequence,
    );
  }

  void complete(ChallengeSubmission submission) {
    if (identical(_pending, submission)) _pending = null;
  }

  void resetAuthoritativeState() {
    _pending = null;
  }
}
