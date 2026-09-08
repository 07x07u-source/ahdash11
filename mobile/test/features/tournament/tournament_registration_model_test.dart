import 'package:ahdash_11/features/tournament/data/tournament_registration_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('available tournament parses registration limits and invite code', () {
    final tournament = AvailableTournament.fromJson({
      'id': 'tournament-1',
      'name': 'كأس الحارة',
      'capacity': 16,
      'players_per_team': 4,
      'invite_code': 'A11CUP26',
      'created_at': '2026-09-02T10:00:00Z',
    });

    expect(tournament.name, 'كأس الحارة');
    expect(tournament.capacity, 16);
    expect(tournament.playersPerTeam, 4);
    expect(tournament.inviteCode, 'A11CUP26');
  });

  test('registration request exposes a safe roster-name list', () {
    final request = TournamentRegistrationRequest.fromJson({
      'id': 'registration-1',
      'team_name': 'الصقور',
      'roster': [
        {'display_name': 'سلمان', 'is_captain': true},
        {'display_name': 'نواف', 'is_captain': false},
        {'display_name': '  '},
      ],
      'created_at': '2026-09-02T10:00:00Z',
    });

    expect(request.teamName, 'الصقور');
    expect(request.playerNames, ['سلمان', 'نواف']);
  });
}
