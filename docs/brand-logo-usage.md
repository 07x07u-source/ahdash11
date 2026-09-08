# استخدام شعار أحدعش

## المصدر والربط

- `branding.logo.primary`: lockup الافتراضي.
- `branding.logo.light`: عند نشر أصل مخصص لسطح فاتح.
- `branding.logo.dark`: عند نشر أصل مخصص لسطح داكن.
- `branding.logo.mark`: الرمز الصغير.
- `AhdashBrandLogo` يقرأ Branding Center، ثم يستخدم PNG الرسمي المحلي فقط كـfallback.

## أين يظهر

- Lockup: Login، Home masthead، How to Play، Launch/About.
- Mark: rail، Profile header، Tournament، Champion، Premium، loading.
- Share cards تستخدم الأصل نفسه عند توليدها؛ لا يعاد رسم 11 بالنص أو canvas.

## قواعد

- حافظ على فراغ لا يقل بصريًا عن ربع ارتفاع الشعار حوله.
- لا تمدد الشعار ولا تعيد تلوينه ولا تضف shadow/glow.
- لا تجمع lockup وكتابة «أحدعش | 11» يدويًا في المرساة نفسها.
- على السطح الداكن، استخدم الأصل المنشور الملائم؛ fallback الأفقي يوضع على backplate ورقي. الرمز الرسمي يعمل مستقلًا.
- النسخ الثلاث داخل brand-package/mobile/admin متطابقة بالـSHA-256، وهي deployment copies وليست هويات مكررة.

