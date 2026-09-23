# AHDASH | 11 — Entry Experience Audit

Audit date: 2026-09-10

Scope: active V10 Launch, Onboarding, Authentication, their routes and controls,
and the current main-navigation foundation. The screenshots in
`docs/v10_complete_ui_atlas` are the visual baseline for this iteration.

## Visual findings

- **Launch:** the mark is legible and calm, but the composition has excessive
  unused space, almost no football signal, and a weak footer. It reads as a
  generic splash rather than a confident AHDASH opening.
- **Onboarding:** the four steps use the same large rounded illustration card,
  generic Material icons, dots and a button. The hierarchy is consistent but
  template-like and not meaningfully football-first.
- **Onboarding defect:** after pressing Next, the 390×844 captures for steps 2
  and 3 are displaced and clipped. Step 4 returns to the expected position.
  The compact 360×800 step 3 is not clipped.
- **Authentication:** the form states are understandable and the Google,
  credential and guest paths are visually separated. The large rounded panel,
  repeated dividers and mixed lime/deep-green primary actions weaken brand
  consistency. Create Account loses the brand header at common portrait sizes.
- **Keyboard and text scale:** the current scroll strategy keeps the fields
  reachable, but the keyboard state removes all identity/context from the top.
  At 1.3 text scale the Sign In footer is clipped until manually scrolled.
- **Accessibility:** error contrast and live-region semantics exist. The
  password action has a tooltip, but its explicit semantic state and 48×48
  target need to be guaranteed.

## Code and route findings

- Launch resolves onboarding preferences and restored authentication in
  parallel, then routes with `go`, which correctly avoids stale back-stack
  entry screens.
- Launch adds a fixed 520 ms minimum wait after readiness. This is artificial
  latency and does not protect any dependency.
- The Onboarding displacement is caused by calling
  `Scrollable.ensureVisible` on the newly keyed scroll view after every step
  change. It changes the scroll position of the step content instead of merely
  resetting it.
- Onboarding completion is guarded against duplicate presses and persists
  before routing. Failure returns the CTA to an enabled state and shows a safe
  message.
- Credential, guest and social authentication are guarded both by disabled UI
  state and the controller's `_authActionInProgress` lock. Social cancellation
  is intentionally quiet; non-cancellation failures remain visible inline.
- Successful account authentication resumes a validated `returnTo`; guests
  intentionally go to Home. Private deep links are gated before their screen
  providers mount.
- The existing `AppShell` uses a stock `NavigationBar`, has five paths, and is
  mounted only by Social Hub. Home and the other primary destinations therefore
  have no shared navigation foundation.
- Online routes are compatibility tombstones that redirect to Home and are not
  candidates for the main dock.

## Interaction control matrix

| Surface | Control | Destination/effect | Audit result |
|---|---|---|---|
| Launch | automatic resolver | Onboarding, Auth, or Home | Works; fixed wait must be removed |
| Onboarding | Skip | persist completion → Auth | Works; duplicate guarded |
| Onboarding | Next / Start | next step / persist → Auth | Works, but steps 2–3 visually displaced |
| Onboarding | Previous | previous step | Works |
| Onboarding landscape | How to play | `/how-to-play` | Works |
| Sign In | Google | native provider → intended route | Works; busy/duplicate/error states covered |
| Sign In | Email submit | account → intended route | Works; validation and safe error covered |
| Sign In | Guest | local guest → Home | Works; capability limits preserved |
| Auth | Password visibility | toggles obscuring in place | Works; semantics to strengthen |
| Auth | Mode switch | Sign In ↔ Create Account | Works and resets validation |
| Auth Gate | Sign in / Create / Back | Auth with safe return / previous or Home | Works |
| Current main nav | five stock destinations | only mounted inside Social Hub | Incomplete foundation |

No intentionally disabled or deferred control is presented as tappable in the
audited entry surfaces. Legal consent is currently static disclosure text, not
a dead link.

## Performance findings

Critical path before the first Flutter frame currently includes:

1. platform orientation and system-UI calls;
2. package metadata;
3. Supabase client initialization when configured;
4. Firebase initialization when enabled;
5. ad consent/SDK initialization, which can wait up to 12 seconds;
6. RevenueCat initialization;
7. `runApp`;
8. preferences and auth restoration on Launch;
9. an additional fixed 520 ms Launch delay.

The highest-confidence repairs are to remove the fixed Launch wait and move ad
initialization off the first-frame critical path. Supabase remains ahead of
`runApp` because the current auth repository requires an initialized client;
changing that lifecycle would be a larger integration rewrite outside this
focused iteration. Meaningful startup checkpoints will be emitted for bindings,
platform setup, core services, first frame, launch resolution, and destination.

## Refinement decisions

- Replace the artificial Launch pause with readiness-driven routing and a short,
  non-blocking entrance motion.
- Replace Onboarding's generic illustration cards with one editorial football
  composition and a compact pitch-inspired progress rail; keep the four truthful
  concepts and the existing persistence contract.
- Keep Auth business logic intact while unifying brand, field, CTA, keyboard and
  error presentation.
- Establish a custom floating AHDASH dock for five real destinations only:
  Home, Play, Tournaments, Teams and Profile. Guest redirects remain controlled
  by the existing capability policy. Online is excluded.

