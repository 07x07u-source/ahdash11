"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { Check, Eye, ImageIcon, LoaderCircle, RotateCcw, Save, Send } from "lucide-react";

interface ContentItem {
  key: string;
  section: string;
  contentType: "text" | "image" | "text_image";
  labelAr: string;
  usageAr: string;
  defaultTextAr: string | null;
  draftTextAr: string | null;
  publishedTextAr: string | null;
  draftMediaId: string | null;
  publishedMediaId: string | null;
  minLength: number;
  maxLength: number;
  version: number;
  draftUpdatedAt: string | null;
  publishedAt: string | null;
}

interface MediaChoice { id: string; url: string; altText: string; storagePath: string; assetGroup: string }
interface Payload { items: ContentItem[]; media: MediaChoice[]; canPublish: boolean; developmentFallback: boolean }

const sectionLabels: Record<string, string> = {
  home: "الرئيسية",
  premium: "Premium",
  store: "المتجر",
  announcements: "الإعلانات",
  system: "النظام",
};

export function ContentManager() {
  const [payload, setPayload] = useState<Payload | null>(null);
  const [drafts, setDrafts] = useState<Record<string, { text: string; mediaId: string }>>({});
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [message, setMessage] = useState<{ tone: "success" | "error"; text: string } | null>(null);
  const [activeSection, setActiveSection] = useState("home");

  const applyPayload = useCallback((data: Payload) => {
    setPayload(data);
    setDrafts(Object.fromEntries(data.items.map((item) => [item.key, { text: item.draftTextAr ?? "", mediaId: item.draftMediaId ?? "" }])));
  }, []);

  const load = useCallback(async () => {
    const response = await fetch("/api/content", { cache: "no-store" });
    const data = await response.json() as Payload & { error?: string };
    if (!response.ok) throw new Error(data.error ?? "تعذر تحميل المحتوى.");
    applyPayload(data);
  }, [applyPayload]);

  useEffect(() => {
    let active = true;
    void fetch("/api/content", { cache: "no-store" })
      .then(async (response) => ({ response, data: await response.json() as Payload & { error?: string } }))
      .then(({ response, data }) => {
        if (!response.ok) throw new Error(data.error ?? "تعذر تحميل المحتوى.");
        if (active) applyPayload(data);
      })
      .catch((error: unknown) => {
        if (active) setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر تحميل المحتوى." });
      });
    return () => { active = false; };
  }, [applyPayload]);

  const sections = useMemo(() => Array.from(new Set(payload?.items.map((item) => item.section) ?? [])), [payload]);
  const items = payload?.items.filter((item) => item.section === activeSection) ?? [];

  async function mutate(item: ContentItem, action: "save" | "reset" | "publish") {
    setBusyKey(`${item.key}:${action}`);
    setMessage(null);
    try {
      const draft = drafts[item.key];
      const response = await fetch("/api/content", {
        method: "PATCH",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(action === "save" ? { action, key: item.key, valueAr: draft.text || null, mediaId: draft.mediaId || null } : { action, key: item.key }),
      });
      const data = await response.json() as { error?: string };
      if (!response.ok) throw new Error(data.error ?? "تعذر تنفيذ العملية.");
      await load();
      setMessage({ tone: "success", text: action === "publish" ? "نُشر المحتوى وأصبح جاهزًا للتطبيق." : action === "reset" ? "أُعيدت المسودة إلى القيمة الافتراضية." : "حُفظت المسودة بأمان." });
    } catch (error) {
      setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر تنفيذ العملية." });
    } finally {
      setBusyKey(null);
    }
  }

  if (!payload) return <div className="surface-card grid min-h-56 place-items-center"><LoaderCircle className="animate-spin text-[#b6ff3b]" /></div>;

  return (
    <div className="space-y-5">
      {payload.developmentFallback ? <div className="rounded-xl border border-[#ffc857]/20 bg-[#ffc857]/7 p-3 text-xs text-[#e3c77f]">المعاينة تعمل ببيانات محلية. طبّق migration واربط Supabase لتفعيل الحفظ والرفع.</div> : null}
      {message ? <div role="status" className={`rounded-xl border p-3 text-xs ${message.tone === "success" ? "border-[#b6ff3b]/20 bg-[#b6ff3b]/7 text-[#d6ff94]" : "border-[#ff4d57]/20 bg-[#ff4d57]/7 text-[#ff9ca2]"}`}>{message.text}</div> : null}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {sections.map((section) => <button key={section} type="button" onClick={() => setActiveSection(section)} className={`shrink-0 rounded-xl px-4 py-2 text-xs font-black transition ${activeSection === section ? "bg-[#b6ff3b] text-[#0b0f14]" : "border border-white/8 bg-white/[0.025] text-[#aeb7c4]"}`}>{sectionLabels[section] ?? section}</button>)}
      </div>
      <div className="grid gap-4 xl:grid-cols-2">
        {items.map((item) => {
          const draft = drafts[item.key] ?? { text: "", mediaId: "" };
          const media = payload.media.find((asset) => asset.id === draft.mediaId);
          const publishedMedia = payload.media.find((asset) => asset.id === item.publishedMediaId);
          const changed = draft.text !== (item.publishedTextAr ?? "") || draft.mediaId !== (item.publishedMediaId ?? "");
          return (
            <article key={item.key} className="surface-card overflow-hidden">
              <div className="flex items-start justify-between gap-3 border-b border-white/7 p-5">
                <div><p className="font-mono text-[9px] text-[#6f7c8d]" dir="ltr">{item.key}</p><h2 className="mt-1 text-sm font-black">{item.labelAr}</h2><p className="mt-1 text-[11px] leading-5 text-[#7f8b9a]">{item.usageAr}</p></div>
                <span className={`rounded-full px-2 py-1 text-[9px] font-bold ${changed ? "bg-[#ffc857]/10 text-[#ffc857]" : "bg-[#b6ff3b]/10 text-[#b6ff3b]"}`}>{changed ? "مسودة" : `منشور v${item.version}`}</span>
              </div>
              <div className="grid gap-4 p-5 sm:grid-cols-2">
                <div className="space-y-3">
                  {item.contentType !== "image" ? <label className="block text-[11px] font-bold text-[#aeb7c4]">النص العربي<textarea value={draft.text} maxLength={item.maxLength} onChange={(event) => setDrafts((state) => ({ ...state, [item.key]: { ...draft, text: event.target.value } }))} className="mt-2 min-h-28 w-full resize-y rounded-xl border border-white/8 bg-[#090d12] p-3 text-sm leading-6 text-white outline-none focus:border-[#b6ff3b]/45" /><span className="mt-1 block text-left font-mono text-[9px] text-[#596577]" dir="ltr">{draft.text.length}/{item.maxLength}</span></label> : null}
                  {item.contentType !== "text" ? <label className="block text-[11px] font-bold text-[#aeb7c4]">الصورة<select value={draft.mediaId} onChange={(event) => setDrafts((state) => ({ ...state, [item.key]: { ...draft, mediaId: event.target.value } }))} className="mt-2 h-11 w-full rounded-xl border border-white/8 bg-[#090d12] px-3 text-xs text-white"><option value="">الصورة المحلية الافتراضية</option>{payload.media.map((asset) => <option key={asset.id} value={asset.id}>{asset.altText || asset.storagePath}</option>)}</select></label> : null}
                  <div className="flex flex-wrap gap-2"><button type="button" disabled={busyKey !== null || payload.developmentFallback} onClick={() => void mutate(item, "save")} className="inline-flex h-10 items-center gap-2 rounded-xl bg-[#b6ff3b] px-3 text-[11px] font-black text-[#0b0f14] disabled:opacity-50">{busyKey === `${item.key}:save` ? <LoaderCircle size={14} className="animate-spin" /> : <Save size={14} />}حفظ المسودة</button><button type="button" disabled={busyKey !== null || payload.developmentFallback} onClick={() => void mutate(item, "reset")} className="inline-flex h-10 items-center gap-2 rounded-xl border border-white/8 px-3 text-[11px] font-bold text-[#aeb7c4] disabled:opacity-40"><RotateCcw size={14} />الافتراضي</button>{payload.canPublish ? <button type="button" disabled={busyKey !== null || !changed || payload.developmentFallback} onClick={() => void mutate(item, "publish")} className="inline-flex h-10 items-center gap-2 rounded-xl border border-[#5797e6]/25 bg-[#5797e6]/8 px-3 text-[11px] font-bold text-[#9cc6fa] disabled:opacity-35"><Send size={14} />نشر</button> : null}</div>
                </div>
                <div><p className="mb-2 flex items-center gap-2 text-[10px] font-bold text-[#7f8b9a]"><Eye size={13} />معاينة المسودة</p><div className="relative min-h-36 overflow-hidden rounded-xl border border-white/8 bg-[#0a0f15] bg-cover bg-center" style={media ? { backgroundImage: `linear-gradient(90deg, rgba(8,12,17,.94), rgba(8,12,17,.3)), url(${JSON.stringify(media.url).slice(1, -1)})` } : undefined}><div className="absolute inset-0 grid content-end p-4">{item.contentType === "image" && !media ? <div className="grid place-items-center gap-2 text-[#657183]"><ImageIcon size={28} /><span className="text-[10px]">ستُستخدم الصورة المحلية</span></div> : <p className="max-w-xs text-sm font-black leading-6 text-white">{draft.text || item.labelAr}</p>}</div></div><p className="mt-2 flex items-center gap-1 text-[9px] text-[#657183]"><Check size={11} />المنشور الآن: {item.publishedTextAr || publishedMedia?.altText || "الصورة المحلية"}</p></div>
              </div>
            </article>
          );
        })}
      </div>
    </div>
  );
}
