import { redirect } from "next/navigation";
import { PlayerAuthForm } from "@/components/player-auth-form";
import { PlayerAuthSurface } from "@/components/player-auth-surface";
import { getPlayerContext, safeReturnPath } from "@/lib/auth/player";

export const metadata = { title: "تسجيل الدخول" };
export const dynamic = "force-dynamic";

export default async function PlayerLoginPage({ searchParams }: { searchParams: Promise<{ next?: string | string[]; error?: string | string[] }> }) {
  const query = await searchParams;
  const next = safeReturnPath(query.next);
  if (await getPlayerContext()) redirect(next);
  const callbackFailed = (Array.isArray(query.error) ? query.error[0] : query.error) === "callback";
  return <PlayerAuthSurface mode="login"><PlayerAuthForm mode="login" next={next} initialError={callbackFailed ? "تعذر إكمال تسجيل الدخول. أعد المحاولة أو استخدم البريد." : ""} /></PlayerAuthSurface>;
}
