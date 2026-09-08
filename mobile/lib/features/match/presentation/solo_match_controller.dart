import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/game_settings_repository.dart';
import '../../../core/services/app_error_reporter.dart';
import '../../../core/services/app_services.dart';
import '../../../shared/domain/game_settings.dart';
import '../../game/domain/game_mode.dart';
import '../domain/question_engine.dart';
import '../domain/quiz_question.dart';
import '../domain/scoring_engine.dart';
import '../domain/solo_opponent.dart';
import 'question_repository_provider.dart';

final soloMatchControllerProvider =
    NotifierProvider<SoloMatchController, SoloMatchState>(
      SoloMatchController.new,
    );

final class SoloMatchRequest {
  const SoloMatchRequest({
    required this.categoryIds,
    required this.difficulty,
    required this.questionCount,
    required this.opponentLevel,
    this.gameType = GameType.classic,
  });

  final Set<String> categoryIds;
  final QuestionDifficulty difficulty;
  final int questionCount;
  final SoloOpponentLevel opponentLevel;
  final GameType gameType;
}

enum SoloMatchStatus { idle, loading, answering, revealed, finished, error }

final class SoloAnswerRecord {
  const SoloAnswerRecord({
    required this.questionId,
    required this.selectedIndex,
    required this.correct,
    required this.score,
    required this.responseTime,
  });

  final String questionId;
  final int selectedIndex;
  final bool correct;
  final int score;
  final Duration responseTime;
}

final class SoloMatchState {
  const SoloMatchState({
    this.status = SoloMatchStatus.idle,
    this.questions = const [],
    this.currentIndex = 0,
    this.playerScore = 0,
    this.opponentScore = 0,
    this.personalBestScore = 0,
    this.selectedIndex,
    this.lastScore,
    this.records = const [],
    this.questionStartedAt,
    this.settings = const GameSettings(),
    this.errorMessage,
    this.gameType = GameType.classic,
  });

  final SoloMatchStatus status;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int playerScore;
  final int personalBestScore;
  final int opponentScore;
  final int? selectedIndex;
  final ScoreBreakdown? lastScore;
  final List<SoloAnswerRecord> records;
  final DateTime? questionStartedAt;
  final GameSettings settings;
  final String? errorMessage;
  final GameType gameType;

  QuizQuestion? get currentQuestion {
    if (questions.isEmpty || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  int get correctAnswers => records.where((record) => record.correct).length;
  int get wrongAnswers => records.length - correctAnswers;
  double get accuracy => records.isEmpty ? 0 : correctAnswers / records.length;
  Duration get totalResponseTime =>
      records.fold(Duration.zero, (sum, record) => sum + record.responseTime);
  Duration get averageResponseTime => records.isEmpty
      ? Duration.zero
      : Duration(
          milliseconds: totalResponseTime.inMilliseconds ~/ records.length,
        );
  int get longestStreak {
    var current = 0;
    var best = 0;
    for (final record in records) {
      current = record.correct ? current + 1 : 0;
      if (current > best) best = current;
    }
    return best;
  }

  bool get won => playerScore > opponentScore;
  bool get draw => playerScore == opponentScore;
}

final class SoloMatchController extends Notifier<SoloMatchState> {
  static const _personalBestKey = 'solo_personal_best_v1';
  SoloMatchRequest? _request;

  @override
  SoloMatchState build() => const SoloMatchState();

  Future<void> start(SoloMatchRequest request) async {
    state = SoloMatchState(
      status: SoloMatchStatus.loading,
      gameType: request.gameType,
    );
    _request = request;
    try {
      final repository = ref.read(questionRepositoryProvider);
      var personalBest = 0;
      try {
        personalBest =
            int.tryParse(
              '${await SharedPreferencesAsync().getInt(_personalBestKey) ?? ''}',
            ) ??
            0;
      } catch (_) {
        // The challenge remains playable when local persistence is unavailable.
      }
      final settings = await ref.read(gameSettingsProvider.future);
      final effectiveTimeSeconds = switch (request.gameType) {
        GameType.speed => 7,
        GameType.trueFalse => 10,
        _ => settings.questionTimeSeconds,
      };
      final effectiveSettings =
          effectiveTimeSeconds != settings.questionTimeSeconds
          ? GameSettings(
              defaultQuestionCount: settings.defaultQuestionCount,
              baseScore: settings.baseScore,
              maxSpeedBonus: settings.maxSpeedBonus,
              questionTimeSeconds: effectiveTimeSeconds,
              difficultySampleSize: settings.difficultySampleSize,
            )
          : settings;
      final pool = await repository.loadSoloPool();
      final history = await repository.loadHistory();
      final selected = const QuestionEngine().select(
        pool: pool,
        request: QuestionSelectionRequest(
          categoryIds: request.categoryIds,
          difficulty: request.difficulty,
          count: request.questionCount,
          seed: DateTime.now().day + 11,
          gameType: request.gameType,
        ),
        history: history,
      );
      if (selected.isEmpty) {
        state = SoloMatchState(
          status: SoloMatchStatus.error,
          errorMessage: 'لا توجد أسئلة متاحة لهذه الإعدادات.',
          gameType: request.gameType,
        );
        return;
      }
      state = SoloMatchState(
        status: SoloMatchStatus.answering,
        questions: selected,
        settings: effectiveSettings,
        personalBestScore: personalBest,
        questionStartedAt: DateTime.now(),
        gameType: request.gameType,
      );
      await ref.read(appServicesProvider).analytics.log('match_started', {
        'mode': 'solo',
        'game_type': request.gameType.slug,
        'question_count': selected.length,
      });
    } catch (error, stackTrace) {
      unawaited(
        ref.read(appServicesProvider).crashReporter.record(error, stackTrace),
      );
      unawaited(
        ref
            .read(appServicesProvider)
            .errors
            .report(
              severity: AppErrorSeverity.error,
              category: AppErrorCategory.unexpectedState,
              feature: 'solo_match_setup',
              error: error,
              stackTrace: stackTrace,
              screen: '/match',
            ),
      );
      state = SoloMatchState(
        status: SoloMatchStatus.error,
        errorMessage: 'تعذر تجهيز المباراة. تحقق من الاتصال وحاول مجددًا.',
        gameType: request.gameType,
      );
    }
  }

  void submitAnswer(int selectedIndex) => _submitAnswer(selectedIndex);

  void _submitAnswer(int selectedIndex, {bool timedOut = false}) {
    final question = state.currentQuestion;
    final startedAt = state.questionStartedAt;
    if (state.status != SoloMatchStatus.answering ||
        question == null ||
        startedAt == null) {
      return;
    }
    final responseTime = DateTime.now().difference(startedAt);
    final correct = selectedIndex == question.correctOptionIndex;
    final rules = ScoringRules(
      basePoints: state.settings.baseScore,
      maxSpeedBonus: state.settings.maxSpeedBonus,
      timeLimit: Duration(seconds: state.settings.questionTimeSeconds),
    );
    final score = ScoringEngine.calculate(
      correct: correct,
      answerTime: responseTime,
      rules: rules,
    );
    final record = SoloAnswerRecord(
      questionId: question.id,
      selectedIndex: selectedIndex,
      correct: correct,
      score: score.total,
      responseTime: responseTime,
    );
    state = SoloMatchState(
      status: SoloMatchStatus.revealed,
      questions: state.questions,
      currentIndex: state.currentIndex,
      playerScore: state.playerScore + score.total,
      opponentScore: 0,
      personalBestScore: state.personalBestScore,
      selectedIndex: timedOut ? null : selectedIndex,
      lastScore: score,
      records: [...state.records, record],
      questionStartedAt: startedAt,
      settings: state.settings,
      gameType: state.gameType,
    );
    unawaited(
      ref
          .read(questionRepositoryProvider)
          .recordAnswer(
            questionId: question.id,
            selectedIndex: selectedIndex,
            correct: correct,
          ),
    );
    unawaited(
      ref.read(appServicesProvider).analytics.log('question_answered', {
        'correct': correct,
        'response_ms': responseTime.inMilliseconds,
      }),
    );
  }

  void timeout() => _submitAnswer(-1, timedOut: true);

  Future<void> nextQuestion() async {
    if (state.status != SoloMatchStatus.revealed) return;
    if (state.currentIndex + 1 >= state.questions.length) {
      final personalBest = state.playerScore > state.personalBestScore
          ? state.playerScore
          : state.personalBestScore;
      state = SoloMatchState(
        status: SoloMatchStatus.finished,
        questions: state.questions,
        currentIndex: state.currentIndex,
        playerScore: state.playerScore,
        opponentScore: state.opponentScore,
        personalBestScore: personalBest,
        records: state.records,
        settings: state.settings,
        gameType: state.gameType,
      );
      await ref.read(appServicesProvider).analytics.log('match_finished', {
        'mode': 'solo',
        'accuracy': state.accuracy,
        'score': state.playerScore,
      });
      try {
        await SharedPreferencesAsync().setInt(_personalBestKey, personalBest);
      } catch (_) {
        // The completed result remains valid; persistence can retry later.
      }
      return;
    }
    state = SoloMatchState(
      status: SoloMatchStatus.answering,
      questions: state.questions,
      currentIndex: state.currentIndex + 1,
      playerScore: state.playerScore,
      opponentScore: state.opponentScore,
      personalBestScore: state.personalBestScore,
      records: state.records,
      questionStartedAt: DateTime.now(),
      settings: state.settings,
      gameType: state.gameType,
    );
  }

  Future<void> replay() async {
    final request = _request;
    if (request != null) await start(request);
  }

  void reset() {
    _request = null;
    state = const SoloMatchState();
  }
}
