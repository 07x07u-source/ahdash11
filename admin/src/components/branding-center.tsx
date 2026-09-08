"use client";

import Image from "next/image";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { Check, Download, ImageIcon, LoaderCircle, RotateCcw, Save, Send, Smartphone } from "lucide-react";

interface ContentItem { key: string; section: string; contentType: "text" | "image" | "text_image"; labelAr: string; usageAr: string; draftTextAr: string | null; publishedTextAr: string | null; draftMediaId: string | null; publishedMediaId: string | null; version: number }
interface MediaChoice { id: string; url: string; altText: string; storagePath: string; assetGroup: string; width: number; height: number; sizeBytes: number }
interface Payload { items: ContentItem[]; media: MediaChoice[]; canPublish: boolean; developmentFallback: boolean }

const sectionLabels: Record<string, string> = { branding: "الأصول البصرية", app_icon: "أيقونة التطبيق", appearance: "المظهر الآمن", feature_controls: "التحكم بالعرض", promotions: "الحملات" };
const allowedSections = Object.keys(sectionLabels);

export function BrandingCenter() {
  const [payload, setPayload] = useState<Payload | null>(null);
  const [drafts, setDrafts] = useState<Record<string, { text: string; mediaId: string }>>({});
  const [section, setSection] = useState("branding");
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<{ tone: "success" | "error"; text: string } | null>(null);

  const apply = useCallback((data: Payload) => { setPayload(data); setDrafts(Object.fromEntries(data.items.map((item) => [item.key, { text: item.draftTextAr ?? "", mediaId: item.draftMediaId ?? "" }]))); }, []);
  const load = useCallback(async () => { const response = await fetch("/api/content", { cache: "no-store" }); const data = await response.json() as Payload & { error?: string }; if (!response.ok) throw new Error(data.error ?? "تعذر تحميل الهوية."); apply(data); }, [apply]);
  useEffect(() => {
    const timer = window.setTimeout(() => {
      void load().catch((error: unknown) => setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر تحميل الهوية." }));
    }, 0);
    return () => window.clearTimeout(timer);
  }, [load]);
  const items = useMemo(() => payload?.items.filter((item) => item.section === section) ?? [], [payload, section]);
  const dirty = useMemo(() => payload?.items.some((item) => { const draft = drafts[item.key]; return draft && (draft.text !== (item.draftTextAr ?? "") || draft.mediaId !== (item.draftMediaId ?? "")); }) ?? false, [drafts, payload]);
  useEffect(() => { const warn = (event: BeforeUnloadEvent) => { if (!dirty) return; event.preventDefault(); }; window.addEventListener("beforeunload", warn); return () => window.removeEventListener("beforeunload", warn); }, [dirty]);

  async function mutate(item: ContentItem, action: "save" | "reset" | "publish") {
    if (action === "publish" && !window.confirm("نشر هذا التغيير للمستخدمين؟ سيبقى التطبيق يستخدم fallback محليًا عند تعذر التحميل.")) return;
    setBusy(`${item.key}:${action}`); setMessage(null);
    try { const draft = drafts[item.key]; const response = await fetch("/api/content", { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify(action === "save" ? { action, key: item.key, valueAr: draft.text || null, mediaId: draft.mediaId || null } : { action, key: item.key }) }); const body = await response.json() as { error?: string }; if (!response.ok) throw new Error(body.error ?? "تعذر تنفيذ العملية."); await load(); setMessage({ tone: "success", text: action === "publish" ? "نُشر التغيير بنجاح." : action === "reset" ? "عادت المسودة إلى القيمة الافتراضية." : "حُفظت المسودة." }); }
    catch (error) { setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر تنفيذ العملية." }); } finally { setBusy(null); }
  }

  if (!payload) return <div className="surface-card grid min-h-64 place-items-center"><LoaderCircle className="animate-spin text-[var(--primary)]" /></div>;
  return <div className="space-y-5">
    {payload.developmentFallback ? <div className="rounded-xl border border-[#aa7200]/20 bg-[#aa7200]/7 p-3 text-sm text-[#855900]">معاينة محلية فقط. طبّق migration الجديدة لظهور مفاتيح الهوية والحفظ الحقيقي.</div> : null}
    {message ? <div role="status" className={`rounded-xl border p-3 text-sm ${message.tone === "success" ? "border-[#74b512]/20 bg-[#74b512]/7 text-[#527f0c]" : "border-[#c83443]/20 bg-[#c83443]/7 text-[#a72b38]"}`}>{message.text}</div> : null}
    <div className="flex gap-2 overflow-x-auto pb-1">{allowedSections.map((value) => <button key={value} type="button" onClick={() => setSection(value)} className={section === value ? "button-primary shrink-0" : "button-secondary shrink-0"}>{sectionLabels[value]}</button>)}</div>
    {section === "app_icon" ? <AppIconNotice /> : null}
    <div className="grid gap-4 xl:grid-cols-2">{items.map((item) => <BrandItem key={item.key} item={item} draft={drafts[item.key] ?? { text: "", mediaId: "" }} media={payload.media} canPublish={payload.canPublish} developmentFallback={payload.developmentFallback} busy={busy} onDraft={(next) => setDrafts((current) => ({ ...current, [item.key]: next }))} onMutate={(action) => void mutate(item, action)} />)}</div>
    {!items.length ? <div className="surface-card p-10 text-center"><ImageIcon className="mx-auto text-[var(--muted)]" /><p className="mt-3 font-black">لا توجد مفاتيح في هذا القسم</p><p className="mt-1 text-sm text-[var(--muted)]">ستظهر بعد تطبيق migration الجديدة.</p></div> : null}
  </div>;
}

function BrandItem({ item, draft, media, canPublish, developmentFallback, busy, onDraft, onMutate }: { item: ContentItem; draft: { text: string; mediaId: string }; media: MediaChoice[]; canPublish: boolean; developmentFallback: boolean; busy: string | null; onDraft: (value: { text: string; mediaId: string }) => void; onMutate: (action: "save" | "reset" | "publish") => void }) {
  const selected = media.find((asset) => asset.id === draft.mediaId); const published = media.find((asset) => asset.id === item.publishedMediaId); const changedFromPublished = draft.text !== (item.publishedTextAr ?? "") || draft.mediaId !== (item.publishedMediaId ?? ""); const isFeature = item.section === "feature_controls"; const isAccent = item.key === "appearance.accent.color"; const isAppIcon = item.key === "branding.appicon.master";
  const choices = media.filter((asset) => isAppIcon ? asset.assetGroup === "app-icons" : ["branding", "promotions", "app-content"].includes(asset.assetGroup));
  return <article className="surface-card overflow-hidden"><div className="flex items-start justify-between gap-3 border-b border-black/7 p-5"><div><code className="text-[9px] text-[var(--muted)]" dir="ltr">{item.key}</code><h2 className="mt-1 text-sm font-black">{item.labelAr}</h2><p className="mt-1 text-[11px] leading-5 text-[var(--muted)]">{item.usageAr}</p></div><span className={`rounded-full px-2 py-1 text-[9px] font-bold ${changedFromPublished ? "bg-[#aa7200]/10 text-[#855900]" : "bg-[#74b512]/10 text-[#527f0c]"}`}>{changedFromPublished ? "مسودة" : `منشور v${item.version}`}</span></div><div className="grid gap-4 p-5 sm:grid-cols-2"><div className="space-y-3">
    {isFeature ? <div className="grid grid-cols-2 gap-2"><button type="button" onClick={() => onDraft({ ...draft, text: "true" })} className={draft.text === "true" ? "button-primary" : "button-secondary"}>ظاهر</button><button type="button" onClick={() => onDraft({ ...draft, text: "false" })} className={draft.text === "false" ? "button-primary" : "button-secondary"}>مخفي</button></div> : null}
    {isAccent ? <label className="block text-xs font-bold">لون التمييز<div className="mt-2 flex gap-2"><input type="color" aria-label="اختيار لون التمييز" value={/^#[0-9A-Fa-f]{6}$/.test(draft.text) ? draft.text : "#78B814"} onChange={(event) => onDraft({ ...draft, text: event.target.value.toUpperCase() })} className="h-12 w-16 rounded-xl border border-black/10 bg-white p-1" /><input className="field font-mono" dir="ltr" maxLength={7} value={draft.text} onChange={(event) => onDraft({ ...draft, text: event.target.value })} /></div></label> : null}
    {item.contentType !== "text" ? <label className="block text-xs font-bold">الأصل من مكتبة الوسائط<select className="field mt-2" value={draft.mediaId} onChange={(event) => onDraft({ ...draft, mediaId: event.target.value })}><option value="">Fallback المحلي</option>{choices.map((asset) => <option key={asset.id} value={asset.id}>{asset.altText || asset.storagePath} · {asset.width}×{asset.height}</option>)}</select></label> : null}
    <div className="flex flex-wrap gap-2"><button type="button" className="button-primary" disabled={busy !== null || developmentFallback} onClick={() => onMutate("save")}>{busy === `${item.key}:save` ? <LoaderCircle size={15} className="animate-spin" /> : <Save size={15} />}حفظ مسودة</button><button type="button" className="button-secondary" disabled={busy !== null || developmentFallback} onClick={() => onMutate("reset")}><RotateCcw size={15} />تراجع</button>{canPublish ? <button type="button" className="button-secondary" disabled={busy !== null || !changedFromPublished || developmentFallback} onClick={() => onMutate("publish")}><Send size={15} />نشر</button> : null}</div>
  </div><div><p className="mb-2 text-[10px] font-bold text-[var(--muted)]">المعاينة</p>{isAppIcon ? <AppIconPreview asset={selected ?? published} /> : item.contentType !== "text" ? <div className="relative aspect-[16/9] overflow-hidden rounded-2xl border border-black/10 bg-[var(--surface-3)]">{selected ? <Image src={selected.url} alt={selected.altText || item.labelAr} fill sizes="(max-width: 768px) 90vw, 360px" className="object-cover" /> : <div className="absolute inset-0 grid place-items-center text-[var(--muted)]"><ImageIcon /></div>}</div> : <div className="grid min-h-32 place-items-center rounded-2xl border border-black/10 bg-[var(--surface-3)] p-5"><span className="rounded-xl px-5 py-3 text-sm font-black" style={isAccent ? { backgroundColor: draft.text, color: "#101600" } : undefined}>{isFeature ? (draft.text === "true" ? "سيظهر القسم" : "سيبقى مخفيًا") : draft.text}</span></div>}{selected ? <p className="mt-2 flex items-center gap-1 text-[10px] text-[var(--muted)]"><Check size={12} />{selected.width}×{selected.height} · {(selected.sizeBytes / 1024).toFixed(0)} KB</p> : null}</div></div></article>;
}

function AppIconNotice() { return <div className="surface-card border-[#2f6fba]/20 bg-[#2f6fba]/5 p-5"><div className="flex items-start gap-3"><Smartphone className="mt-1 shrink-0 text-[#2f6fba]" /><div><h2 className="font-black">تغيير أيقونة التطبيق يتطلب إصدار نسخة جديدة</h2><p className="mt-2 text-sm leading-6 text-[var(--muted)]">هذه الصفحة تعتمد Master Asset فقط. بعد اعتماده يُنزّل إلى `assets/branding/app-icon.png` ثم تُولد أيقونات Android وiOS وقت البناء. لا يمكن تغيير Launcher Icon المثبتة من السيرفر.</p><Link href="/media" className="button-secondary mt-3"><ImageIcon size={16} />رفع أصل إلى مجموعة App Icons</Link></div></div></div>; }
function AppIconPreview({ asset }: { asset?: MediaChoice }) { return <div className="rounded-2xl border border-black/10 bg-gradient-to-br from-[#eef1eb] to-white p-5">{asset ? <><div className="flex items-center justify-center gap-5"><span className="relative size-20 overflow-hidden rounded-[22%] shadow-lg"><Image src={asset.url} alt={asset.altText || "معاينة iOS"} fill sizes="80px" className="object-cover" /></span><span className="relative size-20 overflow-hidden rounded-full shadow-lg"><Image src={asset.url} alt={asset.altText || "معاينة دائرية"} fill sizes="80px" className="object-cover" /></span><span className="relative size-20 overflow-hidden rounded-2xl shadow-lg"><Image src={asset.url} alt={asset.altText || "معاينة Android"} fill sizes="80px" className="object-cover" /></span></div><a className="button-secondary mt-5 w-full" href={asset.url} download><Download size={16} />تنزيل المصدر المعتمد</a></> : <div className="grid min-h-32 place-items-center text-center text-sm text-[var(--muted)]"><span><Smartphone className="mx-auto mb-2" />اختر صورة مربعة 1024×1024 على الأقل</span></div>}</div>; }
