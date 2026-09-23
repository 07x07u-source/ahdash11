import "server-only";

import { cache } from "react";
import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
export { safeReturnPath } from "@/lib/auth/redirects";

export type PlayerContext = {
  id: string;
  email: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  level: number;
  xp: number;
  rating: number;
  favoriteClub: string | null;
};

export const getPlayerContext = cache(async (): Promise<PlayerContext | null> => {
  const supabase = await createServerSupabaseClient();
  if (!supabase) return null;

  const { data: authData, error: authError } = await supabase.auth.getUser();
  const user = authData.user;
  if (authError || !user) return null;
  // Local gameplay mirrors Flutter's real Supabase anonymous guest session.
  // Anonymous identities never satisfy account, tournament, or cloud guards.
  if (user.is_anonymous === true || user.app_metadata?.provider === "anonymous") return null;

  const { data: profile } = await supabase
    .from("profiles")
    .select("id,username,display_name,avatar_url,level,xp,rating,favorite_club,status")
    .eq("id", user.id)
    .maybeSingle();

  if (profile?.status && profile.status !== "active") return null;

  const generatedName = String(user.user_metadata?.display_name ?? user.email?.split("@")[0] ?? "لاعب أحدعش");
  return {
    id: user.id,
    email: user.email ?? "",
    displayName: profile?.display_name ? String(profile.display_name) : generatedName,
    username: profile?.username ? String(profile.username) : `player_${user.id.slice(0, 6)}`,
    avatarUrl: profile?.avatar_url ? String(profile.avatar_url) : null,
    level: Number(profile?.level ?? 1),
    xp: Number(profile?.xp ?? 0),
    rating: Number(profile?.rating ?? 1200),
    favoriteClub: profile?.favorite_club ? String(profile.favorite_club) : null,
  };
});

export async function requirePlayerPage(returnTo: string): Promise<PlayerContext> {
  const player = await getPlayerContext();
  if (!player) redirect(`/account/login?next=${encodeURIComponent(returnTo)}`);
  return player;
}
