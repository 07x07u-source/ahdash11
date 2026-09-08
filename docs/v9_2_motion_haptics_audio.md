# AHDASH 11 V9.2 — Motion, haptics, and audio

## Phase 5 Tournament behavior (2026-09-05)

- Reuses shared button/route motion and the central feedback service; adds no artificial draw delay, shuffle loop, bespoke confetti or Rive animation. The bracket is displayed after persistence succeeds. Static compositions also work with Reduced Motion.
- Creation, committed draw and first confirmed result request semantic feedback after success. Final confirmation uses the win cue once; re-opening Champion and exact duplicate confirmation do not replay it. Staged manual team edits do not claim remote-success feedback.
- Uses the existing analytics abstraction for `tournament_created`, `tournament_draw_completed`, `tournament_result_confirmed` and `tournament_completed`, with no team/player names, IDs, invite codes or payload parameters. Tests/Goldens use the default no-op service. Expected business/network rejection is not sent as a crash; unexpected programming failures in create/draw/confirm use the safe reporter with only operation/status and a constant message.
- Sound and haptics follow existing preferences. No custom SFX, media downloads, sound dependency or player per button was added. The flow remains usable silently. Shared Party start/gameplay feedback remains owned by Party.

## Motion tokens

| Event | Implemented token | Approved range |
|---|---:|---:|
| micro press | 100 ms | 80–120 ms |
| page transition | 200 ms | 180–240 ms |
| selection | 160 ms | 140–180 ms |
| reveal / score | 320 ms | 250–400 ms |
| launch | 520 ms | 400–700 ms |
| champion/result | 700 ms | 500–900 ms |

Use opacity/transform and the centralized curves. Motion communicates state change; it is not applied to every widget. `Reduced Motion` remains supported and must replace transitions with zero/minimal duration where the existing infrastructure exposes `MediaQuery.disableAnimationsOf` or the stored preference.

## Haptics

`AppFeedbackService` is the centralized policy. Feature code requests semantic cues instead of directly vibrating. Appropriate cues include meaningful selection, helper activation, ready/start, score award, draw completion, win/champion, and critical feedback. Navigation taps and rebuilds must not vibrate. The stored haptics preference is authoritative.

## Audio

The current centralized feedback service uses platform system sounds and respects the sound-effects preference. The project has no `audioplayers` dependency and no approved bundled UI/game SFX library. Do not instantiate an audio player per button or add a dependency merely to satisfy a design checklist.

Question audio/video URLs are content data and remain handled by the real question flow. A later audio enhancement requires licensed/original files, a shared lifecycle-aware service, separate UI/game/question channels, interruption/focus handling, and tests. This is a documented gap, not a Phase 1 blocker.

## Figma implementation policy

Only implement motion explicitly evidenced by the handoff or needed for state comprehension. Draw and champion animation starts only after real state succeeds/confirms. Never animate fake scores, matchmaking time, online presence, or premium entitlement.

## Phase 4 gameplay behavior

- Board opening uses a focused pressed/loading state on the requested cell while other cells become disabled; it does not cover the screen with a spinner.
- Question timer animation is visual only and isolated from the rest of the question tree. Backgrounding stops ticks and resume recomputes from persisted time.
- Question-open, helper, reveal, score, and game-complete feedback is requested only after the corresponding controller transition succeeds.
- Reveal does not animate points while the host is only selecting a score recipient. Result entrance is based on a completed session and remains static when Reduced Motion is active.
- Gameplay works silently. Phase 4 added no audio dependency, random SFX, permanent loop, or Rive animation.
