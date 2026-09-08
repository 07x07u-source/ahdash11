# Production database push

Status: **PASS**.

Command: historical cached CLI `db push --linked`.

One real push was executed after the exact dry run. Exit code: 0.

Applied in order:

1. `20260902000100_gameplay_depth_v1.sql`
2. `20260905000100_tournament_bracket_safety_v2.sql`
3. `20260907000100_premium_vouchers_v1.sql`
4. `20260908000100_fix_review_tournament_registration_enum.sql`

CLI result: `dryRun: false`, exactly four migrations, `seeds: []`, `roles: []`.

No retry, migration repair, history edit, relink, or manual applied marker was used.
