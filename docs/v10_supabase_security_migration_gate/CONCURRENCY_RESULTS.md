# Concurrency results

## Tournament

- Real multi-connection result: **BLOCKED** — no PostgreSQL server/driver service is installed.
- Static design: all v2 save/confirm calls lock the organizer-owned tournament row first; target and dependent matches are then locked. This serializes tournament mutations, rejects stale live graphs, makes exact retry idempotent and prevents duplicate advancement/winners.
- Embedded single-connection behavior: 29/29 passed, including retry, conflicts, player preservation and final advancement.
- Residual: legacy `undo_tournament_match_result` uses a different lock order and should be versioned/tested before a current UI exposes it.

## Premium Voucher

- Real same-code/two-user concurrency result: **BLOCKED**.
- Static design: unique hash lookup + `FOR UPDATE` + `redeemed_at is null` compare-and-set + unique `voucher_id` entitlement. Under PostgreSQL READ COMMITTED, the second waiter should observe the consumed row and return `used`; this remains to be proven with two real connections.
- Failure atomicity: representative PostgreSQL/WASM transaction verified that a failed entitlement insert rolls the voucher update back.
- Retry: a committed first redemption leaves the voucher used and the unique entitlement unchanged; no duration-extension path exists. Real lost-response retry remains BLOCKED.

## Rate limit

- `api_rate_limits` uses a `(subject,bucket)` primary key and atomic upsert, so concurrent devices for one account share one server row.
- Attempts 1–8, attempt 9, reset and simultaneous attempts were not executed against real PostgreSQL.

No Dart mock or PGlite result is labeled as a real database concurrency pass.
