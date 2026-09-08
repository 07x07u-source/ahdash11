"use client";

import { LoaderCircle, Save, SlidersHorizontal } from "lucide-react";
import { FormEvent, useState } from "react";
import type { GameSettingItem } from "@/lib/data/admin-data";

export function SettingsForm({ items }: { items: GameSettingItem[] }) {
  const [values, setValues] = useState<Record<string, number>>(Object.fromEntries(items.map((item) => [item.key, item.value])));
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function submit(event: FormEvent) {
    event.preventDefault(); setBusy(true); setMessage(""); setError("");
    try {
      const response = await fetch("/api/settings", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ settings: Object.entries(values).map(([key, value]) => ({ key, value })) }) });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "تعذر حفظ الإعدادات.");
      setMessage(payload.developmentFallback ? "تم حفظ القيم لهذه الجلسة التجريبية فقط." : `تم حفظ ${payload.affected} إعداد.`);
    } catch (saveError) { setError(saveError instanceof Error ? saveError.message : "تعذر حفظ الإعدادات."); }
    finally { setBusy(false); }
  }

  return (
    <form onSubmit={submit} className="surface-card overflow-hidden">
      <div className="flex items-center gap-3 border-b border-white/7 p-5"><span className="grid size-10 place-items-center rounded-xl bg-[#b6ff3b]/8 text-[#b6ff3b]"><SlidersHorizontal size={19} /></span><div><h2 className="text-sm font-black">قيم تشغيل اللعبة</h2><p className="mt-1 text-[10px] text-[#697586]">يقرأها الخادم والتطبيق من game_settings بدل تثبيتها في الكود.</p></div></div>
      <div className="grid gap-3 p-5 md:grid-cols-2">
        {items.map((item) => (
          <label key={item.key} className="rounded-xl border border-white/7 bg-white/[0.018] p-3">
            <span className="flex items-start justify-between gap-3"><span><strong className="block text-xs text-[#e7ebef]">{item.description}</strong><code className="mt-1 block text-[9px] text-[#647082]" dir="ltr">{item.key}</code></span>{item.isPublic ? <span className="rounded-full bg-sky-400/8 px-2 py-1 text-[9px] font-bold text-sky-300">عام</span> : <span className="rounded-full bg-white/5 px-2 py-1 text-[9px] font-bold text-[#778393]">خادم</span>}</span>
            <input type="number" min={0} step={1} value={values[item.key]} onChange={(event) => setValues((current) => ({ ...current, [item.key]: Number(event.target.value) }))} className="field mt-3" dir="ltr" required />
          </label>
        ))}
      </div>
      {(message || error) ? <p role="status" className={`mx-5 mb-4 rounded-xl border p-3 text-[11px] ${error ? "border-[#ff4d57]/20 bg-[#ff4d57]/8 text-[#ff9298]" : "border-[#b6ff3b]/20 bg-[#b6ff3b]/7 text-[#cfff7d]"}`}>{error || message}</p> : null}
      <div className="flex justify-end border-t border-white/7 p-4"><button type="submit" disabled={busy} className="button-primary">{busy ? <LoaderCircle size={16} className="animate-spin" /> : <Save size={16} />} حفظ الإعدادات</button></div>
    </form>
  );
}
