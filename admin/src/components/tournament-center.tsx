"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { AlertTriangle, Ban, LoaderCircle, PlayCircle, RefreshCw, Search, Trophy, UsersRound } from "lucide-react";
import { StatusBadge } from "./ui/status-badge";

interface TournamentRow {
  id: string;
  name: string;
  status: string;
  visibility: string;
  capacity: number;
  playersPerTeam: number;
  organizerId: string;
  championTeamId: string | null;
  teamCount: number;
  matchCount: number;
  completedMatchCount: number;
  pendingRegistrationCount: number;
  createdAt: string;
  updatedAt: string;
}

const labels: Record<string, string> = {
  draft: "مسودة",
  registration: "التسجيل مفتوح",
  ready: "جاهزة",
  live: "جارية",
  completed: "مكتملة",
  cancelled: "ملغاة",
};

export function TournamentCenter() {
  const [rows, setRows] = useState<TournamentRow[]>([]);
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);
  const [migrationPending, setMigrationPending] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setMessage(null);
    const response = await fetch("/api/tournaments", { cache: "no-store" });
    const data = await response.json() as { tournaments?: TournamentRow[]; migrationPending?: boolean; error?: string };
    if (!response.ok) setMessage(data.error ?? "تعذر تحميل البطولات.");
    setRows(data.tournaments ?? []);
    setMigrationPending(Boolean(data.migrationPending));
    setLoading(false);
  }, []);

  useEffect(() => {
    const timeoutId = window.setTimeout(() => void load(), 0);
    return () => window.clearTimeout(timeoutId);
  }, [load]);

  const filtered = useMemo(() => {
    const value = query.trim().toLowerCase();
    return value ? rows.filter((row) => row.name.toLowerCase().includes(value) || row.id.includes(value)) : rows;
  }, [query, rows]);

  async function mutate(row: TournamentRow, action: "cancel" | "reopen") {
    const wording = action === "cancel" ? "إلغاء" : "إعادة فتح";
    if (!window.confirm(`${wording} بطولة «${row.name}»؟`)) return;
    setBusy(row.id);
    setMessage(null);
    const response = await fetch("/api/tournaments", {
      method: "PATCH",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ id: row.id, action }),
    });
    const data = await response.json() as { error?: string };
    if (!response.ok) setMessage(data.error ?? "تعذر تحديث البطولة.");
    else await load();
    setBusy(null);
  }

  if (migrationPending) return <div className="surface-card flex min-h-52 items-center gap-4 p-6"><AlertTriangle className="shrink-0 text-[#aa7200]" /><div><h2 className="font-black">مركز البطولات جاهز بعد تطبيق migration</h2><p className="mt-1 text-sm text-[var(--muted)]">لم تُطبّق جداول البطولات على مشروع Supabase المتصل بعد. لم تُنشأ بيانات تجريبية بديلة.</p></div></div>;

  return <div className="space-y-5">
    <section className="grid grid-cols-2 gap-3 lg:grid-cols-4">
      <Metric label="كل البطولات" value={rows.length} icon={Trophy} />
      <Metric label="جارية" value={rows.filter((row) => row.status === "live").length} icon={PlayCircle} />
      <Metric label="فرق مسجّلة" value={rows.reduce((total, row) => total + row.teamCount, 0)} icon={UsersRound} />
      <Metric label="طلبات معلقة" value={rows.reduce((total, row) => total + row.pendingRegistrationCount, 0)} icon={AlertTriangle} />
    </section>
    <section className="surface-card overflow-hidden">
      <div className="flex flex-col gap-3 border-b border-black/8 p-4 sm:flex-row sm:items-center">
        <label className="relative flex-1"><Search className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--muted)]" size={16} /><input className="field pr-10" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="ابحث باسم البطولة أو المعرّف…" /></label>
        <button type="button" className="button-secondary" onClick={() => void load()} disabled={loading}><RefreshCw size={16} className={loading ? "animate-spin" : ""} />تحديث</button>
      </div>
      {message ? <p className="border-b border-[#c83443]/20 bg-[#c83443]/8 p-3 text-sm text-[#a72b38]">{message}</p> : null}
      {loading ? <div className="grid min-h-52 place-items-center"><LoaderCircle className="animate-spin text-[var(--primary-strong)]" /></div> : filtered.length ? <div className="overflow-x-auto"><table className="w-full min-w-[900px] text-right text-sm"><thead className="bg-black/[0.025] text-[11px] text-[var(--muted)]"><tr><th className="p-4">البطولة</th><th className="p-4">الحالة</th><th className="p-4">الفرق</th><th className="p-4">المباريات</th><th className="p-4">التسجيل</th><th className="p-4">آخر تحديث</th><th className="p-4">إدارة</th></tr></thead><tbody>{filtered.map((row) => <tr key={row.id} className="border-t border-black/7"><td className="p-4"><strong className="block font-black">{row.name}</strong><span className="font-mono text-[10px] text-[var(--muted)]">{row.id}</span></td><td className="p-4"><StatusBadge tone={row.status === "live" ? "success" : row.status === "cancelled" ? "danger" : row.status === "registration" ? "info" : "neutral"}>{labels[row.status] ?? row.status}</StatusBadge></td><td className="p-4 font-black" dir="ltr">{row.teamCount} / {row.capacity}</td><td className="p-4" dir="ltr">{row.completedMatchCount} / {row.matchCount}</td><td className="p-4">{row.pendingRegistrationCount ? <StatusBadge tone="warning">{row.pendingRegistrationCount} معلّق</StatusBadge> : "—"}</td><td className="p-4 text-xs text-[var(--muted)]">{new Intl.DateTimeFormat("ar-SA", { dateStyle: "medium", timeStyle: "short" }).format(new Date(row.updatedAt))}</td><td className="p-4">{row.status === "cancelled" ? <button type="button" className="button-secondary" disabled={busy === row.id} onClick={() => void mutate(row, "reopen")}><PlayCircle size={15} />إعادة فتح</button> : row.status !== "completed" ? <button type="button" className="button-secondary text-[#a72b38]" disabled={busy === row.id} onClick={() => void mutate(row, "cancel")}><Ban size={15} />إلغاء</button> : <span className="text-xs text-[var(--muted)]">مؤرشفة</span>}</td></tr>)}</tbody></table></div> : <div className="grid min-h-52 place-items-center text-center"><div><Trophy className="mx-auto text-[var(--muted)]" /><p className="mt-3 font-black">لا توجد بطولات مطابقة</p></div></div>}
    </section>
    <p className="text-xs leading-6 text-[var(--muted)]">الإلغاء الإداري لا يحذف السجل أو النتائج. تظل أحداث البطولة محفوظة للتدقيق، وتقتصر إعادة الفتح على حالة التسجيل.</p>
  </div>;
}

function Metric({ label, value, icon: Icon }: { label: string; value: number; icon: typeof Trophy }) {
  return <div className="surface-card flex items-center gap-3 p-4"><span className="grid size-10 place-items-center rounded-xl bg-[#74b512]/10 text-[#527f0c]"><Icon size={19} /></span><span><strong className="block text-2xl font-black" dir="ltr">{value}</strong><span className="text-[11px] text-[var(--muted)]">{label}</span></span></div>;
}
