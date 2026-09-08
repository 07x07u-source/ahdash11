Map<String, Object?> socialObjectMap(Object? value) =>
    value is Map<Object?, Object?>
    ? Map<String, Object?>.from(value)
    : const <String, Object?>{};

List<Map<String, Object?>> socialRows(Object? value) =>
    (value as List? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(Map<String, Object?>.from)
        .toList(growable: false);

final class SocialTeamSummary {
  const SocialTeamSummary({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.badgeSeed,
    required this.role,
    required this.memberCount,
    required this.activeChallenges,
  });

  factory SocialTeamSummary.fromJson(Map<String, Object?> json) =>
      SocialTeamSummary(
        id: '${json['id']}',
        name: '${json['name'] ?? 'فريقي'}',
        primaryColor: '${json['primary_color'] ?? '#B6FF3B'}',
        badgeSeed: '${json['badge_seed'] ?? '11'}',
        role: '${json['role'] ?? 'member'}',
        memberCount: (json['member_count'] as num?)?.round() ?? 0,
        activeChallenges: (json['active_challenges'] as num?)?.round() ?? 0,
      );

  final String id;
  final String name;
  final String primaryColor;
  final String badgeSeed;
  final String role;
  final int memberCount;
  final int activeChallenges;
}

final class SocialTeamInvite {
  const SocialTeamInvite({
    required this.inviteId,
    required this.teamId,
    required this.teamName,
    required this.primaryColor,
    required this.badgeSeed,
    required this.invitedByName,
  });

  factory SocialTeamInvite.fromJson(Map<String, Object?> json) =>
      SocialTeamInvite(
        inviteId: '${json['invite_id']}',
        teamId: '${json['team_id']}',
        teamName: '${json['team_name'] ?? 'الفريق'}',
        primaryColor: '${json['primary_color'] ?? '#B6FF3B'}',
        badgeSeed: '${json['badge_seed'] ?? '11'}',
        invitedByName: '${json['invited_by_name'] ?? 'لاعب 11'}',
      );

  final String inviteId;
  final String teamId;
  final String teamName;
  final String primaryColor;
  final String badgeSeed;
  final String invitedByName;
}

final class SocialHub {
  const SocialHub({required this.team, required this.invites});

  factory SocialHub.fromJson(Map<String, Object?> json) {
    final teamJson = socialObjectMap(json['team']);
    return SocialHub(
      team: teamJson.isEmpty ? null : SocialTeamSummary.fromJson(teamJson),
      invites: socialRows(
        json['invites'],
      ).map(SocialTeamInvite.fromJson).toList(growable: false),
    );
  }

  final SocialTeamSummary? team;
  final List<SocialTeamInvite> invites;
}

final class SocialTeamMember {
  const SocialTeamMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.level,
    required this.weeklyPoints,
    required this.rank,
    this.avatarUrl,
  });

  factory SocialTeamMember.fromJson(Map<String, Object?> json) =>
      SocialTeamMember(
        userId: '${json['user_id']}',
        displayName: '${json['display_name'] ?? 'لاعب 11'}',
        role: '${json['role'] ?? 'member'}',
        level: (json['level'] as num?)?.round() ?? 1,
        weeklyPoints: (json['weekly_points'] as num?)?.round() ?? 0,
        rank: (json['rank'] as num?)?.round() ?? 0,
        avatarUrl: json['avatar_url'] as String?,
      );

  final String userId;
  final String displayName;
  final String role;
  final int level;
  final int weeklyPoints;
  final int rank;
  final String? avatarUrl;
}

final class SocialTeamChallenge {
  const SocialTeamChallenge({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.status,
    required this.isOfficial,
    required this.attemptsUsed,
    required this.endsAt,
  });

  factory SocialTeamChallenge.fromJson(Map<String, Object?> json) =>
      SocialTeamChallenge(
        id: '${json['id']}',
        title: '${json['title'] ?? 'تحدي الفريق'}',
        questionCount: (json['question_count'] as num?)?.round() ?? 0,
        status: '${json['status'] ?? 'scheduled'}',
        isOfficial: json['is_official'] == true,
        attemptsUsed: (json['attempts_used'] as num?)?.round() ?? 0,
        endsAt: DateTime.tryParse('${json['ends_at']}'),
      );

  final String id;
  final String title;
  final int questionCount;
  final String status;
  final bool isOfficial;
  final int attemptsUsed;
  final DateTime? endsAt;

  bool get canPlay =>
      status == 'active' &&
      (endsAt == null || endsAt!.isAfter(DateTime.now().toUtc()));
}

final class SocialTeamActivity {
  const SocialTeamActivity({
    required this.id,
    required this.type,
    required this.actorName,
    required this.createdAt,
    required this.data,
  });

  factory SocialTeamActivity.fromJson(Map<String, Object?> json) =>
      SocialTeamActivity(
        id: '${json['id']}',
        type: '${json['type'] ?? ''}',
        actorName: '${json['actor_name'] ?? 'الفريق'}',
        createdAt: DateTime.tryParse('${json['created_at']}'),
        data: socialObjectMap(json['data']),
      );

  final String id;
  final String type;
  final String actorName;
  final DateTime? createdAt;
  final Map<String, Object?> data;
}

final class SocialTeamDetail {
  const SocialTeamDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.badgeSeed,
    required this.currentRole,
    required this.currentUserId,
    required this.members,
    required this.challenges,
    required this.activity,
    required this.weeklyMvp,
  });

  factory SocialTeamDetail.fromJson(Map<String, Object?> json) {
    final team = socialObjectMap(json['team']);
    final mvp = socialObjectMap(json['weekly_mvp']);
    return SocialTeamDetail(
      id: '${team['id']}',
      name: '${team['name'] ?? 'فريقي'}',
      description: team['description'] as String?,
      primaryColor: '${team['primary_color'] ?? '#B6FF3B'}',
      badgeSeed: '${team['badge_seed'] ?? '11'}',
      currentRole: '${team['current_role'] ?? 'member'}',
      currentUserId: '${team['current_user_id'] ?? ''}',
      members: socialRows(
        json['members'],
      ).map(SocialTeamMember.fromJson).toList(growable: false),
      challenges: socialRows(
        json['challenges'],
      ).map(SocialTeamChallenge.fromJson).toList(growable: false),
      activity: socialRows(
        json['activity'],
      ).map(SocialTeamActivity.fromJson).toList(growable: false),
      weeklyMvp: mvp.isEmpty
          ? null
          : SocialTeamMember.fromJson({
              ...mvp,
              'role': 'member',
              'level': 1,
              'rank': 1,
            }),
    );
  }

  final String id;
  final String name;
  final String? description;
  final String primaryColor;
  final String badgeSeed;
  final String currentRole;
  final String currentUserId;
  final List<SocialTeamMember> members;
  final List<SocialTeamChallenge> challenges;
  final List<SocialTeamActivity> activity;
  final SocialTeamMember? weeklyMvp;

  bool get canManage => currentRole == 'owner' || currentRole == 'admin';
}
