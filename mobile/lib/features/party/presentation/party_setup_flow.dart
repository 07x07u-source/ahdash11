import '../domain/party_game.dart';
import 'party_game_controller.dart';

enum PartySetupStep { categories, teams, splitter, helpers, ready }

enum PartyGameplayStep { board, question, reveal, result }

extension PartySetupStepRoute on PartySetupStep {
  String get route => switch (this) {
    PartySetupStep.categories => '/party/categories',
    PartySetupStep.teams => '/party/teams',
    PartySetupStep.splitter => '/party/splitter',
    PartySetupStep.helpers => '/party/helpers',
    PartySetupStep.ready => '/party/ready',
  };
}

extension PartyGameplayStepRoute on PartyGameplayStep {
  String get route => switch (this) {
    PartyGameplayStep.board => '/party/board',
    PartyGameplayStep.question => '/party/question',
    PartyGameplayStep.reveal => '/party/reveal',
    PartyGameplayStep.result => '/party/result',
  };
}

/// The only authority for resolving a saved or deep-linked Party setup.
abstract final class PartySetupFlowResolver {
  static String routeForSession(PartyGameSession session) {
    if (session.isComplete) return PartyGameplayStep.result.route;
    if (session.activeQuestionId == null) return PartyGameplayStep.board.route;
    return session.revealed
        ? PartyGameplayStep.reveal.route
        : PartyGameplayStep.question.route;
  }

  static String canonicalRoute(
    PartyGameState state, {
    Set<PartyHelperId>? activeHelperIds,
    Set<String>? playableCategoryIds,
  }) {
    final session = state.session;
    if (!state.hasSetupDraft && session != null) {
      return routeForSession(session);
    }
    if (!_categoriesComplete(state.selectedCategoryIds)) {
      return PartySetupStep.categories.route;
    }
    if (playableCategoryIds != null &&
        !playableCategoryIds.containsAll(state.selectedCategoryIds)) {
      return PartySetupStep.categories.route;
    }
    if (!state.teamSetupCompleted ||
        state.splitterStatus == PartySplitterStatus.notRequested ||
        PartySetupValidation.teamError(state.teams) != null) {
      return PartySetupStep.teams.route;
    }
    if (state.splitterStatus == PartySplitterStatus.requested) {
      return PartySetupStep.splitter.route;
    }
    final helpers = activeHelperIds ?? PartyHelperId.values.toSet();
    if (!_helpersComplete(state.teams, helpers)) {
      return PartySetupStep.helpers.route;
    }
    return PartySetupStep.ready.route;
  }

  /// Earlier completed screens remain reviewable through Back. A deep link
  /// may never jump past the earliest incomplete screen.
  static String? redirectFor(
    PartySetupStep requested,
    PartyGameState state, {
    Set<PartyHelperId>? activeHelperIds,
    Set<String>? playableCategoryIds,
    bool allowReview = false,
  }) {
    final canonical = canonicalRoute(
      state,
      activeHelperIds: activeHelperIds,
      playableCategoryIds: playableCategoryIds,
    );
    if (!canonical.startsWith('/party/') ||
        !PartySetupStep.values.any((step) => step.route == canonical)) {
      return canonical;
    }
    final canonicalStep = PartySetupStep.values.firstWhere(
      (step) => step.route == canonical,
    );
    if (requested == canonicalStep) return null;
    if (allowReview && requested.index < canonicalStep.index) return null;
    return canonical;
  }

  static String? redirectGameplay(
    PartyGameplayStep requested,
    PartyGameState state, {
    Set<PartyHelperId>? activeHelperIds,
    Set<String>? playableCategoryIds,
  }) {
    final canonical = canonicalRoute(
      state,
      activeHelperIds: activeHelperIds,
      playableCategoryIds: playableCategoryIds,
    );
    return canonical == requested.route ? null : canonical;
  }

  static bool _categoriesComplete(List<String> ids) =>
      ids.length == PartyGameRules.categoriesPerGame &&
      ids.toSet().length == PartyGameRules.categoriesPerGame;

  static bool _helpersComplete(
    List<PartyTeam> teams,
    Set<PartyHelperId> activeHelperIds,
  ) =>
      teams.length == 2 &&
      teams.every(
        (team) =>
            team.selectedHelpers.length == PartyGameRules.helpersPerTeam &&
            activeHelperIds.containsAll(team.selectedHelpers),
      );
}
