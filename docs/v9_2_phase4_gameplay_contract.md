# AHDASH 11 V9.2 — Phase 4 gameplay contract

## Authority and persistence

Figma V9.2 is the visual reference; `PartyGameSession`, `PartyGameController`, `PartyGameEngine`, `PartyHelpEngine`, `PartyScoreEngine`, `TurnEngine`, the question repositories, and existing Drift persistence remain the functional authority. Screens never manufacture question choices, answers, helper consumption, points, turns, or completion.

Mutations are guarded synchronously. A board cell enters a focused loading state while all other cells are disabled. Duplicate question opens, reveals, helper activations, and score awards are rejected from authoritative state. A successful award clears the active question in the same state transition, so rebuilds or rapid taps cannot append a second score event. Best-effort gameplay persistence preserves offline host play; setup start is stricter and clears `party_setup_draft_v2` only in the successful persistence transaction.

## Canonical state map

| Real state | Route | UI |
|---|---|---|
| valid setup draft, no session replacement yet | `/party/ready` | Ready |
| active/incomplete session, no active question | `/party/board` | 6×6 Board |
| active question, `revealed == false` | `/party/question` | format-aware Text/Image Question |
| active question, `revealed == true` | `/party/reveal` | answer and pending host score decision |
| `session.isComplete == true` | `/party/result` | winner or tie result |

All gameplay routes use `PartySetupFlowResolver.redirectGameplay`. A stale deep link is redirected to the earliest truthful state.

## Board and questions

The Board reads all six categories, 36 question snapshots, point values, used state, current turn, scores, and progress from the active session. Used cells include a check mark and semantic state, not color alone. Question formats remain those already released by `PartyQuestionRendererRegistry`; `gameplay_type` is not treated as media type.

Text questions are never truncated and use line-aware sizing for Arabic, English football names, and numbers. Image questions read aspect ratio/focal metadata, support portrait, square, and landscape composition, request cache-aware decode sizes, and expose only the safe semantic label `وسائط السؤال`. Loading is stable; failure shows a branded retry state and reports only route/phase/format/media context through the safe error reporter. It does not reveal, score, or substitute unrelated media.

## Timer and lifecycle

`_QuestionTimer` owns the visual tick, limiting rebuilds to the timer region. Remaining time is calculated from the session's persisted `questionTimerStartedAt` and duration rather than an animation controller. Backgrounding stops local ticks; resume recomputes against the timestamp. Timeout delegates to the existing steal window and then explicit reveal behavior. No client score is inferred from elapsed time.

## Five helpers

| ID | Timing and authoritative effect |
|---|---|
| `two_chances` | after a question opens; arms the existing two-answer opportunity and is not presented as a fabricated multiple-choice control |
| `call_friend` | after a question opens; replaces the visible question timer with `PartyHelperDefinition.callFriendSeconds`, falling back to the snapshotted runtime rule (default 20 seconds) |
| `risk` | before question selection; on an awarded answer for the turn team, the score engine also deducts the configured question multiple from the opponent; a no-score outcome uses the configured wrong multiplier |
| `bench` | before question selection; requires a real opponent player and stores the selected real player as action detail; unavailable without a roster |
| `pass` | after a question opens; transfers `answeringTeamIndex` to the opponent and restricts award to that team or No one; score deltas use the configured trap multipliers |

Availability, active state, consumption, and prerequisites come from the session. Each helper is consumed once in persisted team state. `call_friend` uses no contact lookup, phone number, telephony API, Contacts permission, or Phone permission.

## Reveal, scoring, completion, and rematch

The answer is absent from Board/question visible and semantic trees. Reveal requires a real active question and a successful `revealAnswer` transition. The host then selects Team A, No one, or Team B; this selection has no score effect until the green confirmation requests `award`. No one passes `null` to the score engine instead of awarding zero to a team. Score actions disable while submitting, stay on Reveal after rejection, and apply haptics only after success.

`award` marks the question used, appends one `PartyScoreEvent`, advances the turn through `TurnEngine`, clears transient question/helper/timer state, and sets completion only when the real board/tiebreak contract is complete. Result renders the real winner or a truthful tie. Play Again calls `beginRematch`, preserves teams and timer in a new draft, and resets helper usage only through a newly generated game. New Game calls `beginNewGame` for a clean setup.

## Privacy and telemetry

Gameplay analytics contain counts, format, points, helper ID, and team index where needed. They never contain question/answer/options, player/team names, media URL, tokens, or raw failures. Goldens use production display configuration with no live network or analytics. Competitive answer separation remains unchanged; no answer key was added to Board or media semantics/cache labels.

