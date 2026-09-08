# Flutter Validation

Validation date: 2026-09-08

| Command | Result |
| --- | --- |
| `node --test scripts/check-release-integrations.test.mjs` | PASS — 5/5, 0 failed, 0 skipped |
| `node scripts/check-release-integrations.mjs --env-file mobile/.env` | EXPECTED BLOCK — exit 1 with missing/invalid key names only |
| `gradlew help --no-daemon` | PASS — Gradle configuration accepted |
| `flutter analyze` | PASS — No issues found (165.6s) |
| `flutter test` | PASS — 1407/1407, 0 failed, 0 skipped (3m09s) |

Focused coverage confirms:

- missing Production input fails closed;
- development and Google test AdMob configuration is invalid for Production;
- both Production voucher switches must remain off;
- CLI execution cannot silently return success on incomplete input;
- AppConfig rejects malformed backend/legal configuration;
- online routes remain redirected/deferred;
- RevenueCat plans use localized store prices;
- Premium access centrally controls ad eligibility.

No Golden baseline was updated. The complete unfiltered Flutter suite, including all Golden groups, was run.
