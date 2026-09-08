"use client";

import { useMemo, useState } from "react";
import { CheckCircle2, ClipboardList, LoaderCircle, Search } from "lucide-react";
import type { UserProblemReportRow } from "@/lib/data/monitoring-data";
import { formatDate } from "@/lib/utils";
import { StatusBadge } from "./ui/status-badge";

const statusLabels = { new: "جديد", in_review: "قيد المراجعة", resolved: "محلول", rejected: "مرفوض" } as const;
const categoryLabels: Record<string, string> = { login: "الدخول", gameplay: "اللعب", matchmaking: "البحث عن منافس", room: "الغرف", content: "المحتوى", image: "الصور", wallet: "المحفظة", purchase: "المشتريات", notification: "الإشعارات", performance: "الأداء", other: "أخرى" };

export function UserProblemReports({ available, rows }: { available: boolean; rows: UserProblemReportRow[] }) {
  const [status, setStatus] = useState("all"); const [query, setQuery] = useState(""); const [busy, setBusy] = useState<string | null>(null); const [message, setMessage] = useState<string | null>(null);
  const filtered = useMemo(() => rows.filter((row) => (status === "all" || row.status === status) && (!query.trim() || `${row.description} ${row.screen} ${row.appVersion}`.toLocaleLowerCase("ar").includes(query.trim().toLocaleLowerCase("ar")))), [query, rows, status]);
  async function update(row: UserProblemReportRow, nextStatus: UserProblemReportRow["status"], note: string, issueId: string) {
    setBusy(row.id); setMessage(null);
    try {
      const response = await fetch(`/api/user-reports/${row.id}`, { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify({ status: nextStatus, note: note || null, linkedIssueId: issueId || null }) });
      const body = await response.json() as { error?: string }; if (!response.ok) throw new Error(body.error ?? "تعذر تحديث البلاغ."); setMessage("تم تحديث البلاغ. أعد تحميل الصفحة لرؤية الحالة الجديدة.");
    } catch (error) { setMessage(error instanceof Error ? error.message : "تعذر تحديث البلاغ."); } finally { setBusy(null); }
  }
  if (!available) return <div className="surface-card p-8 text-center"><ClipboardList className="mx-auto text-[var(--muted)]" /><h2 className="mt-3 font-black">نظام البلاغات غير متاح بعد</h2><p className="mt-2 text-sm text-[var(--muted)]">لا تُعرض بيانات تجريبية. طبّق migration الجديدة لتفعيل الاستقبال والمراجعة.</p></div>;
  return <div className="space-y-4">
    <div className="surface-card grid gap-3 p-4 md:grid-cols-[1fr_200px]"><label className="relative"><Search size={17} className="absolute right-3 top-3.5 text-[var(--muted)]" /><input className="field pr-10" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="ابحث في الوصف أو الشاشة أو الإصدار" /></label><select className="field" value={status} onChange={(event) => setStatus(event.target.value)}><option value="all">كل الحالات</option>{Object.entries(statusLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></div>
    {message ? <div role="status" className="rounded-xl border border-[#2f6fba]/20 bg-[#2f6fba]/7 p-3 text-sm text-[#275f9f]">{message}</div> : null}
    <div className="grid gap-4 xl:grid-cols-2">{filtered.map((row) => <ReportCard key={row.id} row={row} busy={busy === row.id} disabled={busy !== null} onSubmit={(next, note, issue) => void update(row, next, note, issue)} />)}</div>
    {!filtered.length ? <div className="surface-card p-10 text-center"><CheckCircle2 className="mx-auto text-[var(--primary)]" /><p className="mt-3 font-black">لا توجد بلاغات مطابقة</p></div> : null}
  </div>;
}

function ReportCard({ row, busy, disabled, onSubmit }: { row: UserProblemReportRow; busy: boolean; disabled: boolean; onSubmit: (status: UserProblemReportRow["status"], note: string, issue: string) => void }) {
  const [nextStatus, setNextStatus] = useState<UserProblemReportRow["status"]>(row.status === "new" ? "in_review" : row.status);
  const [note, setNote] = useState(row.adminNote ?? ""); const [issue, setIssue] = useState(row.linkedIssueId ?? "");
  return <article className="surface-card overflow-hidden"><div className="flex items-start justify-between gap-3 border-b border-black/7 p-5"><div><div className="flex items-center gap-2"><StatusBadge tone={row.status === "resolved" ? "success" : row.status === "rejected" ? "danger" : row.status === "in_review" ? "warning" : "info"}>{statusLabels[row.status]}</StatusBadge><span className="text-xs font-black">{categoryLabels[row.category] ?? row.category}</span></div><p className="mt-2 text-[11px] text-[var(--muted)]">{row.platform} · v{row.appVersion} ({row.buildNumber}) · {formatDate(row.createdAt)}</p></div><code className="text-[9px] text-[var(--muted)]" dir="ltr">{row.id.slice(0, 8)}</code></div><div className="space-y-4 p-5"><div><p className="text-[10px] font-bold text-[var(--muted)]">الوصف المنقّح</p><p className="mt-1 min-h-12 text-sm leading-6">{row.description || "لم يضف المستخدم وصفًا."}</p><p className="mt-2 text-[11px] text-[var(--muted)]">الشاشة: {row.screen || "غير محددة"}</p></div><div className="grid gap-3 sm:grid-cols-2"><label className="text-[11px] font-bold">الحالة<select className="field mt-1" value={nextStatus} onChange={(event) => setNextStatus(event.target.value as UserProblemReportRow["status"])}>{Object.entries(statusLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label><label className="text-[11px] font-bold">ربط بمشكلة تشغيلية<input className="field mt-1" dir="ltr" value={issue} onChange={(event) => setIssue(event.target.value)} placeholder="UUID اختياري" /></label></div><label className="block text-[11px] font-bold">ملاحظة داخلية<textarea className="field mt-1 min-h-20 resize-y" maxLength={2000} value={note} onChange={(event) => setNote(event.target.value)} /></label><button type="button" className="button-primary w-full" disabled={disabled} onClick={() => onSubmit(nextStatus, note, issue)}>{busy ? <LoaderCircle size={16} className="animate-spin" /> : <CheckCircle2 size={16} />}حفظ المراجعة</button></div></article>;
}
