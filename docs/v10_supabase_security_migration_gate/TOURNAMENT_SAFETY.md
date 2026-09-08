# Tournament safety review

## Historical defect

The applied `20260831000200_tournaments_v1.sql` defines `save_tournament_bracket` that deletes `tournament_matches`, `tournament_players` and `tournament_teams`, then rebuilds teams/matches without restoring player identities. This is a concrete **CRITICAL historical risk**.

Pending `20260905000100_tournament_bracket_safety_v2.sql` mitigates it by revoking authenticated/public/anon execution of the destructive writer and legacy result writer, then publishing v2 functions.

## `save_tournament_bracket_v2`

- requires an active authenticated profile;
- rate limits organizer to 20 saves/hour;
- selects only an organizer-owned tournament and locks that row `FOR UPDATE`;
- validates arrays, capacity, UUIDs, approved state, cross-tournament ids, unique names/seeds, roster shape, complete approved-team inclusion, every first-round identity exactly once, positions, graph edges, bye propagation and match state;
- rejects confirmed/session-bound/live graph replacement;
- preserves existing team ownership/status and every existing player id/user/captain/team link;
- inserts roster rows only for genuinely new organizer teams;
- replaces only the unconfirmed match graph;
- makes exact pre-play network retry a no-op and rejects conflicting retry.

## `confirm_tournament_match_result_v2`

- active authenticated organizer only, 120/hour;
- tournament row, target match and dependent match are locked;
- rejects null/negative scores, foreign/missing winner, score/winner disagreement, unavailable match and started/occupied dependent slots;
- exact completed retry returns success without duplicate advancement/event;
- conflicting retry fails;
- match, advancement, final champion and audit event are one transaction.

## Other tournament RPCs

- `create_tournament`, `register_tournament_team`, `review_tournament_registration`, `undo_tournament_match_result`, and stats derive identity from `auth.uid`/`require_active_user` and enforce organizer/requester boundaries.
- Direct table writes are unavailable to ordinary authenticated users.
- The legacy undo function is not used by current Flutter. It remains organizer-scoped, but does not share the v2 tournament-first lock order. This is a **LOW residual concurrency/deadlock risk**, not observed corruption; review/version it before exposing an undo UI.

## Preservation evidence

`tournament_v2_behavior.mjs` executed exact v2 function bodies against the base tournament schema in PostgreSQL/WASM:

- 29/29 passed;
- outsider draw/confirm rejected;
- 11 malformed/partial/cross-state payloads rejected without losing the fixture captain;
- initial save preserved captain id, user id, captain flag, team id and existing team owner;
- repeated save produced no duplicate rows/events;
- live redraw conflict rejected;
- invalid results rejected;
- advancement/final completion occurred once;
- sparse brackets at 4/8/16/32/64 preserved teams.

This proves meaningful function-body behavior, but auth/rate helpers were stubbed and PGlite is not a substitute for Supabase JWT/RLS or real multi-connection PostgreSQL.

## Real concurrency status

**BLOCKED.** No local PostgreSQL/Supabase runtime is installed. Two simultaneous connections, stale transaction snapshots and lock-wait behavior were not executed. Static lock order serializes v2 mutations through the tournament row and prevents lost updates by design, but that is not reported as a real DB pass.

## Migration decision

Static + embedded result: positive. Staging classification: **BLOCKED** until real PostgreSQL preservation, authorization and concurrency cases pass. Production is not approved.
