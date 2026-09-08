import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { rejectCrossOriginMutation } from "@/lib/security/request";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { tournamentAdminMutationSchema } from "@/lib/tournament/schema";

export async function GET() {
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;
  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ tournaments: [], developmentFallback: true, migrationPending: false });

  const [tournamentsResult, teamsResult, matchesResult, registrationsResult] = await Promise.all([
    supabase.from("tournaments").select("id,name,status,visibility,capacity,players_per_team,organizer_id,champion_team_id,started_at,completed_at,created_at,updated_at").order("updated_at", { ascending: false }).limit(250),
    supabase.from("tournament_teams").select("tournament_id,id"),
    supabase.from("tournament_matches").select("tournament_id,id,status"),
    supabase.from("tournament_registrations").select("tournament_id,id,status"),
  ]);
  if (tournamentsResult.error) {
    const migrationPending = tournamentsResult.error.code === "42P01" || tournamentsResult.error.code === "PGRST205";
    if (migrationPending) return Response.json({ tournaments: [], developmentFallback: false, migrationPending: true });
    return Response.json({ error: tournamentsResult.error.message }, { status: 400 });
  }
  const teams = teamsResult.data ?? [];
  const matches = matchesResult.data ?? [];
  const registrations = registrationsResult.data ?? [];
  const tournaments = (tournamentsResult.data ?? []).map((row) => ({
    id: String(row.id),
    name: String(row.name),
    status: String(row.status),
    visibility: String(row.visibility),
    capacity: Number(row.capacity),
    playersPerTeam: Number(row.players_per_team),
    organizerId: String(row.organizer_id),
    championTeamId: row.champion_team_id ? String(row.champion_team_id) : null,
    teamCount: teams.filter((item) => item.tournament_id === row.id).length,
    matchCount: matches.filter((item) => item.tournament_id === row.id).length,
    completedMatchCount: matches.filter((item) => item.tournament_id === row.id && ["completed", "bye"].includes(String(item.status))).length,
    pendingRegistrationCount: registrations.filter((item) => item.tournament_id === row.id && item.status === "pending").length,
    createdAt: String(row.created_at),
    updatedAt: String(row.updated_at),
  }));
  return Response.json({ tournaments, developmentFallback: false, migrationPending: false });
}

export async function PATCH(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("admin");
  if (authorization.response || !authorization.context) return authorization.response;
  try {
    const input = tournamentAdminMutationSchema.parse(await request.json());
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ success: true, developmentFallback: true });
    const status = input.action === "cancel" ? "cancelled" : "registration";
    const { error } = await supabase
      .from("tournaments")
      .update({ status, updated_at: new Date().toISOString() })
      .eq("id", input.id);
    if (error) throw new Error(error.message);
    return Response.json({ success: true, developmentFallback: false });
  } catch (error) {
    if (error instanceof z.ZodError) return Response.json({ error: "طلب إدارة البطولة غير صالح." }, { status: 400 });
    return Response.json({ error: error instanceof Error ? error.message : "تعذر تحديث البطولة." }, { status: 400 });
  }
}
