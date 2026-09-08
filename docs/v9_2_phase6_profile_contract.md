# Phase 6 — Profile contract

Date: 2026-09-05. Screen 38; local implementation only.

## Real state

PlayerProfile and playerProfileProvider remain the public model/provider. ProfileRepository wraps get_my_profile_summary and optional get_my_tournament_stats. Authentication is watched; signed-out/guest/no-Supabase states fail truthfully. A returned profile whose ID differs from the current actor is rejected. There is no durable private profile cache.

The UI renders display name/username, the existing Player 11 component, actual Premium flag, visible football choices, and only returned numeric matches/wins/tournaments_played/tournaments_won. Missing statistics are omitted, not rendered as successful zero queries. questions_answered is derived only when both correct_answers and wrong_answers exist. XP, Coins, rating, accuracy and achievements are not exposed. Legacy model defaults remain for compatibility but are not the Phase 6 UI data source. The production development-player demo fallback is removed.

## Identity and privacy

The existing approved Player 11 male/female packaged artwork is reused, not a remote profile portrait. Color priority is team, visible club, custom, shared fallback. Existing artwork itself is not recolored into an official kit. show_football_preferences must explicitly be true for league/club presentation; hidden club color is not used. No email, phone, OAuth payload, internal ID, report or invite token is rendered.

No unsupported profile editor or fabricated history tab was added. Identity preferences use Settings; football edits use the existing football RPC. Account replacement hides previous data during reload. Server authorization is still required; client checks are not RLS certification.
