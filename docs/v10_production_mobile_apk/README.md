# AHDASH 11 — Production Mobile APK Gate

Audit date: 2026-09-08

The Android Production configuration is currently **BLOCKED**. The repository now has a fail-closed validator and a guarded APK build wrapper, but the real RevenueCat, AdMob, and legal-link values are not available in the local approved configuration path. `APP_ENV` is also still `development`.

No Release APK was built in this phase. No AAB was built and nothing was published.

Use the existing compile-time configuration architecture:

1. Supply the real values through a protected Production environment file or protected CI environment.
2. Run `node scripts/check-release-integrations.mjs --env-file <secure-production-env-file>`.
3. Only after every check is `PRESENT`, run `powershell -File scripts/build-production-apk.ps1 -EnvironmentFile <secure-production-env-file>`.

The scripts never print configuration values. They output only `PRESENT`, `MISSING`, or `INVALID` followed by the configuration key.

See [FINAL_STATUS.md](FINAL_STATUS.md) for the gate decision and [PHYSICAL_DEVICE_QA.md](PHYSICAL_DEVICE_QA.md) for the post-build QA checklist.
