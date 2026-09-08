# Guest access audit — 2026-09-07

Scope: Flutter UX and defensive client checks only. No server schema, RLS, SQL, migrations, deployment, or RPC authorization changed.

## Before

- Routing lacked a global capability guard. Private destinations could mount before their providers rejected anonymous users.
- Production Guest is a Supabase anonymous user. Development Guest is preferences-backed. Neither is a real account.
- Party setup/gameplay are local. Solo uses the local engine and published content with limited options.
- Party history is device-local, not cloud restoration. Archive access is now an explicit least-privilege product restriction; continuing the current local game remains allowed.
- Production tournaments already require authenticated ownership. Premium already rejects Guest. Those server/store boundaries were preserved.
- Social repository calls lacked an early anonymous-client guard.
- Question reports could queue without a user ID and later attach to the currently signed-in user.
- Auth identification included anonymous users when identifying notification and purchase services.

## After: one capability policy

GuestCapabilityPolicy is used by routing, Home, contextual gates, sensitive in-screen actions, social access, reports and notification identification (directly or through the Supabase-user adapter).

| Capability | Guest | Reason |
|---|---|---|
| Home | Allow | Product discovery |
| How to Play | Allow | Local instructions |
| Local Party setup, current gameplay/result | Allow | Existing device-local engine |
| Local Solo | Allow | Existing local engine, limited options |
| Local settings | Allow | Sound, haptics, reduced motion |
| Saved-games archive | Account | Explicit minimum-access choice, not cloud sync |
| Tournaments | Account | Organizer/participant ownership |
| Profile/account management | Account | Persistent identity |
| Friends and blocked players | Account | Private social graph |
| Teams and team challenges | Account | Server identity/membership |
| Notifications | Account | Account-specific invitations/data |
| Ranking | Account | Account-linked discovery |
| Football preferences | Account | Persistent account preferences |
| Premium and restore purchases | Account | Store/account association |
| Reports | Account | Protected mutation, account-bound offline queue |
| Cloud sync | Account | No new sync functionality added |
| Unknown/new destinations | Account | Restricted by default |

## Conversion and safety

- Restricted deep links open a contextual Auth Gate before mounting protected providers.
- Gate offers Sign In, Create Account and Back, with feature-specific descriptions.
- safeReturnTo permits known internal routes and supported queries; rejects external URLs, traversal, fragments, backslashes, unknown destinations and auth-loop targets.
- The existing router refreshes on auth changes without reconstructing the Party controller. Signing in resumes the intended destination.
- Report gates return to the question; authentication never auto-submits a report.
- No identity merge, archive reassignment, or new Party session during conversion.
- Anonymous users are not identified to push/store services. Token registration and rotation check live real-account identity.
- Queued reports are never reassigned to another account.
- These are UX controls and defense in depth, not a replacement for backend JWT, ownership checks or RLS.

## Tests

- Pure policy: allowed/restricted actions, fail-closed routes, safe returns and encoded intents.
- Real GoRouter: 13 private deep links gated before private profile fetch; Sign In resumes Profile; Create Account preserves Friends intent; the exact current Party object survives.
- Guest can open local settings and all three existing preference switches.
- Restored anonymous identity does not identify push/purchase services.
- Guest cannot queue or send a question report.

No remote operation was executed during this audit or implementation.
