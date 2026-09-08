# أحدعش | 11 — Final Product Polish Audit

Date: 2026-08-28

## Scope reviewed

- Flutter design tokens, light/dark themes, navigation safe areas, gameplay layout, timers, feedback, image decoding, offline/loading/error states, settings, notifications, and startup behavior.
- Admin navigation, tables, audit readability, system-health truthfulness, notification campaigns, validation, responsive mobile navigation, and production build behavior.
- Supabase migrations, Edge Function type checking, RLS presence, `SECURITY DEFINER` search paths, and client-side secret boundaries.

## Material fixes

- Added notification lifecycle handling for foreground, background, and terminated launches with safe allow-listed deep links and a non-duplicating foreground banner.
- Added FCM token rotation cleanup, user-scoped logout cleanup, and a tested permission policy that treats denied/not-determined as disabled.
- Rebalanced haptics so routine actions are light/selection feedback and no action uses heavy vibration; sound and haptics continue to respect their settings.
- Made gameplay timeout state represent no selected answer while preserving the timeout record and zero client score.
- Made lobby and online-match waits/timers dispose-safe, guarded lobby loading against duplicate requests, and added bounded initial loading.
- Extended motion, opacity, blur, elevation, loading, and connectivity tokens and applied safe bottom inset handling.
- Added long Arabic question/answer, large text scale, reduced-motion, timeout, and dispose-during-timer regression coverage across 360×800, 390×844, and 412×915 in light/dark modes.
- Removed fake success from the Admin notification API, added idempotent request IDs, safe deep-link validation, duplicate-send protection, and a pre-send preview.
- Changed System Health to a real healthy/problem/unknown model; no notification check appears green without a recorded attempt.
- Improved Admin audit actors/actions, sticky table headers, mobile search sizing, Escape-to-close, and mobile body scroll locking.

## Audio findings

- There are no bundled gameplay audio files and no audio package or asset declarations to validate. Feedback uses Flutter native `SystemSound` only.
- This avoids missing asset paths, file overlap, preload, and player disposal risks, but limits distinct sound design and volume mixing.
- Actual sound behavior, Android volume/silent behavior, and haptic intensity remain physical-device QA items.

## Validation completed

- Flutter: formatting clean, `flutter analyze --fatal-infos` clean, 55 tests passed.
- Admin: ESLint clean, TypeScript clean, 30 tests passed, Next.js production build passed.
- Edge Functions: Deno formatting and type checking passed for 13 TypeScript files.
- SQL: PostgreSQL PL/pgSQL parser passed all 13 migrations; static RLS and `SECURITY DEFINER/search_path` checks passed.
- Android: signed Release APK built with `.env`; package `com.ahdash.eleven`; APK Signature Scheme v2 verified.

## Technical debt and runtime-only QA

- Flutter warns that future releases will require newer Gradle, AGP, and Kotlin versions. They were intentionally not changed because the current Release build succeeds.
- Full local migration execution was not performed because a local PostgreSQL/Supabase container runtime is unavailable; no remote `db push` was run.
- Google Sign-In, FCM delivery/taps/token expiry, Crashlytics delivery, AdMob, RevenueCat, real 1v1/2v2, audio, haptics, background/resume, and network transitions require physical-device/provider QA.
