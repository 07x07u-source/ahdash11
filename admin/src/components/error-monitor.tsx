"use client";

import { useMemo, useState } from "react";
import { AlertTriangle, Bug, CheckCircle2, ChevronDown, LoaderCircle, RotateCcw, Search, ShieldAlert, UsersRound } from "lucide-react";
import type { ErrorMonitoringData, ErrorIssueRow } from "@/lib/data/monitoring-data";
import { formatDate, formatNumber } from "@/lib/utils";
import { StatusBadge } from "./ui/status-badge";

const severityLabels = { info: "معلومات", warning: "تحذير", error: "خطأ", critical: "حرج" } as const;
const categoryLabels: Record<string, string> = { startup: "بدء التشغيل", api: "API", supabase: "Supabase", content: "المحتوى", matchmaking: "البحث عن منافس", room: "الغرف", wallet: "المحفظة", notification: "الإشعارات", image: "الصور", purchase: "المشتريات", auth: "الدخول", offline_sync: "المزامنة", unexpected_state: "حالة غير متوقعة" };

function severityTone(value: ErrorIssueRow["severity"]): "neutral" | "warning" | "danger" | "info" {
  if (value === "critical" || value === "error") return "danger";
  if (value === "warning") return "warning";
  return "info";
}

export function ErrorMonitor({ data, canResolve }: { data: ErrorMonitoringData; canResolve: boolean }) {
  const [severity, setSeverity] = useState("all");
  const [status, setStatus] = useState("open");
  const [platform, setPlatform] = useState("all");
  const [version, setVersion] = useState("all");
  const [feature, setFeature] = useState("all");
  const [period, setPeriod] = useState("all");
  const [query, setQuery] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const filtered = useMemo(() => data.rows.filter((row) => {
    const search = query.trim().toLocaleLowerCase("ar");
    const reference = new Date(data.generatedAt).getTime();
    const since = period === "24h" ? reference - 86_400_000 : period === "7d" ? reference - 604_800_000 : 0;
    return (severity === "all" || row.severity === severity) && (status === "all" || row.status === status) && (platform === "all" || row.platform === platform) && (version === "all" || row.appVersion === version) && (feature === "all" || row.feature === feature) && (!since || new Date(row.lastSeen).getTime() >= since) && (!search || `${row.title} ${row.feature} ${row.message} ${row.appVersion}`.toLocaleLowerCase("ar").includes(search));
  }), [data.generatedAt, data.rows, feature, period, platform, query, severity, status, version]);
  const versions = useMemo(() => [...new Set(data.rows.map((row) => row.appVersion))].sort(), [data.rows]);
  const features = useMemo(() => [...new Set(data.rows.map((row) => row.feature))].sort(), [data.rows]);

  async function updateIssue(row: ErrorIssueRow, nextStatus: "open" | "resolved", note: string) {
    setBusy(row.id); setMessage(null);
    try {
      const response = await fetch(`/api/errors/${row.id}`, { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify({ status: nextStatus, note: note || null }) });
      const body = await response.json() as { error?: string };
      if (!response.ok) throw new Error(body.error ?? "تعذر تحديث المشكلة.");
      setMessage("تم تحديث المشكلة. أعد تحميل الصفحة لرؤية الحالة المحدثة.");
    } catch (error) { setMessage(error instanceof Error ? error.message : "تعذر تحديث المشكلة."); }
    finally { setBusy(null); }
  }

  if (!data.available) return <div className="surface-card p-8 text-center"><Bug className="mx-auto text-[var(--muted)]" /><h2 className="mt-3 font-black">بيانات المراقبة غير متاحة بعد</h2><p className="mt-2 text-sm text-[var(--muted)]">طبّق migration الجديدة محليًا أو على البيئة المقصودة ليبدأ استقبال الأحداث. لا نعرض أرقامًا تجريبية.</p></div>;

  const metrics = [
    { label: "اليوم", value: data.summary.today, icon: AlertTriangle },
    { label: "آخر 24 ساعة", value: data.summary.last24h, icon: AlertTriangle },
    { label: "آخر 7 أيام", value: data.summary.last7d, icon: Bug },
    { label: "مشاكل مفتوحة", value: data.summary.open, icon: Bug },
    { label: "أخطاء حرجة", value: data.summary.critical, icon: ShieldAlert },
    { label: "تم حلها", value: data.summary.resolved, icon: CheckCircle2 },
    { label: "الإصدار الأكثر تأثرًا", value: data.summary.mostAffectedVersion ? `v${data.summary.mostAffectedVersion}` : "—", icon: UsersRound },
  ];
  return <div className="space-y-5">
    <section className="grid grid-cols-2 gap-3 lg:grid-cols-4">{metrics.map(({ label, value, icon: Icon }) => <article key={label} className="surface-card p-4"><div className="flex items-center justify-between"><span className="text-xs font-bold text-[var(--muted)]">{label}</span><Icon size={18} className="text-[var(--primary-strong)]" /></div><strong className="mt-3 block text-2xl font-black" dir="ltr">{typeof value === "number" ? formatNumber(value) : value}</strong></article>)}</section>
    <section className="surface-card p-4"><div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4"><label className="relative md:col-span-2"><Search className="absolute right-3 top-3.5 text-[var(--muted)]" size={17} /><input className="field pr-10" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="ابحث بالعنوان أو الميزة أو الإصدار" /></label><select className="field" value={severity} onChange={(event) => setSeverity(event.target.value)}><option value="all">كل الدرجات</option>{Object.entries(severityLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select><select className="field" value={status} onChange={(event) => setStatus(event.target.value)}><option value="all">كل الحالات</option><option value="open">مفتوحة</option><option value="resolved">محلولة</option></select><select className="field" value={platform} onChange={(event) => setPlatform(event.target.value)}><option value="all">كل المنصات</option><option value="android">Android</option><option value="ios">iOS</option></select><select className="field" value={version} onChange={(event) => setVersion(event.target.value)}><option value="all">كل الإصدارات</option>{versions.map((value) => <option key={value} value={value}>v{value}</option>)}</select><select className="field" value={feature} onChange={(event) => setFeature(event.target.value)}><option value="all">كل الميزات</option>{features.map((value) => <option key={value} value={value}>{value}</option>)}</select><select className="field" value={period} onChange={(event) => setPeriod(event.target.value)}><option value="all">كل الفترات</option><option value="24h">آخر 24 ساعة</option><option value="7d">آخر 7 أيام</option></select></div></section>
    {message ? <div role="status" className="rounded-xl border border-[#2f6fba]/20 bg-[#2f6fba]/7 p-3 text-sm text-[#275f9f]">{message}</div> : null}
    <section className="space-y-3">
      {filtered.map((row) => <details key={row.id} className="surface-card group overflow-hidden">
        <summary className="flex cursor-pointer list-none items-start gap-3 p-4 sm:p-5"><span className={`mt-1 size-2.5 shrink-0 rounded-full ${row.severity === "critical" ? "bg-[#c83443] shadow-[0_0_0_5px_rgba(200,52,67,.1)]" : row.severity === "error" ? "bg-[#d95842]" : row.severity === "warning" ? "bg-[#aa7200]" : "bg-[#2f6fba]"}`} /><span className="min-w-0 flex-1"><span className="flex flex-wrap items-center gap-2"><strong className="text-sm font-black">{row.title}</strong><StatusBadge tone={severityTone(row.severity)}>{severityLabels[row.severity]}</StatusBadge><StatusBadge>{categoryLabels[row.category] ?? row.category}</StatusBadge></span><span className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-[11px] text-[var(--muted)]"><span>{formatNumber(row.occurrenceCount)} تكرار</span><span className="flex items-center gap-1"><UsersRound size={12} />{formatNumber(row.affectedUsers)} مستخدم</span><span dir="ltr">v{row.appVersion} ({row.buildNumber})</span><span>{row.platform}</span><span>آخر ظهور {formatDate(row.lastSeen)}</span></span></span><ChevronDown className="mt-1 text-[var(--muted)] transition group-open:rotate-180" size={18} /></summary>
        <div className="border-t border-black/7 bg-black/[0.018] p-4 sm:p-5"><div className="grid gap-5 xl:grid-cols-[1.2fr_.8fr]"><div><h3 className="text-xs font-black">الرسالة المنقّحة</h3><p className="mt-2 rounded-xl border border-black/8 bg-white p-3 text-sm leading-6">{row.message}</p><h3 className="mt-4 text-xs font-black">Stack trace المنقّح</h3><pre className="mt-2 max-h-64 overflow-auto whitespace-pre-wrap rounded-xl bg-[#11171e] p-4 text-left text-[11px] leading-5 text-[#d5dce4]" dir="ltr">{row.stack || "لا يوجد stack trace محفوظ."}</pre><h3 className="mt-4 text-xs font-black">آخر مرات الظهور</h3><div className="mt-2 space-y-2">{row.occurrences.map((entry) => <div key={entry.id} className="rounded-xl border border-black/8 bg-white p-3 text-[11px]"><div className="flex flex-wrap justify-between gap-2"><strong>{formatDate(entry.occurredAt)}</strong><span>{entry.networkState} · {entry.screen ?? "شاشة غير محددة"}</span></div>{Object.keys(entry.context).length ? <code className="mt-2 block overflow-x-auto text-[9px] text-[var(--muted)]" dir="ltr">{JSON.stringify(entry.context)}</code> : null}</div>)}{!row.occurrences.length ? <p className="rounded-xl border border-black/8 bg-white p-3 text-xs text-[var(--muted)]">لا توجد تفاصيل occurrence متاحة ضمن آخر السجلات.</p> : null}</div></div><div className="space-y-3"><div className="rounded-xl border border-black/8 bg-white p-4 text-xs leading-6"><p><strong>الميزة:</strong> {row.feature}</p><p><strong>أول ظهور:</strong> {formatDate(row.firstSeen)}</p><p><strong>آخر ظهور:</strong> {formatDate(row.lastSeen)}</p><p><strong>الحالة:</strong> {row.status === "resolved" ? "محلولة" : "مفتوحة"}</p></div><div className="rounded-xl border border-black/8 bg-white p-4 text-xs"><h3 className="font-black">بلاغات مرتبطة ({formatNumber(row.relatedReports.length)})</h3>{row.relatedReports.map((report) => <div key={report.id} className="mt-3 border-t border-black/7 pt-3"><p className="font-bold">{report.category} · {report.status}</p><p className="mt-1 text-[var(--muted)]">{report.description ?? "بلا وصف"}</p></div>)}{!row.relatedReports.length ? <p className="mt-2 text-[var(--muted)]">لا توجد بلاغات مرتبطة بهذه المشكلة.</p> : null}</div><IssueAction row={row} busy={busy === row.id} disabled={!canResolve || busy !== null} onSubmit={(next, note) => void updateIssue(row, next, note)} /></div></div></div>
      </details>)}
      {!filtered.length ? <div className="surface-card p-10 text-center"><CheckCircle2 className="mx-auto text-[var(--primary)]" /><p className="mt-3 font-black">لا توجد نتائج مطابقة</p><p className="mt-1 text-sm text-[var(--muted)]">غيّر المرشحات أو راجع الفترة لاحقًا.</p></div> : null}
    </section>
  </div>;
}

function IssueAction({ row, busy, disabled, onSubmit }: { row: ErrorIssueRow; busy: boolean; disabled: boolean; onSubmit: (status: "open" | "resolved", note: string) => void }) {
  const [note, setNote] = useState(row.internalNote ?? "");
  const next = row.status === "open" ? "resolved" : "open";
  return <div className="rounded-xl border border-black/8 bg-white p-4"><label className="text-xs font-bold">ملاحظة داخلية<textarea className="field mt-2 min-h-24 resize-y" maxLength={2000} value={note} onChange={(event) => setNote(event.target.value)} placeholder="لا تُكتب بيانات مستخدم حساسة هنا" /></label><button type="button" disabled={disabled} onClick={() => onSubmit(next, note)} className={row.status === "open" ? "button-primary mt-3 w-full" : "button-secondary mt-3 w-full"}>{busy ? <LoaderCircle className="animate-spin" size={16} /> : row.status === "open" ? <CheckCircle2 size={16} /> : <RotateCcw size={16} />}{row.status === "open" ? "تحديد كمحلولة" : "إعادة فتح المشكلة"}</button></div>;
}
