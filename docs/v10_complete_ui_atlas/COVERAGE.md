# Coverage

## Counts

| Metric | Count |
|---|---:|
| Expected active screens | 38 |
| Captured active screens | 38 |
| Total PNG files | 242 |
| Full-screen screenshots | 152 |
| Primary full-screen screenshots | 76 |
| Compact screenshots | 42 |
| Keyboard screenshots | 9 |
| Guest screenshots | 7 |
| Empty-state screenshots | 5 |
| Loading-state screenshots | 6 |
| Error-state screenshots | 5 |
| Detail crops | 56 |
| Component crops | 30 |
| Existing before/after artifacts | 4 |
| Byte-identical planned outputs deduplicated | 0 |

## Missing active screens

None.

Online Lobby (30), Online Match (31), and Private Room (32) are intentionally deferred and are not counted as active expected screens.

## State-level gaps and intentional skips

Screen coverage is complete, but interaction-state coverage is not 100%. The following states were not fabricated merely to increase the screenshot count:

- Category Selection: separate 0-selected, partial-selected, no-results, loading, and error frames are not exposed by the current deterministic screenshot harness.
- Category Detail: dedicated media-fallback and variable-metadata frames are not exposed.
- Team Setup: separate empty/default, validation, and optional-distribution frames are not exposed.
- Team Splitter: separate no-player and manual-allocation frames are not exposed; current automatic populated state is captured.
- Helpers: individual available/selected/consumed frames for all five helpers are not exposed separately; the three-selected summary is captured.
- Game Board: dedicated fresh, near-complete, completed-cell, and helper-active frames are not exposed separately.
- Questions: dedicated two-chances, call-friend, helper-active, and media-fallback frames are not exposed separately.
- Answer Reveal: Team A award, Team B award, and no-score frames are not exposed separately.
- Final Result: winner-B and tie frames are not exposed separately.
- Saved Games: one-game, resume-error, and loading frames are not exposed; empty and multiple-game fixture frames are captured.
- Tournament Hub: empty, loading, and error frames are not exposed.
- Create Tournament / Teams: dedicated filled-form and validation frames are not exposed; keyboard and current form/stage are captured.
- Tournament Draw / Bracket: distinct pre-draw, post-draw, and completed-bracket frames are not all exposed; draw, initial, semifinal, and final-stage frames are captured.
- Tournament Match: a separate completed-match frame is not exposed.
- Solo: only the real current limited state is captured; gameplay was not invented.
- Team Challenge: separate loading, unavailable, and error frames are not exposed by the visual harness.
- Friends: add-success, add-error, pending/duplicate, and menu-dialog frames are behavior-tested but not exposed as stable screenshots.
- Blocked Players: confirmation and post-unblock success frames are not exposed; populated, empty, and error frames are captured.
- Profile: partial, edit, validation, and save-loading frames are not exposed; normal and guest-gate frames are captured.
- Notifications: read/unread distinction and permission denied/granted frames are not exposed; populated, empty, loading, and error frames are captured.
- Settings: guest-specific settings and logout-confirmation frames are not exposed as stable screenshots.
- Report a Problem: filled, validation, submitting, success, and failure frames are behavior-tested but not exposed as stable screenshots.
- Football Preferences: separate empty, save-loading, and error frames are not exposed; selected/search keyboard state is captured.
- Premium: active entitlement, purchase/restore progress, success, failure, and a visually distinct unavailable frame are not exposed. The current inactive package list with monthly selection and one loading frame are captured; the harness outputs labeled packages-fixture and unavailable were byte-identical to loading, so they were not misrepresented as distinct states.
- Component atlas: no stable confirmation dialog screenshot exists, so a Dialog crop was not fabricated.

All missing mutation-specific states remain covered by the existing behavioral test suite where applicable; production behavior was not changed for documentation.
