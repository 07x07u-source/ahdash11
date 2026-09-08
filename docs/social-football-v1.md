# Social Football V1

This V1 is private by design. It adds friends safety controls, invite-only **فرق الاستراحة**, server-scored team challenges, rights-aware football preferences, and bounded admin moderation. It does not add public discovery, chat, posts, live-presence claims, or team-vs-team matchmaking.

## Database contract

The forward-only local migration is:

`supabase/migrations/20260828000300_social_football_v1.sql`

It has **not** been pushed to any Supabase project by this implementation. Apply it only after reviewing the dry run and running pgTAP in a disposable/staging database.

Security boundaries:

- Team membership, roles, invite codes, challenge attempts, answers, scores, ranks, achievements, and weekly totals are server-owned.
- Flutter cannot select challenge question snapshots, answer-key options, scored answers, or write attempts/scores directly.
- Active attempts resume through the start RPC; the client never invents a replacement score.
- Blocking removes the friendship and pending direct/team requests. Search omits either side of a block.
- Football images render only when `visual_status` is `custom` or `licensed`. Licensed rows additionally require a non-empty `license_reference`.
- Admin mutations remain behind authenticated Admin RLS; team moderation is role-checked and audited.

The matching pgTAP contract is:

`supabase/tests/004_social_football_v1_security.sql`

## Provider and rights policy

No football data provider is configured or bundled. The app intentionally displays an empty state until an administrator imports real provider-backed rows. Provider availability is not proof of logo rights.

- `fallback`: no logo URL; Flutter generates an initials badge.
- `custom`: requires a project-owned custom asset URL.
- `licensed`: requires both an asset URL and a license reference.

Never call a commercial football provider directly from Flutter. Normalize and review data server-side, record `provider_name`/`provider_id`/`last_synced_at`, then explicitly assign the visual rights state.

## Operational rollout

1. Review the migration and parser output.
2. Run a local/staging Supabase reset and `supabase test db` where Docker/PostgreSQL is available.
3. Test RLS with user, moderator, admin, anon, and service-role sessions.
4. Import a small rights-reviewed country/league/club sample through Football Data admin.
5. Manually test create/join/invite/block/report/challenge/reconnect/notification deep links on real devices.
6. Monitor `audit_logs`, `social_reports`, notification deliveries, and app-error features during rollout.
