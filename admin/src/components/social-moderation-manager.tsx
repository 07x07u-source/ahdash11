"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { Ban, CheckCircle2, LoaderCircle } from "lucide-react";
import type { SocialModerationData } from "@/lib/data/social-football-data";

export function SocialModerationManager({ data, disabled }: { data: SocialModerationData; disabled: boolean }) {
  const router = useRouter();
  const [message, setMessage] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  async function moderate(teamId: string, status: "active" | "suspended") {
    const reason = status === "suspended" ? window.prompt("سبب التعليق (يظهر للمراجعين فقط):")?.trim() : null;
    if (status === "suspended" && !reason) return;
    const response = await fetch("/api/social/moderate", { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify({ teamId, status, reason }) });
    const result = await response.json() as { error?: string };
    if (!response.ok) return setMessage(result.error ?? "تعذر تنفيذ الإجراء.");
    setMessage(status === "active" ? "أعيد تفعيل الفريق." : "عُلّق الفريق وسُجل الإجراء.");
    startTransition(() => router.refresh());
  }
  async function reviewReport(reportId: string, status: "reviewing" | "resolved" | "dismissed") {
    const note = window.prompt("ملاحظة إدارية اختيارية:")?.trim() || null;
    const response = await fetch("/api/social/moderate", { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify({ reportId, status, note }) });
    const result = await response.json() as { error?: string };
    if (!response.ok) return setMessage(result.error ?? "تعذر تحديث البلاغ.");
    setMessage("حُدّث البلاغ وسُجل الإجراء في سجل التدقيق.");
    startTransition(() => router.refresh());
  }
  return <div className="grid gap-5 xl:grid-cols-[1.35fr_1fr]">
    <section className="surface-card overflow-hidden"><div className="border-b border-[var(--border)] p-4"><h2 className="font-black">الفرق الخاصة</h2><p className="mt-1 text-[10px] text-[var(--muted)]">لا تُعرض المحتويات الخاصة؛ الإشراف على الاسم والحالة والبلاغات فقط.</p></div><div className="divide-y divide-[var(--border)]">{data.teams.map((team) => <article key={team.id} className="flex items-center gap-3 p-4"><span className="grid size-10 place-items-center rounded-xl bg-[var(--surface-3)] font-black">{team.name.charAt(0)}</span><div className="min-w-0 flex-1"><strong className="block truncate text-sm">{team.name}</strong><span className="text-[10px] text-[var(--muted)]">{team.memberCount} أعضاء • {team.status}</span>{team.reason ? <span className="block text-[9px] text-red-600">{team.reason}</span> : null}</div>{team.status === "active" ? <button disabled={disabled || pending} onClick={() => void moderate(team.id, "suspended")} className="inline-flex min-h-9 items-center gap-1 rounded-lg bg-red-500/8 px-3 text-[10px] font-bold text-red-600"><Ban size={13} />تعليق</button> : <button disabled={disabled || pending} onClick={() => void moderate(team.id, "active")} className="inline-flex min-h-9 items-center gap-1 rounded-lg bg-emerald-500/8 px-3 text-[10px] font-bold text-emerald-700"><CheckCircle2 size={13} />تفعيل</button>}</article>)}</div>{!data.teams.length ? <p className="p-8 text-center text-xs text-[var(--muted)]">لا توجد فرق فعلية لعرضها.</p> : null}</section>
    <section className="surface-card overflow-hidden"><div className="border-b border-[var(--border)] p-4"><h2 className="font-black">بلاغات Social</h2></div><div className="divide-y divide-[var(--border)]">{data.reports.map((report) => <article key={report.id} className="p-4"><div className="flex items-center justify-between gap-2"><strong className="text-xs">{report.reason}</strong><span className="rounded-full bg-amber-500/10 px-2 py-1 text-[9px] font-bold">{report.status}</span></div><p className="mt-2 font-mono text-[9px] text-[var(--muted)]" dir="ltr">{report.subjectType}:{report.subjectId}</p>{report.status === "open" || report.status === "reviewing" ? <div className="mt-3 flex flex-wrap gap-2"><button disabled={disabled || pending} onClick={() => void reviewReport(report.id, "reviewing")} className="rounded-lg bg-blue-500/8 px-2 py-1.5 text-[9px] font-bold text-blue-700">قيد المراجعة</button><button disabled={disabled || pending} onClick={() => void reviewReport(report.id, "resolved")} className="rounded-lg bg-emerald-500/8 px-2 py-1.5 text-[9px] font-bold text-emerald-700">معالجة</button><button disabled={disabled || pending} onClick={() => void reviewReport(report.id, "dismissed")} className="rounded-lg bg-[var(--surface-3)] px-2 py-1.5 text-[9px] font-bold">استبعاد</button></div> : null}</article>)}</div>{!data.reports.length ? <p className="p-8 text-center text-xs text-[var(--muted)]">لا توجد بلاغات Social فعلية.</p> : null}</section>
    {message || pending ? <p role="status" className="xl:col-span-2 flex items-center gap-2 text-xs font-bold text-[var(--muted)]">{pending ? <LoaderCircle size={14} className="animate-spin" /> : null}{message}</p> : null}
  </div>;
}
