# Ahdash Tournament V1 Specification

## Lifecycle

`draft → registration (optional) → live → completed`, with `cancelled` available for administrative intervention. Rules and categories are snapshotted before live play.

## Creation

The organizer names the tournament, selects 4/8/16/32/64 capacity, 1–8 players per team, private/invite/public visibility, and draw/manual seeding. At least two approved teams are required to lock a bracket.

## Bracket

- Standard seed placement distributes high seeds and BYEs.
- Every round and next-match edge is created before play.
- Empty first-round branches settle as BYEs; a later match waits until both feeders settle.
- A match becomes ready only when both teams are known.
- A winner advances only after explicit result confirmation.
- The final winner completes the tournament and becomes champion.

## Match play

A ready match can launch Party with team names/rosters or accept an external manual score. Negative scores and non-participant winners are rejected. Equal scores require an explicit tiebreak winner. The local and cloud models record Party session ID when present.

## Undo

An organizer may undo a confirmed result only while the dependent next match is pending/ready. Undo is rejected after the dependent match becomes live or completed. The advance slot and champion are cleared atomically.

## Resume and history

The full tournament, teams, matches, rules, and timestamps serialize into Drift `local_settings`. Home exposes one active-tournament resume action. Completed snapshots are retained in local history and cloud event history.

