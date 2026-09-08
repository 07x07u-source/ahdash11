import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/domain/party_rule_engines.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/v10_feature_fixtures.dart';

void main() {
  const helpEngine = PartyHelpEngine();
  const scoreEngine = PartyScoreEngine();

  for (final helper in PartyHelperId.values) {
    test('${helper.storageId} has available, active and consumed fixtures', () {
      final base = _available(helper);
      expect(helpEngine.canUse(base, helper), isTrue);

      final active = base.copyWith(
        armedHelper: helper,
        teams: [
          base.teams.first.copyWith(usedHelpers: {helper}),
          base.teams.last,
        ],
      );
      expect(active.armedHelper, helper);
      expect(active.teams.first.usedHelpers, contains(helper));
      expect(helpEngine.canUse(active, helper), isFalse);

      final restored = PartyGameSession.fromJson(active.toJson());
      expect(restored.armedHelper, helper);
      expect(restored.teams.first.usedHelpers, contains(helper));
      expect(helpEngine.canUse(restored, helper), isFalse);
    });
  }

  test('two chances remains a host-moderated two-answer allowance', () {
    final session = _available(PartyHelperId.twoChances);
    final active = session.copyWith(armedHelper: PartyHelperId.twoChances);
    expect(
      active.helperDefinition(PartyHelperId.twoChances).description,
      contains('إجابتين'),
    );
    expect(active.activeQuestion, isNotNull);
    expect(active.revealed, isFalse);
  });

  test('call friend owns a deterministic timer and consumes once', () {
    final session = _available(PartyHelperId.callFriend);
    final definition = session.helperDefinition(PartyHelperId.callFriend);
    expect(definition.callFriendSeconds, 20);
    final active = session.copyWith(
      armedHelper: PartyHelperId.callFriend,
      questionTimerStartedAt: V10FeatureFixtures.fixedNow,
      questionTimerDurationSeconds: definition.callFriendSeconds,
    );
    expect(active.questionTimerDurationSeconds, 20);
    expect(
      V10FeatureFixtures.fixedNow.add(
        Duration(seconds: active.questionTimerDurationSeconds!),
      ),
      DateTime.utc(2026, 9, 7, 12, 0, 20),
    );
  });

  test('risk success and failure use the snapshotted score contract', () {
    final active = _withActiveQuestion(
      _available(PartyHelperId.risk),
    ).copyWith(armedHelper: PartyHelperId.risk);
    final points = active.activeQuestion!.pointValue;
    expect(scoreEngine.deltas(active, 0), [points, -points]);
    expect(scoreEngine.deltas(active, null), [0, 0]);
  });

  test('bench needs a real opposing player and preserves selection', () {
    final available = _available(PartyHelperId.bench);
    expect(helpEngine.canUse(available, PartyHelperId.bench), isTrue);
    expect(
      available.copyWith(helperActionDetail: 'نواف').helperActionDetail,
      'نواف',
    );
    final noOpponent = available.copyWith(
      teams: [
        available.teams.first,
        available.teams.last.copyWith(players: []),
      ],
    );
    expect(helpEngine.canUse(noOpponent, PartyHelperId.bench), isFalse);
  });

  test('pass transfers answer ownership and applies the configured result', () {
    final active = _available(
      PartyHelperId.pass,
    ).copyWith(armedHelper: PartyHelperId.pass, answeringTeamIndex: 1);
    final points = active.activeQuestion!.pointValue;
    expect(active.answeringTeamIndex, 1);
    expect(scoreEngine.deltas(active, 1), [0, points]);
    expect(scoreEngine.deltas(active, null), [0, -points]);
  });

  test('a helper cannot be consumed by the team that does not own it', () {
    final session = _available(PartyHelperId.risk).copyWith(turnTeamIndex: 1);
    expect(helpEngine.canUse(session, PartyHelperId.risk), isFalse);
  });
}

PartyGameSession _available(PartyHelperId helper) {
  final needsQuestion =
      helper.defaultDefinition.timing == PartyHelperTiming.afterQuestion;
  final base = phase4BoardSession.copyWith(
    teams: [
      phase4Teams.first.copyWith(
        selectedHelpers: {helper},
        usedHelpers: const {},
      ),
      phase4Teams.last.copyWith(
        selectedHelpers: const {},
        usedHelpers: const {},
      ),
    ],
    clearArmedHelper: true,
    clearHelperActionDetail: true,
    activeQuestionId: needsQuestion ? 'question-0-2' : null,
    clearActiveQuestion: !needsQuestion,
    answeringTeamIndex: 0,
    turnTeamIndex: 0,
    revealed: false,
  );
  return base;
}

PartyGameSession _withActiveQuestion(PartyGameSession session) =>
    session.copyWith(activeQuestionId: 'question-0-2');
