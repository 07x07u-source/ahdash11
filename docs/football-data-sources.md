# مصادر بيانات كرة القدم والحقوق

تاريخ التحقق: 2026-08-28. الموسم المستهدف: 2026/27.  
هذه الوثيقة تسجّل مرجع التحقق فقط؛ لا تمنح حق نسخ الشعارات أو الصور أو kits، ولا تعني أن البيانات استوردت.

## الدوريات الرسمية

| الدوري | season | official_source | official club_count verified | checked_at | local seed rows in migrations | rights decision |
|---|---|---|---:|---|---:|---|
| دوري روشن السعودي | 2026/27 | https://www.spl.com.sa/en/news/spl-announces-2026-27-rsl-fixture-schedule | 18 | 2026-08-28 | 0 | names/metadata may be curated; visual is procedural fallback unless licensed |
| Premier League | 2026/27 | https://www.premierleague.com/en/clubs | 20 | 2026-08-28 | 0 | no official crest/logo import without explicit license |
| LALIGA EA SPORTS | 2026/27 | https://www.laliga.com/laliga-easports/clubes | 20 | 2026-08-28 | 0 | procedural/custom badges only by default |
| Serie A | 2026/27 | https://www.legaseriea.it/team/index | 20 | 2026-08-28 | 0 | official source validates membership, not artwork rights |
| Bundesliga | 2026/27 | https://www.bundesliga.com/en/bundesliga/clubs | 18 | 2026-08-28 | 0 | no Bundesliga/club marks bundled |
| Ligue 1 | 2026/27 | https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released | 18 | 2026-08-28 | 0 | no photography/kits/crests copied |

Official expected total across these competitions is 114 clubs. Migration `20260829000200_landscape_premium_football.sql` now seeds the verified 2026/27 catalog, and the linked Supabase RPC verified **6 leagues and 114 clubs** on 2026-08-29. The detailed source and rights record is in `football-data-sources-2026-27.md`.

## مصادر إضافية للتحقق الزمني

- SPL club licensing 2026/27 (18 clubs): https://www.spl.com.sa/ar/news/2026-2027
- Bundesliga current club listing: https://www.bundesliga.com/en/bundesliga/clubs
- Ligue 1 list of 18 club return dates: https://ligue1.com/fr/articles/l1_article_5293-les-dates-de-reprise-des-clubs-de-l1-2627
- Serie A 2026/27 promoted teams/20-team schedule context: https://en.legaseriea.it/serie-a/news/looking-forward-to-the-2026-27-serie-a-fixture-list

## سياسة seed المقترحة

كل صف يحتاج traceable record خارج visual assets:

```text
season
league_official_source
club_official_source
checked_at
name_ar
name_en
country
primary_color
secondary_color
aliases
provider_id nullable
logo_url nullable
visual_status: fallback | custom | licensed
license_reference nullable unless licensed/custom requires it
```

لا تُحفظ official logos تلقائيًا. `fallback` يعني procedural shield/initials/safe colors. `custom` يحتاج أصلًا صممه المشروع ومرجع provenance. `licensed` يحتاج عقدًا/مرجعًا واضحًا ومجال استخدام صالحًا.

## Search normalization

المطلوب للبحث فقط، مع بقاء display names الأصلية:

- إزالة التشكيل والتطويل.
- توحيد أ/إ/آ إلى ا، والياء/الألف المقصورة عند الحاجة في search key.
- Unicode/case folding للإنجليزية.
- whitespace collapse.
- aliases موثقة مثل `الهلال`/`Al Hilal`، لا استبدال اسم العرض.

Schema الحالية تمتلك `normalized_search` وtrigram indexes/RPCs، لذلك يجب تطوير الموجود وعدم إنشاء catalog مكرر.

## حدود الحقوق

- Official source يثبت membership/spelling/season فقط؛ لا يثبت ترخيص الشعار أو الصورة.
- لا player photos، kits، sponsor marks، league logos، أو crests في APK بلا license.
- `AhdashClubBadge` يجب ألا يرسم `logo_url` إلا عندما `visual_status` هو `custom` أو `licensed` ومرجع الحقوق صالح؛ خلاف ذلك procedural fallback.
- Eagle Eye لا يُفعّل بميديا حقيقية قبل rights metadata وpublish gate في Admin.

## حالة الاستيراد

| item | status |
|---|---|
| six league sources verified | Implemented (documentation) |
| league/club local seeds | Not implemented; actual count 0 |
| official logos | Not imported |
| procedural fallback architecture | Existing schema supports fallback; UI hardening required |
| remote data verification | Not performed in this local-only round |
