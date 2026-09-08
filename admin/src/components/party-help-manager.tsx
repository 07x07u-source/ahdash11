"use client";

import { LoaderCircle, Save } from "lucide-react";
import { useState } from "react";

export interface PartyHelpItem {
  id: "two_chances" | "call_friend" | "risk" | "bench" | "pass";
  nameAr: string;
  descriptionAr: string;
  iconKey: string;
  timing: "before_question" | "after_question";
  active: boolean;
  config: Record<string, unknown>;
}

export function PartyHelpManager({ initialItems }: { initialItems: PartyHelpItem[] }) {
  const [items, setItems] = useState(() => initialItems.map((item) => ({ ...item, configText: JSON.stringify(item.config) })));
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState("");
  async function save(item: PartyHelpItem) {
    setBusy(item.id); setMessage("");
    try {
      const editable = item as PartyHelpItem & { configText?: string };
      const config = JSON.parse(editable.configText ?? "{}") as Record<string, unknown>;
      const response = await fetch("/api/party-game", { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify({ ...item, config }) });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "تعذر الحفظ.");
      setMessage(payload.developmentFallback ? "محاكاة تطوير فقط." : `حُفظت «${item.nameAr}».`);
    } catch (error) { setMessage(error instanceof Error ? error.message : "تعذر الحفظ."); }
    finally { setBusy(null); }
  }
  return <section className="surface-card overflow-hidden">
    <div className="border-b border-white/7 p-5"><h2 className="text-sm font-black">كتالوج المساعدات</h2><p className="mt-1 text-[10px] text-[var(--muted)]">خمس أدوات فقط. إعداد التأثير محفوظ كـ JSON وتطبقه قواعد الجلسة.</p></div>
    <div className="grid gap-3 p-5 xl:grid-cols-2">
      {items.map((item, index) => <article key={item.id} className="rounded-xl border border-white/7 bg-white/[0.018] p-3">
        <div className="grid gap-2 sm:grid-cols-2">
          <label className="text-[10px] font-bold">الاسم<input className="field mt-1" value={item.nameAr} onChange={(event) => setItems((current) => current.map((value, valueIndex) => valueIndex === index ? { ...value, nameAr: event.target.value } : value))} /></label>
          <label className="text-[10px] font-bold">التوقيت<select className="field mt-1" value={item.timing} onChange={(event) => setItems((current) => current.map((value, valueIndex) => valueIndex === index ? { ...value, timing: event.target.value as PartyHelpItem["timing"] } : value))}><option value="before_question">قبل السؤال</option><option value="after_question">بعد عرض السؤال</option></select></label>
        </div>
        <label className="mt-2 block text-[10px] font-bold">مفتاح الأيقونة<input dir="ltr" className="field mt-1" value={item.iconKey} onChange={(event) => setItems((current) => current.map((value, valueIndex) => valueIndex === index ? { ...value, iconKey: event.target.value } : value))} /></label>
        <label className="mt-2 block text-[10px] font-bold">الوصف<input className="field mt-1" value={item.descriptionAr} onChange={(event) => setItems((current) => current.map((value, valueIndex) => valueIndex === index ? { ...value, descriptionAr: event.target.value } : value))} /></label>
        <label className="mt-2 block text-[10px] font-bold">إعداد التأثير JSON<textarea dir="ltr" className="field mt-1 min-h-16 font-mono text-[10px]" value={item.configText} onChange={(event) => setItems((current) => current.map((value, valueIndex) => valueIndex === index ? { ...value, configText: event.target.value } : value))} /></label>
        <div className="mt-2 flex items-center gap-3"><label className="flex items-center gap-2 text-xs"><input type="checkbox" checked={item.active} onChange={(event) => setItems((current) => current.map((value, valueIndex) => valueIndex === index ? { ...value, active: event.target.checked } : value))} /> مفعلة</label><div className="flex-1" /><button type="button" disabled={busy !== null} onClick={() => void save(item)} className="button-secondary min-h-9 px-3 text-xs">{busy === item.id ? <LoaderCircle size={14} className="animate-spin" /> : <Save size={14} />} حفظ</button></div>
      </article>)}
    </div>
    {message ? <p role="status" className="mx-5 mb-5 text-xs text-[var(--primary-strong)]">{message}</p> : null}
  </section>;
}
