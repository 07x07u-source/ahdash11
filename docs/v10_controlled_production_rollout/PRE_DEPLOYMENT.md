# Controlled Production rollout: pre-deployment

Date: 2026-09-08

## Target and tool

- Existing linked target verified against the real Mobile/Admin configuration without printing identifiers or secrets.
- Historical CLI used exactly as requested: Supabase CLI v2.116.0 from the existing npm cache.
- No CLI installation, relink, migration repair, or migration-history rewrite occurred.

## Recovery gate and explicit override

The read-only backup check reported `pitr_enabled: false`, `backups: null`, `physical_backup_data: {}`, and `walg_enabled: true`. This did not provide a verifiable restore point.

`20260902000100_gameplay_depth_v1.sql` overwrites existing Party configuration values without retaining their previous values. The first rollout attempt therefore stopped as required.

The Product Owner then explicitly instructed `انشر مباشرة` (deploy directly). The deployment continued on that explicit risk acceptance despite the unavailable recovery point. This report does not represent that the backup risk was resolved.

## Final pre-push state

`migration list --linked` returned 27 local entries: 23 local/remote matches, exactly four local-only migrations, and zero remote-only migrations. Remote parity was confirmed through `20260831000300`.

The final `db push --linked --dry-run` exited 0 and listed exactly:

1. `20260902000100_gameplay_depth_v1.sql`
2. `20260905000100_tournament_bracket_safety_v2.sql`
3. `20260907000100_premium_vouchers_v1.sql`
4. `20260908000100_fix_review_tournament_registration_enum.sql`

No fifth migration, seed, or role operation appeared.
