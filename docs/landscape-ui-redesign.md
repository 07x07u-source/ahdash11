# Landscape UI Redesign

آخر تحديث: 2026-08-29.

التطبيق مقفل على `landscapeLeft` و`landscapeRight`. المقاييس المركزية في `mobile/lib/shared/presentation/landscape_layout.dart` تقسم العرض إلى compact/standard/large وتضبط الـgutter والفواصل وعرض الألواح. أصبح التنقل Dock جانبيًا ثابتًا مع RTL بدل Bottom Navigation.

التنفيذ الفعلي يشمل Home ثنائي اللوحات، Play بشبكة 3×2، Question بتقسيم السؤال/الإجابات وإجابات 2×2 عند المساحة المناسبة، Auth بتقسيم الهوية والنموذج، Settings بقائمة أقسام جانبية، وPremium بهوية ومزايا وخطط في لوحتين. الصور البعيدة تستخدم fallback محليًا دائمًا.

مصفوفة التحقق البصري: 800×360، 844×390، 915×412، 1280×720، 1366×768، في Light وDark. توجد 30 golden لصالح Home/Play/Premium. لا يوجد ادعاء بقياس FPS لأن ذلك يحتاج جهازًا حقيقيًا.

قواعد الوصول: RTL عربي أصلي، لا دلالة لونية منفردة في الإجابات، أهداف لمس مناسبة، Reduced Motion محترم، والنص الكبير ينتقل إلى scrolling آمن عند الحاجة.
