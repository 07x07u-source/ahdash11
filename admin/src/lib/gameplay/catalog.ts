import { createBrowserSupabaseClient } from "@/lib/supabase/client";
import {
  defaultPartyHelpers,
  defaultPartyRules,
  parseGameplayCategory,
  parseGameplayQuestion,
  parsePartyHelper,
  parsePartyRules,
  type GameplayCategory,
  type GameplayDifficulty,
  type GameplayQuestion,
  type PartyHelperDefinition,
  type PartyRules,
} from "./contracts";

export type GameplayCatalog = {
  categories: GameplayCategory[];
  helpers: PartyHelperDefinition[];
  rules: PartyRules;
  premiumAccess: boolean;
  guestSession: boolean;
};

export class GameplayCatalogError extends Error {
  constructor(message: string, readonly code: "configuration" | "guest-session" | "categories" | "catalog" | "pack") {
    super(message);
  }
}

function rows(value: unknown): Record<string, unknown>[] {
  return Array.isArray(value) ? value.filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === "object" && !Array.isArray(item)) : [];
}

async function ensureGameplayIdentity() {
  const supabase = createBrowserSupabaseClient();
  if (!supabase) throw new GameplayCatalogError("خدمة محتوى أحدعش غير متصلة في هذه البيئة.", "configuration");
  const existing = await supabase.auth.getUser();
  if (existing.data.user) {
    return { supabase, user: existing.data.user, guest: existing.data.user.is_anonymous === true };
  }
  const created = await supabase.auth.signInAnonymously();
  if (created.error || !created.data.user) throw new GameplayCatalogError("تعذر بدء جلسة الضيف. تحقق من الاتصال وحاول مجدداً.", "guest-session");
  return { supabase, user: created.data.user, guest: true };
}

async function resolvePremiumAccess(supabase: ReturnType<typeof createBrowserSupabaseClient>, guest: boolean) {
  if (!supabase || guest) return false;
  const now = new Date().toISOString();
  const result = await supabase
    .from("subscriptions")
    .select("status,current_period_ends_at")
    .in("status", ["trialing", "active", "grace_period"])
    .gt("current_period_ends_at", now)
    .limit(1);
  return !result.error && Boolean(result.data?.length);
}

export async function loadGameplayCatalog(): Promise<GameplayCatalog> {
  const { supabase, guest } = await ensureGameplayIdentity();
  const [categoryResult, healthResult, helperResult, settingsResult, premiumAccess] = await Promise.all([
    supabase
      .from("categories")
      .select("id,parent_id,name_ar,description_ar,image_url,cover_focal_x,cover_focal_y,access_tier,is_free_rotation,is_featured,sort_order")
      .is("parent_id", null)
      .eq("is_active", true)
      .eq("editorial_status", "published")
      .order("is_featured", { ascending: false })
      .order("sort_order"),
    supabase.rpc("get_party_category_health"),
    supabase.from("party_help_tools").select("id,name_ar,description_ar,timing,rule_config,sort_order").eq("is_active", true).order("sort_order"),
    supabase.from("game_settings").select("key,value").in("key", ["party.rule_config"]),
    resolvePremiumAccess(supabase, guest),
  ]);
  if (categoryResult.error) throw new GameplayCatalogError("تعذر تحميل الفئات المنشورة.", "categories");
  if (healthResult.error) throw new GameplayCatalogError("تعذر التحقق من جاهزية أسئلة الفئات.", "catalog");

  const health = new Map(rows(healthResult.data).map((row) => [String(row.category_id ?? ""), row]));
  const categories = rows(categoryResult.data)
    .map((row) => parseGameplayCategory(row, health.get(String(row.id ?? ""))))
    .filter((category): category is GameplayCategory => category !== null);
  const helpers = helperResult.error
    ? defaultPartyHelpers
    : rows(helperResult.data).map(parsePartyHelper).filter((helper): helper is PartyHelperDefinition => helper !== null);
  const ruleRow = rows(settingsResult.data).find((row) => row.key === "party.rule_config");
  return {
    categories,
    helpers: helpers.length ? helpers : defaultPartyHelpers,
    rules: settingsResult.error ? defaultPartyRules : parsePartyRules(ruleRow?.value),
    premiumAccess,
    guestSession: guest,
  };
}

export function categoryIsAccessible(category: GameplayCategory, premiumAccess: boolean) {
  return category.accessTier === "free" || category.freeRotation || premiumAccess;
}

export async function loadPartyQuestionPack(categoryIds: readonly string[]): Promise<GameplayQuestion[]> {
  const { supabase } = await ensureGameplayIdentity();
  const result = await supabase.rpc("get_party_question_pack", { p_limit: 250, p_category_ids: [...categoryIds] });
  if (result.error) throw new GameplayCatalogError("تعذر تحميل حزمة Party من كتالوج أحدعش.", "pack");
  const questions = rows(result.data).map(parseGameplayQuestion).filter((question): question is GameplayQuestion => question !== null);
  if (!questions.length) throw new GameplayCatalogError("لا توجد حزمة أسئلة منشورة صالحة لهذه الفئات.", "pack");
  return questions;
}

export async function loadSoloQuestionPack(input: { categoryIds: readonly string[]; difficulty: GameplayDifficulty; count: number }): Promise<GameplayQuestion[]> {
  const { supabase } = await ensureGameplayIdentity();
  const result = await supabase.rpc("get_solo_question_pack", {
    p_limit: Math.min(250, Math.max(input.count * 4, 50)),
    p_category_ids: [...input.categoryIds],
    p_difficulty: input.difficulty,
  });
  if (result.error) throw new GameplayCatalogError("تعذر تحميل أسئلة التحدي الفردي.", "pack");
  const questions = rows(result.data).map(parseGameplayQuestion).filter((question): question is GameplayQuestion => question !== null && question.gameplayType === "classic");
  if (!questions.length) throw new GameplayCatalogError("لا توجد أسئلة منشورة صالحة لهذه الإعدادات.", "pack");
  return questions;
}

export async function recordSoloAnswer(questionId: string, selectedIndex: number | null) {
  const supabase = createBrowserSupabaseClient();
  if (!supabase) return;
  await supabase.rpc("record_solo_answer", { p_question_id: questionId, p_selected_position: selectedIndex === null ? 0 : selectedIndex + 1 });
}
