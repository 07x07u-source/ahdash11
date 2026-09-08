import 'dart:math';

import '../../../shared/domain/category.dart';
import '../../game/domain/game_mode.dart';
import '../../game/domain/game_rules.dart';
import '../../match/domain/quiz_question.dart';
import 'party_game.dart';

final class PartyGameGenerationException implements Exception {
  const PartyGameGenerationException(this.message);
  final String message;
  @override
  String toString() => message;
}

final class PartyGameEngine {
  const PartyGameEngine();

  /// Chooses a six-category mix without favouring the same visible taxonomy
  /// repeatedly.  The source order is shuffled first so the result remains a
  /// true random pick when all candidates are equally distinct.
  List<QuizCategory> pickDiverseCategories(
    List<QuizCategory> categories, {
    int? seed,
  }) {
    final random = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final remaining = [...categories]..shuffle(random);
    final selected = <QuizCategory>[];
    while (remaining.isNotEmpty &&
        selected.length < PartyGameRules.categoriesPerGame) {
      var bestIndex = 0;
      var bestPenalty = _taxonomyOverlap(remaining.first, selected);
      for (var index = 1; index < remaining.length; index++) {
        final penalty = _taxonomyOverlap(remaining[index], selected);
        if (penalty < bestPenalty) {
          bestIndex = index;
          bestPenalty = penalty;
        }
      }
      selected.add(remaining.removeAt(bestIndex));
    }
    return selected;
  }

  PartyGameSession generate({
    required List<QuizCategory> categories,
    required List<QuizQuestion> pool,
    required List<PartyTeam> teams,
    List<PartyHelperDefinition> helperDefinitions = const [],
    bool tieBreakerEnabled = true,
    int? timerSeconds = PartyGameRules.defaultTimerSeconds,
    GameRuleConfig ruleConfig = GameRuleConfig.classicSession,
    Set<String> recentlySeen = const {},
    int? seed,
  }) {
    if (categories.length != PartyGameRules.categoriesPerGame) {
      throw const PartyGameGenerationException('اختر 6 أقسام بالضبط.');
    }
    if (teams.length != 2) {
      throw const PartyGameGenerationException('تحتاج اللعبة فريقين.');
    }
    final random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final snapshots = <PartyCategorySnapshot>[];
    final usedIds = <String>{};
    for (
      var categoryIndex = 0;
      categoryIndex < categories.length;
      categoryIndex++
    ) {
      final category = categories[categoryIndex];
      final candidates = pool
          .where(
            (question) =>
                question.categoryId == category.id &&
                _isPartyEligible(question),
          )
          .toList();
      final picked = <QuizQuestion>[];
      for (final difficulty in const [
        QuestionDifficulty.easy,
        QuestionDifficulty.medium,
        QuestionDifficulty.hard,
      ]) {
        final tier =
            candidates
                .where(
                  (question) =>
                      (difficulty == QuestionDifficulty.hard
                          ? question.difficulty == QuestionDifficulty.hard ||
                                question.difficulty == QuestionDifficulty.expert
                          : question.difficulty == difficulty) &&
                      !usedIds.contains(question.id),
                )
                .toList()
              ..shuffle(random)
              ..sort(
                (a, b) => (recentlySeen.contains(a.id) ? 1 : 0).compareTo(
                  recentlySeen.contains(b.id) ? 1 : 0,
                ),
              );
        if (tier.length < 2) {
          throw PartyGameGenerationException(
            'قسم ${category.name} لا يملك سؤالين صالحين من مستوى ${difficulty.arabicLabel}.',
          );
        }
        picked.addAll(tier.take(2));
        usedIds.addAll(tier.take(2).map((value) => value.id));
      }
      snapshots.add(
        PartyCategorySnapshot(
          id: category.id,
          name: category.name,
          colorValue: category.accentColor.toARGB32(),
          ownerTeamIndex: categoryIndex < PartyGameRules.categoriesPerGame ~/ 2
              ? 0
              : 1,
          imageUrl: category.imageUrl,
          focalX: category.focalX,
          focalY: category.focalY,
          questions: picked.map(_snapshot).toList(growable: false),
        ),
      );
    }
    if (usedIds.length != 36) {
      throw const PartyGameGenerationException('تعذر إنشاء 36 سؤالًا فريدًا.');
    }
    final selectedIds = categories.map((category) => category.id).toSet();
    final tieBreakerCandidates =
        pool
            .where(
              (question) =>
                  selectedIds.contains(question.categoryId) &&
                  _isPartyEligible(question) &&
                  !usedIds.contains(question.id),
            )
            .toList()
          ..shuffle(random)
          ..sort(
            (a, b) => (recentlySeen.contains(a.id) ? 1 : 0).compareTo(
              recentlySeen.contains(b.id) ? 1 : 0,
            ),
          );
    return PartyGameSession(
      id: 'party-${DateTime.now().microsecondsSinceEpoch}',
      teams: teams,
      categories: snapshots,
      helperDefinitions: helperDefinitions.isEmpty
          ? defaultPartyHelperDefinitions
          : helperDefinitions,
      timerSeconds: timerSeconds,
      ruleConfig: ruleConfig.copyWith(
        primaryAnswerSeconds: timerSeconds ?? ruleConfig.primaryAnswerSeconds,
      ),
      createdAt: DateTime.now(),
      tieBreakerQuestion:
          !tieBreakerEnabled || tieBreakerCandidates.firstOrNull == null
          ? null
          : _snapshot(tieBreakerCandidates.first),
    );
  }

  bool isCategoryReady(String categoryId, List<QuizQuestion> pool) {
    final rows = pool.where(
      (question) =>
          question.categoryId == categoryId && _isPartyEligible(question),
    );
    final easy = rows
        .where((question) => question.difficulty == QuestionDifficulty.easy)
        .length;
    final medium = rows
        .where((question) => question.difficulty == QuestionDifficulty.medium)
        .length;
    final hard = rows
        .where(
          (question) =>
              question.difficulty == QuestionDifficulty.hard ||
              question.difficulty == QuestionDifficulty.expert,
        )
        .length;
    return easy >= 2 && medium >= 2 && hard >= 2;
  }

  PartyQuestionSnapshot _snapshot(QuizQuestion question) {
    final format = switch (question.format) {
      QuestionFormat.openAnswer => PartyQuestionFormat.openAnswer,
      QuestionFormat.multipleChoice => PartyQuestionFormat.multipleChoice,
      QuestionFormat.trueFalse => PartyQuestionFormat.trueFalse,
      QuestionFormat.image => PartyQuestionFormat.image,
      QuestionFormat.imageCrop => PartyQuestionFormat.imageCrop,
      QuestionFormat.imageBlur => PartyQuestionFormat.imageBlur,
      QuestionFormat.audio => PartyQuestionFormat.audio,
      QuestionFormat.video => PartyQuestionFormat.video,
      QuestionFormat.ordering => PartyQuestionFormat.ordering,
      QuestionFormat.progressiveHints => PartyQuestionFormat.progressiveHints,
      QuestionFormat.drawing => PartyQuestionFormat.drawing,
      QuestionFormat.charades => PartyQuestionFormat.charades,
      QuestionFormat.secretIdentity => PartyQuestionFormat.secretIdentity,
      QuestionFormat.numeric => PartyQuestionFormat.numeric,
      QuestionFormat.year => PartyQuestionFormat.year,
    };
    return PartyQuestionSnapshot(
      id: question.id,
      categoryId: question.categoryId,
      text: question.text,
      answer:
          question.correctAnswer ??
          (question.correctOptionIndex < question.options.length
              ? question.options[question.correctOptionIndex]
              : ''),
      difficulty: question.difficulty,
      // Party board values are a fixed 100 / 200 / 300 contract.  Question
      // metadata may carry a different value for another game mode, but it
      // must never deform a six-by-six Party board.
      pointValue: PartyGameRules.pointsByDifficulty[question.difficulty]!,
      format: format,
      options:
          format == PartyQuestionFormat.trueFalse ||
              format == PartyQuestionFormat.multipleChoice
          ? question.options
          : const [],
      imageUrl: question.imageUrl,
      audioUrl: question.audioUrl,
      videoUrl: question.videoUrl,
      orderingItems: question.orderingItems,
      hints: question.hints,
      pointDecayPerHint: question.pointDecayPerHint,
      mechanicConfig: question.mechanicConfig,
      alternativeAnswers: question.alternativeAnswers,
      explanation: question.explanation,
    );
  }

  int _taxonomyOverlap(QuizCategory candidate, List<QuizCategory> selected) {
    if (selected.isEmpty) return 0;
    final candidateTokens = _categoryTokens(candidate);
    return selected.fold(0, (penalty, existing) {
      final common = candidateTokens.intersection(_categoryTokens(existing));
      // A shared leading slug is usually the clearest sign of sibling
      // categories (for example: saudi-clubs / saudi-legends).
      final sameFamily =
          _slugFamily(candidate.slug) == _slugFamily(existing.slug);
      return penalty + common.length + (sameFamily ? 8 : 0);
    });
  }

  Set<String> _categoryTokens(QuizCategory category) {
    final source = <String>[
      category.groupKey,
      category.slug,
      category.name,
      ...category.subcategories,
    ].join(' ').toLowerCase();
    return source
        .split(RegExp(r'[^a-z0-9\u0600-\u06ff]+'))
        .where((token) => token.length >= 3)
        .where(
          (token) => !const {
            'كرة',
            'قدم',
            'football',
            'the',
            'and',
            'من',
            'في',
          }.contains(token),
        )
        .toSet();
  }

  String _slugFamily(String slug) =>
      slug.toLowerCase().split(RegExp('[-_]')).firstOrNull ?? slug;

  bool _isPartyEligible(QuizQuestion question) =>
      question.gameType == GameType.classic ||
      question.gameType == GameType.trueFalse;
}
