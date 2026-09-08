"use client";

import { LogOut } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { createBrowserSupabaseClient } from "@/lib/supabase/client";

export function LogoutButton() {
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  async function logout() {
    setBusy(true);
    const supabase = createBrowserSupabaseClient();
    if (supabase) await supabase.auth.signOut();
    router.replace("/login");
    router.refresh();
  }

  return (
    <button type="button" onClick={logout} disabled={busy} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-xs font-bold text-[#8e98a7] transition hover:bg-[#ff4d57]/8 hover:text-[#ff7c84] disabled:opacity-50">
      <LogOut size={17} />
      {busy ? "جارٍ تسجيل الخروج…" : "تسجيل الخروج"}
    </button>
  );
}
