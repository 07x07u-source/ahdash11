# Tournament Domain Model

## Aggregate

`Tournament` is the aggregate root: identity, organizer, name, status, visibility, immutable `TournamentRules`, teams, matches, timestamps, invite code, and champion.

`TournamentTeam` contains a stable ID, name, roster display names, seed, and approval state. A player name/user may belong to only one team in a tournament.

`TournamentMatch` contains round/position, two optional team slots, score, winner, state, next match/slot edge, Party session reference, and confirmation timestamp.

## State invariants

- Capacity is one of 4/8/16/32/64.
- Team count never exceeds capacity.
- Team names are unique inside a tournament.
- A winner must be team A or team B.
- A ready match has both teams.
- A completed result has a winner; a knockout tie needs explicit tiebreak resolution.
- A next edge always has a slot 0 or 1.
- Only a terminal feeder can populate a dependent match.
- Champion is the final match winner.

## Storage mapping

Cloud tables: `tournaments`, `tournament_teams`, `tournament_players`, `tournament_registrations`, `tournament_matches`, and append-only `tournament_events`. Composite foreign keys prevent teams from crossing tournament boundaries. Local storage uses the aggregate JSON snapshot; no Drift schema migration is required.

