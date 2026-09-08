# Physical-device verification checklist

Status: **PREPARED, NOT EXECUTED**.

Use this checklist only after a successful controlled database rollout, post-push verification, and a newly generated test APK. Record device model, Android version, app build identifier, account type, timestamp, and PASS/FAIL evidence for every item.

## Authentication

- [ ] Google Sign-In succeeds; provider handoff/cancel/error states remain recoverable.
- [ ] Create Account succeeds and reaches the intended destination.
- [ ] Email Sign In succeeds and reaches the intended destination.
- [ ] Logout clears the authenticated UI and protected cached state.
- [ ] Guest entry and subsequent upgrade/authentication path work as designed.

## Party core

- [ ] Category Selection loads, selection limits work, and entitlement-gated categories stay gated.
- [ ] Team Setup creates and edits teams correctly.
- [ ] Helpers selection and availability match the rules.
- [ ] Ready state accurately summarizes teams, categories, and rules.
- [ ] Board loads with correct round/team/score state.
- [ ] Text Question and Image Question load correctly.
- [ ] Timer, Answer Reveal, scoring, turn rotation, and Final Result behave as specified.
- [ ] Resume/background/foreground does not duplicate answers or corrupt state.

## Helpers

- [ ] `جاوب جوابين` behavior and consumption are correct.
- [ ] `اتصال بصديق` timing and consumption are correct.
- [ ] `الحفرة` applies the intended opponent scoring behavior.
- [ ] `استريح` applies the intended pass/rest behavior.
- [ ] `الفخ` applies the intended team/opponent scoring behavior.
- [ ] Helpers cannot be reused beyond their allowed count.

## Tournament

- [ ] Create tournament and add/edit Teams.
- [ ] Registration review accepts valid transitions and rejects invalid transitions.
- [ ] Generate Draw and Bracket without duplicated or orphaned matches.
- [ ] Complete Match flow through Champion state.
- [ ] Close/reopen restores the tournament accurately.
- [ ] Retry/resume operations remain idempotent.
- [ ] Destructive tournament actions require the intended authorization and scope.

## Social

- [ ] Search Friend returns only intended public results.
- [ ] Add Friend changes only the authorized relationship.
- [ ] Block and Unblock work and update visibility safely.
- [ ] Team Detail visibility follows membership and RLS rules.
- [ ] Ranking loads correctly without leaking private data.

## Premium

- [ ] Monthly and annual products show localized store prices only.
- [ ] No hardcoded price or fake discount appears.
- [ ] Benefits remain limited to `فئات حصرية` and `بدون إعلانات`.
- [ ] Active subscriber sees no purchase CTA and sees Restore Purchases.
- [ ] Premium-only categories remain entitlement gated.
- [ ] Subscriber ads remain disabled through the existing entitlement truth.

## Voucher

- [ ] Voucher entry remains hidden/disabled while the Production gate is off.
- [ ] After a separately approved gate enablement, invalid/expired/reused vouchers fail safely.
- [ ] Valid redemption is atomic, grants only the intended entitlement, and is idempotent.
- [ ] Client cannot enumerate, create, alter, or revoke vouchers.
- [ ] Voucher values/codes do not appear in logs, analytics, screenshots, or error messages.

## App and device behavior

- [ ] Reduced-motion fallback works.
- [ ] Home primary CTA remains `لعبة جماعية`; Premium does not overpower it.
- [ ] Online remains Deferred.
- [ ] Close/reopen and background/resume preserve valid state.
- [ ] Keyboard, safe areas, RTL layout, and compact viewport remain stable.
- [ ] Weak network and offline behavior fail safely and recover correctly.
- [ ] Back navigation and deep links are stable.
- [ ] No crash, ANR, overflow, missing asset, or unintended debug output occurs.

## FCM/notifications

- [ ] Notification permission prompt follows product timing.
- [ ] Token registration/refresh belongs to the authenticated account only.
- [ ] Foreground, background, terminated, and tap navigation behavior are correct.
- [ ] Sign-out removes or invalidates the device association as designed.
- [ ] Notification payloads expose no secrets or inappropriate personal data.
