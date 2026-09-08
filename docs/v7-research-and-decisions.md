# أحدعش | 11 — بحث وقرارات V7

تاريخ التحقق: 2026-09-01

## الخلاصة التنفيذية

V7 ليست إعادة تلوين لـV6. القرار هو إعادة بناء التكوين المرئي حول فعل واحد واضح في كل شاشة، مع إبقاء عقود البيانات ومحركات Party والبطولات وSupabase وFirebase وRevenueCat كما هي. Material 3 يبقى أساسًا تقنيًا، بينما تأتي شخصية المنتج من Thmanyah، الأصول القانونية لأحدعش، الورق الدافئ والحبر، صور كرة القدم، وأيقونات متوازنة.

## بحث المنتج

تمت مراجعة المصادر العامة الرسمية التالية:

- [Seen Jeem — الموقع الرسمي](https://seenjeemsa.com/)
- [Seen Jeem — بدء اللعبة](https://seenjeemsa.com/start-game)
- [Seen Jeem — Google Play](https://play.google.com/store/apps/details?id=com.seenjeem.challengeapp&hl=ar)
- [Seen Jeem — Apple App Store](https://apps.apple.com/sa/app/%D8%B3%D9%8A%D9%86-%D8%AC%D9%8A%D9%85-seen-jeem/id6479301314)

المبدأ المفيد هو وضوح اللعبة الجماعية: ست فئات، 36 سؤالًا، فريقان وثلاث وسائل مساعدة لكل فريق. لا تُنسخ الشاشة أو الألوان أو النصوص أو الأصول أو الـtrade dress. أحدعش تستخدم البساطة نفسها كقاعدة منتج، ثم تقدم تكوينًا أصليًا سعوديًا وكرويًا.

## Material 3 وFlutter

المصادر:

- [Flutter Material](https://docs.flutter.dev/ui/design/material)
- [Flutter themes cookbook](https://docs.flutter.dev/cookbook/design/themes)
- [Material 3 default migration](https://docs.flutter.dev/release/breaking-changes/material-3-default)

القرار:

- يبقى `useMaterial3: true`.
- `ColorScheme` و`TextTheme` وcomponent themes هي مصدر الحقيقة، مع `ThemeExtension` لألوان أحدعش الدلالية.
- لا نعتمد المظهر الافتراضي للمكونات، ولا يُسمح بظهور أزرق/بنفسجي افتراضي.
- تكتمل ثيمات `checkbox` و`radio` و`chip` و`tooltip` و`segmented button` و`tab bar` و`icon` في V7.
- تُستخدم البطاقات فقط عند وجود معنى للتجميع، وليس كحاوية افتراضية لكل شيء.

## الخط

فُحصت ملفات OTF المحلية الفعلية باستخدام metadata داخل الخط. العائلات والأوزان المتاحة:

- `ThmanyahSans`: Light 300، Regular 400، Medium 500، Bold 700، Black 900.
- `ThmanyahSerifDisplay`: Light 300، Regular 400، Medium 500، Bold 700، Black 900.
- `ThmanyahSerifText`: Light 300، Regular 400، Medium 500، Bold 700، Black 900.

تسجيل `pubspec.yaml` يطابق الملفات الفعلية. `ThmanyahSans` هو خط الواجهة. `ThmanyahSerifDisplay` محصور في لحظة بطل/نهائي/عنوان افتتاحي خاص. لا يُعاد تسمية الملفات ولا تُحمّل خطوط بديلة.

## الشعار

المصدر القانوني المحلي المعتمد:

- `mobile/assets/branding/logo-horizontal.png`
- `mobile/assets/branding/logo-symbol.png`
- `mobile/assets/branding/logo-wordmark.png`

الأصول مطابقة لنسخ حزمة العلامة ولوحة الإدارة. لا يوجد SVG قانوني معتمد؛ لذلك لن يُنشأ SVG بديل. تبقى فتحات Branding Center البعيدة مصدرًا أعلى عند توافرها، مع fallback محلي آمن.

## الأيقونات

المصادر:

- [Flutter CupertinoIcons](https://api.flutter.dev/flutter/cupertino/CupertinoIcons-class.html)
- [Apple SF Symbols](https://developer.apple.com/sf-symbols/)
- [Apple HIG — SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)

الحالة الحالية: 322 مرجعًا إلى `Icons.*` ولا يوجد استخدام لـ`CupertinoIcons` داخل `mobile/lib`.

القرار:

- إنشاء mapping دلالي مركزي `AhdashIcons` واستخدام `CupertinoIcons` حيث يوجد مكافئ واضح.
- outline للحالة العادية وfilled/أقوى للحالة المختارة.
- الحد المرئي غالبًا 18–24، والهدف التفاعلي لا يقل عن 44×44 تقريبًا.
- الاتجاهات تستخدم رموزًا/تحويلات تحترم RTL.
- لا يتم تصدير SF Symbols كصور إلى Android، ولا خلط emoji مع Material filled وCupertino في التدفق نفسه.

## الحركة

المصدر: [flutter_animate](https://pub.dev/packages/flutter_animate)

الحزمة غير موجودة حاليًا. ستضاف فقط عندما تستخدمها أول شاشة مرجعية استخدامًا حقيقيًا. الاستخدام المعتمد: دخول الشعار/العنوان، تبدّل اختيار الفئة، دخول السؤال، كشف النتيجة، وكشف قرعة البطولة. لا loops مستمرة ولا shimmer دائم. جميع التأثيرات تحترم `MediaQuery.disableAnimations` وإعداد reduced motion.

## Rive

المصادر:

- [Rive](https://rive.app/)
- [Rive Flutter package](https://pub.dev/packages/rive)

لا يوجد ملف `.riv` حقيقي في أصول المشروع. لذلك لا تضاف الحزمة ولا يُخترع binary. القرار الحالي: `RIVE ASSET REQUIRED` للحظات loader/قرعة/بطل فقط، مع fallback ثابت أو Flutter animation بسيط. لا يصبح غياب Rive مانعًا للعبة.

## الصوت والاهتزاز

المصدر: [audioplayers](https://pub.dev/packages/audioplayers)

لا يوجد أصل صوتي محلي مرخص في المشروع، و`audioplayers` غير مضافة. الموجود حاليًا `AppFeedbackService` مركزي يستخدم `SystemSound` و`HapticFeedback` ويحترم الإعدادات. القرار:

- لا يُنشأ `AudioPlayer` داخل widget.
- إضافة `AhdashAudioService` و`audioplayers` مؤجلة حتى إدخال SFX أصلية/مرخصة فعلية.
- السؤال الصوتي له قناة مستقلة عن UI/Game SFX عند وصول أصوله.
- فشل الصوت أو الاهتزاز لا يوقف اللعبة.
- يُفصل wrapper دلالي للاهتزاز عن اختيار نوع التأثير.

## الصور والكاش

المصدر: [cached_network_image](https://pub.dev/packages/cached_network_image)

الحزمة موجودة. `AhdashImage` يفرق بين asset وremote، يحافظ على aspect ratio، يدعم focal alignment وfallback و`memCacheWidth/Height`. توجد استثناءات مباشرة (`Image.network` و`NetworkImage`) في auth/profile/shared components وستوحد عند إعادة بناء الشاشات.

القرار: remote فقط عبر cached image abstraction؛ asset محلي عبر `Image.asset`. لا spinner دائري داخل كل صورة، ولا broken-image icon في المسار الأساسي، ولا تحميل full-res داخل tile صغير.

## Riverpod

المصدر: [Riverpod](https://riverpod.dev/)

الحالة الحالية جيدة نسبيًا: خدمات، repositories، المحتوى، Party، البطولة، الحساب، المتجر والإعدادات لها providers واضحة. القرار هو consolidation محدود لا إعادة هندسة: state العابر البصري يبقى محليًا، وstate المنتج/الشبكة/المحرك يبقى في providers قابلة للاستبدال في الاختبار. نستخدم `select` فقط عندما يثبت أن rebuild واسعًا.

## go_router

المصدر: [go_router](https://pub.dev/packages/go_router)

الخريطة الحالية مركزية لكنها مسطحة ولا تحتوي redirects للمصادقة. `/wallet` يعيد إلى `/store`. القرار:

- الحفاظ على الروابط الحالية أثناء إعادة البناء.
- إزالة/إخفاء legacy public routes تدريجيًا عبر redirects صريحة بدل كسر deep links.
- لا ننقل navigation state إلى SharedPreferences.
- اختبارات redirects وpath/query parameters مطلوبة قبل أي حذف فعلي.

## Firebase Analytics وCrashlytics

المصادر:

- [Firebase Analytics events for Flutter](https://firebase.google.com/docs/analytics/flutter/events)
- [Customize Crashlytics reports for Flutter](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports)

المشروع يملك abstractions فعلية `AnalyticsService` و`CrashReporter` مع Noop/Firebase implementations. كما يسجل `FlutterError.onError` و`PlatformDispatcher.instance.onError`.

القرار:

- taxonomy صغيرة تجيب أسئلة المنتج: بدء Party، اختيار الفئة، random، الانسحاب قبل البداية، format، إنشاء/إكمال بطولة، ظهور/تحول premium.
- لا نسجل نص السؤال أو البريد أو الاسم أو room code أو أي PII.
- non-fatal متوقع للصورة/الصوت/analytics لا يملأ Crashlytics؛ الأعطال غير المتوقعة فقط مع سياق آمن.

## SharedPreferences

المصدر: [shared_preferences](https://pub.dev/packages/shared_preferences)

الحزمة المحلية `^2.5.3`. الوثائق الحالية توصي `SharedPreferencesAsync` أو `SharedPreferencesWithCache` للكود الجديد، ولا تعتبرها مخزنًا للبيانات الحرجة.

المفاتيح الحالية:

- `appearance_theme`
- `sound_effects_enabled`
- `haptics_enabled`
- `reduced_motion_enabled`
- `player11_variant`

توجد استخدامات إضافية للـonboarding وdevelopment auth والإعلانات. القرار: تنتقل تفضيلات UI البسيطة إلى repository واحد مبني على API الحديثة عند مرحلة الاعتمادية. لا تُحفظ المباراة أو البطولة أو النتائج أو أرصدة المستخدم أو أسرار المصادقة في SharedPreferences.

## قرار الاعتمادات النهائي لهذه المرحلة

| الأداة | الحالة المحلية | قرار V7 |
|---|---|---|
| Material 3 | موجود | توسيع الثيم المركزي |
| Cupertino Icons | موجود | mapping دلالي واستخدام فعلي |
| flutter_animate | غير موجود | يضاف مع أول استخدام مرجعي فقط |
| Rive | غير موجود ولا `.riv` | لا يضاف؛ `RIVE ASSET REQUIRED` |
| audioplayers | غير موجود ولا ملفات صوت | مؤجل إلى أصول مرخصة فعلية |
| cached_network_image | موجود | توحيد كل remote surfaces |
| Riverpod | موجود | consolidation محدود |
| go_router | موجود | redirects/legacy audit دون كسر الروابط |
| Firebase Analytics | موجود خلف abstraction | taxonomy صغيرة وآمنة |
| Crashlytics | موجود خلف abstraction | unexpected only |
| shared_preferences | موجود | API حديثة لتفضيلات بسيطة فقط |

