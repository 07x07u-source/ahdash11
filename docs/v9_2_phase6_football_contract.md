# Phase 6 — Football preferences contract

Date: 2026-09-05. Screen 42.

Existing FootballRepository calls list_football_leagues, search_football_clubs, get_my_football_preferences and set_football_preferences. Searches keep the existing 30-row limit and league filter. Search is debounced, stale responses ignored, and incompatible club/query cleared when the league changes. Loading, empty catalog, no result, error/retry, saving and confirmation are truthful. Selection and visibility remain a draft until the real RPC completes; failure preserves draft, double save is blocked.

A read-only anonymous catalog audit returned 6 published leagues and 114 published clubs on 2026-09-05. All 114 club visual_status values were fallback. No official artwork was downloaded; no production catalog was seeded or hardcoded. Counts are audit evidence, not constants in the screen.

Only licensed/custom visual states may use logo_url; all others use existing AhdashClubBadge procedural fallback. Text, color and ID come from the actual catalog. No official kit, sponsor, fabricated club or personalization percentage was added.

show_publicly is submitted to the existing RPC; profile hides both club and league when visibility is false. Preferences provider follows auth changes, has no durable account cache, and rejects stale save completion. Guest catalog browsing is possible but saving requires the real account.
