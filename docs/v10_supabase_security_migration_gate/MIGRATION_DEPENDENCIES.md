# Migration dependencies

## Historical baseline

```text
20260827000100 extensions/types
  └─ 20260827000200 profiles/questions
      ├─ 20260827000300 matches/rooms/social
      └─ 20260827000400 economy/notifications/admin
          └─ 20260827000500 RLS/helpers/safe grants
              └─ 20260827000600 auth + rate-limit + match/room RPCs
                  ├─ 20260827000700 economy/import/admin RPCs
                  ├─ 20260827000800 client/matchmaking RPCs
                  └─ 20260827000900 provider integrations
                      ├─ 20260827001000 service-role notification grants
                      └─ 20260827001100 service-role role-helper grants
                          └─ 20260828000100 app content/media
                              └─ 20260828000200 monitoring/branding
                                  └─ 20260828000300 social/football
                                      └─ 20260828000400 gameplay contract v2
                                          └─ 20260829000100 visual store
                                              └─ 20260829000200 football/Premium catalog
                                                  └─ 20260829000300 publish assets
                                                      └─ 20260829000400 RPC type fixes
                                                          └─ 20260830000100 Party content
                                                              └─ 20260831000100 Party category controls
                                                                  ├─ 20260831000200 tournaments v1
                                                                  └─ 20260831000300 editorial media v5
```

The chain is chronological where later functions replace earlier signatures and where the repository assumes the cumulative schema. Direct object dependencies are narrower than the display chain.

## Pending graph

```text
Historical baseline through 20260831000300
  ├─ 20260902000100 gameplay_depth_v1
  │    requires: categories/questions/question_options/question_history,
  │              Party settings, store/inventory, game_settings,
  │              profiles, has_role, require_active_user, assert_rate_limit,
  │              extensions.digest
  │
  ├─ 20260905000100 tournament_bracket_safety_v2
  │    requires: tournaments_v1 tables/types/functions,
  │              profiles, require_active_user, assert_rate_limit
  │
  ├─ 20260907000100 premium_vouchers_v1
  │    requires: profiles, game_settings, audit_logs,
  │              has_role, require_active_user, assert_rate_limit,
  │              gen_random_uuid/gen_random_bytes/digest
  │
  └─ 20260908000100 fix_review_tournament_registration_enum
       requires: tournaments_v1 enum/tables/function,
                 profiles and require_active_user
```

There is no direct object dependency among Gameplay, Tournament v2, Voucher, and the enum fix beyond their common historical baseline. The enum fix is independently valid immediately after `20260831000200`, but timestamp order places it last:

1. `20260902000100_gameplay_depth_v1.sql`
2. migration-specific checks and schema/data snapshot
3. `20260905000100_tournament_bracket_safety_v2.sql`
4. tournament fixtures, preservation and real concurrency checks
5. `20260907000100_premium_vouchers_v1.sql`
6. voucher RLS/RPC/secret/time/rate-limit/concurrency checks
7. `20260908000100_fix_review_tournament_registration_enum.sql`
8. registration approval/rejection/type/authorization and linked-lint checks

Do not batch-apply them blindly. The order above is a staging test plan, not deployment authorization.

## Important dependency observations

- Gameplay replaces `assert_question_publishable` and `get_party_question_pack`; it must run after Party and editorial question columns exist.
- Tournament v2 must resolve the exact legacy signatures before its initial REVOKEs can succeed; the base tournament migration is mandatory.
- Voucher creation needs `extensions.gen_random_bytes`; hashing needs `extensions.digest`; both come from the base extension migration.
- Voucher admin checks depend on `profiles.role` through `has_role`; redemption depends on `require_active_user`; rate limiting depends on `api_rate_limits` and `assert_rate_limit`.
- The enum fix depends only on the already-applied Tournament v1 function and `public.tournament_team_status`; it does not use Gameplay, Tournament v2, or Voucher objects.
- Policies reference only pre-existing fixed-search-path helpers. No pending policy references an object created later.
