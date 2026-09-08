# AHDASH | 11 — V8.2 Pictogram Report

## الأصول

- 15 رسمًا تصويريًا بصيغة PNG نقطية حقيقية وبخلفية شفافة.
- أبعاد المصدر الرئيسي لكل رسم: 1024×1024.
- تم التحقق من المجموعة عبر لوحة اتصال في الوضع الفاتح والعكسي والذهبي.
- لا يعتمد كتالوج الشاشات على لقطات SVG.

## مقياس العرض التكيفي

| الاستخدام | النطاق المنطقي |
|---|---:|
| Inline | 32–40 |
| Helper | 52–64 |
| Compact feature | 56–72 |
| Empty state | 72–96 |
| Section identity | 72–96 |
| Result / Tournament draw | 96–128 |
| Premium | 88–112 |
| How to play | 72–104 |
| Champion | 104–152 |
| Hero | 120–160 |

أكبر عرض منطقي مستخدم هو 160؛ لذلك يبقى المصدر 1024px مناسبًا حتى لكثافات العرض المرتفعة دون اعتماد على تكبير أصل صغير.

## مسارات التحقق

- المكوّن: `mobile/lib/shared/presentation/ahdash_pictograms.dart`
- لوحة الاتصال: `docs/visual-validation/ahdash-pictograms-v2-contact-sheet.png`
