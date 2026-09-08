# V9.2 Phase 5 — Tournament flow

The existing `TournamentEngine` remains the only bracket/advancement engine. `TournamentFlowResolver` owns canonical routes, deterministic current match/round, confirmed champion eligibility and the Party confirmation boundary.

| Real state | Canonical action |
|---|---|
| None / cancelled | Hub |
| Draft / registration, fewer than two approved teams | Teams |
| Draft / registration / ready with eligible teams and no graph | Draw |
| Live graph | Bracket; selected ready/live match opens Match |
| Same tournament Party draft/session | Resume its existing setup/board/question/reveal/result route |
| Matching completed non-tied Party session | Tournament Match, review and confirm |
| Completed final, real confirmed winner and champion identity | Champion |
| Incomplete/corrupt completed snapshot | Read-only Bracket, never invent a champion |

Semifinal and Final are selected rounds of `/tournaments/bracket`. No routes 24/25 were added. Explicit completed Bracket and Match routes remain reviewable. Unknown match links attempt a read-only RLS-scoped lookup of the owning tournament before canonical resolution.

## Persistence and authority

- Drift settings retain the existing cache architecture. Wizard values, step and UUID are persisted separately from the active tournament. A failed/uncertain creation reuses the persisted candidate UUID and rules.
- The draw candidate is persisted before RPC. A retry after reconstruction reuses every team/match ID, seed, edge and slot. Team edits are blocked while this result is uncertain.
- Approved registration rows are hydrated by their server IDs, including original roster/user/captain metadata. Accepting a registration no longer creates a second local team with the same display name.
- Manual teams are explicitly labelled as local staged entries until the safe draw transaction saves them. They are not represented as remotely committed roster rows before that point.
- Party sessions carry `tournament_id`, `match_id`, `team_a_id`, `team_b_id`, fixed categories and tiebreaker rules. `session.id` stays unchanged through play, restore and result confirmation. Standalone Party sessions have no tournament context.
- Result submission requires a complete, non-tied, matching session and matching scores. A new/different Party session cannot confirm a selected tournament match. The organizer can explicitly enter a non-tied external result through the separate manual flow.
- Production/staging never turn a missing auth/configuration or failed RPC into local success. Development without Supabase remains explicitly local. Server result/draw errors preserve the pre-commit tournament snapshot.

## Deliberate compatibility limits

The existing Party setup requires six categories and helper selection. Imported tournament rules disabling helpers, or fixing a non-six category set, are blocked from Party launch with an Arabic explanation; organizer-entered external results remain available. No alternative game engine was invented. Server undo is not exposed by this client. Other tournaments cannot replace an unfinished Party session silently.

The cache is not a realtime multi-device subscription. Refresh hydrates server state; uncertain offline snapshots are identified as cached. The RPC remains the authority on locks, ownership and acceptance.
