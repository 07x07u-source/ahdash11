# ADR 001 — حدود Flutter وFlame

- Status: Accepted
- Date: 2026-08-28

## Context

أحدعش تطبيق Flutter عربي قائم ويحتوي auth/social/store/settings ونصوص أسئلة طويلة. المطلوب game feel حقيقي مع Flame دون كسر RTL/accessibility أو نقل authority إلى rendering.

## Decision

- Flutter يحتفظ بالـshell والنص العربي والإجابات والsemantics/forms/dialogs.
- Flame يقدم gameplay stage والمؤثرات البصرية/timing presentation فقط.
- `GameSessionController` مستقل عن الاثنين ويصدر immutable view state وvisual cues.
- Supabase/Edge/PostgreSQL فقط يقرر correctness/score/rewards/rank/team results.

## Why

- Flutter أفضل لـArabic shaping/wrapping/TextScale/screen reader.
- Flame أفضل للloop/effects/particles دون animation-controller sprawl.
- controller المستقل قابل للاختبار والاستبدال ويمنع network/scoring داخل components.

## Consequences

- layering إضافي لكنه واضح.
- GameWidget لا يرسم question text الطويل.
- أي mode جديد يحتاج presenter + server contract، لا game class جديدة لكل format.
- lifecycle يجب أن ينسق controller/game/widget صراحة.

## Rejected alternatives

- Flutter-only cosmetic animations: لا يحقق vertical slice المطلوب ولا stage موحدًا.
- Flame-only UI: يضعف Arabic accessibility/forms/text scaling.
- scoring/network داخل Flame: غير قابل للاختبار ويخرق server authority.
