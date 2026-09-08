import { Activity, BellRing, Bug, Cloud, Database, Radio } from "lucide-react";
import { PageHeader } from "@/components/ui/page-header";
import { StatusBadge } from "@/components/ui/status-badge";
import { requireAdminPage } from "@/lib/auth/context";
import { getSystemHealthData } from "@/lib/data/monitoring-data";
import { formatDate, formatNumber } from "@/lib/utils";

export const metadata = { title: "صحة الأنظمة" };
export const dynamic = "force-dynamic";
export default async function SystemHealthPage() {
  await requireAdminPage("moderator"); const health = await getSystemHealthData();
  const checks: Array<{ label: string; state: "healthy" | "problem" | "unknown"; detail: string; icon: typeof Database }> = [
    { label: "الاتصال بـSupabase", state: health.connected ? "healthy" : "problem", detail: health.connected ? "تم تنفيذ استعلام إدارة فعلي" : "لا يوجد اتصال أو إعداد صالح", icon: Database },
    { label: "عقد المحتوى المنشور", state: !health.connected ? "unknown" : health.contentRpcAvailable ? "healthy" : "problem", detail: health.contentRpcAvailable ? `${formatNumber(health.publishedContentCount)} قيمة منشورة` : "RPC غير متاح أو لم يمكن التحقق منه", icon: Cloud },
    { label: "رصد أخطاء التطبيق", state: !health.connected ? "unknown" : health.monitoringAvailable ? "healthy" : "problem", detail: health.monitoringAvailable ? `${formatNumber(health.errors24h)} حدث خلال 24 ساعة` : "تعذر قراءة سجل المراقبة", icon: Bug },
    { label: "إرسال الإشعارات", state: !health.notificationMonitoringAvailable || !health.lastNotificationAttempt ? "unknown" : health.notificationFailures24h === 0 ? "healthy" : "problem", detail: health.lastNotificationAttempt ? `آخر محاولة ${formatDate(health.lastNotificationAttempt)} · ${formatNumber(health.notificationFailures24h)} فشل` : "لا توجد محاولة إرسال مسجلة للحكم على الحالة", icon: BellRing },
  ];
  return <div className="space-y-6"><PageHeader eyebrow="بيانات حقيقية فقط" title="صحة الأنظمة" description="مؤشرات مباشرة من Supabase وسجلات الإرسال والمحتوى. لا تمثل فحصًا خارجيًا شاملًا ولا تعرض حالة خضراء افتراضية." />
    <section className="grid gap-4 md:grid-cols-2">{checks.map(({ label, state, detail, icon: Icon }) => <article key={label} className="surface-card p-5"><div className="flex items-start gap-4"><span className={`grid size-11 place-items-center rounded-xl ${state === "healthy" ? "bg-[#74b512]/10 text-[#527f0c]" : state === "problem" ? "bg-[#c83443]/10 text-[#c83443]" : "bg-black/5 text-[var(--muted)]"}`}><Icon size={21} /></span><div><div className="flex flex-wrap items-center gap-2"><h2 className="font-black">{label}</h2><StatusBadge tone={state === "healthy" ? "success" : state === "problem" ? "danger" : "neutral"}>{state === "healthy" ? "متاح" : state === "problem" ? "يحتاج مراجعة" : "غير معروف"}</StatusBadge></div><p className="mt-2 text-sm leading-6 text-[var(--muted)]">{detail}</p></div></div></article>)}</section>
    <section className="grid gap-4 xl:grid-cols-[1fr_.7fr]"><article className="surface-card p-5"><div className="flex items-center gap-2"><Radio size={18} className="text-[var(--primary-strong)]" /><h2 className="font-black">إصدارات الأجهزة النشطة</h2></div><div className="mt-4 space-y-2">{health.activeVersions.map((item) => <div key={item.version} className="flex items-center justify-between rounded-xl border border-black/8 bg-white p-3 text-sm"><span dir="ltr">v{item.version}</span><strong>{formatNumber(item.devices)} جهاز</strong></div>)}{!health.activeVersions.length ? <p className="py-7 text-center text-sm text-[var(--muted)]">لا توجد Device Tokens نشطة تحمل رقم إصدار.</p> : null}</div></article><article className="surface-card p-5"><div className="flex items-center gap-2"><Activity size={18} className="text-[var(--primary-strong)]" /><h2 className="font-black">آخر نشر للمحتوى</h2></div><p className="mt-6 text-2xl font-black">{health.lastContentPublish ? formatDate(health.lastContentPublish) : "—"}</p><p className="mt-2 text-sm leading-6 text-[var(--muted)]">يتحقق هذا المؤشر من آخر `published_at` في عقد المحتوى، ولا يفترض أن كل جهاز استلم التحديث.</p></article></section>
  </div>;
}
