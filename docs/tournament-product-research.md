# Tournament Product Research

## Verified patterns

Public regional football-quiz tournaments consistently use knockout play, organizer-controlled draws, fixed rosters, duplicate-player prevention, and category restrictions. Verified examples include [Boubyan 2026](https://www.bankboubyan.com/ar/events-social-responsibility/boubyan-seen-jeem-ramadan-2026), [Boubyan 2025](https://www.bankboubyan.com/ar/events-social-responsibility/boubyan-seenjeem-tournament-2025), [KOC's 64-team event](https://www.kockw.com/sites/AR/EMagazine/Pages/Events/903.aspx), and the [Kuwait Ministry of Information 2026 registration rules](https://competitions.media.gov.kw/Ramadan/2026/SeenJeem/).

These sources validate the problem space, not a competitor interface. No visual design, media, copy, or proprietary flow was copied.

## Ahdash decisions

- Single elimination is the V1 format because its mental model is immediate on a shared phone.
- Bracket capacities are 4, 8, 16, 32, and 64; a smaller field receives deterministic BYEs.
- Teams allow 1–8 roster names so home gatherings and organized events share one model.
- Draw and manual seeding are both supported.
- The phone UI is round-focused with paging, avoiding an unreadable giant bracket.
- The Party engine is the match surface; the Tournament engine owns advancement and finality.
- Local-first operation is the default. Cloud sync adds registration, invitations, admin visibility, and multi-device continuity.

## Rejected for V1

Double elimination, groups, leagues, Swiss pairing, live spectator chat, public roster PII, and user-generated bracket rules are deliberately excluded. They expand trust and moderation risk without improving the core first tournament.

