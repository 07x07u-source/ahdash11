import 'package:ahdash_11/features/game/domain/game_mode.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/domain/party_game_engine.dart';
import 'package:ahdash_11/features/party/domain/party_rule_engines.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = PartyGameEngine();
  final categories = List.generate(
    6,
    (index) => QuizCategory(
      id: 'c$index',
      name: 'قسم $index',
      description: '',
      iconName: '',
      accentColor: const Color(0xFF123456),
    ),
  );
  final teams = const [
    PartyTeam(
      name: 'أ',
      colorValue: 1,
      selectedHelpers: {
        PartyHelperId.risk,
        PartyHelperId.pass,
        PartyHelperId.twoChances,
      },
    ),
    PartyTeam(
      name: 'ب',
      colorValue: 2,
      players: ['لاعب'],
      selectedHelpers: {
        PartyHelperId.risk,
        PartyHelperId.pass,
        PartyHelperId.bench,
      },
    ),
  ];

  test(
    'generator creates exactly 36 unique questions with 2/2/2 per category',
    () {
      final game = engine.generate(
        categories: categories,
        pool: _pool(categories, 2),
        teams: teams,
        seed: 11,
      );
      expect(game.categories, hasLength(6));
      expect(game.questions, hasLength(36));
      expect(
        game.questions.map((question) => question.id).toSet(),
        hasLength(36),
      );
      for (final category in game.categories) {
        expect(
          category.ownerTeamIndex,
          categories.indexOf(
                    categories.firstWhere((row) => row.id == category.id),
                  ) <
                  3
              ? 0
              : 1,
        );
        expect(
          category.questions.where((question) => question.pointValue == 100),
          hasLength(2),
        );
        expect(
          category.questions.where((question) => question.pointValue == 200),
          hasLength(2),
        );
        expect(
          category.questions.where((question) => question.pointValue == 300),
          hasLength(2),
        );
      }
    },
  );

  test('generator rejects a category with a missing difficulty tier', () {
    final pool = _pool(categories, 2)
      ..removeWhere(
        (question) =>
            question.categoryId == 'c0' &&
            question.difficulty == QuestionDifficulty.hard,
      );
    expect(
      () => engine.generate(categories: categories, pool: pool, teams: teams),
      throwsA(isA<PartyGameGenerationException>()),
    );
  });

  test('recent questions lose priority when an unused alternative exists', () {
    final pool = _pool(categories, 3);
    final recent = pool
        .where((question) => question.id.endsWith('-0'))
        .map((question) => question.id)
        .toSet();
    final game = engine.generate(
      categories: categories,
      pool: pool,
      teams: teams,
      recentlySeen: recent,
      seed: 9,
    );
    expect(
      game.questions.any((question) => recent.contains(question.id)),
      isFalse,
    );
  });

  test('random category picker prefers distinct editorial groups', () {
    const groups = [
      'saudi',
      'leagues',
      'clubs',
      'players',
      'history',
      'images',
    ];
    final candidates = [
      for (final group in groups)
        for (var index = 0; index < 2; index++)
          QuizCategory(
            id: '$group-$index',
            name: '$group $index',
            description: '',
            iconName: '',
            accentColor: const Color(0xFF123456),
            slug: '$group-$index',
            groupKey: group,
          ),
    ];

    final picked = engine.pickDiverseCategories(candidates, seed: 11);

    expect(picked, hasLength(6));
    expect(picked.map((category) => category.groupKey).toSet(), hasLength(6));
  });

  test(
    'random category picker avoids repeating a category family when possible',
    () {
      final catalog = [
        ...List.generate(
          3,
          (index) => QuizCategory(
            id: 'saudi-$index',
            name: 'السعودية $index',
            description: '',
            iconName: '',
            slug: 'saudi-${index + 1}',
            accentColor: const Color(0xFF123456),
          ),
        ),
        for (final family in const ['world', 'europe', 'clubs', 'players'])
          QuizCategory(
            id: family,
            name: family,
            description: '',
            iconName: '',
            slug: family,
            accentColor: const Color(0xFF123456),
          ),
      ];

      final picked = engine.pickDiverseCategories(catalog, seed: 17);
      expect(picked, hasLength(6));
      expect(
        picked.where((row) => row.slug.startsWith('saudi-')),
        hasLength(2),
      );
    },
  );

  test('image question pack accepts a server answer without fake options', () {
    final question = QuizQuestion.fromJson({
      'id': 'image-1',
      'question_text': 'من اللاعب؟',
      'category_id': 'c0',
      'difficulty': 'easy',
      'question_format': 'image',
      'question_type': 'image',
      'correct_answer': 'سالم الدوسري',
      'image_url': 'https://example.com/player.jpg',
    });
    expect(question.format, QuestionFormat.image);
    expect(question.options, ['سالم الدوسري']);
    expect(question.correctAnswer, 'سالم الدوسري');
  });

  test(
    'party board keeps the fixed tier values over foreign question metadata',
    () {
      final pool = _pool(categories, 2)
          .map(
            (question) => QuizQuestion(
              id: question.id,
              text: question.text,
              options: question.options,
              correctOptionIndex: question.correctOptionIndex,
              categoryId: question.categoryId,
              difficulty: question.difficulty,
              gameType: question.gameType,
              format: question.format,
              correctAnswer: question.correctAnswer,
              pointValue: 50,
            ),
          )
          .toList();
      final game = engine.generate(
        categories: categories,
        pool: pool,
        teams: teams,
        seed: 5,
      );
      expect(
        game.questions
            .where((question) => question.difficulty == QuestionDifficulty.easy)
            .map((question) => question.pointValue)
            .toSet(),
        {100},
      );
    },
  );

  test('session snapshot survives JSON round trip', () {
    final game = engine
        .generate(
          categories: categories,
          pool: _pool(categories, 3),
          teams: teams,
          seed: 4,
        )
        .copyWith(
          activeQuestionId: 'timer-question',
          questionTimerStartedAt: DateTime.utc(2026, 8, 30, 12),
          questionTimerDurationSeconds: 20,
          helperActionDetail: 'لاعب طويل الاسم',
        );
    final restored = PartyGameSession.decode(game.encode());
    expect(restored.id, game.id);
    expect(
      restored.questions.map((question) => question.id),
      game.questions.map((question) => question.id),
    );
    expect(restored.teams.first.selectedHelpers, teams.first.selectedHelpers);
    expect(restored.helperDefinitions.length, 5);
    expect(restored.questionTimerDurationSeconds, 20);
    expect(restored.helperActionDetail, 'لاعب طويل الاسم');
    expect(restored.tieBreakerQuestion?.id, game.tieBreakerQuestion?.id);
  });

  test('tie breaker uses an unused question and obeys the remote switch', () {
    final pool = _pool(categories, 3);
    final enabled = engine.generate(
      categories: categories,
      pool: pool,
      teams: teams,
      seed: 9,
    );
    expect(enabled.tieBreakerQuestion, isNotNull);
    expect(
      enabled.questions.map((question) => question.id),
      isNot(contains(enabled.tieBreakerQuestion!.id)),
    );
    final disabled = engine.generate(
      categories: categories,
      pool: pool,
      teams: teams,
      tieBreakerEnabled: false,
      seed: 9,
    );
    expect(disabled.tieBreakerQuestion, isNull);
  });

  test(
    'help engine blocks timing misuse, wrong prerequisites and double use',
    () {
      final game = engine.generate(
        categories: categories,
        pool: _pool(categories, 2),
        teams: teams,
        seed: 2,
      );
      const helps = PartyHelpEngine();
      expect(helps.canUse(game, PartyHelperId.risk), isTrue);
      expect(helps.canUse(game, PartyHelperId.pass), isFalse);
      final active = game.copyWith(activeQuestionId: game.questions.first.id);
      expect(helps.canUse(active, PartyHelperId.pass), isTrue);
      final usedTeams = [...active.teams];
      usedTeams[0] = usedTeams[0].copyWith(usedHelpers: {PartyHelperId.pass});
      expect(
        helps.canUse(active.copyWith(teams: usedTeams), PartyHelperId.pass),
        isFalse,
      );
    },
  );

  test('pit, trap and steal score deltas follow the central rules', () {
    final base = engine.generate(
      categories: categories,
      pool: _pool(categories, 2),
      teams: teams,
      seed: 3,
    );
    final active = base.copyWith(activeQuestionId: base.questions.first.id);
    const scores = PartyScoreEngine();
    expect(scores.deltas(active.copyWith(armedHelper: PartyHelperId.risk), 0), [
      100,
      -100,
    ]);
    expect(
      scores.deltas(active.copyWith(armedHelper: PartyHelperId.risk), null),
      [0, 0],
    );
    expect(
      scores.deltas(
        active.copyWith(armedHelper: PartyHelperId.pass, answeringTeamIndex: 1),
        null,
      ),
      [0, -100],
    );
    expect(
      scores.deltas(
        active.copyWith(stealActive: true, answeringTeamIndex: 1),
        1,
      ),
      [0, 100],
    );
  });

  test('score engine applies snapshotted Admin risk configuration', () {
    final definitions = defaultPartyHelperDefinitions
        .map(
          (definition) => definition.id == PartyHelperId.risk
              ? const PartyHelperDefinition(
                  id: PartyHelperId.risk,
                  label: 'مخاطرة',
                  description: 'قاعدة اختبار',
                  iconKey: 'trending_up',
                  timing: PartyHelperTiming.beforeQuestion,
                  correctMultiplier: 3,
                  wrongMultiplier: -2,
                )
              : definition,
        )
        .toList();
    final base = engine.generate(
      categories: categories,
      pool: _pool(categories, 2),
      teams: teams,
      helperDefinitions: definitions,
      seed: 11,
    );
    final active = base.copyWith(
      activeQuestionId: base.questions.first.id,
      armedHelper: PartyHelperId.risk,
    );
    const scores = PartyScoreEngine();
    expect(scores.deltas(active, 0), [100, -300]);
    expect(scores.deltas(active, null), [-200, 0]);
  });
}

List<QuizQuestion> _pool(List<QuizCategory> categories, int perTier) => [
  for (final category in categories)
    for (final difficulty in const [
      QuestionDifficulty.easy,
      QuestionDifficulty.medium,
      QuestionDifficulty.hard,
    ])
      for (var index = 0; index < perTier; index++)
        QuizQuestion(
          id: '${category.id}-${difficulty.name}-$index',
          text: 'سؤال ${category.id} ${difficulty.name} $index',
          options: const ['جواب', 'ب', 'ج', 'د'],
          correctOptionIndex: 0,
          categoryId: category.id,
          difficulty: difficulty,
          gameType: GameType.classic,
          format: QuestionFormat.openAnswer,
          correctAnswer: 'جواب',
        ),
];
