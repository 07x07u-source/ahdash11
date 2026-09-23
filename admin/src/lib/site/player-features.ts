export const playerFeatures = [
  { slug: "profile", title: "الملف الشخصي", description: "حدّث اسمك الظاهر واسم المستخدم." },
  { slug: "saved-games", title: "معاينات الويب", description: "نتائج محلية من لعب المتصفح التجريبي." },
  { slug: "tournaments", title: "البطولات", description: "إنشاء خروج مغلوب أو انضمام برمز." },
  { slug: "football-preferences", title: "النادي المفضل", description: "احفظ اختياراً واحداً في ملف اللاعب." },
  { slug: "premium", title: "Premium", description: "الخطط والفوائد المعتمدة فقط." },
  { slug: "report", title: "الإبلاغ عن مشكلة", description: "أرسل بلاغاً إلى فريق التشغيل." },
] as const;

export type PlayerFeatureSlug = (typeof playerFeatures)[number]["slug"];

export function getPlayerFeature(slug: string) {
  return playerFeatures.find((feature) => feature.slug === slug);
}
