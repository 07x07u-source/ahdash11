import { PlayerAuthForm } from "@/components/player-auth-form";
import { PlayerAuthSurface } from "@/components/player-auth-surface";
import { requirePlayerPage } from "@/lib/auth/player";

export const metadata = { title: "تعيين كلمة مرور جديدة" };
export const dynamic = "force-dynamic";

export default async function PlayerResetPage() {
  await requirePlayerPage("/account/reset");
  return <PlayerAuthSurface mode="reset"><PlayerAuthForm mode="reset" /></PlayerAuthSurface>;
}
