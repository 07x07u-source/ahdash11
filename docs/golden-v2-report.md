# أحدعش 11 — تقرير Golden V2

تاريخ التحقق: 2026-08-29 (Asia/Riyadh).

## النتيجة

**PASS — 100/100 Golden فعّالة.**

أُجري التشغيل النهائي من مجلد `mobile` بالأمر الآتي:

```powershell
flutter test --no-pub test/visual/image_first_golden_test.dart
```

كان التشغيل النهائي تحققًا مقابل الملفات المعتمدة، ولم يستخدم `--update-goldens`. اجتازت الحالات المئة كلها. إنشاء أو تحديث الصور المرجعية عملية منفصلة، ولا يُحتسب تشغيل `--update-goldens` كدليل PASS نهائي.

مصدر المصفوفة هو [image_first_golden_test.dart](../mobile/test/visual/image_first_golden_test.dart)، ومصدر إعداد العربية وRTL هو [test_app.dart](../mobile/test/helpers/test_app.dart).

## المصفوفة الفعّالة

الحساب هو:

`10 شاشات × 5 مقاسات × ثيمين = 100 Golden`

### الشاشات

1. Home
2. Play
3. Question
4. Results
5. Teams
6. Profile
7. Settings
8. Login
9. Club Picker
10. Premium

### المقاسات

- 800×360
- 844×390
- 915×412
- 1280×720
- 1366×768

### الثيمات وإعداد الرسم

- Light وDark.
- Locale عربية واتجاه RTL.
- `devicePixelRatio = 1`.
- `disableAnimations = true` لتثبيت اللقطة.
- تحميل Tajawal وNoto Kufi Arabic داخل الـharness.
- بيانات ثابتة و`AppServices.noop` لتقليل التباين الخارجي.

## جرد الملفات على القرص

يحتوي `docs/visual-validation/goldens` على **130 PNG**، وليس 100 فقط. التفصيل:

| التصنيف | العدد | هل يستدعيه اختبار V2 الحالي؟ |
|---|---:|---|
| Golden V2 الفعّالة | 100 | نعم |
| Portrait legacy | 30 | لا |
| الإجمالي على القرص | 130 | — |

الـ30 legacy هي:

- Home: ست لقطات عند 360×800 و390×844 و412×915 في Light/Dark.
- Play: ست لقطات بالمصفوفة نفسها.
- Store: ست لقطات بالمصفوفة نفسها.
- Product: ست لقطات بالمصفوفة نفسها.
- Wallet: ست لقطات بالمصفوفة نفسها.

هذه الملفات لا تتطابق مع أي اسم يولده الـharness الحالي، ولذلك لا تدخل في نتيجة 100/100.

## التوزيع حسب الشاشة

| الشاشة | V2 فعّالة | Legacy إضافية | الموجود في `goldens` | Before Landscape قابل للمقارنة |
|---|---:|---:|---:|---:|
| Home | 10 | 6 | 16 | 10 |
| Play | 10 | 6 | 16 | 10 |
| Premium | 10 | 0 | 10 | 10 |
| Question | 10 | 0 | 10 | 0 |
| Results | 10 | 0 | 10 | 0 |
| Teams | 10 | 0 | 10 | 0 |
| Profile | 10 | 0 | 10 | 0 |
| Settings | 10 | 0 | 10 | 0 |
| Login | 10 | 0 | 10 | 0 |
| Club Picker | 10 | 0 | 10 | 0 |
| Store | 0 | 6 | 6 | 0 |
| Product | 0 | 6 | 6 | 0 |
| Wallet | 0 | 6 | 6 | 0 |
| **الإجمالي** | **100** | **30** | **130** | **30** |

## أرشيف before-v2

يحتوي `docs/visual-validation/before-v2` على **60 PNG**:

- 30 Landscape لـHome وPlay وPremium: خمس دقات × ثيمين × ثلاث شاشات.
- 30 Portrait legacy لـHome وPlay وStore وProduct وWallet: ثلاث دقات × ثيمين × خمس شاشات.

المقارنة بالاسم والـSHA-256 تعطي:

| النتيجة | العدد | التفسير |
|---|---:|---|
| تغيّر المحتوى | 30 | كل لقطات Landscape لـHome وPlay وPremium تغيّرت في V2 |
| مطابق للـbefore | 30 | ملفات Portrait legacy بقيت كما هي |
| Before بلا مقابل current | 0 | كل أسماء before ما زالت موجودة على القرص |
| Current-only | 70 | Question، Results، Teams، Profile، Settings، Login، Club Picker |

لذلك المقارنة التاريخية الصالحة لـV2 هي 30 زوجًا فقط. الصور المختارة وروابطها موجودة في [وثيقة قبل/بعد](ui-v2-before-after.md).

## تحقق سلامة الجرد

- ملفات V2 المئة المطلوبة موجودة؛ لا Golden فعّالة مفقودة.
- أسماء الملفات وأبعاد PNG الفعلية متوافقة في `before-v2` و`goldens`.
- لا توجد ملفات متطابقة hash داخل مجموعة `goldens` الحالية.
- نتيجة PASS مأخوذة من التشغيل النهائي من دون تحديث الـmasters، لا من مجرد وجود الملفات.

قد تبقى ملفات فرق تاريخية داخل `mobile/test/visual/failures` لأن Flutter لا يحذفها تلقائيًا بعد نجاح لاحق. هذه artifacts تشخيصية من تشغيلات أقدم، وليست جزءًا من matrix أو نتيجة التشغيل النهائي؛ الدليل الحاكم هو تشغيل 100/100 من دون `--update-goldens`.

## ما تثبته النتيجة

- ثبات الرسم مقابل masters المعتمدة للشاشات العشر، والمقاسات الخمسة، والثيمين.
- عدم وجود اختلاف pixel-level جديد في الحالة المجمدة المستخدمة بالاختبار.
- إنتاج العربية وRTL والخطين المحملين ضمن بيئة Flutter test.
- وجود composition صالحة للالتقاط عند المقاسات الخمسة المحددة.

## ما لا تثبته النتيجة

- لا تثبت جودة التصميم أو صحة كل icon والخطوط على GPU وجهاز Android حقيقي؛ الـGolden يقارن بالـmaster المقبول فقط.
- لا تثبت semantics أو ترتيب التركيز أو TalkBack أو قياس أهداف اللمس.
- لا تختبر text scale الكبير أو high contrast أو safe insets أو keyboard insets.
- لا تختبر الحركة الفعلية؛ جميع اللقطات تستخدم `disableAnimations = true`.
- لا تختبر 4:3 أو 16:10 أو 21:9 كقيم exact؛ النتيجة تخص المقاسات الخمسة المسماة فقط.
- لا تغطي Ranking أو Game Setup أو Onboarding أو Online Match أو Room/Online Lobby أو Team Detail.
- Question وResults تستخدمان fixture تدريب محليًا، فلا تثبتان authoritative online match أو reconnect أو timeout الخادمي.
- Login لا يثبت Google Sign-In، وPremium لا يثبت أسعار RevenueCat أو الشراء والاستعادة، والبيانات الثابتة لا تثبت Supabase live states.
- لا يوجد claim لـFPS أو frame time أو startup أو الذاكرة أو ANR؛ هذه تحتاج profile وQA على جهاز حقيقي.

## الحكم النهائي

حالة Golden V2 الآلية هي **100/100 PASS** ضمن النطاق المحدد. يجب عند ذكر عدد الملفات التمييز دائمًا بين **100 Golden فعّالة** و**130 PNG موجودة على القرص**، إذ إن الثلاثين الإضافية legacy وغير مستدعاة من الاختبار الحالي.
