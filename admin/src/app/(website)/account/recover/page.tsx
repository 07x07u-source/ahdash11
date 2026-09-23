import { PlayerAuthForm } from "@/components/player-auth-form";
import { PlayerAuthSurface } from "@/components/player-auth-surface";

export const metadata = { title: "استعادة الحساب" };

export default function PlayerRecoverPage() {
  return <PlayerAuthSurface mode="recover"><PlayerAuthForm mode="recover" /></PlayerAuthSurface>;
}
