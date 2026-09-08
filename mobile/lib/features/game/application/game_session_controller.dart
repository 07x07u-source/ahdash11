import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../match/data/online_match_gateway.dart';
import '../../match/domain/quiz_question.dart';
import 'game_clock.dart';

enum GameSessionPhase {
  bootstrapping,
  acceptingInput,
  lockingInput,
  submittingAnswer,
  revealingVerdict,
  transitioning,
  reconnecting,
  completed,
  failed,
}

@immutable
final class GameSessionState {
  const GameSessionState({
    required this.phase,
    this.question,
    this.reveal,
    this.selectedOptionId,
    this.remaining = Duration.zero,
    this.finalResult,
    this.error,
    this.canRetrySubmission = false,
  });

  const GameSessionState.bootstrapping()
    : this(phase: GameSessionPhase.bootstrapping);

  final GameSessionPhase phase;
  final PublicQuestion? question;
  final AnswerReveal? reveal;
  final String? selectedOptionId;
  final Duration remaining;
  final Map<String, Object?>? finalResult;
  final String? error;
  final bool canRetrySubmission;

  bool get canAnswer =>
      phase == GameSessionPhase.acceptingInput && remaining > Duration.zero;

  GameSessionState copyWith({
    GameSessionPhase? phase,
    Object? question = _keep,
    Object? reveal = _keep,
    Object? selectedOptionId = _keep,
    Duration? remaining,
    Object? finalResult = _keep,
    Object? error = _keep,
    bool? canRetrySubmission,
  }) {
    return GameSessionState(
      phase: phase ?? this.phase,
      question: identical(question, _keep)
          ? this.question
          : question as PublicQuestion?,
      reveal: identical(reveal, _keep) ? this.reveal : reveal as AnswerReveal?,
      selectedOptionId: identical(selectedOptionId, _keep)
          ? this.selectedOptionId
          : selectedOptionId as String?,
      remaining: remaining ?? this.remaining,
      finalResult: identical(finalResult, _keep)
          ? this.finalResult
          : finalResult as Map<String, Object?>?,
      error: identical(error, _keep) ? this.error : error as String?,
      canRetrySubmission: canRetrySubmission ?? this.canRetrySubmission,
    );
  }

  static const _keep = Object();
}

final class GameSessionController extends ChangeNotifier {
  GameSessionController({
    required this.matchId,
    required OnlineMatchGateway gateway,
    GameClock clock = const SystemGameClock(),
    String Function()? idempotencyKeyFactory,
  }) : _gateway = gateway,
       _clock = clock,
       _idempotencyKeyFactory = idempotencyKeyFactory ?? const Uuid().v4;

  final String matchId;
  final OnlineMatchGateway _gateway;
  final GameClock _clock;
  final String Function() _idempotencyKeyFactory;

  GameSessionState _state = const GameSessionState.bootstrapping();
  StreamSubscription<DateTime>? _ticker;
  _PendingSubmission? _pending;
  Duration _serverOffset = Duration.zero;
  var _clientSequence = 0;
  var _disposed = false;
  var _pollGeneration = 0;

  GameSessionState get state => _state;

  Future<void> start() => _loadQuestion();

  Future<void> recover() async {
    _pollGeneration++;
    _emit(_state.copyWith(phase: GameSessionPhase.reconnecting, error: null));
    await _loadQuestion();
  }

  Future<void> submitAnswer(int index) async {
    final question = _state.question;
    if (!_state.canAnswer ||
        question == null ||
        index < 0 ||
        index >= question.optionIds.length) {
      return;
    }

    final optionId = question.optionIds[index];
    final pending = _PendingSubmission(
      questionId: question.id,
      optionId: optionId,
      idempotencyKey:
          '$matchId:${question.id}:${_clientSequence + 1}:${_idempotencyKeyFactory()}',
      clientSequence: ++_clientSequence,
    );
    _pending = pending;

    // The state locks synchronously before the first await.
    _emit(
      _state.copyWith(
        phase: GameSessionPhase.lockingInput,
        selectedOptionId: optionId,
        error: null,
        canRetrySubmission: false,
      ),
    );
    await _sendPending(pending);
  }

  Future<void> retryPendingSubmission() async {
    final pending = _pending;
    if (!_state.canRetrySubmission || pending == null) return;
    await _sendPending(pending);
  }

  Future<void> nextQuestion() async {
    if (_state.phase != GameSessionPhase.revealingVerdict ||
        _state.reveal == null) {
      return;
    }
    _emit(
      _state.copyWith(
        phase: GameSessionPhase.transitioning,
        error: null,
        canRetrySubmission: false,
      ),
    );
    try {
      final result = await _gateway.advance(matchId);
      if (_disposed) return;
      if (result['state'] == 'finished') {
        _cancelTicker();
        _emit(
          GameSessionState(
            phase: GameSessionPhase.completed,
            finalResult: result,
          ),
        );
        return;
      }
      await _clock.wait(const Duration(milliseconds: 240));
      if (!_disposed) await _loadQuestion();
    } catch (_) {
      if (_disposed) return;
      _emit(
        _state.copyWith(
          phase: GameSessionPhase.reconnecting,
          error: 'تعذر الانتقال. استعد حالة المباراة من الخادم.',
        ),
      );
    }
  }

  Future<void> _loadQuestion() async {
    _cancelTicker();
    _pending = null;
    _emit(const GameSessionState.bootstrapping());
    try {
      final question = await _gateway.fetchCurrentQuestion(matchId);
      final expectedOptionCount = question.gameType == 'true-false' ? 2 : 4;
      if (question.options.length != expectedOptionCount ||
          question.optionIds.length != expectedOptionCount) {
        throw FormatException(
          'Online ${question.gameType} question must contain '
          '$expectedOptionCount public options',
        );
      }
      if (_disposed) return;
      final clientNow = _clock.nowUtc();
      _serverOffset = question.serverNow == null
          ? Duration.zero
          : question.serverNow!.toUtc().difference(clientNow);
      final remaining = _remainingFor(question);
      _emit(
        GameSessionState(
          phase: remaining > Duration.zero
              ? GameSessionPhase.acceptingInput
              : GameSessionPhase.revealingVerdict,
          question: question,
          remaining: remaining,
        ),
      );
      _ticker = _clock
          .ticks(const Duration(milliseconds: 250))
          .listen((_) => _onTick(question));
      if (remaining == Duration.zero) unawaited(_pollForReveal(question));
    } catch (_) {
      if (_disposed) return;
      _emit(
        const GameSessionState(
          phase: GameSessionPhase.failed,
          error: 'تعذر تحميل حالة المباراة من الخادم.',
        ),
      );
    }
  }

  Future<void> _sendPending(_PendingSubmission pending) async {
    final question = _state.question;
    if (question == null || question.id != pending.questionId) return;
    _emit(
      _state.copyWith(
        phase: GameSessionPhase.submittingAnswer,
        selectedOptionId: pending.optionId,
        error: null,
        canRetrySubmission: false,
      ),
    );
    try {
      final receipt = await _gateway.submitAnswer(
        matchQuestionId: pending.questionId,
        matchOptionId: pending.optionId,
        idempotencyKey: pending.idempotencyKey,
        clientSequence: pending.clientSequence,
      );
      if (_disposed || _state.question?.id != pending.questionId) return;
      if (!receipt.accepted) throw StateError('Answer was not accepted');
      if (receipt.reveal != null) {
        _showReveal(receipt.reveal!);
      } else {
        _emit(
          _state.copyWith(
            phase: GameSessionPhase.revealingVerdict,
            canRetrySubmission: false,
          ),
        );
        await _pollForReveal(question);
      }
    } catch (_) {
      if (_disposed || _state.question?.id != pending.questionId) return;
      _emit(
        _state.copyWith(
          phase: GameSessionPhase.reconnecting,
          error:
              'لم يصل تأكيد الخادم. أعد الإرسال الآمن بنفس المحاولة قبل انتهاء الوقت.',
          canRetrySubmission: _state.remaining > Duration.zero,
        ),
      );
    }
  }

  Future<void> _pollForReveal(PublicQuestion question) async {
    final generation = ++_pollGeneration;
    for (var attempt = 0; attempt < 35 && !_disposed; attempt++) {
      if (generation != _pollGeneration || _state.question?.id != question.id) {
        return;
      }
      final reveal = await _gateway.reveal(question.id);
      if (_disposed || generation != _pollGeneration) return;
      if (reveal != null) {
        _showReveal(reveal);
        return;
      }
      await _clock.wait(const Duration(milliseconds: 700));
    }
    if (_disposed || generation != _pollGeneration) return;
    _emit(
      _state.copyWith(
        phase: GameSessionPhase.reconnecting,
        error: 'تأخر إغلاق السؤال. استعد الحالة من الخادم.',
        canRetrySubmission: false,
      ),
    );
  }

  void _onTick(PublicQuestion question) {
    if (_disposed ||
        _state.question?.id != question.id ||
        _state.reveal != null) {
      return;
    }
    final remaining = _remainingFor(question);
    _emit(_state.copyWith(remaining: remaining));
    if (remaining == Duration.zero &&
        _state.phase == GameSessionPhase.acceptingInput) {
      _emit(
        _state.copyWith(
          phase: GameSessionPhase.revealingVerdict,
          canRetrySubmission: false,
        ),
      );
      unawaited(_pollForReveal(question));
    }
  }

  Duration _remainingFor(PublicQuestion question) {
    final deadline = question.serverDeadline;
    if (deadline == null) return const Duration(seconds: 15);
    final serverAdjustedNow = _clock.nowUtc().add(_serverOffset);
    final difference = deadline.toUtc().difference(serverAdjustedNow);
    return difference.isNegative ? Duration.zero : difference;
  }

  void _showReveal(AnswerReveal reveal) {
    if (_disposed || reveal.questionId != _state.question?.id) return;
    _cancelTicker();
    _emit(
      _state.copyWith(
        phase: GameSessionPhase.revealingVerdict,
        reveal: reveal,
        error: null,
        canRetrySubmission: false,
      ),
    );
  }

  void _emit(GameSessionState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  void _cancelTicker() {
    unawaited(_ticker?.cancel());
    _ticker = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _pollGeneration++;
    _cancelTicker();
    super.dispose();
  }
}

final class _PendingSubmission {
  const _PendingSubmission({
    required this.questionId,
    required this.optionId,
    required this.idempotencyKey,
    required this.clientSequence,
  });

  final String questionId;
  final String optionId;
  final String idempotencyKey;
  final int clientSequence;
}
