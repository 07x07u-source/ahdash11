# أحدعش | 11 — Social Game Design Research

Date: 2026-08-28

This research records principles, not visual copies. No third-party interface, character, club crest, player image, sound, or protected asset is reused.

## Primary sources reviewed

### Apple

- [Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games/): jump into play quickly, teach through play, use strong defaults, support safe areas, legible text, adaptable aspect ratios, and comfortable controls.
- [Game Center](https://developer.apple.com/game-center/) and [GameKit](https://developer.apple.com/documentation/gamekit): player identity, friend competition, recurring leaderboards, achievements, invitations, and showing social context at meaningful transitions.
- [Game Center challenges](https://developer.apple.com/documentation/appstoreconnectapi/configuring-game-center-challenges): turn a verified leaderboard activity into a bounded friendly challenge with progress, key notifications, a winner, and a rematch path.
- [Motion](https://developer.apple.com/design/human-interface-guidelines/motion): motion must be brief, purposeful, cancelable, and optional; important information needs visual/text alternatives to motion, sound, and haptics.
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials) and [Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/): glass is a functional navigation/control layer above content, not a treatment for every content card; contrast and reduced-transparency behavior remain mandatory.
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility): maintain comfortable targets and spacing, pair audio with visual/haptic feedback, and never encode meaning in only one channel.

### Flutter

- [Animations](https://docs.flutter.dev/ui/animations), [Hero animations](https://docs.flutter.dev/ui/animations/hero-animations), and [staggered animation](https://docs.flutter.dev/cookbook/effects/staggered-menu-animation): use implicit motion for simple state changes, shared-element transitions for continuity, and small stagger groups rather than global entrance choreography.
- [Performance best practices](https://docs.flutter.dev/perf/best-practices) and [performance profiling](https://docs.flutter.dev/perf/ui-performance): localize rebuilds, keep lists lazy, avoid unnecessary opacity/clipping/saveLayer, decode images near their display size, and profile before micro-optimizing.
- [Adaptive design best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices), [general approach](https://docs.flutter.dev/ui/adaptive-responsive/general), and [SafeArea/MediaQuery](https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery): adapt to available window space rather than device labels, preserve state, and keep content clear of system intrusions.

### Google / Android

- [Google Play Games Services quality checklist](https://developer.android.com/games/pgs/quality): expose leaderboards at meaningful moments, show the player near adjacent ranks, submit scores at critical transitions rather than continuously, impose plausible score bounds, cache social data, and respect denied friend access.
- [Adaptive app quality](https://developer.android.com/develop/adaptive-apps/quality-guidelines/adaptive-app-quality) and [Adaptive Apps](https://developer.android.com/develop/adaptive-apps): use layouts that remain usable across resizable windows and larger form factors without forcing a separate product.
- [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/views/apps-views): target at least 48dp for Android interactive areas and preserve keyboard/screen-reader navigation.

### Social learning/game patterns

- [Kahoot team experience](https://support.kahoot.com/hc/en-us/articles/4408679135891-Team-experience-How-to-play-kahoot-in-groups): make team membership and the shared objective immediately clear; personal-device teams reduce ambiguity, while reconnect behavior must be designed explicitly.
- [Duolingo Friends Quests](https://blog.duolingo.com/friends-quests/): short, time-bounded cooperative goals and safe prewritten nudges create accountability without requiring a full social network.
- [Duolingo Friend Streak product lessons](https://blog.duolingo.com/product-lessons-friend-streak/): design for later scale while launching with a deliberately small social limit; social motivation can work through parallel participation rather than chat.
- [Duolingo leaderboards](https://blog.duolingo.com/duolingo-leagues-leaderboards/): weekly competition benefits from clear reset timing, visible promotion/status, anti-cheat monitoring, and an opt-out/privacy path.

## Principles extracted for أحدعش

1. The fastest path remains play; club selection, friends, and teams are optional progressive layers.
2. V1 social competition is private and relationship-based: friends and invite-only “فرق الاستراحة”; no public random social discovery or public matchmaking.
3. Social surfaces show one primary next action, a short weekly state, and the player's own rank even when outside the top positions.
4. Weekly MVP uses verified weekly challenge/match points, not lifetime XP, so new members can compete fairly.
5. Score, rank, challenge outcomes, achievements, and weekly totals are server-derived. Flutter never sends a trusted score or rank.
6. Club imagery is rights-aware. An official/custom image is rendered only when explicitly licensed; otherwise the product generates an original initials badge.
7. Saudi identity comes from language, abstract Najdi/Sadu geometry, warm desert neutrals, restrained Saudi green, and the “الاستراحة” social concept—not repeated flags or official national marks.
8. Player 11 is a neutral, back-facing, recolorable original silhouette. Jersey priority is social team color, then favorite-club safe color, then brand lime.
9. Liquid-glass-like treatment stays on navigation, selected filters, sheets, and floating controls. Questions, data cards, and lists keep solid high-contrast surfaces.
10. Motion communicates entry, selection, rank movement, and results; it is brief, cancelable, and disabled by Reduced Motion.
11. Notifications are grouped by friends, teams, challenges, and promotions; each deep link uses a small allowlist and every category can be disabled independently.
12. V1 has no posts, comments, free-form chat, public presence claim, pay-to-win mechanic, or team-vs-team scoring.

## Decisions applied in this implementation

- A bounded social/football schema with rights metadata, normalized Arabic/English search, invite-only teams, role constraints, blocking, reports, challenges, verified attempts, a weekly team-detail RPC, rate limits, and audit hooks.
- Original code-native Saudi pattern, procedural club/team badges, and Player 11 components to avoid licensing and large bitmap costs in repeated UI.
- Progressive football preference selection with skip support, bounded server filtering, honest empty/error states, and profile privacy controls.
- “ربعك” and “فرق الاستراحة” flows centered on requests, invite codes, weekly competition, MVP, and a compact activity stream—not a general social network.
- Admin sections for football data rights state and social moderation, with no ability to edit user scores or ranks.

## Ideas deliberately rejected or deferred

- Public random matchmaking: explicitly excluded from V1 and increases moderation/abuse risk.
- Direct provider calls from Flutter: rejected because API keys, data normalization, caching, and rights decisions belong server-side.
- Official club logos by default: rejected because provider availability is not proof of display rights.
- Full character creator: deferred; it would multiply assets, state, accessibility, and moderation complexity before the core avatar proves useful.
- Team-vs-team competition: schema seams remain possible, but V1 focuses on verified competition inside a private team.
- Posts, comments, chat, and real-time online presence: rejected for V1 due to moderation, privacy, notification, and infrastructure cost.
- Custom sound pack: deferred until original/licensed source audio exists; the current native SystemSound path remains safer than inventing or scraping files.
- Glass on content cards: rejected because it harms hierarchy, contrast, and mid-range Android performance.
- Shipping thousands of clubs in the app bundle: rejected; the architecture is provider/import ready and uses bounded server filtering. A dedicated football-catalog cache remains a follow-up before importing a large catalog.
