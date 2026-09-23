import { redirect } from "next/navigation";
import { PlayerAuthForm } from "@/components/player-auth-form";
import { PlayerAuthSurface } from "@/components/player-auth-surface";
import { getPlayerContext, safeReturnPath } from "@/lib/auth/player";

export const metadata = { title: "حساب جديد" };
export const dynamic = "force-dynamic";

export default async function PlayerRegisterPage({ searchParams }: { searchParams: Promise<{ next?: string | string[] }> }) {
  const next = safeReturnPath((await searchParams).next);
  if (await getPlayerContext()) redirect(next);
  return <PlayerAuthSurface mode="register"><PlayerAuthForm mode="register" next={next} /></PlayerAuthSurface>;
}
