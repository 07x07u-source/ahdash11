import 'party_game.dart';

final class PartyHelpEngine {
  const PartyHelpEngine();

  bool canUse(PartyGameSession session, PartyHelperId helper) {
    if (session.armedHelper != null) return false;
    final teamIndex = session.turnTeamIndex;
    final team = session.teams[teamIndex];
    final correctTiming =
        session.helperDefinition(helper).timing ==
            PartyHelperTiming.beforeQuestion
        ? session.activeQuestionId == null
        : session.activeQuestionId != null && !session.revealed;
    if (!correctTiming ||
        !team.selectedHelpers.contains(helper) ||
        team.usedHelpers.contains(helper)) {
      return false;
    }
    return helper != PartyHelperId.bench ||
        session.teams[1 - teamIndex].players.isNotEmpty;
  }
}

final class PartyScoreEngine {
  const PartyScoreEngine();

  List<int> deltas(PartyGameSession session, int? awardedTeamIndex) {
    final question = session.activeQuestion;
    if (question == null) return const [0, 0];
    final result = [0, 0];
    if (awardedTeamIndex != null &&
        awardedTeamIndex >= 0 &&
        awardedTeamIndex <= 1) {
      result[awardedTeamIndex] += question.pointValue;
    } else if (!session.stealActive &&
        session.armedHelper != PartyHelperId.pass) {
      result[session.turnTeamIndex] += session.ruleConfig.incorrectPenalty;
    }
    if (session.stealActive) {
      if (awardedTeamIndex == session.answeringTeamIndex) {
        result[session.answeringTeamIndex] +=
            question.pointValue *
            (session.ruleConfig.stealRewardMultiplier - 1);
      } else if (awardedTeamIndex == null) {
        result[session.answeringTeamIndex] +=
            question.pointValue *
            session.ruleConfig.stealWrongPenaltyMultiplier;
      }
    }
    if (session.armedHelper == PartyHelperId.risk) {
      final definition = session.helperDefinition(PartyHelperId.risk);
      if (awardedTeamIndex == session.turnTeamIndex) {
        result[1 - session.turnTeamIndex] +=
            question.pointValue *
            -(definition.correctMultiplier ??
                    session.ruleConfig.pitOpponentPenaltyMultiplier.abs())
                .abs();
      } else if (awardedTeamIndex == null) {
        result[session.turnTeamIndex] +=
            question.pointValue *
            (definition.wrongMultiplier ?? session.ruleConfig.incorrectPenalty);
      }
    }
    if (session.armedHelper == PartyHelperId.pass) {
      if (awardedTeamIndex == session.answeringTeamIndex) {
        result[session.answeringTeamIndex] +=
            question.pointValue *
            (session.ruleConfig.trapCorrectRewardMultiplier - 1);
      } else if (awardedTeamIndex == null) {
        result[session.answeringTeamIndex] +=
            question.pointValue * session.ruleConfig.trapWrongPenaltyMultiplier;
      }
    }
    return result;
  }
}
