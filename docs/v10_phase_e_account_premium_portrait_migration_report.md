# V10 Phase E — Account and Premium Portrait Migration

## النتيجة

نُقلت الشاشات 38–43 إلى بنية V10 العمودية مع حالات loading/empty/error الحقيقية، وحُذفت الادعاءات أو الإحصاءات غير المدعومة من واجهة الإنتاج.

## مصادر الحقيقة

- Profile: `get_my_profile_summary` مع تفضيلات كرة القدم الاختيارية وصورة Player 11 الرمزية. لا XP أو Level أو إحصاءات مباريات/فوز في العرض.
- Notifications: `notificationsProvider` ومستودع Supabase، مع read/unread والتنقل عبر allowlist آمن. تكامل FCM البرمجي موجود للforeground وbackground-open وterminated initial message، لكن التسليم الفعلي لم يُعتمد على جهاز في هذه المرحلة.
- Settings: تفضيلات الصوت والاهتزاز وتقليل الحركة محفوظة محليًا عبر provider، وتفضيلات الإشعارات محفوظة في `notification_preferences`. لا Power Saving أو Dark Mode أو Coins/Wallet. تسجيل الخروج ينظف FCM وRevenueCat وهوية crash reporter ثم جلسة Supabase.
- Report: RPC `submit_user_problem_report`، مع sanitization وحد 1500 حرف، حماية من النقر المزدوج وحالة timeout غير مؤكدة. migration الحالية تفرض 5 بلاغات لكل مستخدم خلال 24 ساعة.
- Football: RPCs `list_football_leagues` و`search_football_clubs` و`get/set_my_football_preferences`. البحث حقيقي، الحفظ مؤكد قبل رسالة النجاح، والوسائط لا تُعرض إلا عند `licensed/custom` وإلا تُستخدم شارة إجرائية مستقرة.
- Premium: RevenueCat offering الحالي وentitlement المعرّف في `AppConfig` (الافتراضي `premium`). الشهري والسنوي يُعرضان فقط إذا أعادهما المتجر، وبـ`priceString` المحلي؛ لا سعر أو عملة أو خصم أو توفير ثابت.

## Premium

- التدفق يدعم التحميل والشراء والإلغاء والفشل والاستعادة وتحديث entitlement. الحالة غير المؤكدة لا تمنح صلاحية.
- الاستعادة تستخدم `Purchases.restorePurchases` وتعلن النجاح فقط إذا ظهر entitlement نشط.
- تبديل الحساب محمي بـepoch ومعرّف الحساب، وsign-out يستدعي `Purchases.logOut`.
- الفوائد الظاهرة مقتصرة على وصف اشتراك رقمي غير تنافسي. لا ad-free أو catalog unlock أو تحليلات أو أي pay-to-win.
- `/store` يعرض Premium و`/wallet` يحوّل إلى `/store`.

## التحقق

- مصفوفة RTL: الأحجام الخمسة مع text scale 1.0 و1.2 و1.3.
- Keyboard: Report وFootball Search عند 360×800 و390×844.
- Goldens: 18/18، تشمل empty وkeyboard وPremium loading، وتمت مراجعة الصور الخام المطلوبة.
- اختبارات Phase E المركزة: 24/24.
- Google auth بقي على تكامله الحالي. كود Apple موجود، لكن إعداد Apple Developer/Supabase والتحقق على جهاز حقيقي ما زالا خارج هذه المرحلة.
- لا ادعاء باعتماد شراء RevenueCat أو FCM على جهاز فعلي.
