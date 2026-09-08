import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PartySetupFlowResolver', () {
    test('resolves every canonical setup checkpoint from real state', () {
      expect(
        PartySetupFlowResolver.canonicalRoute(const PartyGameState()),
        '/party/categories',
      );

      final categoriesDone = PartyGameState(
        selectedCategoryIds: _categoryIds,
        hasSetupDraft: true,
      );
      expect(
        PartySetupFlowResolver.canonicalRoute(categoriesDone),
        '/party/teams',
      );

      final splitterRequested = categoriesDone.copyWith(
        teamSetupCompleted: true,
        splitterStatus: PartySplitterStatus.requested,
      );
      expect(
        PartySetupFlowResolver.canonicalRoute(splitterRequested),
        '/party/splitter',
      );

      final splitterSkipped = splitterRequested.copyWith(
        splitterStatus: PartySplitterStatus.skipped,
      );
      expect(
        PartySetupFlowResolver.canonicalRoute(splitterSkipped),
        '/party/helpers',
      );

      final ready = splitterSkipped.copyWith(teams: _readyTeams);
      expect(PartySetupFlowResolver.canonicalRoute(ready), '/party/ready');
    });

    test('legacy routes cannot jump past the earliest incomplete step', () {
      expect(
        PartySetupFlowResolver.redirectFor(
          PartySetupStep.ready,
          const PartyGameState(hasSetupDraft: true),
        ),
        '/party/categories',
      );
      expect(
        PartySetupFlowResolver.redirectFor(
          PartySetupStep.categories,
          PartyGameState(
            selectedCategoryIds: _categoryIds,
            hasSetupDraft: true,
          ),
        ),
        '/party/teams',
      );
      expect(
        PartySetupFlowResolver.redirectFor(
          PartySetupStep.categories,
          PartyGameState(
            selectedCategoryIds: _categoryIds,
            hasSetupDraft: true,
          ),
          allowReview: true,
        ),
        isNull,
      );
    });

    test('an active session resumes at Board', () {
      final state = PartyGameState(session: _activeSession, restored: true);
      expect(PartySetupFlowResolver.canonicalRoute(state), '/party/board');
    });

    test('an opened question resumes at Question', () {
      final session = _activeSession.copyWith(
        activeQuestionId: _activeSession.questions.first.id,
      );
      final state = PartyGameState(session: session, restored: true);
      expect(PartySetupFlowResolver.canonicalRoute(state), '/party/question');
      expect(
        PartySetupFlowResolver.redirectGameplay(PartyGameplayStep.board, state),
        '/party/question',
      );
    });

    test('a revealed answer resumes at Reveal awaiting score', () {
      final session = _activeSession.copyWith(
        activeQuestionId: _activeSession.questions.first.id,
        revealed: true,
      );
      final state = PartyGameState(session: session, restored: true);
      expect(PartySetupFlowResolver.canonicalRoute(state), '/party/reveal');
      expect(
        PartySetupFlowResolver.redirectGameplay(
          PartyGameplayStep.reveal,
          state,
        ),
        isNull,
      );
    });

    test('an authoritatively completed session resumes at Result', () {
      final completed = _activeSession.copyWith(
        categories: _activeSession.categories
            .map(
              (category) => category.copyWith(
                questions: category.questions
                    .map((question) => question.copyWith(used: true))
                    .toList(),
              ),
            )
            .toList(),
        completedAt: DateTime.utc(2026, 9, 5),
      );
      final state = PartyGameState(session: completed, restored: true);
      expect(PartySetupFlowResolver.canonicalRoute(state), '/party/result');
    });

    test('a new draft takes precedence without deleting a saved session', () {
      final state = PartyGameState(
        session: _activeSession,
        hasSetupDraft: true,
        restored: true,
      );
      expect(PartySetupFlowResolver.canonicalRoute(state), '/party/categories');
    });

    test('unplayable or newly locked categories resolve back to selection', () {
      final state = PartyGameState(
        selectedCategoryIds: _categoryIds,
        teamSetupCompleted: true,
        splitterStatus: PartySplitterStatus.skipped,
        teams: _readyTeams,
        hasSetupDraft: true,
      );
      expect(
        PartySetupFlowResolver.canonicalRoute(
          state,
          playableCategoryIds: _categoryIds.take(5).toSet(),
        ),
        '/party/categories',
      );
    });
  });

  group('PartySetupValidation', () {
    test('rejects blank, long, and duplicate team names in Arabic', () {
      expect(
        PartySetupValidation.teamError(const [
          PartyTeam(name: '  ', colorValue: 1),
          PartyTeam(name: 'الثاني', colorValue: 2),
        ]),
        isNotNull,
      );
      expect(
        PartySetupValidation.teamError(const [
          PartyTeam(name: 'الفريق', colorValue: 1),
          PartyTeam(name: '  الفريق  ', colorValue: 2),
        ]),
        isNotNull,
      );
      expect(
        PartySetupValidation.teamError([
          PartyTeam(name: List.filled(25, 'س').join(), colorValue: 1),
          const PartyTeam(name: 'الثاني', colorValue: 2),
        ]),
        isNotNull,
      );
    });

    test('Ready uses one complete validation contract', () {
      expect(
        PartySetupValidation.readyError(
          hasSetupDraft: true,
          teamSetupCompleted: true,
          splitterStatus: PartySplitterStatus.skipped,
          selectedCategoryIds: _categoryIds,
          playableCategoryIds: _categoryIds.toSet(),
          teams: _readyTeams,
          activeHelperIds: PartyHelperId.values.toSet(),
        ),
        isNull,
      );
      expect(
        PartySetupValidation.readyError(
          hasSetupDraft: true,
          teamSetupCompleted: true,
          splitterStatus: PartySplitterStatus.completed,
          selectedCategoryIds: [..._categoryIds.take(5), _categoryIds.first],
          playableCategoryIds: _categoryIds.toSet(),
          teams: _readyTeams,
          activeHelperIds: PartyHelperId.values.toSet(),
        ),
        isNotNull,
      );
      expect(
        PartySetupValidation.readyError(
          hasSetupDraft: true,
          teamSetupCompleted: true,
          splitterStatus: PartySplitterStatus.notRequested,
          selectedCategoryIds: _categoryIds,
          playableCategoryIds: _categoryIds.toSet(),
          teams: _readyTeams,
          activeHelperIds: PartyHelperId.values.toSet(),
        ),
        isNotNull,
      );
    });

    test('the five helper definitions are distinct and domain-backed', () {
      expect(defaultPartyHelperDefinitions, hasLength(5));
      expect(
        defaultPartyHelperDefinitions.map((value) => value.id).toSet(),
        PartyHelperId.values.toSet(),
      );
      expect(
        defaultPartyHelperDefinitions.map((value) => value.iconKey).toSet(),
        hasLength(5),
      );
    });
  });
}

final _categoryIds = List.generate(6, (index) => 'category-$index');

final _readyTeams = [
  PartyTeam(
    name: 'الصقور',
    colorValue: 0xFF2368A2,
    players: const ['سلمان'],
    selectedHelpers: const {
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
      PartyHelperId.bench,
    },
  ),
  PartyTeam(
    name: 'النجوم',
    colorValue: 0xFFB63863,
    players: const ['نواف'],
    selectedHelpers: const {
      PartyHelperId.risk,
      PartyHelperId.pass,
      PartyHelperId.bench,
    },
  ),
];

final _activeSession = PartyGameSession(
  id: 'legacy-session',
  teams: _readyTeams,
  categories: const [
    PartyCategorySnapshot(
      id: 'category-0',
      name: 'فئة',
      colorValue: 0xFF2368A2,
      ownerTeamIndex: 0,
      questions: [
        PartyQuestionSnapshot(
          id: 'question-0',
          categoryId: 'category-0',
          text: 'سؤال محفوظ',
          answer: 'إجابة محفوظة',
          difficulty: QuestionDifficulty.easy,
          pointValue: 100,
          format: PartyQuestionFormat.openAnswer,
        ),
      ],
    ),
  ],
  timerSeconds: 60,
  createdAt: DateTime.utc(2026),
);
