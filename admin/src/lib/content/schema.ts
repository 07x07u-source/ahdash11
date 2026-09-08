import { z } from "zod";

export const contentKeySchema = z.string().regex(/^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*){1,4}$/);

export const contentDraftSchema = z.object({
  action: z.literal("save"),
  key: contentKeySchema,
  valueAr: z.string().trim().max(1_000).nullable(),
  mediaId: z.string().uuid().nullable(),
});

export const contentResetSchema = z.object({
  action: z.literal("reset"),
  key: contentKeySchema,
});

export const contentPublishSchema = z.object({
  action: z.literal("publish"),
  key: contentKeySchema,
});

export const contentMutationSchema = z.discriminatedUnion("action", [
  contentDraftSchema,
  contentResetSchema,
  contentPublishSchema,
]);

export const categoryContentSchema = z.object({
  descriptionAr: z.string().trim().max(500).nullable(),
  coverMediaId: z.string().uuid().nullable(),
  focalX: z.number().min(0).max(1).default(0.5),
  focalY: z.number().min(0).max(1).default(0.5),
});

const categoryFieldsSchema = z.object({
  nameAr: z.string().trim().min(1).max(80),
  slug: z.string().trim().toLowerCase().regex(/^[a-z0-9][a-z0-9_-]{1,63}$/),
  parentId: z.string().uuid().nullable(),
  iconKey: z.string().trim().max(64).nullable(),
  descriptionAr: z.string().trim().max(500).nullable(),
  isActive: z.boolean(),
  groupKey: z.enum(["saudi", "leagues", "clubs", "competitions", "national_teams", "players", "history", "images", "audio_video", "tactics", "other"]).default("other"),
  seasonLabel: z.string().trim().min(1).max(40).nullable().default(null),
  questionFormats: z.array(z.enum(["open_answer", "multiple_choice", "true_false", "image", "zoom_image", "focus_memory", "audio", "reversed_audio", "video", "career_path", "player_number", "first_name", "player_crop", "silhouette", "club_league", "kit", "ordering", "multi_clue", "hidden_player", "drawing"])).min(1).max(16).default(["open_answer"]),
  favoriteEligible: z.boolean().default(true),
  accessTier: z.enum(["free", "premium"]).default("free"),
  featured: z.boolean().default(false),
  isNew: z.boolean().default(false),
  editorialStatus: z.enum(["draft", "review", "published", "archived"]).default("published"),
  freeRotation: z.boolean().default(false),
});

export const categoryCreateSchema = categoryFieldsSchema;

export const categoryUpdateSchema = categoryFieldsSchema.extend({
  sortOrder: z.number().int().min(0).max(100_000),
});

export interface LocalContentDefinition {
  key: string;
  section: string;
  contentType: "text" | "image" | "text_image";
  labelAr: string;
  usageAr: string;
  defaultTextAr: string | null;
  minLength: number;
  maxLength: number;
}

export const localContentDefinitions: LocalContentDefinition[] = [
  { key: "home.hero.title", section: "home", contentType: "text", labelAr: "عنوان الواجهة الرئيسية", usageAr: "العنوان الكبير داخل صورة البداية", defaultTextAr: "مستعد تثبت إنك تعرف الكورة؟", minLength: 3, maxLength: 70 },
  { key: "home.hero.subtitle", section: "home", contentType: "text", labelAr: "وصف الواجهة الرئيسية", usageAr: "الشارة المختصرة أعلى عنوان البداية", defaultTextAr: "15 سؤال • دقايق قليلة", minLength: 3, maxLength: 80 },
  { key: "home.hero.image", section: "home", contentType: "image", labelAr: "صورة الواجهة الرئيسية", usageAr: "الخلفية البصرية لبطاقة بدء التحدي", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "home.featured.title", section: "home", contentType: "text", labelAr: "عنوان التحدي المميز", usageAr: "عنوان بطاقة التحدي اليومية", defaultTextAr: "تحدي اليوم", minLength: 3, maxLength: 50 },
  { key: "home.featured.description", section: "home", contentType: "text", labelAr: "وصف التحدي المميز", usageAr: "الوصف أسفل عنوان التحدي اليومية", defaultTextAr: "5 أسئلة ومكافأة تنتظرك", minLength: 3, maxLength: 120 },
  { key: "premium.hero.title", section: "premium", contentType: "text", labelAr: "عنوان Premium", usageAr: "عنوان بطاقة الاشتراك في المتجر", defaultTextAr: "11 Premium", minLength: 3, maxLength: 50 },
  { key: "premium.hero.subtitle", section: "premium", contentType: "text", labelAr: "وصف Premium", usageAr: "وصف مزايا الاشتراك في المتجر", defaultTextAr: "بدون إعلانات • مزايا تجميلية • إحصائيات أوسع", minLength: 3, maxLength: 160 },
  { key: "premium.hero.image", section: "premium", contentType: "image", labelAr: "صورة Premium", usageAr: "خلفية بطاقة الاشتراك في المتجر", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "store.banner.title", section: "store", contentType: "text", labelAr: "عنوان بنر المتجر", usageAr: "عنوان الحملة الترويجية في المتجر", defaultTextAr: "ميّز حسابك", minLength: 3, maxLength: 60 },
  { key: "store.banner.subtitle", section: "store", contentType: "text", labelAr: "وصف بنر المتجر", usageAr: "النص المختصر للحملة الترويجية", defaultTextAr: "عناصر تجميلية بدون أفضلية تنافسية", minLength: 3, maxLength: 140 },
  { key: "maintenance.message", section: "system", contentType: "text", labelAr: "رسالة الصيانة", usageAr: "رسالة عامة تظهر فقط عند تفعيل وضع الصيانة", defaultTextAr: "نرجع لك قريب، نجهّز الملعب.", minLength: 3, maxLength: 180 },
  { key: "announcement.title", section: "announcements", contentType: "text", labelAr: "عنوان الإعلان", usageAr: "عنوان الإعلان الموسمي أو العام", defaultTextAr: "الجديد في أحدعش", minLength: 3, maxLength: 70 },
  { key: "announcement.description", section: "announcements", contentType: "text", labelAr: "وصف الإعلان", usageAr: "النص المختصر للإعلان الموسمي أو العام", defaultTextAr: "تابع التحديات والمواسم الجديدة.", minLength: 3, maxLength: 220 },
  { key: "announcement.image", section: "announcements", contentType: "image", labelAr: "صورة الإعلان", usageAr: "الصورة المصاحبة للإعلان العام", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.logo.primary", section: "branding", contentType: "image", labelAr: "الشعار الرئيسي", usageAr: "الشعار الأساسي داخل التطبيق", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.logo.light", section: "branding", contentType: "image", labelAr: "شعار الخلفيات الفاتحة", usageAr: "نسخة الشعار المناسبة للأسطح الفاتحة", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.logo.dark", section: "branding", contentType: "image", labelAr: "شعار الخلفيات الداكنة", usageAr: "نسخة الشعار المناسبة للأسطح الداكنة", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.logo.mark", section: "branding", contentType: "image", labelAr: "الشعار المصغر", usageAr: "رمز أحدعش في المساحات الصغيرة", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.splash.artwork", section: "branding", contentType: "image", labelAr: "صورة شاشة البداية", usageAr: "العمل البصري لشاشة Splash", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.login.artwork", section: "branding", contentType: "image", labelAr: "صورة تسجيل الدخول", usageAr: "العمل البصري في شاشة الدخول", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.placeholder.default", section: "branding", contentType: "image", labelAr: "الصورة البديلة العامة", usageAr: "Fallback آمن عند تعذر تحميل صورة", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.category.fallback", section: "branding", contentType: "image", labelAr: "صورة التصنيفات البديلة", usageAr: "Fallback للتصنيفات دون غلاف", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.store.artwork", section: "branding", contentType: "image", labelAr: "صورة المتجر", usageAr: "العمل البصري الافتراضي للمتجر", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.premium.artwork", section: "branding", contentType: "image", labelAr: "صورة Premium", usageAr: "العمل البصري الافتراضي لقسم Premium", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "branding.appicon.master", section: "app_icon", contentType: "image", labelAr: "أيقونة التطبيق المصدرية", usageAr: "مصدر 1024×1024 للإصدار القادم", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "promotions.home.image", section: "promotions", contentType: "image", labelAr: "صورة ترويج الرئيسية", usageAr: "الصورة الاختيارية للعرض الترويجي", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "promotions.seasonal.image", section: "promotions", contentType: "image", labelAr: "صورة الحملة الموسمية", usageAr: "صورة حملة آمنة الحقوق", defaultTextAr: null, minLength: 0, maxLength: 1 },
  { key: "appearance.accent.color", section: "appearance", contentType: "text", labelAr: "لون التمييز الترويجي", usageAr: "لون Hex للأسطح الترويجية فقط", defaultTextAr: "#78B814", minLength: 7, maxLength: 7 },
  { key: "feature.home.promotion", section: "feature_controls", contentType: "text", labelAr: "ترويج الرئيسية", usageAr: "إظهار البطاقة الترويجية", defaultTextAr: "false", minLength: 4, maxLength: 5 },
  { key: "feature.home.seasonal", section: "feature_controls", contentType: "text", labelAr: "الحملة الموسمية", usageAr: "إظهار الحملة الموسمية", defaultTextAr: "false", minLength: 4, maxLength: 5 },
  { key: "feature.premium.promotion", section: "feature_controls", contentType: "text", labelAr: "ترويج Premium", usageAr: "إظهار العرض دون تغيير الاستحقاق", defaultTextAr: "true", minLength: 4, maxLength: 5 },
  { key: "feature.rewarded.cta", section: "feature_controls", contentType: "text", labelAr: "دعوة الإعلان بمكافأة", usageAr: "إظهار الدعوة فقط", defaultTextAr: "false", minLength: 4, maxLength: 5 },
  { key: "feature.home.featured", section: "feature_controls", contentType: "text", labelAr: "التصنيف المميز", usageAr: "إظهار اختيار اليوم", defaultTextAr: "true", minLength: 4, maxLength: 5 },
];

export function validateDraftForDefinition(
  definition: LocalContentDefinition,
  valueAr: string | null,
  mediaId: string | null,
): { valueAr: string | null; mediaId: string | null } {
  const normalized = valueAr?.trim() || null;
  if (definition.contentType !== "image") {
    if (!normalized) throw new Error("النص مطلوب.");
    if (normalized.length < definition.minLength || normalized.length > definition.maxLength) {
      throw new Error(`طول النص يجب أن يكون بين ${definition.minLength} و${definition.maxLength} حرفًا.`);
    }
  }
  if (definition.contentType === "text" && mediaId) throw new Error("هذا الحقل لا يقبل صورة.");
  if (definition.section === "feature_controls" && normalized !== "true" && normalized !== "false") throw new Error("قيمة التحكم يجب أن تكون true أو false فقط.");
  if (definition.key === "appearance.accent.color" && !/^#[0-9A-Fa-f]{6}$/.test(normalized ?? "")) throw new Error("لون التمييز يجب أن يكون Hex من ست خانات.");
  return { valueAr: normalized, mediaId };
}
