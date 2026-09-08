# Phase 6 — Notifications, Settings and Reports

Date: 2026-09-05. Screens 39–41.

## Notifications

NotificationsRepository loads the actual notifications table with target_user_id (not user_id), explicit actor filtering, created_at descending and a 100-row bound. Fields: id, type, title_ar, body_ar, data, read_at, created_at. No sample rows or durable private inbox cache. Loading, data, empty, error, unread/read and refresh are represented. All/unread filters operate on returned data; unsupported accept/reject/mark-all actions are omitted.

Mark-read uses both actor and notification ID and requires a returned row before local refresh/navigation. In-flight row actions are guarded. NotificationNavigation retains the existing route allowlist and validates UUID destinations and 4–12 alphanumeric join codes. Absolute URLs, authorities, fragments, backslashes, arbitrary paths and invalid codes fail to /notifications. Join links are reconstructed with only code. Existing deferred route resolvers remain in place; no Online screen was enabled.

Firebase service architecture still covers foreground events, onMessageOpenedApp and getInitialMessage. Unit tests validate routing, not physical FCM delivery. Foreground/background/terminated delivery, permission denial and account token rotation require a device.

## Settings

Single-column rows: sound, haptics, reduced motion, notifications, account/Player 11 identity, league/club, Premium, help/privacy. Account sheet preserves profile navigation, sign-out and confirmed deletion. Help retains report, existing blocked-player entry and configured HTTPS privacy/terms. Notification sheet exposes the existing eight server preferences and permission request. No active theme selector, currency page or global Save button.

PreferenceStorage wraps existing SharedPreferences keys; widgets do not call storage directly. Writes are serialized and state changes only after successful persistence. Failed reads use safe defaults; failed writes show safe Arabic feedback. Legacy theme infrastructure is retained inactive. Device-wide UI preferences contain no tokens, receipts, scores, answers or entitlement authority. Notification preferences remain server/account scoped.

Sound/haptics use the existing centralized feedback service. Settings toggles do not vibrate on every interaction. No custom sound library or Rive was added.

## Report contract

Existing submit_user_problem_report RPC only. Category plus optional description (maximum 1500 characters); safe allowlisted source screen plus existing version/build/platform metadata. No unsupported attachment upload. A nonempty server result is required for success. Draft is in-memory and account-reset, preserved on failure, never sent to analytics. Busy/sent guards prevent double submits. Timeout is an ambiguous outcome and blocks automatic retry; backend has no idempotency key, so cross-process exactly-once delivery is not claimed.

Existing server limit is 5 reports per user per 24 hours. No client bypass, migration or live submission was performed. Validation and expected offline errors are not crash events. Physical keyboard, device permission and account deletion remain manual checks.
