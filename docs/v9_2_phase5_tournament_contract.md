# Phase 5 tournament contract and safety audit

## Audit evidence

Inspected the bodies in `supabase/migrations/20260831000200_tournaments_v1.sql`, all Tournament models/controllers/repositories/routes, registration review, Party orchestration and table RLS/grants. The old `save_tournament_bracket(uuid,jsonb,jsonb)` explicitly deletes matches, players and teams; its replacement loop reinserts teams/matches but not the player roster. Calling it can lose player IDs, membership, captain/user association and valid registered-team identity. This is a concrete SQL-body risk, not an inference from a filename. A live remote `pg_get_functiondef` dump was not obtained; the linked dry-run lists this old migration as already present, but cannot prove the server has no manual drift.

## New migration (not deployed)

`20260905000100_tournament_bracket_safety_v2.sql` is additive. No applied migration was edited. There are no new product tables/columns.

- Revokes client execution of the destructive v1 save and weaker legacy result function. The client calls only versioned v2 functions and has no v1 fallback.
- Both new functions call the existing `require_active_user` and rate limiter, use fixed `search_path = pg_catalog, public`, lock the organizer-owned tournament row, and execute transactionally.
- Save validates JSON shape, capacities, IDs, approved membership, unique names/seeds, roster shape, every first-round team exactly once, no self-pairing, round positions, dependent IDs/slot parity, propagated bye winners and all pending/ready/bye states.
- Existing teams keep ownership and registration status; existing player rows are never updated or deleted. Only name/seed bracket metadata is upserted for approved existing teams. New manually entered teams get newly inserted player rows.
- Missing approved registrations and cross-tournament IDs are rejected. A rejected/pending team cannot be silently promoted by draw.
- Matches may be replaced only in draft/registration/ready, with no confirmed/playing/session-bound rows. Live/completed exact pre-play replay is a no-op; any conflict is rejected. Retrying an old draw after results exist is rejected and requires refresh, not redraw.
- Confirmation rejects null/negative scores, a missing/foreign winner, winner-score disagreement, unfinished participants, locked dependents and occupied advancement slots. Exact completed-result replay returns success without another event or advancement; conflicting replay is rejected.
- Final confirmation updates the match, champion and tournament completion in one transaction. Existing host-judged/manual result authority is retained; no claim of cryptographically verified Party scores is made.

## Validation boundary

Parser validation checks all migrations/PLpgSQL bodies. The pgTAP file `007_tournament_bracket_safety_v2_security.sql` contains 21 structural/grant checks and is **not run against a Supabase instance** in this environment.

`tournament_v2_behavior.mjs` executes the exact patch bodies against the original tournament table definitions in ephemeral PostgreSQL/WASM. It stubs only the profile authentication helper/rate limiter and the citext domain. It checks roster preservation, bad payload rollback, outsider rejection, immutable live graph, duplicate result, advancement/final completion, and sparse brackets at 4/8/16/32/64 capacity. It does **not** certify JWT/RLS integration, rate limits or concurrent connections. Its isolated dependency is in `.codex-temp/phase5-sql`, not the Flutter application.

`npx supabase db lint --local` could not connect to `127.0.0.1:54322`; no local Supabase/PostgreSQL service is running. `npx supabase db push --dry-run` succeeded and listed **two pending migrations**: pre-existing `20260902000100_gameplay_depth_v1.sql` and this patch. Neither was applied. Do not deploy both blindly; the owner must review the earlier migration too.

Production draw/result writes are release-gated by deployment of the tested v2 RPCs and full Supabase security validation. Until then the application fails closed with safe Arabic errors. No remote push, emulator or APK build was performed.
