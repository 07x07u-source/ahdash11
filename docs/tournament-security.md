# Tournament Security

## Authority

The server derives the actor from `auth.uid()` through `require_active_user()`. Client-supplied organizer IDs are never trusted. Security-definer functions pin `search_path` to `pg_catalog, public` and sensitive RPC grants are restricted to `authenticated`.

## Access

- Organizer: creates, locks bracket, confirms results, and performs safe undo.
- Participant: reads tournaments where their user ID is on a roster.
- Public viewer: reads only public tournaments.
- Moderator/admin: reads operational state; admin can cancel/reopen through RLS-protected Admin API.
- Service role: reserved for trusted backend operations.

RLS is enabled on every Tournament table. A security-definer `can_view_tournament` helper avoids recursive policies. Organizer mutations happen through validated RPCs rather than direct client writes.

## Integrity and abuse controls

Composite `(team_id, tournament_id)` references prevent cross-bracket winners. Unique constraints prevent duplicate seed, name, registration, and authenticated player membership. RPCs validate capacity, state transitions, scores, winner membership, dependency state, and JSON shapes. Creation, registration, bracket save, and result confirmation are rate-limited. `tournament_events` preserves sensitive transitions without destructive history edits.

Invite codes use cryptographic random bytes and are not authorization to mutate a bracket; they only locate an open registration. Public rosters should contain display names, not private contact data.

