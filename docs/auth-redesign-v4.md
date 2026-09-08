# Auth Redesign V4

## Outcome

Login is now a full-bleed football entrance rather than three large panels. The brand story occupies one side and the compact authentication flow occupies the other. The existing generated 1920×1080 artwork is the immediate local fallback.

## Content precedence

1. Packaged `assets/images/backgrounds/login_landscape_v2.webp` renders immediately and offline.
2. Published CMS slot `auth.login.background` replaces it when available.
3. Legacy slot `branding.login.artwork` remains a backward-compatible fallback until the additive migration is deployed.
4. A fixed directional scrim protects Arabic text contrast regardless of the selected image.

## Authentication preserved

- Email sign-in and account creation.
- Guest continuation.
- Native Google only when `GOOGLE_AUTH_ENABLED` is enabled on Android/iOS.
- Native Apple only when enabled on iOS.
- Existing Supabase/Auth repositories and package identity.

Errors now appear inside the composition as an accessible live region. A successful build only verifies that native configuration is packaged; it does not claim that any provider works on a real device.

