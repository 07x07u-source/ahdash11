import type { SupabaseClient } from "@supabase/supabase-js";

export interface CategoryListItem {
  id: string;
  name: string;
  slug: string;
  parentId: string | null;
  sortOrder: number;
  active: boolean;
  icon: string;
  questionCount: number;
  easyCount: number;
  mediumCount: number;
  hardCount: number;
  health: "READY" | "NEEDS QUESTIONS" | "MEDIA ISSUE" | "RIGHTS ISSUE" | "ARCHIVED";
  description: string;
  imageUrl: string | null;
  coverMediaId: string | null;
  focalX: number;
  focalY: number;
  mediaHealth: "READY" | "NO IMAGE";
  updatedAt: string;
  groupKey: string;
  seasonLabel: string | null;
  questionFormats: string[];
  favoriteEligible: boolean;
  accessTier: "free" | "premium";
  featured: boolean;
  isNew: boolean;
  editorialStatus: "draft" | "review" | "published" | "archived";
  freeRotation: boolean;
}

export type CategoryConnectionState = "live" | "partial" | "error" | "not_configured" | "demo";

export interface CategoryDataResult {
  state: CategoryConnectionState;
  rows: CategoryListItem[];
  checkedAt: string;
  detail?: string;
}

interface RawCategory {
  id: unknown;
  name_ar: unknown;
  slug: unknown;
  parent_id: unknown;
  sort_order: unknown;
  is_active: unknown;
  icon_key: unknown;
  description_ar: unknown;
  image_url: unknown;
  cover_media_id: unknown;
  cover_focal_x?: unknown;
  cover_focal_y?: unknown;
  updated_at: unknown;
  group_key?: unknown;
  season_label?: unknown;
  question_formats?: unknown;
  is_favorite_eligible?: unknown;
  access_tier?: unknown;
  is_featured?: unknown;
  is_new?: unknown;
  editorial_status?: unknown;
  is_free_rotation?: unknown;
}

export interface CategoryDataSource {
  list(): Promise<{ data: RawCategory[] | null; error: { code?: string; message?: string } | null }>;
  count(categoryId: string, isSubcategory: boolean): Promise<{ count: number | null; error: { code?: string; message?: string } | null }>;
  health?(categoryId: string, isSubcategory: boolean): Promise<{ data: Array<Record<string, unknown>> | null; error: { code?: string; message?: string } | null }>;
}

const demoPartyFields = { groupKey: "other", seasonLabel: null, questionFormats: ["open_answer"], favoriteEligible: true, accessTier: "free" as const, featured: false, isNew: false, editorialStatus: "published" as const, freeRotation: false };
const demoRows: CategoryListItem[] = [
  { ...demoPartyFields, id: "c1", name: "عين الصقر", slug: "eagle-eye", parentId: null, sortOrder: 1, active: true, icon: "eye", questionCount: 1540, easyCount: 500, mediumCount: 520, hardCount: 520, health: "MEDIA ISSUE", description: "لاحظ التفاصيل قبل الكل", imageUrl: null, coverMediaId: null, focalX: 0.5, focalY: 0.5, mediaHealth: "NO IMAGE", updatedAt: "2026-08-28T00:00:00Z" },
  { ...demoPartyFields, id: "c2", name: "سوق الانتقالات", slug: "transfers", parentId: null, sortOrder: 2, active: true, icon: "repeat", questionCount: 1280, easyCount: 420, mediumCount: 430, hardCount: 430, health: "MEDIA ISSUE", description: "اختبر ذاكرتك في الصفقات", imageUrl: null, coverMediaId: null, focalX: 0.5, focalY: 0.5, mediaHealth: "NO IMAGE", updatedAt: "2026-08-28T00:00:00Z" },
  { ...demoPartyFields, id: "c3", name: "الدوريات والبطولات", slug: "leagues", parentId: null, sortOrder: 3, active: true, icon: "trophy", questionCount: 3920, easyCount: 1300, mediumCount: 1310, hardCount: 1310, health: "MEDIA ISSUE", description: "من المحلية إلى العالمية", imageUrl: null, coverMediaId: null, focalX: 0.5, focalY: 0.5, mediaHealth: "NO IMAGE", updatedAt: "2026-08-28T00:00:00Z" },
  { ...demoPartyFields, id: "c4", name: "دوري روشن السعودي", slug: "saudi-pro-league", parentId: "c3", sortOrder: 1, active: true, icon: "trophy", questionCount: 740, easyCount: 240, mediumCount: 250, hardCount: 250, health: "MEDIA ISSUE", description: "كرة القدم السعودية", imageUrl: null, coverMediaId: null, focalX: 0.5, focalY: 0.5, mediaHealth: "NO IMAGE", updatedAt: "2026-08-28T00:00:00Z" },
];

function safeDatabaseDetail(error: { code?: string; message?: string } | null): string {
  if (!error) return "تعذر تحميل الأقسام من Supabase.";
  const code = error.code?.trim();
  return code ? `تعذر تحميل الأقسام من Supabase (رمز ${code}).` : "تعذر تحميل الأقسام من Supabase.";
}

export async function loadCategoryData(
  source: CategoryDataSource | null,
  options: { configured: boolean; demoEnabled: boolean; now?: () => Date },
): Promise<CategoryDataResult> {
  const checkedAt = (options.now?.() ?? new Date()).toISOString();
  if (options.demoEnabled) return { state: "demo", rows: demoRows, checkedAt };
  if (!options.configured || !source) {
    return { state: "not_configured", rows: [], checkedAt, detail: "متغيرات Supabase العامة غير مكتملة في بيئة Admin." };
  }

  const categories = await source.list();
  if (categories.error) {
    return { state: "error", rows: [], checkedAt, detail: safeDatabaseDetail(categories.error) };
  }

  const rawRows = categories.data ?? [];
  const counts = await Promise.all(rawRows.map((row) => source.count(String(row.id), Boolean(row.parent_id))));
  const healthRows = source.health
    ? await Promise.all(rawRows.map((row) => source.health!(String(row.id), Boolean(row.parent_id))))
    : rawRows.map(() => null);
  const countFailed = counts.some((result) => result.error);
  const rows = rawRows.map((row, index): CategoryListItem => {
    const eligible = healthRows[index]?.data ?? [];
    const easyCount = eligible.filter((question) => question.difficulty === "easy").length;
    const mediumCount = eligible.filter((question) => question.difficulty === "medium").length;
    const hardCount = eligible.filter((question) => question.difficulty === "hard" || question.difficulty === "expert").length;
    const mediaIssue = eligible.some((question) => question.question_type === "image" && !question.image_url);
    const rightsIssue = eligible.some((question) => question.question_type === "image" && !["original", "generated", "licensed"].includes(String(question.media_rights_status)));
    const health: CategoryListItem["health"] = !Boolean(row.is_active) ? "ARCHIVED" : rightsIssue ? "RIGHTS ISSUE" : mediaIssue ? "MEDIA ISSUE" : easyCount >= 2 && mediumCount >= 2 && hardCount >= 2 ? "READY" : "NEEDS QUESTIONS";
    return {
    id: String(row.id),
    name: String(row.name_ar),
    slug: String(row.slug),
    parentId: row.parent_id ? String(row.parent_id) : null,
    sortOrder: Number(row.sort_order ?? 0),
    active: Boolean(row.is_active),
    icon: String(row.icon_key ?? "folder"),
    questionCount: counts[index]?.error ? 0 : Number(counts[index]?.count ?? 0),
    easyCount,
    mediumCount,
    hardCount,
    health,
    description: String(row.description_ar ?? ""),
    imageUrl: row.image_url ? String(row.image_url) : null,
    coverMediaId: row.cover_media_id ? String(row.cover_media_id) : null,
    focalX: Number(row.cover_focal_x ?? 0.5),
    focalY: Number(row.cover_focal_y ?? 0.5),
    mediaHealth: row.cover_media_id && row.image_url ? "READY" : "NO IMAGE",
    updatedAt: String(row.updated_at ?? checkedAt),
    groupKey: String(row.group_key ?? "other"),
    seasonLabel: row.season_label ? String(row.season_label) : null,
    questionFormats: Array.isArray(row.question_formats) ? row.question_formats.map(String) : ["open_answer"],
    favoriteEligible: row.is_favorite_eligible === undefined ? true : Boolean(row.is_favorite_eligible),
    accessTier: row.access_tier === "premium" ? "premium" : "free",
    featured: Boolean(row.is_featured),
    isNew: Boolean(row.is_new),
    editorialStatus: ["draft", "review", "archived"].includes(String(row.editorial_status)) ? String(row.editorial_status) as CategoryListItem["editorialStatus"] : "published",
    freeRotation: Boolean(row.is_free_rotation),
    };
  });

  return {
    state: countFailed ? "partial" : "live",
    rows,
    checkedAt,
    detail: countFailed ? "تم تحميل الأقسام، لكن تعذر تحديث عدّاد بعض الأسئلة بسبب صلاحيات القراءة." : undefined,
  };
}

export function createSupabaseCategoryDataSource(client: SupabaseClient): CategoryDataSource {
  return {
    async list() {
      const result = await client
        .from("categories")
        .select("id, name_ar, slug, parent_id, sort_order, is_active, icon_key, description_ar, image_url, cover_media_id, cover_focal_x, cover_focal_y, updated_at, group_key, season_label, question_formats, is_favorite_eligible, access_tier, is_featured, is_new, editorial_status, is_free_rotation")
        .order("parent_id", { ascending: true, nullsFirst: true })
        .order("sort_order", { ascending: true });
      if (result.error?.code === "42703") {
        const legacy = await client
          .from("categories")
          .select("id, name_ar, slug, parent_id, sort_order, is_active, icon_key, description_ar, image_url, cover_media_id, updated_at")
          .order("parent_id", { ascending: true, nullsFirst: true })
          .order("sort_order", { ascending: true });
        return { data: legacy.data as RawCategory[] | null, error: legacy.error };
      }
      return { data: result.data as RawCategory[] | null, error: result.error };
    },
    async count(categoryId, isSubcategory) {
      const column = isSubcategory ? "subcategory_id" : "category_id";
      const result = await client.from("questions").select("id", { count: "exact", head: true }).eq(column, categoryId);
      return { count: result.count, error: result.error };
    },
    async health(categoryId, isSubcategory) {
      const column = isSubcategory ? "subcategory_id" : "category_id";
      const result = await client
        .from("questions")
        .select("difficulty, question_type, image_url, media_rights_status")
        .eq(column, categoryId)
        .eq("status", "published")
        .eq("needs_review", false)
        .eq("offline_practice_eligible", true)
        .eq("competitive_eligible", false);
      return { data: result.data as Array<Record<string, unknown>> | null, error: result.error };
    },
  };
}
