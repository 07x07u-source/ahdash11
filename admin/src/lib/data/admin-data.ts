import "server-only";

import {
  createSupabaseCategoryDataSource,
  loadCategoryData,
  type CategoryDataResult,
} from "@/lib/data/category-data";
import { hasSupabaseConfig, useDemoData } from "@/lib/supabase/config";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export type { CategoryDataResult, CategoryListItem } from "@/lib/data/category-data";

export type DataMode = "live" | "development";

export interface DashboardData {
  mode: DataMode;
  available: boolean;
  totals: {
    users: number;
    activeUsers: number;
    newUsers: number;
    questions: number;
    publishedQuestions: number;
    draftQuestions: number;
    categories: number;
    matches: number;
    matchesToday: number;
    soloMatches: number;
    oneVOneMatches: number;
    twoVTwoMatches: number;
    questionReports: number;
    userReports: number;
    errors: number;
    criticalErrors: number;
    coinsCirculation: number;
    purchases30d: number;
    premiumUsers: number;
    notificationsSent7d: number;
    notificationsFailed7d: number;
  };
  activity: { day: string; matches: number }[];
  latestImports: { id: string; filename: string; status: string; totalRows: number; createdAt: string }[];
  latestErrors: { id: string; title: string; severity: string; count: number; lastSeen: string }[];
  latestContent: { key: string; label: string; version: number; publishedAt: string }[];
  latestAudit: { id: string; action: string; entityType: string; createdAt: string }[];
}

const fallbackDashboard: DashboardData = {
  mode: "development",
  available: false,
  totals: { users: 0, activeUsers: 0, newUsers: 0, questions: 0, publishedQuestions: 0, draftQuestions: 0, categories: 0, matches: 0, matchesToday: 0, soloMatches: 0, oneVOneMatches: 0, twoVTwoMatches: 0, questionReports: 0, userReports: 0, errors: 0, criticalErrors: 0, coinsCirculation: 0, purchases30d: 0, premiumUsers: 0, notificationsSent7d: 0, notificationsFailed7d: 0 },
  activity: [], latestImports: [], latestErrors: [], latestContent: [], latestAudit: [],
};

function relationName(value: unknown, key: string, fallback = "—"): string {
  if (Array.isArray(value)) return String((value[0] as Record<string, unknown> | undefined)?.[key] ?? fallback);
  if (value && typeof value === "object") return String((value as Record<string, unknown>)[key] ?? fallback);
  return fallback;
}

export async function getDashboardData(): Promise<DashboardData> {
  const supabase = await createServerSupabaseClient();
  if (!supabase) return fallbackDashboard;

  try {
    const weekAgo = new Date(Date.now() - 6 * 24 * 60 * 60 * 1000);
    weekAgo.setUTCHours(0, 0, 0, 0);
    const [metricsResult, recentMatches, imports, errors, content, audit] = await Promise.all([
      supabase.rpc("get_admin_dashboard_metrics"),
      supabase.from("matches").select("created_at").gte("created_at", weekAgo.toISOString()),
      supabase.from("import_batches").select("id, filename, status, total_rows, created_at").order("created_at", { ascending: false }).limit(4),
      supabase.from("app_error_issues").select("id,title,severity,occurrence_count,last_seen").order("last_seen", { ascending: false }).limit(5),
      supabase.from("app_content").select("key,label_ar,version,published_at").not("published_at", "is", null).order("published_at", { ascending: false }).limit(5),
      supabase.from("audit_logs").select("id,action,entity_type,created_at").order("created_at", { ascending: false }).limit(5),
    ]);
    if (metricsResult.error || !metricsResult.data) return fallbackDashboard;
    const metrics = metricsResult.data as Record<string, unknown>;
    const number = (key: string) => Number(metrics[key] ?? 0);

    const formatter = new Intl.DateTimeFormat("ar-SA", { weekday: "short" });
    const activity = Array.from({ length: 7 }, (_, index) => {
      const date = new Date(weekAgo.getTime() + index * 24 * 60 * 60 * 1000);
      const dateKey = date.toISOString().slice(0, 10);
      return {
        day: formatter.format(date),
        matches: (recentMatches.data ?? []).filter((match) => String(match.created_at).startsWith(dateKey)).length,
      };
    });

    return {
      mode: "live",
      available: true,
      totals: {
        users: number("users"), activeUsers: number("active_users_24h"), newUsers: number("new_users_7d"),
        questions: number("questions"), publishedQuestions: number("published_questions"), draftQuestions: number("draft_questions"), categories: number("categories"),
        matches: number("matches"), matchesToday: number("matches_today"), soloMatches: number("solo_matches"), oneVOneMatches: number("one_v_one_matches"), twoVTwoMatches: number("two_v_two_matches"),
        questionReports: number("question_reports_open"), userReports: number("user_reports_open"), errors: number("error_issues_open"), criticalErrors: number("critical_issues_open"),
        coinsCirculation: number("coins_circulation"), purchases30d: number("wallet_purchases_30d"), premiumUsers: number("premium_users"),
        notificationsSent7d: number("notifications_sent_7d"), notificationsFailed7d: number("notifications_failed_7d"),
      },
      activity,
      latestImports: (imports.data ?? []).map((batch) => ({
        id: String(batch.id),
        filename: String(batch.filename),
        status: String(batch.status),
        totalRows: Number(batch.total_rows ?? 0),
        createdAt: String(batch.created_at),
      })),
      latestErrors: (errors.data ?? []).map((row) => ({ id: String(row.id), title: String(row.title), severity: String(row.severity), count: Number(row.occurrence_count), lastSeen: String(row.last_seen) })),
      latestContent: (content.data ?? []).map((row) => ({ key: String(row.key), label: String(row.label_ar), version: Number(row.version), publishedAt: String(row.published_at) })),
      latestAudit: (audit.data ?? []).map((row) => ({ id: String(row.id), action: String(row.action), entityType: String(row.entity_type), createdAt: String(row.created_at) })),
    };
  } catch {
    return fallbackDashboard;
  }
}

export interface QuestionListItem {
  id: string;
  text: string;
  category: string;
  difficulty: string;
  status: string;
  played: number;
  accuracy: number | null;
  needsReview: boolean;
  gameplayType: string;
}

export async function getQuestions(): Promise<{ mode: DataMode; rows: QuestionListItem[] }> {
  const supabase = await createServerSupabaseClient();
  if (supabase) {
    const { data, error } = await supabase
      .from("questions")
      .select("id, question_text, gameplay_type, difficulty, status, times_played, correct_answers, needs_review, category:categories!questions_category_id_fkey(name_ar)")
      .order("updated_at", { ascending: false })
      .limit(50);
    if (!error) {
      return {
        mode: "live",
        rows: (data ?? []).map((row) => ({
          id: String(row.id), text: String(row.question_text), category: relationName(row.category, "name_ar"),
          difficulty: String(row.difficulty), status: String(row.status), played: Number(row.times_played ?? 0),
          accuracy: Number(row.times_played ?? 0) > 0 ? Math.round(Number(row.correct_answers ?? 0) / Number(row.times_played) * 100) : null,
          needsReview: Boolean(row.needs_review),
          gameplayType: String(row.gameplay_type ?? "classic"),
        })),
      };
    }
  }
  return {
    mode: "development",
    rows: [
      { id: "q-1", text: "أين يقع ملعب أنفيلد؟", category: "الملاعب", difficulty: "easy", status: "published", played: 1840, accuracy: 82, needsReview: false, gameplayType: "classic" },
      { id: "q-2", text: "في أي موسم حقق هذا النادي لقبه الأول؟", category: "عين الصقر", difficulty: "hard", status: "review", played: 0, accuracy: null, needsReview: true, gameplayType: "classic" },
      { id: "q-3", text: "الفريق الأعلى نقاطًا يتصدر جدول الدوري.", category: "الدوريات والبطولات", difficulty: "easy", status: "draft", played: 0, accuracy: null, needsReview: true, gameplayType: "true-false" },
      { id: "q-4", text: "أي منتخب حقق هذه الجائزة ثلاث مرات؟", category: "الجوائز الفردية", difficulty: "expert", status: "draft", played: 0, accuracy: null, needsReview: true, gameplayType: "classic" },
      { id: "q-5", text: "من كان مدرب الفريق في نهائي البطولة؟", category: "غرفة الملابس", difficulty: "hard", status: "published", played: 611, accuracy: 38, needsReview: false, gameplayType: "classic" },
    ],
  };
}

export async function getCategories(): Promise<CategoryDataResult> {
  const supabase = await createServerSupabaseClient();
  return loadCategoryData(
    supabase ? createSupabaseCategoryDataSource(supabase) : null,
    { configured: hasSupabaseConfig, demoEnabled: useDemoData },
  );
}

export interface UserListItem { id: string; name: string; username: string; role: string; status: string; level: number; rating: number; createdAt: string; }
export async function getUsers(): Promise<{ mode: DataMode; rows: UserListItem[] }> {
  const supabase = await createServerSupabaseClient();
  if (supabase) {
    const { data, error } = await supabase.from("profiles").select("id, display_name, username, role, status, level, rating, created_at").order("created_at", { ascending: false }).limit(50);
    if (!error) return { mode: "live", rows: (data ?? []).map((row) => ({ id: String(row.id), name: String(row.display_name ?? row.username), username: String(row.username), role: String(row.role), status: String(row.status), level: Number(row.level), rating: Number(row.rating), createdAt: String(row.created_at) })) };
  }
  return { mode: "development", rows: [
    { id: "u1", name: "ياسر العتيبي", username: "Yasser11", role: "user", status: "active", level: 18, rating: 1642, createdAt: "2026-08-14T09:00:00Z" },
    { id: "u2", name: "أحمد المالكي", username: "Ahmad_KSA", role: "user", status: "active", level: 22, rating: 1788, createdAt: "2026-08-13T12:10:00Z" },
    { id: "u3", name: "سارة الحربي", username: "SaraGoal", role: "moderator", status: "active", level: 15, rating: 1510, createdAt: "2026-08-11T16:30:00Z" },
    { id: "u4", name: "خالد محمد", username: "Khalid90", role: "user", status: "suspended", level: 9, rating: 1211, createdAt: "2026-08-09T07:42:00Z" },
  ] };
}

export interface MatchListItem { id: string; mode: string; status: string; players: number; questions: number; createdAt: string; duration: number | null; }
export async function getMatches(): Promise<{ mode: DataMode; rows: MatchListItem[] }> {
  const supabase = await createServerSupabaseClient();
  if (supabase) {
    const { data, error } = await supabase.from("matches").select("id, mode, status, question_count, created_at, started_at, finished_at, match_players(count)").order("created_at", { ascending: false }).limit(50);
    if (!error) return { mode: "live", rows: (data ?? []).map((row) => ({
      id: String(row.id), mode: String(row.mode), status: String(row.status), questions: Number(row.question_count ?? 0), createdAt: String(row.created_at),
      players: Number(Array.isArray(row.match_players) ? (row.match_players[0] as { count?: number })?.count ?? 0 : 0),
      duration: row.started_at && row.finished_at ? Math.round((new Date(String(row.finished_at)).getTime() - new Date(String(row.started_at)).getTime()) / 1000) : null,
    })) };
  }
  return { mode: "development", rows: [
    { id: "8F2A11", mode: "quick_1v1", status: "finished", players: 2, questions: 15, createdAt: "2026-08-27T16:22:00Z", duration: 238 },
    { id: "9D7B04", mode: "team_2v2", status: "question", players: 4, questions: 15, createdAt: "2026-08-27T16:18:00Z", duration: null },
    { id: "2C1E81", mode: "solo", status: "finished", players: 1, questions: 10, createdAt: "2026-08-27T16:10:00Z", duration: 174 },
    { id: "1A5F90", mode: "friend_1v1", status: "cancelled", players: 2, questions: 15, createdAt: "2026-08-27T15:56:00Z", duration: null },
  ] };
}

export interface ReportListItem { id: string; reason: string; status: string; question: string; reporter: string; createdAt: string; }
const reportReasonLabels: Record<string, string> = {
  wrong_answer: "الإجابة خطأ",
  outdated: "السؤال قديم",
  unclear: "غير واضح",
  wrong_image: "الصورة خاطئة",
  broken_media: "الصورة/الصوت لا يعمل",
  duplicate: "مكرر",
  other: "أخرى",
};
export async function getReports(): Promise<{ mode: DataMode; rows: ReportListItem[] }> {
  const supabase = await createServerSupabaseClient();
  if (supabase) {
    const { data, error } = await supabase.from("question_reports").select("id, reason, status, created_at, reporter_id, questions(question_text)").order("created_at", { ascending: false }).limit(50);
    if (!error) return { mode: "live", rows: (data ?? []).map((row) => ({ id: String(row.id), reason: reportReasonLabels[String(row.reason)] ?? String(row.reason), status: String(row.status), question: relationName(row.questions, "question_text"), reporter: String(row.reporter_id).slice(0, 8), createdAt: String(row.created_at) })) };
  }
  return { mode: "development", rows: [
    { id: "r1", reason: "الإجابة خاطئة", status: "open", question: "من فاز بالكرة الذهبية في هذا الموسم؟", reporter: "GoalKing", createdAt: "2026-08-27T15:42:00Z" },
    { id: "r2", reason: "الصورة خاطئة", status: "reviewing", question: "تعرّف على النادي من هذا الشعار", reporter: "Nawaf11", createdAt: "2026-08-27T14:11:00Z" },
    { id: "r3", reason: "السؤال مكرر", status: "resolved", question: "أين يقع ملعب أنفيلد؟", reporter: "SaraGoal", createdAt: "2026-08-26T21:08:00Z" },
    { id: "r4", reason: "السؤال غير واضح", status: "open", question: "من سجل أولًا؟", reporter: "Fahad_X", createdAt: "2026-08-26T18:30:00Z" },
  ] };
}

export interface StoreListItem { id: string; name: string; type: string; price: number; active: boolean; rarity: string; }
export async function getStoreItems(): Promise<{ mode: DataMode; rows: StoreListItem[] }> {
  const supabase = await createServerSupabaseClient();
  if (supabase) {
    const { data, error } = await supabase.from("store_items").select("id, name_ar, type, price_coins, is_active, metadata").order("sort_order").limit(50);
    if (!error) return { mode: "live", rows: (data ?? []).map((row) => ({ id: String(row.id), name: String(row.name_ar), type: String(row.type), price: Number(row.price_coins ?? 0), active: Boolean(row.is_active), rarity: String((row.metadata as Record<string, unknown> | null)?.rarity ?? "common") })) };
  }
  return { mode: "development", rows: [
    { id: "s1", name: "إطار بطل الدوري", type: "frame", price: 1200, active: true, rarity: "legendary" },
    { id: "s2", name: "تأثير انتصار أخضر", type: "victory_effect", price: 800, active: true, rarity: "epic" },
    { id: "s3", name: "تلميح 50/50", type: "hint", price: 75, active: true, rarity: "common" },
    { id: "s4", name: "شارة 11 Premium", type: "badge", price: 0, active: true, rarity: "premium" },
  ] };
}

export interface NotificationListItem { id: string; title: string; type: string; audience: string; status: string; scheduledAt: string | null; createdAt: string; }
export async function getNotifications(): Promise<{ mode: DataMode; rows: NotificationListItem[] }> {
  const supabase = await createServerSupabaseClient();
  if (supabase) {
    const { data, error } = await supabase
      .from("notifications")
      .select("id, title_ar, type, audience, status, scheduled_at, created_at")
      .is("target_user_id", null)
      .order("created_at", { ascending: false })
      .limit(30);
    if (!error) return { mode: "live", rows: (data ?? []).map((row) => ({
      id: String(row.id), title: String(row.title_ar), type: String(row.type),
      audience: String((row.audience as Record<string, unknown> | null)?.segment ?? "all"), status: String(row.status),
      scheduledAt: row.scheduled_at ? String(row.scheduled_at) : null, createdAt: String(row.created_at),
    })) };
  }
  return { mode: "development", rows: [
    { id: "n1", title: "تحدي الخميس جاهز ⚽", type: "daily_challenge", audience: "active", status: "sent", scheduledAt: null, createdAt: "2026-08-27T10:00:00Z" },
    { id: "n2", title: "مكافأة العودة تنتظرك", type: "reward", audience: "inactive_7d", status: "queued", scheduledAt: "2026-08-28T15:00:00Z", createdAt: "2026-08-27T09:10:00Z" },
    { id: "n3", title: "بداية موسم أحدعش الأول", type: "season", audience: "all", status: "sent", scheduledAt: null, createdAt: "2026-08-24T17:00:00Z" },
  ] };
}

export interface GameSettingItem { key: string; value: number; description: string; isPublic: boolean; }
const fallbackSettings: GameSettingItem[] = [
  { key: "party.categories_per_game", value: 6, description: "عدد الأقسام في لعبة الجلسة", isPublic: true },
  { key: "party.free.daily_games", value: 0, description: "حد يومي مستقبلي للجولات المجانية (0 = غير مفعّل)", isPublic: true },
  { key: "party.free.monthly_games", value: 0, description: "حد شهري مستقبلي للجولات المجانية (0 = غير مفعّل)", isPublic: true },
  { key: "party.free.rotating_categories_enabled", value: 0, description: "تدوير الأقسام المجانية مستقبلًا", isPublic: true },
  { key: "party.free.ad_supported_enabled", value: 0, description: "جولة مجانية مدعومة بإعلان مستقبلًا", isPublic: true },
  { key: "party.questions_per_category", value: 6, description: "عدد الأسئلة لكل قسم", isPublic: true },
  { key: "party.helpers_per_team", value: 3, description: "عدد المساعدات لكل فريق", isPublic: true },
  { key: "party.default_timer_seconds", value: 30, description: "المؤقت الافتراضي للسؤال", isPublic: true },
  { key: "party.tiebreaker_enabled", value: 1, description: "تفعيل السؤال الفاصل عند التعادل", isPublic: true },
  { key: "party.easy_points", value: 100, description: "نقاط السؤال السهل", isPublic: true },
  { key: "party.medium_points", value: 200, description: "نقاط السؤال المتوسط", isPublic: true },
  { key: "party.hard_points", value: 300, description: "نقاط السؤال الصعب", isPublic: true },
  { key: "default_question_count", value: 15, description: "عدد الأسئلة الافتراضي في المباراة", isPublic: true },
  { key: "base_score", value: 100, description: "النقاط الأساسية للإجابة الصحيحة", isPublic: true },
  { key: "max_speed_bonus", value: 50, description: "الحد الأعلى لمكافأة السرعة", isPublic: true },
  { key: "matchmaking_initial_range", value: 100, description: "نطاق التقييم الأولي للبحث عن خصم", isPublic: false },
  { key: "ad_frequency", value: 3, description: "أقل عدد جولات بين الإعلانات البينية", isPublic: false },
  { key: "rewarded_ad_coins", value: 50, description: "عملات مشاهدة إعلان بمكافأة", isPublic: true },
  { key: "daily_reward_coins", value: 100, description: "مكافأة الدخول اليومية الأساسية", isPublic: true },
  { key: "difficulty_min_sample", value: 50, description: "أقل عينة قبل إعادة تقدير الصعوبة", isPublic: false },
];

export async function getGameSettings(): Promise<{ mode: DataMode; rows: GameSettingItem[] }> {
  const supabase = await createServerSupabaseClient();
  if (supabase) {
    const { data, error } = await supabase.from("game_settings").select("key, value, description_ar, is_public").order("key");
    if (!error && data?.length) return { mode: "live", rows: data.map((row) => ({
      key: String(row.key), value: typeof row.value === "number" ? row.value : Number((row.value as { value?: unknown } | null)?.value ?? row.value ?? 0),
      description: String(row.description_ar ?? row.key), isPublic: Boolean(row.is_public),
    })) };
  }
  return { mode: "development", rows: fallbackSettings };
}
