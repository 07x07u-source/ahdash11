import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../auth/data/supabase_user_mapper.dart';
import '../domain/social_entities.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  final configured = ref.watch(appConfigProvider).hasSupabase;
  return SocialRepository(configured ? Supabase.instance.client : null);
});

final socialHubProvider = FutureProvider<SocialHub>((ref) {
  return ref.watch(socialRepositoryProvider).loadHub();
});

final friendsDashboardProvider = FutureProvider<Map<String, Object?>>((ref) {
  return ref.watch(socialRepositoryProvider).loadFriendDashboard();
});

final socialTeamDetailProvider =
    FutureProvider.family<SocialTeamDetail, String>(
      (ref, teamId) => ref.watch(socialRepositoryProvider).loadTeam(teamId),
    );

class SocialRepository {
  const SocialRepository(this._client);

  final SupabaseClient? _client;

  bool get isAvailable => _client != null;

  SupabaseClient get _requiredClient {
    final client = _client;
    if (client == null ||
        !supabaseCapabilities(client.auth.currentUser).hasAccount) {
      throw StateError('Account required');
    }
    return client;
  }

  Future<SocialHub> loadHub() async {
    if (_client == null) return const SocialHub(team: null, invites: []);
    final data = await _requiredClient.rpc<Object?>('get_social_hub');
    return SocialHub.fromJson(socialObjectMap(data));
  }

  Future<SocialTeamDetail> loadTeam(String teamId) async {
    final data = await _requiredClient.rpc<Object?>(
      'get_social_team_detail',
      params: {'p_team_id': teamId},
    );
    return SocialTeamDetail.fromJson(socialObjectMap(data));
  }

  Future<Map<String, Object?>> loadFriendDashboard() async {
    if (_client == null) {
      return const {'friends': [], 'inbox': [], 'outbox': []};
    }
    final data = await _requiredClient.rpc<Object?>('get_friend_dashboard');
    return socialObjectMap(data);
  }

  Future<List<Map<String, Object?>>> searchPlayers(String query) async {
    final data = await _requiredClient.rpc<Object?>(
      'search_players',
      params: {'p_query': query.trim(), 'p_limit': 20},
    );
    return socialRows(data);
  }

  Future<void> sendFriendRequest(String userId) async {
    await _requiredClient.rpc<Object?>(
      'send_friend_request',
      params: {'p_receiver_id': userId, 'p_message': null},
    );
  }

  Future<void> respondFriendRequest(
    String requestId, {
    required bool accept,
  }) async {
    await _requiredClient.rpc<Object?>(
      'respond_friend_request',
      params: {'p_request_id': requestId, 'p_accept': accept},
    );
  }

  Future<void> removeFriend(String userId) async {
    await _requiredClient.rpc<Object?>(
      'remove_friend',
      params: {'p_friend_user_id': userId},
    );
  }

  Future<Map<String, Object?>> createTeam({
    required String name,
    String? description,
    String primaryColor = '#B6FF3B',
    String bannerStyle = 'najdi_lines',
  }) async {
    final data = await _requiredClient.rpc<Object?>(
      'create_social_team',
      params: {
        'p_name': name.trim(),
        'p_description': description?.trim(),
        'p_primary_color': primaryColor,
        'p_banner_style': bannerStyle,
      },
    );
    return socialObjectMap(data);
  }

  Future<Map<String, Object?>> joinTeam(String code) async {
    final data = await _requiredClient.rpc<Object?>(
      'join_social_team',
      params: {'p_invite_code': code.trim()},
    );
    return socialObjectMap(data);
  }

  Future<void> respondInvite(String inviteId, {required bool accept}) async {
    await _requiredClient.rpc<Object?>(
      'respond_social_team_invite',
      params: {'p_invite_id': inviteId, 'p_accept': accept},
    );
  }

  Future<void> inviteFriend(String teamId, String userId) async {
    await _requiredClient.rpc<Object?>(
      'invite_friend_to_social_team',
      params: {'p_team_id': teamId, 'p_friend_user_id': userId},
    );
  }

  Future<String> rotateInviteCode(String teamId) async {
    final data = await _requiredClient.rpc<Object?>(
      'rotate_social_team_code',
      params: {'p_team_id': teamId},
    );
    return '$data';
  }

  Future<void> removeTeamMember(String teamId, String userId) async {
    await _requiredClient.rpc<Object?>(
      'remove_social_team_member',
      params: {'p_team_id': teamId, 'p_user_id': userId},
    );
  }

  Future<void> setTeamMemberRole(
    String teamId,
    String userId,
    String role,
  ) async {
    await _requiredClient.rpc<Object?>(
      'set_social_team_member_role',
      params: {'p_team_id': teamId, 'p_user_id': userId, 'p_role': role},
    );
  }

  Future<void> blockPlayer(String userId) async {
    await _requiredClient.rpc<Object?>(
      'block_player',
      params: {'p_blocked_user_id': userId},
    );
  }

  Future<List<Map<String, Object?>>> loadBlockedPlayers() async {
    final data = await _requiredClient.rpc<Object?>('get_blocked_players');
    return socialRows(data);
  }

  Future<void> unblockPlayer(String userId) async {
    await _requiredClient.rpc<Object?>(
      'unblock_player',
      params: {'p_blocked_user_id': userId},
    );
  }

  Future<void> reportPlayer({
    required String userId,
    required String reason,
  }) async {
    await _requiredClient.rpc<Object?>(
      'report_social_subject',
      params: {
        'p_subject_type': 'user',
        'p_subject_id': userId,
        'p_reason': reason,
        'p_details': null,
      },
    );
  }

  Future<Map<String, Object?>> createChallenge({
    required String teamId,
    required String title,
  }) async {
    final now = DateTime.now().toUtc();
    final data = await _requiredClient.rpc<Object?>(
      'create_team_challenge',
      params: {
        'p_team_id': teamId,
        'p_title': title.trim(),
        'p_category_id': null,
        'p_question_count': 5,
        'p_starts_at': now.toIso8601String(),
        'p_ends_at': now.add(const Duration(days: 7)).toIso8601String(),
        'p_max_attempts': 1,
        'p_artwork_key': 'thursday_challenge',
      },
    );
    return socialObjectMap(data);
  }

  Future<Map<String, Object?>> startChallenge(String challengeId) async {
    final data = await _requiredClient.rpc<Object?>(
      'start_team_challenge_attempt',
      params: {'p_challenge_id': challengeId},
    );
    return socialObjectMap(data);
  }

  Future<Map<String, Object?>> getChallengeQuestion(String attemptId) async {
    final data = await _requiredClient.rpc<Object?>(
      'get_team_challenge_question',
      params: {'p_attempt_id': attemptId},
    );
    return socialObjectMap(data);
  }

  Future<Map<String, Object?>> submitChallengeAnswer({
    required String attemptId,
    String? optionId,
    required String idempotencyKey,
    required int clientSequence,
  }) async {
    try {
      final data = await _requiredClient.rpc<Object?>(
        'submit_team_challenge_answer_v2',
        params: {
          'p_attempt_id': attemptId,
          'p_option_id': optionId,
          'p_idempotency_key': idempotencyKey,
          'p_client_sequence': clientSequence,
        },
      );
      return socialObjectMap(data);
    } on PostgrestException catch (error) {
      final missingV2 =
          error.code == 'PGRST202' ||
          error.message.contains('submit_team_challenge_answer_v2');
      if (!missingV2) rethrow;
      final data = await _requiredClient.rpc<Object?>(
        'submit_team_challenge_answer',
        params: {'p_attempt_id': attemptId, 'p_option_id': optionId},
      );
      return socialObjectMap(data);
    }
  }

  Future<Map<String, Object?>> getChallengeResult(String attemptId) async {
    final data = await _requiredClient.rpc<Object?>(
      'get_team_challenge_result',
      params: {'p_attempt_id': attemptId},
    );
    return socialObjectMap(data);
  }
}
