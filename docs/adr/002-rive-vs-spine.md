# ADR 002 — Rive مقابل Spine لشخصية Player 11

- Status: Accepted — Static fallback now, Rive-ready later
- Date: 2026-08-28

## Context

المطلوب Player 11 ذكر/أنثى وحالات متعددة. المشروع لا يحتوي `.riv` أو Spine project/license، ولا workflow animation جاهزًا.

## Comparison

| criterion | Rive | Spine |
|---|---|---|
| Flutter support | runtime رسمي حديث + state machines | runtime متاح لكن workflow موجّه أكثر للـskeletal game animation |
| Flame integration | يمكن كـFlutter overlay؛ canvas integration عند الحاجة | تكامل game canvas ممكن لكنه يزيد coupling |
| State control | مناسب لشخصية vector-like وUI states | ممتاز للskeletal animation المعقدة |
| Licensing | runtime مفتوح المصدر، لكن asset/editor/workflow يجب التحقق منه | Spine runtime/editor licensing أكثر تقييدًا ويحتاج مراجعة دقيقة |
| Bundle/maintenance | native runtime يزيد الحجم، ولا معنى له بلا `.riv` | runtime/assets/workflow أكبر من حاجة mascot UI الحالية |
| Current assets | لا `.riv` | لا Spine project |

## Decision

- لا تضاف أي dependency الآن.
- نستخدم static/generated-safe male/female foundation موثقة، مع transitions بسيطة.
- Rive هو الاتجاه المفضل مستقبلًا فقط عند تسليم `.riv` أصلي/مرخص يحتوي state machine للحالات المطلوبة ويمر lifecycle/size QA.
- لا نضيف Rive وSpine معًا، ولا نقول Rive completed.

## Revisit criteria

1. `.riv` فعلي مع provenance/license.
2. state machine: idle/ready/thinking/correct/wrong/win/loss/MVP/level-up.
3. male/female coverage.
4. disposal/reduced-motion behavior.
5. APK size delta مقاس ومقبول.

## Consequences

- states المتحركة الكاملة `Partial` حاليًا.
- static fallback آمن وأخف ويمنع إضافة runtime بلا قيمة.
