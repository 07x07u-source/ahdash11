import 'package:ahdash_11/features/profile/domain/player_profile.dart';
import 'package:ahdash_11/features/social/domain/social_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('social hub parses a private team and bounded invite data', () {
    final hub = SocialHub.fromJson({
      'team': {
        'id': 'team-1',
        'name': 'ربع الخميس',
        'primary_color': '#18A276',
        'badge_seed': 'رخ',
        'role': 'owner',
        'member_count': 4,
        'active_challenges': 1,
      },
      'invites': const [],
    });

    expect(hub.team?.name, 'ربع الخميس');
    expect(hub.team?.role, 'owner');
    expect(hub.team?.activeChallenges, 1);
    expect(hub.invites, isEmpty);
  });

  test('team challenge availability uses server status and expiry', () {
    final challenge = SocialTeamChallenge.fromJson({
      'id': 'challenge-1',
      'title': 'تحدي الخميس',
      'question_count': 5,
      'status': 'active',
      'ends_at': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });

    expect(challenge.canPlay, isTrue);
    expect(challenge.questionCount, 5);
  });

  test('rich profile parses rights-aware football and team identity', () {
    final profile = PlayerProfile.fromJson({
      'id': 'player-1',
      'username': 'player11',
      'display_name': 'لاعب أحدعش',
      'favorite_league_data': {
        'id': 'league-1',
        'name_ar': 'دوري تجريبي',
        'primary_color': '#18A276',
        'visual_status': 'fallback',
      },
      'favorite_club_data': {
        'id': 'club-1',
        'name_ar': 'نادي تجريبي',
        'badge_text': '11',
        'primary_color': '#18A276',
        'visual_status': 'fallback',
        'logo_url': null,
      },
      'social_team': {
        'id': 'team-1',
        'name': 'ربع الخميس',
        'primary_color': '#18A276',
        'badge_seed': 'رخ',
        'role': 'member',
      },
      'achievements': const [],
    });

    expect(profile.publicName, 'لاعب أحدعش');
    expect(profile.favoriteClubData?.logoUrl, isNull);
    expect(profile.favoriteClubData?.visualStatus, 'fallback');
    expect(profile.socialTeam?.name, 'ربع الخميس');
  });
}
