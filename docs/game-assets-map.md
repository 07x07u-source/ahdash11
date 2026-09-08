# خريطة أصول اللعبة

آخر تحديث: 2026-08-29.

## LANDSCAPE PREMIUM 2026-08-29

| Slot | Remote object / local fallback | Status | Rights |
|---|---|---|---|
| auth.login.hero.image | `login-hero.webp` / `assets/images/backgrounds/login_landscape_v2.webp` | published | generated-safe |
| auth.signup.hero.image | `signup-hero.webp` / login landscape artwork | published | generated-safe |
| home.hero.image | `home-hero.webp` / home background | published | generated-safe |
| play.classic.image | `play-classic.webp` / classic art | published | generated-safe |
| play.truefalse.image | `play-truefalse.webp` / true-false art | published | generated-safe |
| play.speed.image | `play-speed.webp` / speed art | published | generated-safe |
| play.ordering.image | `play-ordering.webp` / ordering art | published | generated-safe |
| play.clubguess.image | `play-clubguess.webp` / club-guess art | published | generated-safe |
| play.eagleeye.image | `play-eagleeye.png` / eagle-eye cover | published | generated-safe |
| premium.hero.image | `premium-hero.webp` / `assets/images/backgrounds/premium_landscape_v2.webp` | published | generated-safe |
| team/friends/challenge empty | corresponding `*-empty.webp` / local backgrounds | published | generated-safe |
| profile.background.image | `profile-background.webp` / local profile background | published | generated-safe |

كل URL بعيد versioned ومخزّن مؤقتًا، وكل خانة لها fallback محلي ولا تمنع فتح الشاشة عند فشل الشبكة.

## VISUAL ART-FIRST 2026-08-29

كل الأصول أدناه Local WebP إلا mark، وتُحمّل عند ظهور الشاشة مع `cacheWidth`؛ لا يجري precache للكتالوج كاملًا. الحقوق `original-generated-safe`، وطريقة الإنشاء Codex built-in ImageGen مع رفض العلامات/الأطقم/الوجوه الواقعية، ثم ضغط WebP. fallback هو النص واللون/Scrim، والـRemote store image اختياري مع Local preview ثابت.

| المجموعة | الأسماء والمسارات | الأبعاد | الأحجام بالبايت | الغرض/الشاشات | Light/Dark |
|---|---|---:|---|---|---|
| Coin | `assets/images/currency/ahdash_coin_mark.svg`, `ahdash_coin_token.webp`, `ahdash_coin_stack.webp`, `ahdash_coin_reward.webp` | vector; 512²; 720²; 720² | 997; 58,686; 94,100; 42,638 | Home/Store/Wallet/rewards | حافة/ظل + container token |
| Backgrounds | `home_background`, `play_hub_background`, `store_background`, `profile_background`, `team_background`, `leaderboard_background`, `wallet_background`, `question_background` تحت `assets/images/backgrounds/*.webp` | 768×1152 | 34,028; 64,078; 79,884; 40,084; 85,658; 29,206; 84,624; 10,880 | خلفية مميزة لكل شاشة رئيسية؛ Question هادئة | `AhdashPageBackground` scrim متكيف |
| Modes | `classic_mode_art`, `true_false_mode_art`, `speed_mode_art` تحت `assets/images/modes/*.webp` | 720×720 | 54,492; 53,604; 77,034 | Home/Play/Setup | gradient نصي ثابت |
| Store categories | `player11_cosmetics`, `profile_backgrounds`, `player_frames`, `team_patterns`, `victory_effects`, `nameplates` تحت `assets/images/store/*.webp` | 720×720 | 35,530; 55,272; 18,958; 57,200; 51,634; 32,038 | Hero/future category rails/onboarding | edge-to-edge + scrim |
| States | `store_empty`, `inventory_empty`, `insufficient_coins`, `purchase_success` تحت `assets/images/states/*.webp` | 720×720 | 33,272; 16,260; 55,274; 43,686 | Loading/empty/purchase states | داخل surface متكيف |
| Results | `victory_background`, `defeat_background`, `draw_background`, `mvp_background` تحت `assets/images/results/*.webp` | 768×1152 | 69,700; 26,520; 41,400; 52,258 | نتائج/Future MVP | scrim 0.84 |

### Product previews (20)

المسار المشترك `mobile/assets/images/store/products/`، جميعها 720×720 WebP وLocal fallback. الحقوق `original-generated-safe`؛ الـmetadata في migration يحمل المسار والحقوق والفئة.

| SKU | bytes | SKU | bytes |
|---|---:|---|---:|
| `card_tunnel_lime` | 28,304 | `card_night_pitch` | 24,244 |
| `card_gold_stage` | 26,506 | `card_sand_geometry` | 58,370 |
| `frame_tactical` | 9,690 | `frame_gold_step` | 10,830 |
| `frame_sand_cut` | 9,820 | `style_pitch_diagonal` | 23,362 |
| `style_nocturne_split` | 7,276 | `style_desert_blocks` | 22,326 |
| `style_stadium_wave` | 35,026 | `team_tactics` | 20,844 |
| `team_sadu_step` | 13,420 | `team_stadium_wave` | 24,124 |
| `victory_lime_spiral` | 25,498 | `victory_gold_prism` | 25,540 |
| `nameplate_tactical` | 9,852 | `nameplate_majlis_gold` | 14,842 |
| `answer_effect_pitch_pulse` | 48,856 | `lobby_tactical_room` | 28,222 |

Runtime assets لهذه الجولة (باستثناء مصدر token غير المعلن): قرابة 1.78 MiB. `tooling/generate_store_product_art.py` يعيد إنتاج product derivatives من الأصول المقبولة. ملخص prompt العام: premium Saudi-inspired football-game 2.5D/vector-like artwork، charcoal/lime/warm gold/sand، stadium/tactical geometry، no text, real people, official logos, kits, sponsors, watermark or phone mockups.

## Baseline الموجود

| name | path | type | purpose | dimensions_or_vector | file_size | rights_status | source_or_generation_method | where_used | fallback |
|---|---|---|---|---|---:|---|---|---|---|
| app icon | `mobile/assets/branding/app-icon.png` | PNG | launcher/runtime brand | 1254×1254 | 1,132,383 | custom (project-provided; verify source archive) | supplied brand package | launcher + some UI | logo symbol |
| brand guidelines | `mobile/assets/branding/brand-guidelines.png` | PNG | documentation reference | 1448×1086 | 1,169,560 | custom | supplied brand package | not intended runtime | docs only |
| brand pattern | `mobile/assets/branding/brand-pattern.png` | PNG | abstract background | 2172×724 | 1,191,265 | custom | supplied brand package | BrandScaffold | procedural geometry |
| horizontal logo | `mobile/assets/branding/logo-horizontal.png` | PNG | horizontal identity | 2172×724 | 260,582 | custom | supplied brand package | limited/possibly unused | wordmark + symbol |
| logo symbol | `mobile/assets/branding/logo-symbol.png` | PNG | compact brand | 1254×1254 | 476,723 | custom | supplied brand package | auth/launcher/avatar fallback | text 11 |
| wordmark | `mobile/assets/branding/logo-wordmark.png` | PNG | wordmark | 2172×724 | 250,983 | custom | supplied brand package | limited/possibly unused | text |
| Eagle Eye cover | `mobile/assets/visuals/eagle-eye-cover.png` | PNG | prior promotional visual | 1122×1402 | 2,011,157 | generated-safe assumed; provenance needs confirmation | existing project asset | mode preview | code-native icon |
| home hero | `mobile/assets/visuals/home-hero.png` | PNG | prior home poster | 1824×862 | 1,580,548 | generated-safe assumed; provenance needs confirmation | existing project asset | Home | procedural game stage |
| Player 11 stadium hero | `mobile/assets/visuals/player_11_stadium_hero.png` | PNG | prior profile/social poster | 1672×941 | 1,575,683 | generated-safe assumed; provenance needs confirmation | existing project asset | Profile/Social | compact mascot |
| results backdrop | `mobile/assets/visuals/results-backdrop.png` | PNG | prior results poster | 1570×1002 | 1,589,705 | generated-safe assumed; provenance needs confirmation | existing project asset | Results | procedural result energy |

Baseline: 11 files including `ASSET_MAP.txt`, 11,239,159 bytes / 10.72 MiB. Release APK baseline 83,487,790 bytes / 79.62 MiB.

## Assets المطلوبة/المخططة

| name | target path/type | status | rights/generation | intended use | fallback |
|---|---|---|---|---|---|
| player11_male | `mobile/assets/player11/player11-male-card.png` (1024×1536, 2,115,482 bytes) | Implemented | built-in ImageGen, original fictional 3D character, no real-person likeness, club, sponsor, badge, or trademark | onboarding/settings and the local Player11 fallback used across profile/home/social | football icon if decoding fails |
| player11_female | `mobile/assets/player11/player11-female-card.png` (1024×1536, 1,893,746 bytes) | Implemented | built-in ImageGen + targeted removal of an extra character and logo-like shoe marks; original fictional 3D character, no real-person likeness, club, sponsor, badge, or trademark | onboarding/settings and the local Player11 fallback used across profile/home/social | football icon if decoding fails |
| mode icons | code-native Material icons | Implemented | SDK-provided icons، بلا ملفات طرف ثالث | Play Hub/HUD | text labels remain authoritative |
| gameplay particles | procedural Flame shapes | Implemented | code-generated bounded visual burst | correct verdict/game feedback | zero particles under reduced motion |
| club/team badges | procedural Flutter geometry/initials | Implemented | server gates real logo URL to `custom|licensed`; otherwise initials/safe colors | picker/team/profile | text initials |

لا تُنشأ 30 صورة لمجرد ملء القائمة. الأصل يضاف فقط إذا استخدم فعليًا. لا logos/players/kits/sponsors حقيقية.

## سجل توليد Player11

- Method: Codex built-in ImageGen (`stylized-concept`), 2026-08-28. The final project files are opaque character-card artwork rather than claimed transparent cutouts: the built-in transparency attempts produced a baked checkerboard and were rejected after inspecting the PNG pixel format.
- Male prompt summary: fictional Saudi-inspired male football-quiz mascot, premium friendly 3D style, emerald/sand/gold palette, plain football, full-body framing, warm sand studio card, abstract pitch arc; no text, logo, badge, trademark, official kit, watermark, or real-person likeness.
- Female prompt summary: fictional Saudi-inspired female football-quiz mascot in modest athletic wear and sports hijab, matching 3D/palette/framing; an edit removed the accidentally generated extra character, another removed logo-like shoe markings, and the final edit supplied an intentional opaque sand card background.
- Rights status: newly generated original project artwork. It intentionally avoids real players, official club/national kits, sponsor marks, and protected crests. Human review is still required before commercial publication, as with every generated visual.
- SHA-256: male `E12C0929598CA470AC21912BEBD56C6CE3B16BA32A01DA48B3EDDB9EAFB0663D`; female `2349A7D589A4F59296101449E5131C1F3F6F7724264788D0D053DE2B025C6C95`.

## Budget

- target final APK <100MB إن أمكن؛ hard review قبل 110MB.
- target delta <20MB فوق baseline إلا بتبرير.
- large runtime PNGs تحتاج decode sizing أو derivatives؛ documentation-only assets يجب ألا تبقى في runtime bundle عند إثبات عدم استخدامها.
- لا حذف للأصل قبل route/use audit، ولا optimization بخسارة غير قابلة للعكس دون حفظ المصدر.
