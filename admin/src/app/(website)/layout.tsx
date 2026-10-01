import { SiteShell } from "@/components/site-shell";
import { getPlayerContext } from "@/lib/auth/player";

export const dynamic = "force-dynamic";

export default async function WebsiteLayout({ children }: { children: React.ReactNode }) {
  const player = await getPlayerContext();
  return <SiteShell player={player ? { displayName: player.displayName, username: player.username } : null}>{children}</SiteShell>;
}
