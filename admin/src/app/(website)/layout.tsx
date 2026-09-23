import { SiteShell } from "@/components/site-shell";
import { MobileAppDownload } from "@/components/mobile-app-download";
import { getPlayerContext } from "@/lib/auth/player";

export const dynamic = "force-dynamic";

export default async function WebsiteLayout({ children }: { children: React.ReactNode }) {
  const player = await getPlayerContext();
  return (
    <>
      <div className="website-desktop-only"><SiteShell player={player ? { displayName: player.displayName, username: player.username } : null}>{children}</SiteShell></div>
      <div className="website-mobile-only"><MobileAppDownload /></div>
    </>
  );
}
