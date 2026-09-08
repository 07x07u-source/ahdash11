# Party Game V4

## Product contract

Party remains the primary game: two local teams, six categories, thirty-six unique questions, three helpers per team, a configurable timer, a board, reveal, scoring, undo, tiebreaker, result, rematch, and offline resume. V4 does not fork or replace this engine.

## V4 changes

- Home now gives Party and Tournament equal primary visibility without becoming a dashboard.
- A Tournament match launches the same Party setup and question engine with the bracket teams and rosters prefilled.
- The Party result is not authoritative for a bracket until the organizer taps «اعتماد نتيجة البطولة».
- A tied knockout match exposes the existing Party tiebreaker. The bracket cannot accept an unresolved tie.
- Party remains usable with no tournament context; the integration state is optional and cleared after confirmation.

## Preserved invariants

- Exactly six categories and thirty-six questions.
- Two easy, two medium, and two hard questions per category.
- Fixed 100/200/300 point bands.
- Question snapshots prevent editorial changes from mutating an active session.
- Recent-question avoidance, favorites, helper timing, score events, local persistence, and resume routing remain unchanged.

## Failure behavior

- Loss of network never discards the local Party or Tournament snapshot.
- A failed cloud confirmation leaves the organizer-owned local result intact for later reconciliation.
- A corrupt local preference cannot block starting a new game.
- Starting a new Party game does not silently erase a resumable round until its replacement is successfully generated.

