"use client";

import { BellRing, CalendarClock, Eye, LoaderCircle, Send, Smartphone } from "lucide-react";
import { FormEvent, useRef, useState } from "react";

const destinations = [
  ["/home", "الرئيسية"], ["/notifications", "مركز الإشعارات"], ["/profile", "الملف الشخصي"],
  ["/store", "المتجر"], ["/ranking", "الترتيب"], ["/friends", "الأصدقاء"],
] as const;

export function NotificationCampaignForm() {
  const submitting = useRef(false);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [type, setType] = useState("announcement");
  const [audience, setAudience] = useState("all");
  const [deepLink, setDeepLink] = useState("/notifications");
  const [scheduledAt, setScheduledAt] = useState("");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (submitting.current) return;
    submitting.current = true;
    setBusy(true); setMessage(""); setError("");
    try {
      const response = await fetch("/api/notifications", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title, body, type, audience, deepLink,
          requestId: crypto.randomUUID(),
          scheduledAt: scheduledAt ? new Date(scheduledAt).toISOString() : null,
        }),
      });
      const payload = await response.json() as { error?: string; duplicate?: boolean; dispatchRequested?: boolean };
      if (!response.ok) throw new Error(payload.error || "تعذر إنشاء الحملة.");
      setMessage(payload.duplicate ? "هذه العملية مسجلة مسبقًا ولم تُرسل مرتين." : payload.dispatchRequested ? "حُفظت الحملة وبدأ طلب الإرسال." : "حُفظت الحملة في الطابور.");
      setTitle(""); setBody(""); setScheduledAt("");
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "تعذر إنشاء الحملة.");
    } finally {
      submitting.current = false;
      setBusy(false);
    }
  }

  return (
    <div className="grid items-start gap-5 xl:grid-cols-[minmax(0,1.3fr)_minmax(300px,.7fr)]">
      <form onSubmit={submit} className="surface-card overflow-hidden">
        <div className="flex items-center gap-3 border-b border-[var(--border)] p-5"><span className="grid size-10 place-items-center rounded-xl bg-[var(--surface-3)] text-[var(--primary-strong)]"><BellRing size={19} /></span><div><h2 className="text-sm font-black">حملة Push جديدة</h2><p className="mt-1 text-xs text-[var(--muted)]">راجع المعاينة والوجهة قبل إضافتها إلى طابور FCM.</p></div></div>
        <div className="grid gap-4 p-5 sm:grid-cols-2">
          <label className="sm:col-span-2"><span className="mb-2 block text-xs font-bold">العنوان</span><input value={title} onChange={(event) => setTitle(event.target.value)} className="field" maxLength={80} minLength={3} required placeholder="تحدي اليوم جاهز" /></label>
          <label className="sm:col-span-2"><span className="mb-2 block text-xs font-bold">نص الرسالة</span><textarea value={body} onChange={(event) => setBody(event.target.value)} className="field min-h-24 resize-y" maxLength={240} minLength={5} required placeholder="ادخل الآن واختبر معلوماتك الكروية…" /></label>
          <label><span className="mb-2 block text-xs font-bold">النوع</span><select value={type} onChange={(event) => setType(event.target.value)} className="field"><option value="announcement">إعلان مهم</option><option value="daily_challenge">تحدي يومي</option><option value="reward">مكافأة</option><option value="season">موسم</option><option value="system">نظام</option></select></label>
          <label><span className="mb-2 block text-xs font-bold">الجمهور</span><select value={audience} onChange={(event) => setAudience(event.target.value)} className="field"><option value="all">كل المستخدمين</option><option value="active">النشطون</option><option value="premium">Premium</option><option value="inactive_7d">غير نشطين منذ 7 أيام</option></select></label>
          <label><span className="mb-2 block text-xs font-bold">الوجهة عند الضغط</span><select value={deepLink} onChange={(event) => setDeepLink(event.target.value)} className="field">{destinations.map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
          <label><span className="mb-2 flex items-center gap-2 text-xs font-bold"><CalendarClock size={14} /> موعد اختياري</span><input value={scheduledAt} onChange={(event) => setScheduledAt(event.target.value)} type="datetime-local" className="field" /></label>
        </div>
        {(message || error) ? <p aria-live="polite" className={`mx-5 mb-4 rounded-xl border p-3 text-xs ${error ? "border-red-200 bg-red-50 text-[var(--danger)]" : "border-lime-200 bg-lime-50 text-[var(--primary-strong)]"}`}>{error || message}</p> : null}
        <div className="flex justify-end border-t border-[var(--border)] p-4"><button type="submit" disabled={busy} className="button-primary">{busy ? <LoaderCircle size={16} className="animate-spin" /> : <Send size={16} />} إضافة إلى طابور الإرسال</button></div>
      </form>

      <aside className="surface-card sticky top-5 overflow-hidden" aria-label="معاينة الإشعار">
        <div className="flex items-center gap-2 border-b border-[var(--border)] p-4 text-sm font-black"><Eye size={16} /> معاينة قبل الإرسال</div>
        <div className="p-5">
          <div className="mx-auto max-w-sm rounded-[1.75rem] border border-[var(--border-strong)] bg-[var(--surface-3)] p-3 shadow-sm">
            <div className="rounded-2xl bg-[var(--surface)] p-4 shadow-sm">
              <div className="flex items-start gap-3"><span className="grid size-9 shrink-0 place-items-center rounded-xl bg-[var(--primary)] text-[#101600]"><Smartphone size={16} /></span><div className="min-w-0"><p className="truncate text-sm font-black">{title.trim() || "عنوان الإشعار"}</p><p className="mt-1 text-xs leading-5 text-[var(--muted)]">{body.trim() || "سيظهر نص الرسالة هنا قبل الإرسال."}</p><p className="mt-2 text-[10px] text-[var(--primary-strong)]">يفتح: {destinations.find(([value]) => value === deepLink)?.[1]}</p></div></div>
            </div>
          </div>
          <p className="mt-4 text-xs leading-6 text-[var(--muted)]">المعاينة تقريبية؛ العرض النهائي يختلف قليلًا حسب إصدار Android أو iOS وإعدادات الجهاز.</p>
        </div>
      </aside>
    </div>
  );
}
