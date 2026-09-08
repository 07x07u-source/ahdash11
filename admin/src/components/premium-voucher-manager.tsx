"use client";

import { Check, Clipboard, Gift, Loader2, Plus, ShieldCheck, TicketCheck, XCircle } from "lucide-react";
import { useMemo, useState } from "react";
import type { CreatedPremiumVoucher, PremiumVoucherRow, VoucherType } from "@/lib/premium-vouchers/schema";

const typeLabel: Record<VoucherType, string> = {
  monthly_promo: "شهر ترويجي",
  annual_promo: "سنة ترويجية",
};

const statusLabel: Record<PremiumVoucherRow["status"], string> = {
  unused: "غير مستخدمة",
  redeemed: "مستخدمة",
  expired: "منتهية",
  disabled: "معطلة",
};

export function PremiumVoucherManager({
  initialRows,
  backendAvailable,
  actionsEnabled,
  initialVoucherType = "monthly_promo",
  initialCreated = [],
}: {
  initialRows: PremiumVoucherRow[];
  backendAvailable: boolean;
  actionsEnabled: boolean;
  initialVoucherType?: VoucherType;
  initialCreated?: CreatedPremiumVoucher[];
}) {
  const [rows, setRows] = useState(initialRows);
  const [voucherType, setVoucherType] = useState<VoucherType>(initialVoucherType);
  const [quantity, setQuantity] = useState(1);
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);
  const [created, setCreated] = useState<CreatedPremiumVoucher[]>(initialCreated);
  const [message, setMessage] = useState<string | null>(null);
  const counts = useMemo(() => ({
    unused: rows.filter((row) => row.status === "unused").length,
    redeemed: rows.filter((row) => row.status === "redeemed").length,
  }), [rows]);

  async function createVouchers(event: React.FormEvent) {
    event.preventDefault();
    if (busy || !actionsEnabled) return;
    setBusy(true);
    setMessage(null);
    setCreated([]);
    try {
      const response = await fetch("/api/premium-vouchers", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ voucherType, quantity, internalNote: note }),
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "تعذر إنشاء القسيمة.");
      setCreated(payload.vouchers);
      setMessage("اعرض الرموز وانسخها الآن؛ لن تظهر مرة أخرى بعد إغلاق هذه اللوحة.");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "تعذر إنشاء القسيمة.");
    } finally {
      setBusy(false);
    }
  }

  async function disableVoucher(id: string) {
    if (busy || !actionsEnabled) return;
    setBusy(true);
    setMessage(null);
    try {
      const response = await fetch(`/api/premium-vouchers/${id}/disable`, { method: "POST" });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "تعذر تعطيل القسيمة.");
      setRows((current) => current.map((row) => row.id === id ? { ...row, status: "disabled" } : row));
      setMessage("تم تعطيل القسيمة غير المستخدمة.");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "تعذر تعطيل القسيمة.");
    } finally {
      setBusy(false);
    }
  }

  return <div className="space-y-6">
    <section className="relative overflow-hidden rounded-[1.75rem] border border-[#191714] bg-[#191714] p-6 text-[#fbf7ef] lg:p-8">
      <div className="absolute inset-y-0 right-0 w-1.5 bg-[#ffc857]" />
      <div className="pointer-events-none absolute -left-14 -top-20 size-72 rounded-full border border-[#ffc857]/20" />
      <div className="pointer-events-none absolute left-10 top-8 grid grid-cols-4 gap-3 opacity-25" aria-hidden="true">
        {Array.from({ length: 12 }).map((_, index) => <span key={index} className={`size-2 rounded-full ${index === 5 ? "bg-[#b6ff3b]" : "bg-[#ddceb5]"}`} />)}
      </div>
      <div className="relative max-w-2xl">
        <p dir="ltr" className="mb-4 text-[10px] font-black tracking-[0.2em] text-[#ffc857]">AHDASH / VOUCHER DESK 11</p>
        <h2 className="text-3xl font-black leading-tight lg:text-4xl">رموز قصيرة العرض.<br />صلاحية كاملة التدقيق.</h2>
        <p className="mt-4 max-w-xl text-sm leading-7 text-[#ddceb5]">أنشئ القسيمة من جهة الخادم، انسخ السر مرة واحدة، ثم تابع حالتها دون كشف الرمز مجددًا.</p>
      </div>
    </section>
    {!actionsEnabled ? <div className="rounded-2xl border border-[#ffc857]/35 bg-[#ffc857]/10 p-4 text-sm leading-7 text-[#785613]">
      <strong className="block text-base">بوابة السياسة مغلقة</strong>
      الإنشاء والاسترداد معطلان افتراضيًا حتى اعتماد Apple وGoogle وتفعيل مفتاحي البيئة والخادم.
    </div> : null}

    <section className="grid gap-3 sm:grid-cols-3">
      <Metric icon={TicketCheck} label="إجمالي القسائم" value={rows.length} />
      <Metric icon={Gift} label="غير مستخدمة" value={counts.unused} />
      <Metric icon={Check} label="تم استردادها" value={counts.redeemed} />
    </section>

    <section className="grid gap-6 xl:grid-cols-[22rem_1fr]">
      <form onSubmit={createVouchers} className="overflow-hidden rounded-[1.4rem] border border-[#191714] bg-[#fbf7ef]">
        <div className="flex items-center gap-3 bg-[#191714] p-5 text-[#fbf7ef]"><span className="grid size-11 place-items-center rounded-xl border border-[#fbf7ef]/25 bg-[#b6ff3b] text-[#191714]"><Plus size={20} /></span><div><p dir="ltr" className="text-[9px] font-black tracking-[0.16em] text-[#ffc857]">CREATE / 01</p><h2 className="text-lg font-black">إنشاء قسيمة</h2><p className="text-xs text-[#ddceb5]">سر عالي العشوائية — عرض وحيد</p></div></div>
        <fieldset disabled={busy || !actionsEnabled} className="space-y-4">
          <div className="space-y-4 p-5">
            <div><span className="mb-2 block text-xs font-black">نوع القسيمة</span><div className="grid grid-cols-2 gap-2 rounded-xl bg-[#ebe0cf] p-1.5" role="radiogroup" aria-label="نوع القسيمة">
              {(["monthly_promo", "annual_promo"] as VoucherType[]).map((type) => <button key={type} type="button" role="radio" aria-checked={voucherType === type} onClick={() => setVoucherType(type)} className={`min-h-12 rounded-lg border px-3 text-sm font-black transition ${voucherType === type ? "border-[#191714] bg-[#fbf7ef] text-[#191714]" : "border-transparent text-[#756e63]"}`}>{type === "monthly_promo" ? "شهر" : "سنة"}<span className="mt-0.5 block text-[9px] font-normal">غير متجددة</span></button>)}
            </div></div>
            <label className="block text-xs font-black">الكمية <span className="font-normal text-[var(--muted)]">/ حتى 50</span><input type="number" min={1} max={50} value={quantity} onChange={(event) => setQuantity(Number(event.target.value))} className="mt-2 min-h-12 w-full rounded-xl border border-[#d3c6b2] bg-[#fbf7ef] px-3 text-base font-black" /></label>
            <label className="block text-xs font-black">ملاحظة داخلية <span className="font-normal text-[var(--muted)]">/ اختيارية</span><textarea maxLength={500} value={note} onChange={(event) => setNote(event.target.value)} className="mt-2 min-h-24 w-full resize-y rounded-xl border border-[#d3c6b2] bg-[#fbf7ef] p-3" /></label>
            <button className="flex min-h-12 w-full items-center justify-center gap-2 rounded-xl border border-[#191714] bg-[#b6ff3b] px-4 font-black text-[#191714] shadow-[3px_3px_0_#191714] transition active:translate-x-[2px] active:translate-y-[2px] active:shadow-none disabled:opacity-45">{busy ? <Loader2 className="animate-spin" size={18} /> : <Plus size={18} />}إنشاء القسيمة</button>
          </div>
        </fieldset>
      </form>

      <div className="overflow-hidden rounded-[1.4rem] border border-[#191714] bg-[#fbf7ef]">
        <div className="flex items-center justify-between border-b border-[#d3c6b2] p-5"><div><p dir="ltr" className="text-[9px] font-black tracking-[0.16em] text-[#7eb900]">LEDGER / LIVE</p><h2 className="text-lg font-black">سجل القسائم</h2><p className="text-xs text-[var(--muted)]">الحالة فقط — لا أسرار خام</p></div><span className="grid size-11 place-items-center rounded-xl bg-[#191714] text-[#b6ff3b]"><ShieldCheck size={20} /></span></div>
        {!backendAvailable ? <VoucherEmpty text="اتصال قاعدة البيانات غير متاح. لا نعرض بيانات تجريبية تشغيلية." /> : rows.length === 0 ? <VoucherEmpty text="لا توجد قسائم منشأة بعد." /> : <div className="overflow-x-auto"><table className="w-full min-w-[760px] text-right text-sm"><thead className="bg-[#ebe0cf]"><tr><th className="p-3">النوع</th><th className="p-3">الحالة</th><th className="p-3">الإنشاء</th><th className="p-3">المستفيد</th><th className="p-3">انتهاء Premium</th><th className="p-3">إجراء</th></tr></thead><tbody>{rows.map((row) => <tr key={row.id} className="border-t border-[#d3c6b2] transition hover:bg-[#f4ebdd]"><td className="p-3 font-black">{typeLabel[row.voucherType]}</td><td className="p-3"><VoucherStatus status={row.status} /></td><td className="p-3">{formatDate(row.createdAt)}</td><td className="p-3">{row.redeemedBy ?? "—"}</td><td className="p-3">{row.promoExpiresAt ? formatDate(row.promoExpiresAt) : "—"}</td><td className="p-3">{row.status === "unused" ? <button type="button" onClick={() => disableVoucher(row.id)} disabled={busy || !actionsEnabled} className="inline-flex min-h-10 items-center gap-1 rounded-lg px-3 font-bold text-[#9b302b] hover:bg-[#9b302b]/8 disabled:opacity-40"><XCircle size={16} />تعطيل</button> : "—"}</td></tr>)}</tbody></table></div>}
      </div>
    </section>

    {created.length ? <section className="overflow-hidden rounded-[1.4rem] border border-[#191714] bg-[#191714] text-[#fbf7ef]"><div className="flex items-start justify-between border-b border-[#fbf7ef]/15 p-5"><div><p dir="ltr" className="text-[9px] font-black tracking-[0.18em] text-[#ffc857]">ONE-TIME REVEAL</p><h2 className="text-xl font-black">الرموز الجديدة</h2><p className="mt-1 text-sm text-[#ddceb5]">انسخها الآن؛ لن تظهر بعد مغادرة الصفحة.</p></div><TicketCheck className="text-[#b6ff3b]" /></div><div className="grid gap-3 p-5">{created.map((voucher) => <div key={voucher.id} className="relative flex items-center gap-3 overflow-hidden rounded-xl border border-[#fbf7ef]/25 bg-[#35312b] p-4 before:absolute before:inset-y-0 before:right-0 before:w-1 before:bg-[#ffc857]"><code dir="ltr" className="flex-1 select-all text-base font-black tracking-[0.15em] text-[#fbf7ef]">{voucher.code}</code><button type="button" onClick={() => navigator.clipboard.writeText(voucher.code)} className="grid size-11 place-items-center rounded-xl border border-[#fbf7ef]/25 bg-[#b6ff3b] text-[#191714]" aria-label="نسخ الرمز"><Clipboard size={18} /></button></div>)}</div></section> : null}
    {message ? <p role="status" className="rounded-xl border border-black/10 bg-white p-3 text-center text-sm">{message}</p> : null}
  </div>;
}

function Metric({ icon: Icon, label, value }: { icon: typeof Gift; label: string; value: number }) {
  return <div className="relative flex min-h-24 items-center gap-4 overflow-hidden rounded-2xl border border-[#d3c6b2] bg-[#fbf7ef] p-4 before:absolute before:inset-y-3 before:right-0 before:w-1 before:rounded-full before:bg-[#b6ff3b]"><span className="grid size-11 place-items-center rounded-xl bg-[#191714] text-[#b6ff3b]"><Icon size={20} /></span><div><strong className="block text-3xl font-black leading-none">{value}</strong><span className="mt-1 block text-xs text-[var(--muted)]">{label}</span></div></div>;
}

function VoucherStatus({ status }: { status: PremiumVoucherRow["status"] }) {
  const styles: Record<PremiumVoucherRow["status"], string> = {
    unused: "border-[#7eb900]/35 bg-[#b6ff3b]/20",
    redeemed: "border-[#191714]/15 bg-[#ebe0cf]",
    expired: "border-[#ffc857]/45 bg-[#ffc857]/16",
    disabled: "border-[#756e63]/25 bg-[#ddceb5]/45 text-[#756e63]",
  };
  return <span className={`inline-flex rounded-full border px-2.5 py-1 text-xs font-black ${styles[status]}`}>{statusLabel[status]}</span>;
}

function VoucherEmpty({ text }: { text: string }) {
  return <div className="grid min-h-72 place-items-center p-8 text-center"><div><div className="relative mx-auto mb-4 h-24 w-40 rounded-2xl border border-[#d3c6b2] bg-[#f4ebdd]"><span className="absolute left-7 top-8 size-4 rounded-full bg-[#ffc857]" /><span className="absolute right-8 top-5 grid size-12 place-items-center rounded-xl border border-[#191714] bg-[#b6ff3b] font-black">11</span><span className="absolute bottom-5 left-6 right-6 h-px rotate-[-9deg] bg-[#191714]" /></div><p className="text-sm leading-7 text-[var(--muted)]">{text}</p></div></div>;
}

function formatDate(value: string) {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? "—" : new Intl.DateTimeFormat("ar-SA", { dateStyle: "medium" }).format(date);
}
