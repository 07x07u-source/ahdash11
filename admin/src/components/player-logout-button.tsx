"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { LoaderCircle, LogOut } from "lucide-react";
import { createBrowserSupabaseClient } from "@/lib/supabase/client";

export function PlayerLogoutButton() {
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  async function logout() {
    setBusy(true);
    await createBrowserSupabaseClient()?.auth.signOut();
    router.replace("/");
    router.refresh();
  }

  return <button type="button" onClick={logout} disabled={busy} className="player-logout">{busy ? <LoaderCircle size={17} className="animate-spin" /> : <LogOut size={17} />}تسجيل الخروج</button>;
}
