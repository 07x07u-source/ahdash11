# Supabase backend — أحدعش | 11

This directory is a deployable Supabase backend, not a mock. It provides PostgreSQL migrations, RLS, storage policies, server-authoritative match RPCs, Edge Functions, deterministic question import, demo data, and pgTAP security tests.

## Local setup

```bash
supabase start
supabase db reset
supabase test db
supabase functions serve --env-file supabase/.env.local
```

Copy `.env.example` to `.env.local` and use the keys printed by `supabase status`. Never commit the service-role key. The configured seed intentionally does not insert into Supabase Auth internals. New anonymous, Google, Apple, or email users receive `profiles`, `player_stats`, `wallets`, and `notification_preferences` rows through database hooks. Linking an anonymous account keeps the same auth user ID and therefore preserves progress.

## Migration map

- `001`: extensions, enums, normalization helpers.
- `002`: profiles, global stats, dynamic categories/subcategories, questions, options, tags, history, bot opponents, auth hooks.
- `003`: seasons, friends, matches, match snapshots/options/answers/events, rooms, queue.
- `004`: wallet ledger, store/inventory, subscriptions, devices, notifications, reports, import staging, settings, account deletion/audit.
- `005`: RLS, allowlisted column grants, client-safe views, storage buckets/policies.
- `006`: solo/room/match lifecycle and answer submission/reveal RPCs.
- `007`: ledger/store/finalization/admin/import/account RPCs and field-protection triggers.
- `008`: client-aligned solo pack/history contracts, atomic quick matchmaking, and participant-safe quick-match advancement.
- `009`: provider integrations, idempotent RevenueCat state, FCM delivery audit, verified AdMob rewards, and server-managed friends/invites.
- `010`: explicit service-role grants required by notification delivery and provider callbacks.
- `011`: service-role role helpers used by protected server-side workflows.
- `20260828000100`: versioned application copy, media library, category/store media references, publishing RPCs, Storage policies, and audit logging.
- `20260828000200`: Branding Center keys, safe appearance/feature controls, operational error aggregation, user problem reports, dashboard metrics, RLS, rate limits, sanitization, and review audit.

All `SECURITY DEFINER` functions use a fixed `search_path`. Trigger-only and internal writer functions have `EXECUTE` revoked from `anon` and `authenticated`.

## Client-safe question DTO

Online clients read `match_question_payloads`, which contains only:

```json
{
  "match_question_id": "uuid",
  "match_id": "uuid",
  "sequence_number": 1,
  "status": "accepting",
  "question_text": "...",
  "question_type": "text",
  "image_url": null,
  "category_id": "uuid",
  "duration_ms": 15000,
  "opened_at": "server timestamp",
  "closes_at": "server timestamp",
  "options": [{ "id": "match-option-uuid", "text": "...", "position": 1 }]
}
```

It never contains `questions.correct_option_id`, `match_questions.question_id`, or `match_question_options.source_option_id`. Authenticated users have no direct `SELECT` on `match_answers`. Moderators retrieve a full question, including its answer key, only through role-checked `get_admin_question(p_question_id)`.

## RPC contracts

PostgREST RPC parameter names are exact.

### Matches and rooms

| RPC | Input | Result / rule |
|---|---|---|
| `start_solo_match` | `p_category_ids uuid[]`, `p_difficulty`, `p_question_count`, `p_opponent_slug` | Creates a match, selects unseen/least-recent questions, snapshots/shuffles options, and opens question 1. |
| `create_room` | `p_mode` (`friend_1v1` or `team_2v2`), `p_category_ids`, `p_question_count`, `p_settings` | Returns `room_id`, six-digit `room_code`, `match_id`, capacity, expiry. |
| `join_room` | `p_code`, optional `p_preferred_team` (`a`/`b`) | Locks the room row, enforces capacity/expiry, allocates team and seat. |
| `set_room_ready` | `p_room_id`, `p_ready` | Updates caller readiness only. |
| `start_room_match` | `p_room_id` | Host-only; requires every seat filled and ready, then snapshots a shared ordered question set. |
| `submit_match_answer` | `p_match_question_id`, `p_match_option_id` | First answer wins. Server clock calculates latency/score. Returns acceptance only—never correctness or score. |
| `reveal_match_question` | `p_match_question_id` | Reveals only after all human players answered or the server deadline passed; applies scores/statistics once. |
| `get_match_question_result` | `p_match_question_id` | Participant-only and only after reveal; returns correct match option plus all scored answers. |
| `advance_match` | `p_match_id` | Solo owner/room host only; opens the next question or atomically finalizes rewards/results. |

The match state machine is enforced by a transition trigger. Match scores, response times, XP, coins, ratings, question statistics, and results are never accepted from a phone.

### Wallet and store

| RPC | Input | Rule |
|---|---|---|
| `purchase_store_item` | `p_store_item_id`, `p_quantity`, required `p_idempotency_key` | Locks wallet, rejects negative balance, appends ledger, upserts inventory atomically. |
| `admin_adjust_wallet` | `p_user_id`, signed `p_amount`, `p_reason`, required `p_idempotency_key` | Admin-only and audited. |

`post_wallet_transaction` and `finalize_match` are internal-only. No client role can insert a ledger row or mutate a wallet balance directly.

### App content and media

- Public clients call `get_published_app_content()` and receive published values only; draft fields are not exposed.
- Moderators can save/reset drafts and manage category presentation. Admins publish content and may update store media.
- Media uploads use the `app-content` bucket and are restricted to safe versioned paths, JPEG/PNG/WebP, 8MB, and dimensions from 64 to 6000 pixels.
- Media replacement updates references transactionally. Deletion is blocked while an asset is still in use.
- Content and media mutations write to `audit_logs`; direct table privileges remain constrained by RLS and role checks.

### Operational monitoring

- Authenticated clients submit selected non-fatal operational failures through `report_app_error`; direct writes to monitoring tables are revoked.
- The server sanitizes tokens, credentials, email addresses, control characters, and oversized fields, then fingerprints matching issues and suppresses duplicate events from the same session for 30 seconds.
- Accepted occurrences are limited to 20 per user/hour. User-authored reports use `submit_user_problem_report` and are limited to 5 per user/day.
- Moderators can read sanitized issues/reports. Admin review actions use role-checked RPCs and write audit rows.
- Crashlytics remains the crash/uncaught-error layer; the Admin monitoring pages intentionally show the Supabase operational stream only.

### Import

The seven supported minimal headers are:

```text
السؤال
الخيار الأول
الخيار الثاني
الخيار الثالث
الخيار الرابع
الإجابة الصحيحة
الصورة - اختياري
```

Canonical English aliases (`question_text`, `option_1` through `option_4`, `correct_answer`, `image_url`) also work.

- `validate_import_row_data(p_raw_data, p_filename, p_category_hint_id)` performs required-field, four-option, answer-membership, exact SHA-256 duplicate, trigram similarity, keyword/category, difficulty, tags, and suitable-mode rules. It uses no LLM.
- `validate_import_batch(p_batch_id)` stores normalized data/errors/warnings/classification/confidence and updates batch counters.
- `commit_import_batch(p_batch_id, p_publish)` commits only rows whose staging status is explicitly `valid`. A reviewer approves a `needs_review` row by correcting `normalized_data` and changing the row status to `valid` before commit.
- `get_admin_question(p_question_id)` is the moderator-only full editor DTO.

`import_rows.normalized_data.suitable_modes` accepts: `solo`, `quick_1v1`, `friend_1v1`, `team_2v2`.

## Edge Function HTTP bodies

All endpoints are `POST`, require `Authorization: Bearer <user JWT>`, and accept JSON.

- `submit-answer`: `{ "matchQuestionId": "uuid", "optionId": "uuid" }`
- `create-room`: `{ "mode": "friend_1v1", "categoryIds": [], "questionCount": 15, "settings": {} }`
- `join-room`: `{ "code": "827451", "preferredTeam": "a" }`
- `queue-matchmaking`: enqueue/heartbeat `{ "categoryIds": [], "questionCount": 15, "region": null, "initialRange": 100 }`; cancel `{ "action": "cancel" }`.
- `wallet-transaction`: purchase `{ "action": "purchase", "storeItemId": "uuid", "quantity": 1, "idempotencyKey": "unique-key" }`; admin adjustment uses `action`, `userId`, `amount`, `reason`, `idempotencyKey`.
- `import-validate`: either `{ "batchId": "uuid" }` or `{ "filename": "questions.xlsx", "sourceType": "xlsx", "categoryHintId": "uuid", "rows": [...] }`.
- `import-commit`: `{ "batchId": "uuid", "publish": false }`.
- `delete-account`: `{ "reason": "optional" }`; records the request, disables active surfaces, then uses the Edge-only service role to remove the Auth user. Historical match rows retain anonymized display snapshots via `ON DELETE SET NULL`.

Provider callbacks use different authentication contracts:

- `revenuecat-webhook` accepts RevenueCat's `Authorization: Bearer <secret>`, rejects unknown users, and applies only events at least as new as the stored event.
- `dispatch-notifications` accepts either an admin JWT or `NOTIFICATION_DISPATCH_SECRET`, sends FCM HTTP v1 in bounded batches, respects preferences/quiet hours, and records idempotent per-device delivery rows.
- `admob-reward` accepts Google SSV `GET` callbacks, verifies the unmodified query with Google's rotating ECDSA key, validates unit/user/time, and grants the configured coins once per provider transaction.

Social clients use `search_players`, `send_friend_request`, `respond_friend_request`, `remove_friend`, `get_friend_dashboard`, and `invite_friend_to_room`. Direct friend writes are revoked so rate limits and canonical pair rules cannot be bypassed.

## Realtime

Subscribe narrowly by primary key:

- room lobby: `room_members` filtered by `room_id`;
- match state: `matches` filtered by `id`;
- question timing/state: `match_questions` filtered by `match_id`;
- append-only events/reconnect cursor: `match_events` filtered by `match_id`, ordered by identity `id`.

Do not subscribe to the global question bank or matchmaking queue.

## Demo data

The seed provides six main categories, subcategories, settings, a demo season, four configurable bot opponents, store items, and exactly 50 fictional questions prefixed with `[تجريبي]`. It does not claim real football facts and contains no unlicensed media.
