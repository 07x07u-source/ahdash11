import 'package:ahdash_11/features/football/domain/football_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('private football preferences preserve owner ids for later editing', () {
    final value = FootballPreferences.fromJson({
      'league_id': 'league-1',
      'club_id': 'club-1',
      'show_publicly': false,
    });

    expect(value.leagueId, 'league-1');
    expect(value.clubId, 'club-1');
    expect(value.showPublicly, isFalse);
  });

  test(
    'missing visibility defaults to public without inventing selections',
    () {
      final value = FootballPreferences.fromJson(const {});

      expect(value.leagueId, isNull);
      expect(value.clubId, isNull);
      expect(value.showPublicly, isTrue);
    },
  );
}
