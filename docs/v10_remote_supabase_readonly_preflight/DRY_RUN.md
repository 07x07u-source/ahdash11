# Linked database push dry run

Command: cached CLI `db push --linked --dry-run`.

## Result

- Exit: 0.
- CLI confirmation: migrations would not be pushed.
- Structured result: `dryRun: true`, `upToDate: false`.
- Seeds: none.
- Role changes: none.

The dry run would apply exactly, in order:

1. `20260902000100_gameplay_depth_v1.sql`
2. `20260905000100_tournament_bracket_safety_v2.sql`
3. `20260907000100_premium_vouchers_v1.sql`

No fourth or unexpected migration appeared. A real `db push` was not executed and remains prohibited until the real PostgreSQL security gate passes.

## Post-fix dry run

After the local enum follow-up was created, a second `db push --linked --dry-run` reported exactly four migrations in order: Gameplay, Tournament v2, Voucher, then `20260908000100_fix_review_tournament_registration_enum.sql`. Seeds and role changes remained empty. No real push was executed.
