import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/quiz_question.dart';

abstract interface class OnlineMatchGateway {
  Future<PublicQuestion> fetchCurrentQuestion(String matchId);
  Future<OnlineAnswerReceipt> submitAnswer({
    required String matchQuestionId,
    required String matchOptionId,
    required String idempotencyKey,
    required int clientSequence,
  });
  Future<AnswerReveal?> reveal(String matchQuestionId);
  Future<Map<String, Object?>> advance(String matchId);
}

final class OnlineAnswerReceipt {
  const OnlineAnswerReceipt({
    required this.accepted,
    required this.duplicate,
    required this.serverReceivedAt,
    this.reveal,
  });

  final bool accepted;
  final bool duplicate;
  final DateTime serverReceivedAt;
  final AnswerReveal? reveal;
}

final class SupabaseOnlineMatchGateway implements OnlineMatchGateway {
  SupabaseOnlineMatchGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<PublicQuestion> fetchCurrentQuestion(String matchId) async {
    final data = await _client
        .from('match_question_payloads')
        .select()
        .eq('match_id', matchId)
        .eq('status', 'accepting')
        .order('sequence_number')
        .limit(1)
        .maybeSingle();
    if (data == null) throw const FormatException('No open match question');
    return PublicQuestion.fromJson(data);
  }

  @override
  Future<OnlineAnswerReceipt> submitAnswer({
    required String matchQuestionId,
    required String matchOptionId,
    required String idempotencyKey,
    required int clientSequence,
  }) async {
    final response = await _client.functions.invoke(
      'submit-answer',
      body: {
        'matchQuestionId': matchQuestionId,
        'optionId': matchOptionId,
        'idempotencyKey': idempotencyKey,
        'clientSequence': clientSequence,
      },
    );
    final data = _map(response.data);
    final submission = _map(data?['submission']);
    if (submission == null) {
      throw const FormatException('Invalid answer reveal payload');
    }
    return OnlineAnswerReceipt(
      accepted: submission['accepted'] == true,
      duplicate: submission['duplicate'] == true,
      serverReceivedAt:
          DateTime.tryParse(
            submission['server_received_at'] as String? ?? '',
          ) ??
          DateTime.now().toUtc(),
      reveal: _parseReveal(_map(data?['result'])),
    );
  }

  @override
  Future<AnswerReveal?> reveal(String matchQuestionId) async {
    try {
      final data = await _client.rpc<Object?>(
        'reveal_match_question',
        params: {'p_match_question_id': matchQuestionId},
      );
      return _parseReveal(_map(data));
    } on PostgrestException {
      return null;
    }
  }

  @override
  Future<Map<String, Object?>> advance(String matchId) async {
    final data = await _client.rpc<Object?>(
      'advance_match',
      params: {'p_match_id': matchId},
    );
    final mapped = _map(data);
    if (mapped == null) throw const FormatException('Invalid match state');
    return mapped;
  }

  static Map<String, Object?>? _map(Object? value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static AnswerReveal? _parseReveal(Map<String, Object?>? data) {
    if (data == null || data['correct_option_id'] is! String) return null;
    final answers = ((data['answers'] as List?) ?? const [])
        .map(_map)
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
    return AnswerReveal(
      questionId: data['match_question_id']! as String,
      correctOptionId: data['correct_option_id']! as String,
      answers: answers,
    );
  }
}
