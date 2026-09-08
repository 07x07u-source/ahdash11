# AHDASH 11 V9.2 — Party setup and gameplay flow

## Canonical order

`Categories → Teams → optional Splitter → Helpers → Ready → Board → Question → Reveal → Score → Board/Result`

`PartySetupFlowResolver` in `mobile/lib/features/party/presentation/party_setup_flow.dart` is the single route authority for Party setup and gameplay. Widgets request controller actions and render resulting state; they do not independently decide whether a step, score, or completion is valid.

## Resolution rules

1. An active saved session is resumed through `routeForSession` when there is no newer setup draft.
2. A new setup draft takes precedence over the older active session without deleting it.
3. Anything other than exactly six unique selected category IDs resolves to `/party/categories`.
4. If the real catalog/entitlement check says a selected category is no longer playable, resolution returns to `/party/categories`.
5. Invalid or unfinished team setup resolves to `/party/teams`.
6. A specifically requested but unfinished player split resolves to `/party/splitter`.
7. Missing, inactive, or non-three-per-team helper selections resolve to `/party/helpers`.
8. A valid unstarted draft resolves to `/party/ready`.
9. A session with no open question resolves to `/party/board`.
10. An open unrevealed question resolves to `/party/question`.
11. A revealed question awaiting its score decision resolves to `/party/reveal`.
12. An authoritatively completed session resolves to `/party/result`.

Back navigation adds `review=1` only for an already completed earlier step. This preserves intentional review/editing while a direct or stale deep link still resolves to the earliest real incomplete step and avoids redirect loops.

## Local draft compatibility

Setup progress is stored under `party_setup_draft_v2` in the existing Drift settings table. The payload contains version `2`, selected category IDs, the two existing `PartyTeam` JSON snapshots, timer, team-completion flag, splitter status, and entered players.

This is a versioned value in an existing key/value store, not a database schema migration. Corrupt, absent, or unsupported payloads are ignored safely. The existing `party_active_game_v1`, history, favorites, server sessions, and `PartyGameSession` serialization remain unchanged. Start waits for queued draft writes, then atomically persists the replacement session/history and clears the setup draft. A failed start leaves the complete draft available for retry.

## Optional splitter

The splitter runs only when explicitly requested from Team Setup. Skip marks the step as skipped and continues. Splitting requires at least two unique non-empty entered names, uses injectable seeded randomness in tests, assigns each player exactly once, and keeps team sizes within one player. Manual moves preserve the same uniqueness/non-empty-team contract.

## Ready and Start

`PartySetupValidation.readyError` is shared by Ready and `PartyGameController.start`. It verifies:

- a real setup draft exists;
- exactly six unique selected categories are still playable;
- both team names pass the existing validation;
- Team Setup is complete;
- a requested split is not left unfinished;
- each team has exactly three active helpers;
- `bench`/`استريح` is not selected without at least one opponent player.

Start is guarded by `busy`, rejects rapid duplicate submission, uses the existing question-pack/repository/session engine, keeps the draft and displays a safe retry message on failure, and routes to the real Board on success.

## Resume entry points

Home, Play/Game Setup, Party Games, How To Play, rematch/new-game actions, category group entry, and Party-backed tournament setup enter through the canonical resolver. Home shows setup-resume when a draft exists; otherwise an existing session resumes at Board, Question, Reveal, or Result according to its saved state. A consumed question cannot reopen because its snapshot remains `used`, and a revealed answer cannot skip its pending score choice.

## Authoritative gameplay loop

- Board requests `chooseQuestion`; the controller rejects missing, used, or concurrent choices and persists the new active-question snapshot.
- Question renders the snapshot without the answer. The timer derives remaining time from the persisted start timestamp, recomputes after app resume, and delegates timeout to the existing steal/reveal rules.
- Helpers call `useHelper`; timing, ownership, prerequisites, one-time consumption, answering team, and score effects stay in `PartyHelpEngine`/`PartyScoreEngine`.
- Reveal appears only after `revealAnswer` succeeds. Team A, No one, or Team B is only a local pending selection until `award` authoritatively writes one score event, marks the question used, advances the turn, and clears the active question.
- Completion is read from the session. The next route is Board or Result; the UI never counts cells locally to declare completion.

## Exit, rematch, and tournament context

System Back from active gameplay opens a safe confirmation and never mutates the question, reveal, score, or helper state. `beginRematch` creates a real setup draft with the existing teams and timer, resets helper consumption through the next generated session, and retains the completed snapshot until replacement persistence succeeds. `beginNewGame` starts a clean draft. Existing tournament-origin metadata/result confirmation remains intact; Phase 4 adds no Tournament visuals.
