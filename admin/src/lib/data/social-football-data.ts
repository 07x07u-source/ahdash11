import "server-only";

import { hasSupabaseConfig } from "@/lib/supabase/config";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export type OperationalState = "live" | "error" | "not_configured";

export interface FootballCountryRow { id: string; code: string; nameAr: string; nameEn: string; active: boolean; featured: boolean }
export interface FootballLeagueRow { id: string; countryId: string; nameAr: string; nameEn: string; shortName: string | null; visualStatus: string; logoUrl: string | null; active: boolean }
export interface FootballClubRow { id: string; leagueId: string; nameAr: string; nameEn: string; shortName: string | null; visualStatus: string; logoUrl: string | null; licenseReference: string | null; active: boolean; updatedAt: string }

export interface FootballCatalogData {
  state: OperationalState;
  checkedAt: string;
  detail?: string;
  countries: FootballCountryRow[];
  leagues: FootballLeagueRow[];
  clubs: FootballClubRow[];
}

export async function getFootballCatalogData(): Promise<FootballCatalogData> {
  const checkedAt = new Date().toISOString();
  if (!hasSupabaseConfig) return { state: "not_configured", checkedAt, detail: "إعدادات Supabase غير متوفرة.", countries: [], leagues: [], clubs: [] };
  const supabase = await createServerSupabaseClient();
  if (!supabase) return { state: "not_configured", checkedAt, detail: "تعذر إنشاء عميل Supabase.", countries: [], leagues: [], clubs: [] };
  const [countries, leagues, clubs] = await Promise.all([
    supabase.from("football_countries").select("id,code,name_ar,name_en,is_active,is_featured").order("sort_order"),
    supabase.from("football_leagues").select("id,country_id,name_ar,name_en,short_name,visual_status,logo_url,is_active").order("sort_order"),
    supabase.from("football_clubs").select("id,league_id,name_ar,name_en,short_name,visual_status,logo_url,license_reference,is_active,updated_at").order("updated_at", { ascending: false }).limit(250),
  ]);
  const error = countries.error ?? leagues.error ?? clubs.error;
  if (error) return { state: "error", checkedAt, detail: `تعذر قراءة جداول Football Data (${error.code ?? "unknown"}). قد تكون migration غير مطبقة بعد.`, countries: [], leagues: [], clubs: [] };
  return {
    state: "live",
    checkedAt,
    countries: (countries.data ?? []).map((row) => ({ id: String(row.id), code: String(row.code), nameAr: String(row.name_ar), nameEn: String(row.name_en), active: Boolean(row.is_active), featured: Boolean(row.is_featured) })),
    leagues: (leagues.data ?? []).map((row) => ({ id: String(row.id), countryId: String(row.country_id), nameAr: String(row.name_ar), nameEn: String(row.name_en), shortName: row.short_name ? String(row.short_name) : null, visualStatus: String(row.visual_status), logoUrl: row.logo_url ? String(row.logo_url) : null, active: Boolean(row.is_active) })),
    clubs: (clubs.data ?? []).map((row) => ({ id: String(row.id), leagueId: String(row.league_id), nameAr: String(row.name_ar), nameEn: String(row.name_en), shortName: row.short_name ? String(row.short_name) : null, visualStatus: String(row.visual_status), logoUrl: row.logo_url ? String(row.logo_url) : null, licenseReference: row.license_reference ? String(row.license_reference) : null, active: Boolean(row.is_active), updatedAt: String(row.updated_at) })),
  };
}

export interface SocialModerationData {
  state: OperationalState;
  checkedAt: string;
  detail?: string;
  teams: Array<{ id: string; name: string; status: string; memberCount: number; createdAt: string; reason: string | null }>;
  reports: Array<{ id: string; subjectType: string; subjectId: string; reason: string; status: string; reporterId: string; createdAt: string }>;
}

export async function getSocialModerationData(): Promise<SocialModerationData> {
  const checkedAt = new Date().toISOString();
  if (!hasSupabaseConfig) return { state: "not_configured", checkedAt, detail: "إعدادات Supabase غير متوفرة.", teams: [], reports: [] };
  const supabase = await createServerSupabaseClient();
  if (!supabase) return { state: "not_configured", checkedAt, teams: [], reports: [] };
  const [teams, reports] = await Promise.all([
    supabase.from("social_teams").select("id,name,status,moderation_reason,created_at,social_team_members(count)").order("created_at", { ascending: false }).limit(100),
    supabase.from("social_reports").select("id,subject_type,subject_id,reason,status,reporter_id,created_at").order("created_at", { ascending: false }).limit(100),
  ]);
  const error = teams.error ?? reports.error;
  if (error) return { state: "error", checkedAt, detail: `تعذر قراءة Social (${error.code ?? "unknown"}). قد تكون migration غير مطبقة بعد.`, teams: [], reports: [] };
  return {
    state: "live",
    checkedAt,
    teams: (teams.data ?? []).map((row) => ({
      id: String(row.id), name: String(row.name), status: String(row.status), reason: row.moderation_reason ? String(row.moderation_reason) : null,
      memberCount: Number(Array.isArray(row.social_team_members) ? (row.social_team_members[0] as { count?: number })?.count ?? 0 : 0), createdAt: String(row.created_at),
    })),
    reports: (reports.data ?? []).map((row) => ({ id: String(row.id), subjectType: String(row.subject_type), subjectId: String(row.subject_id), reason: String(row.reason), status: String(row.status), reporterId: String(row.reporter_id), createdAt: String(row.created_at) })),
  };
}
