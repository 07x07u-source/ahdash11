// Deterministic test fake. Production code must never import this file.
import 'dart:async';

import 'package:ahdash_11/features/social/data/social_repository.dart';

final class FakeSocialRepository extends SocialRepository {
  FakeSocialRepository({
    this.dashboard = const {'friends': [], 'inbox': [], 'outbox': []},
    this.searchResults = const [],
    this.blockedPlayers = const [],
    this.challengeQuestion,
    this.challengeFeedback,
    this.challengeResult,
    this.inviteCode = 'AHDASH-11',
  }) : super(null);

  Map<String, Object?> dashboard;
  List<Map<String, Object?>> searchResults;
  List<Map<String, Object?>> blockedPlayers;
  Map<String, Object?>? challengeQuestion;
  Map<String, Object?>? challengeFeedback;
  Map<String, Object?>? challengeResult;
  String inviteCode;
  Object? dashboardError;
  Object? searchError;
  Object? sendError;
  Object? blockError;
  Object? unblockError;
  Object? blockedLoadError;
  Object? rotateInviteCodeError;
  Object? removeTeamMemberError;
  Completer<void>? searchGate;
  Future<List<Map<String, Object?>>> Function(String query)? searchHandler;
  Completer<void>? sendGate;
  Completer<void>? blockGate;
  Completer<void>? unblockGate;
  Completer<void>? rotateInviteCodeGate;
  Completer<void>? removeTeamMemberGate;
  int dashboardLoads = 0;
  int searches = 0;
  int sends = 0;
  int blocks = 0;
  int unblocks = 0;
  int blockedLoads = 0;
  int inviteCodeRotations = 0;
  int teamMemberRemovals = 0;
  int responses = 0;
  int removals = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<Map<String, Object?>> loadFriendDashboard() async {
    dashboardLoads++;
    if (dashboardError case final error?) throw error;
    return dashboard;
  }

  @override
  Future<List<Map<String, Object?>>> searchPlayers(String query) async {
    searches++;
    if (searchHandler case final handler?) return handler(query);
    if (searchError case final error?) throw error;
    await searchGate?.future;
    return searchResults;
  }

  @override
  Future<void> sendFriendRequest(String userId) async {
    sends++;
    if (sendError case final error?) throw error;
    await sendGate?.future;
  }

  @override
  Future<void> respondFriendRequest(
    String requestId, {
    required bool accept,
  }) async {
    responses++;
  }

  @override
  Future<void> removeFriend(String userId) async {
    removals++;
  }

  @override
  Future<void> blockPlayer(String userId) async {
    blocks++;
    if (blockError case final error?) throw error;
    await blockGate?.future;
    dashboard = const {'friends': [], 'inbox': [], 'outbox': []};
  }

  @override
  Future<List<Map<String, Object?>>> loadBlockedPlayers() async {
    blockedLoads++;
    if (blockedLoadError case final error?) throw error;
    return blockedPlayers;
  }

  @override
  Future<void> unblockPlayer(String userId) async {
    unblocks++;
    if (unblockError case final error?) throw error;
    await unblockGate?.future;
    blockedPlayers = blockedPlayers
        .where((row) => row['user_id'] != userId)
        .toList(growable: false);
  }

  @override
  Future<String> rotateInviteCode(String teamId) async {
    inviteCodeRotations++;
    if (rotateInviteCodeError case final error?) throw error;
    await rotateInviteCodeGate?.future;
    return inviteCode;
  }

  @override
  Future<void> removeTeamMember(String teamId, String userId) async {
    teamMemberRemovals++;
    if (removeTeamMemberError case final error?) throw error;
    await removeTeamMemberGate?.future;
  }

  @override
  Future<Map<String, Object?>> startChallenge(String challengeId) async {
    if (challengeQuestion == null) throw StateError('Challenge unavailable');
    return {'attempt_id': 'challenge-attempt-fixture'};
  }

  @override
  Future<Map<String, Object?>> getChallengeQuestion(String attemptId) async {
    final question = challengeQuestion;
    if (question == null) throw StateError('Challenge unavailable');
    return question;
  }

  @override
  Future<Map<String, Object?>> submitChallengeAnswer({
    required String attemptId,
    String? optionId,
    required String idempotencyKey,
    required int clientSequence,
  }) async {
    return challengeFeedback ??
        {
          'correct': optionId == 'option-1',
          'score_awarded': optionId == 'option-1' ? 138 : 0,
          'total_score': optionId == 'option-1' ? 458 : 320,
          'correct_option_id': 'option-1',
          'completed': true,
        };
  }

  @override
  Future<Map<String, Object?>> getChallengeResult(String attemptId) async {
    final result = challengeResult;
    if (result == null) throw StateError('Challenge result unavailable');
    return result;
  }
}

const teamChallengeQuestionFixture = <String, Object?>{
  'question_id': 'challenge-question-fixture',
  'challenge_title': 'تحدي ليلة الكورة',
  'question_count': 5,
  'sequence': 2,
  'duration_ms': 20000,
  'question_text': 'أي نادٍ حقق أكبر عدد من ألقاب دوري أبطال أوروبا؟',
  'score': 320,
  'options': <Object?>[
    <String, Object?>{'id': 'option-1', 'text': 'ريال مدريد'},
    <String, Object?>{'id': 'option-2', 'text': 'ميلان'},
    <String, Object?>{'id': 'option-3', 'text': 'ليفربول'},
    <String, Object?>{'id': 'option-4', 'text': 'بايرن ميونخ'},
  ],
};

const teamChallengeResultFixture = <String, Object?>{
  'score': 658,
  'rank': 2,
  'correct_answers': 4,
  'wrong_answers': 1,
  'gap_to_next': 42,
  'leaderboard': <Object?>[
    <String, Object?>{'rank': 1, 'display_name': 'نواف العتيبي', 'score': 700},
    <String, Object?>{'rank': 2, 'display_name': 'سلمان الحربي', 'score': 658},
    <String, Object?>{'rank': 3, 'display_name': 'خالد منصور', 'score': 590},
    <String, Object?>{'rank': 4, 'display_name': 'فيصل الزهراني', 'score': 540},
  ],
};
