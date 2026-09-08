# هوية Ahdash Coin

آخر تحديث: 2026-08-29

## الفكرة

عملة «أحدعش» قطعة ذهبية ذات silhouette سميكة وواضحة، تحمل الرقم `11` في المركز داخل تقسيمات هندسية مقتبسة من ألواح كرة القدم. الشق الصغير بلون Lime يربطها بلون اللعب الأساسي من دون أن يحولها إلى أيقونة صفراء عامة. لا تستخدم رمز عملة حقيقية، ولا هيئة Bitcoin، ولا شعار نادٍ أو دوري.

## الألوان والمعالجة

- ذهب دافئ: الإضاءة والحافة والقيمة.
- Charcoal: الفصل بين ألواح الكرة ورفع وضوح `11`.
- Lime محدود: notch/لمعة هوية فقط.
- Light Mode: حافة فحمية وظل محدود يمنع ذوبان الذهب على الخلفية الرملية.
- Dark Mode: حلقة ذهبية ولمعة خفيفة من دون bloom كبير.
- النسخة أحادية اللون: `ahdash_coin_mark.svg`؛ تعتمد الشكل والحافة والرقم، ولا تعتمد على texture.

## المقاسات

`AhdashCoinIcon` مصمم ليظل مقروءًا عند 16، 20، 24، 32، 48، 64 و128 بكسل. الواجهة تستخدم `cacheWidth` بحسب كثافة الشاشة. الرمز الصغير يستعمل token، والمشاهد الكبيرة تستعمل stack/reward ولا تعيد تكبير النسخة الصغيرة.

| الأصل | المسار | الأبعاد | الحجم | الاستخدام |
|---|---|---:|---:|---|
| mark | `mobile/assets/images/currency/ahdash_coin_mark.svg` | vector | 997 B | fallback أحادي اللون وتوثيق الشكل |
| token | `mobile/assets/images/currency/ahdash_coin_token.webp` | 512×512 | 58,686 B | الرصيد والسعر وسجل المحفظة |
| stack | `mobile/assets/images/currency/ahdash_coin_stack.webp` | 720×720 | 94,100 B | Hero المحفظة |
| reward | `mobile/assets/images/currency/ahdash_coin_reward.webp` | 720×720 | 42,638 B | الجوائز والتحديات |

## المكونات والاستخدام

- `AhdashCoinIcon`: الشكل الموحد الصغير مع Semantics اختيارية.
- `AhdashCoinBalance`: رصيد، count-up وscale خفيف عند الزيادة.
- `AhdashCoinPrice`: السعر في المتجر من دون Material currency icon.
- `AhdashCoinReward`: مكافأة مرئية في Home والتحديات.
- الزيادة تحترم `Reduced Motion`، ويصدر haptic خفيف عبر `FeedbackService` فقط عند زيادة حقيقية.
- مستخدمة في Home، Store، Product details، Wallet وWallet history. نجاح بناء التطبيق لا يعني أن مكافأة خادمية حدثت فعليًا.

## الحقوق وطريقة الإنشاء

الـSVG أصل code-native صُمم داخل المشروع. ملفات WebP أصلية مولدة بواسطة Codex built-in ImageGen، ثم رُفضت المحاولات ذات العلامات غير المتسقة واختيرت نسخة `11` الواضحة، وضُغطت محليًا. ملخص prompt: *premium original game coin, clear number 11, football-panel geometry, warm gold and charcoal, tiny lime notch, no currency symbol, Bitcoin form, club crest, sponsor, text or watermark*. الملفات `generated-safe` ولا تتضمن لاعبًا حقيقيًا أو علامة رسمية؛ تبقى المراجعة البشرية النهائية مطلوبة قبل النشر التجاري.

الملف `ahdash_coin_token-source.png` مصدر توليد غير معلن في `pubspec.yaml`، لذلك لا يدخل حزمة التشغيل أو APK.
