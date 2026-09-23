import { notFound } from "next/navigation";
import { AccountFeatureSurface } from "@/components/account-feature-surface";
import { requirePlayerPage } from "@/lib/auth/player";
import { getPlayerFeature } from "@/lib/site/player-features";

export const dynamic = "force-dynamic";

export default async function AccountFeaturePage({ params }: { params: Promise<{ feature: string }> }) {
  const { feature: slug } = await params;
  const feature = getPlayerFeature(slug);
  if (!feature) notFound();
  const player = await requirePlayerPage(`/account/${slug}`);
  return <AccountFeatureSurface feature={feature} player={{ id: player.id, displayName: player.displayName, username: player.username, rating: player.rating, favoriteClub: player.favoriteClub }} />;
}
