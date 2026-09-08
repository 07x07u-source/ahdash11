"use client";

import { useRouter } from "next/navigation";
import { useTransition } from "react";
import { CheckCircle2, Database, LoaderCircle, RefreshCw, TriangleAlert } from "lucide-react";

export function SupabaseConnectionState({
  state,
  checkedAt,
  detail,
}: {
  state: "live" | "partial" | "error" | "not_configured" | "demo";
  checkedAt: string;
  detail?: string;
}) {
  const router = useRouter();
  const [refreshing, startTransition] = useTransition();
  const connected = state === "live";
  const demo = state === "demo";
  const Icon = connected ? CheckCircle2 : demo ? Database : TriangleAlert;
  const label = connected ? "Connected" : state === "partial" ? "Partial connection" : demo ? "Explicit demo mode" : "Connection problem";

  return (
    <div className={`flex flex-wrap items-center gap-3 rounded-xl border px-4 py-3 text-xs ${connected ? "border-emerald-500/20 bg-emerald-500/6" : "border-amber-500/20 bg-amber-500/6"}`}>
      <Icon size={18} className={connected ? "text-emerald-600" : "text-amber-600"} />
      <div className="min-w-0 flex-1">
        <p className="font-black">Supabase · {label}</p>
        {detail ? <p className="mt-1 text-[10px] leading-5 text-[var(--muted)]">{detail}</p> : null}
        <time dateTime={checkedAt} className="mt-1 block font-mono text-[9px] text-[var(--muted)]" dir="ltr">
          Last checked: {new Date(checkedAt).toLocaleString("ar-SA")}
        </time>
      </div>
      {!connected ? (
        <button
          type="button"
          disabled={refreshing}
          onClick={() => startTransition(() => router.refresh())}
          className="inline-flex min-h-10 items-center gap-2 rounded-lg border border-current/15 px-3 font-bold disabled:opacity-50"
        >
          {refreshing ? <LoaderCircle size={14} className="animate-spin" /> : <RefreshCw size={14} />}
          إعادة المحاولة
        </button>
      ) : null}
    </div>
  );
}
