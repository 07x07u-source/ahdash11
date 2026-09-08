# Auth UX repair comparison evidence

Scope: V10 screens 03 Sign In and 04 Create Account on Android.

The six requested variants are stored in `before`, `after`, `side_by_side`,
`overlay`, and `diff`. Raw results are in `metrics.csv`. Status/navigation chrome
and reference keyboard pixels are normalized; application pixels are not masked.

The post-repair layout intentionally replaces the reference's large dark empty
upper region with a compact AHDASH brand header and a warm-paper composition.
Consequently the whole-image pixel score falls for normal states even though the
physical-device blocker is corrected. This is an approved physical-usability
override required by the Auth repair brief, not an attempt to claim >=95 parity.

Android captures show Google and do not show Apple. Google uses the official
four-colour asset from Google's pre-approved Sign in with Google asset bundle:
https://developers.google.com/identity/branding-guidelines

Verification:

- Auth-focused tests and visual cases: 97/97 passed.
- Full maintained Flutter suite: 560/560 passed.
- `flutter analyze`: No issues found.
- Responsive coverage: 360x800, 390x844, 393x852, 412x915, 430x932.
- Text scale: 1.0, 1.2, 1.3.
- Keyboard inset: 0 and approximately 300 px.
