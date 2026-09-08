# Profile Redesign V4

Profile is a personal football identity, not an operations dashboard. The player/avatar is the anchor, followed by a single inline statistics rail and three meaningful preferences: club, league, and favorite categories.

Displayed measures are limited to understandable product outcomes: games, wins, tournaments played, tournaments won, questions answered, and accuracy. Rating, XP, economy, ranks, shortcut grids, and achievement tiles are no longer the visual hierarchy.

The screen uses the existing published `profile.background` slot with the packaged image as an offline fallback. Licensed club art remains optional: absent or unsafe art falls back to the existing procedural badge. Guest users see one clear account-save action; signed-in users see sync status. Football preferences, tournaments, and settings remain reachable without duplicating their editors inside Profile.

Tournament profile counts come from `get_my_tournament_stats()` after the new migration. Until then the additive call fails softly and renders zero rather than breaking the existing profile summary.

