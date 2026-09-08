"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { CheckSquare, Clipboard, Download, Grid2X2, ImagePlus, List, LoaderCircle, RefreshCcw, Search, Square, Trash2, Upload } from "lucide-react";
import { formatDate, formatNumber } from "@/lib/utils";

interface MediaUsage { type: string; id: string; label: string; state: string }
interface MediaAsset {
  id: string; originalFilename: string; storagePath: string; mimeType: string;
  sizeBytes: number; width: number; height: number; altText: string;
  assetGroup: string; createdAt: string; createdBy: string | null; updatedAt: string;
  slotKey: string | null; rightsStatus: string; status: string; version: number;
  sourceText: string | null; attribution: string | null;
  url: string; usage: MediaUsage[];
}

const groups = [
  ["app-content", "محتوى التطبيق"], ["categories", "التصنيفات"],
  ["store", "المتجر"], ["achievements", "الإنجازات"],
  ["promotions", "العروض"], ["onboarding", "الترحيب"],
  ["branding", "هوية التطبيق"], ["app-icons", "مصادر الأيقونة"],
] as const;
const pageSize = 24;

export function MediaLibrary() {
  const [assets, setAssets] = useState<MediaAsset[]>([]);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("all");
  const [sort, setSort] = useState("newest");
  const [view, setView] = useState<"grid" | "list">("grid");
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [uploadGroup, setUploadGroup] = useState("app-content");
  const [altText, setAltText] = useState("");
  const [slotKey, setSlotKey] = useState("");
  const [rightsStatus, setRightsStatus] = useState("original");
  const [sourceText, setSourceText] = useState("");
  const [attribution, setAttribution] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<{ tone: "success" | "error"; text: string } | null>(null);
  const replacementInput = useRef<HTMLInputElement>(null);
  const replacementId = useRef<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch("/api/media", { cache: "no-store" });
      const data = await response.json() as { assets?: MediaAsset[]; error?: string };
      if (!response.ok) throw new Error(data.error ?? "تعذر تحميل الوسائط.");
      setAssets(data.assets ?? []);
    } catch (error) {
      setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر تحميل الوسائط." });
    } finally { setLoading(false); }
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(() => { void load(); }, 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  const visibleAssets = useMemo(() => {
    const query = search.trim().toLocaleLowerCase("ar");
    const filtered = assets.filter((asset) =>
      (filter === "all" || asset.assetGroup === filter) &&
      (!query || `${asset.originalFilename} ${asset.altText} ${asset.storagePath} ${asset.mimeType}`.toLocaleLowerCase("ar").includes(query)),
    );
    return [...filtered].sort((a, b) => {
      if (sort === "oldest") return a.createdAt.localeCompare(b.createdAt);
      if (sort === "name") return a.originalFilename.localeCompare(b.originalFilename, "ar");
      if (sort === "size") return b.sizeBytes - a.sizeBytes;
      if (sort === "usage") return b.usage.length - a.usage.length;
      return b.createdAt.localeCompare(a.createdAt);
    });
  }, [assets, filter, search, sort]);
  const totalPages = Math.max(1, Math.ceil(visibleAssets.length / pageSize));
  const pagedAssets = visibleAssets.slice((Math.min(page, totalPages) - 1) * pageSize, Math.min(page, totalPages) * pageSize);
  const selectedUnused = assets.filter((asset) => selected.has(asset.id) && asset.usage.length === 0);

  async function upload() {
    if (!file) return setMessage({ tone: "error", text: "اختر صورة أولًا." });
    setBusy("upload"); setMessage(null);
    try {
      const form = new FormData(); form.set("file", file); form.set("group", uploadGroup); form.set("altText", altText); form.set("slotKey", slotKey); form.set("rightsStatus", rightsStatus); form.set("sourceText", sourceText); form.set("attribution", attribution);
      const response = await fetch("/api/media", { method: "POST", body: form });
      const data = await response.json() as { error?: string };
      if (!response.ok) throw new Error(data.error ?? "تعذر رفع الصورة.");
      setFile(null); setAltText(""); setSlotKey(""); setSourceText(""); setAttribution(""); setMessage({ tone: "success", text: "رُفعت الصورة كمسودة آمنة؛ انشرها من محرر المحتوى عند الجاهزية." });
      await load();
    } catch (error) { setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر رفع الصورة." }); }
    finally { setBusy(null); }
  }

  async function deleteAsset(asset: MediaAsset, confirm = true) {
    if (asset.usage.length) throw new Error("الصورة مستخدمة حاليًا؛ أزل استخدامها قبل الحذف.");
    if (confirm && !window.confirm(`حذف ${asset.originalFilename} نهائيًا؟`)) return false;
    const response = await fetch(`/api/media/${asset.id}`, { method: "DELETE" });
    const data = await response.json() as { error?: string };
    if (!response.ok) throw new Error(data.error ?? "تعذر حذف الصورة.");
    return true;
  }

  async function remove(asset: MediaAsset) {
    setBusy(asset.id); setMessage(null);
    try {
      if (await deleteAsset(asset)) { setMessage({ tone: "success", text: "حُذفت الصورة غير المستخدمة." }); await load(); }
    } catch (error) { setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر حذف الصورة." }); }
    finally { setBusy(null); }
  }

  async function bulkRemove() {
    if (!selectedUnused.length || !window.confirm(`حذف ${selectedUnused.length} ملف غير مستخدم نهائيًا؟`)) return;
    setBusy("bulk"); setMessage(null);
    try {
      for (const asset of selectedUnused) await deleteAsset(asset, false);
      setSelected(new Set()); setMessage({ tone: "success", text: `حُذف ${selectedUnused.length} ملف غير مستخدم.` }); await load();
    } catch (error) { setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر إكمال الحذف الجماعي." }); }
    finally { setBusy(null); }
  }

  function chooseReplacement(id: string) { replacementId.current = id; replacementInput.current?.click(); }
  async function replace(event: React.ChangeEvent<HTMLInputElement>) {
    const nextFile = event.target.files?.[0]; const id = replacementId.current; event.target.value = "";
    if (!nextFile || !id) return; const asset = assets.find((item) => item.id === id); if (!asset) return;
    setBusy(id); setMessage(null);
    try {
      const form = new FormData(); form.set("file", nextFile); form.set("group", asset.assetGroup); form.set("altText", asset.altText);
      const response = await fetch(`/api/media/${id}`, { method: "PATCH", body: form });
      const data = await response.json() as { error?: string }; if (!response.ok) throw new Error(data.error ?? "تعذر استبدال الصورة.");
      setMessage({ tone: "success", text: "استُبدلت الصورة بمسار جديد، وسيُحدّث التطبيق الكاش تلقائيًا." }); await load();
    } catch (error) { setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر استبدال الصورة." }); }
    finally { setBusy(null); }
  }

  function toggle(id: string) { setSelected((current) => { const next = new Set(current); if (next.has(id)) next.delete(id); else next.add(id); return next; }); }
  function changeFilter(value: string) { setFilter(value); setPage(1); }
  async function toggleStatus(asset: MediaAsset) {
    setBusy(asset.id); setMessage(null);
    try {
      const status = asset.status === "active" ? "archived" : "active";
      const response = await fetch(`/api/media/${asset.id}`, { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify({ status }) });
      const data = await response.json() as { error?: string }; if (!response.ok) throw new Error(data.error ?? "تعذر تغيير الحالة.");
      setMessage({ tone: "success", text: status === "active" ? "فُعّل الأصل؛ لن يراه التطبيق حتى نشر الـSlot." : "عُطّل الأصل." }); await load();
    } catch (error) { setMessage({ tone: "error", text: error instanceof Error ? error.message : "تعذر تغيير الحالة." }); }
    finally { setBusy(null); }
  }

  return <div className="space-y-5">
    <section className="surface-card p-5">
      <div className="mb-4 flex items-center gap-3"><span className="grid size-10 place-items-center rounded-xl bg-[#74b512]/10 text-[var(--primary-strong)]"><ImagePlus size={19} /></span><div><h2 className="text-sm font-black">رفع أصل بصري جديد</h2><p className="text-[11px] text-[var(--muted)]">JPEG / PNG / WebP · حتى 8MB · أبعاد 64–6000px</p></div></div>
      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        <label className="field grid cursor-pointer place-items-center border-dashed text-center text-xs font-bold"><input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={(event) => setFile(event.target.files?.[0] ?? null)} />{file?.name ?? "اختر صورة من جهازك"}</label>
        <select value={uploadGroup} onChange={(event) => setUploadGroup(event.target.value)} className="field text-xs">{groups.map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select>
        <input value={altText} maxLength={160} onChange={(event) => setAltText(event.target.value)} placeholder="وصف بديل للصورة" className="field text-xs" />
        <input value={slotKey} onChange={(event) => setSlotKey(event.target.value)} placeholder="Slot مثل home.hero" dir="ltr" className="field text-xs" />
        <select value={rightsStatus} onChange={(event) => setRightsStatus(event.target.value)} className="field text-xs"><option value="original">Original</option><option value="generated">Generated</option><option value="licensed">Licensed</option></select>
        <input value={sourceText} maxLength={500} onChange={(event) => setSourceText(event.target.value)} placeholder="المصدر أو رابط الترخيص" dir="ltr" className="field text-xs" />
        <input value={attribution} maxLength={500} onChange={(event) => setAttribution(event.target.value)} placeholder="نص النسبة/الاعتماد عند الحاجة" className="field text-xs" />
        <button type="button" disabled={busy !== null || !file} onClick={() => void upload()} className="button-primary">{busy === "upload" ? <LoaderCircle size={16} className="animate-spin" /> : <Upload size={16} />}رفع</button>
      </div>
    </section>

    {message ? <div role="status" className={`rounded-xl border p-3 text-sm ${message.tone === "success" ? "border-[#74b512]/25 bg-[#74b512]/8 text-[#527f0c]" : "border-[#c83443]/25 bg-[#c83443]/8 text-[#a72b38]"}`}>{message.text}</div> : null}

    <section className="surface-card space-y-4 p-4">
      <div className="flex flex-col gap-3 xl:flex-row xl:items-center">
        <label className="relative min-w-64 flex-1"><Search size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--muted)]" /><input value={search} onChange={(event) => { setSearch(event.target.value); setPage(1); }} placeholder="ابحث بالاسم أو الوصف أو المسار أو النوع…" className="field pr-10 text-xs" /></label>
        <select className="field max-w-48 text-xs" value={sort} onChange={(event) => { setSort(event.target.value); setPage(1); }} aria-label="ترتيب الوسائط"><option value="newest">الأحدث أولًا</option><option value="oldest">الأقدم أولًا</option><option value="name">حسب الاسم</option><option value="size">حسب الحجم</option><option value="usage">حسب الاستخدام</option></select>
        <div className="flex gap-1 rounded-xl border border-black/10 bg-white p-1"><button type="button" onClick={() => setView("grid")} className={view === "grid" ? "rounded-lg bg-black/7 p-2" : "p-2 text-[var(--muted)]"} aria-label="عرض شبكي"><Grid2X2 size={16} /></button><button type="button" onClick={() => setView("list")} className={view === "list" ? "rounded-lg bg-black/7 p-2" : "p-2 text-[var(--muted)]"} aria-label="عرض قائمة"><List size={16} /></button></div>
        {selected.size ? <button type="button" className="button-danger" disabled={busy !== null || !selectedUnused.length} onClick={() => void bulkRemove()}><Trash2 size={16} />حذف غير المستخدم ({selectedUnused.length})</button> : null}
      </div>
      <div className="flex gap-2 overflow-x-auto pb-1"><button type="button" onClick={() => changeFilter("all")} className={filter === "all" ? "button-primary shrink-0" : "button-secondary shrink-0"}>الكل</button>{groups.map(([value, label]) => <button key={value} type="button" onClick={() => changeFilter(value)} className={filter === value ? "button-primary shrink-0" : "button-secondary shrink-0"}>{label}</button>)}</div>
    </section>

    <input ref={replacementInput} type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={(event) => void replace(event)} />
    {loading ? <div className="surface-card grid min-h-52 place-items-center"><div className="text-center"><LoaderCircle className="mx-auto animate-spin text-[var(--primary-strong)]" /><p className="mt-3 text-sm text-[var(--muted)]">جارٍ تحميل مكتبة الوسائط…</p></div></div> : pagedAssets.length ? <section className={view === "grid" ? "grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4" : "space-y-3"}>{pagedAssets.map((asset) => <MediaAssetCard key={asset.id} asset={asset} view={view} selected={selected.has(asset.id)} busy={busy === asset.id} onToggle={() => toggle(asset.id)} onReplace={() => chooseReplacement(asset.id)} onRemove={() => void remove(asset)} onToggleStatus={() => void toggleStatus(asset)} onMessage={setMessage} />)}</section> : <div className="surface-card grid min-h-52 place-items-center text-center"><div><ImagePlus className="mx-auto text-[var(--muted)]" /><p className="mt-3 font-black">لا توجد صور مطابقة</p><p className="mt-1 text-sm text-[var(--muted)]">غيّر البحث أو التصنيف، أو ارفع أصلًا بصريًا جديدًا.</p></div></div>}

    {!loading && visibleAssets.length ? <nav className="flex items-center justify-between gap-3" aria-label="صفحات الوسائط"><p className="text-xs text-[var(--muted)]">{formatNumber(visibleAssets.length)} أصل · صفحة {Math.min(page, totalPages)} من {totalPages}</p><div className="flex gap-2"><button type="button" className="button-secondary" disabled={page <= 1} onClick={() => setPage((value) => Math.max(1, value - 1))}>السابق</button><button type="button" className="button-secondary" disabled={page >= totalPages} onClick={() => setPage((value) => Math.min(totalPages, value + 1))}>التالي</button></div></nav> : null}
  </div>;
}

function MediaAssetCard({ asset, view, selected, busy, onToggle, onReplace, onRemove, onToggleStatus, onMessage }: { asset: MediaAsset; view: "grid" | "list"; selected: boolean; busy: boolean; onToggle: () => void; onReplace: () => void; onRemove: () => void; onToggleStatus: () => void; onMessage: (value: { tone: "success" | "error"; text: string }) => void }) {
  const groupLabel = groups.find(([value]) => value === asset.assetGroup)?.[1] ?? asset.assetGroup;
  return <article className={`surface-card surface-card-hover overflow-hidden ${view === "list" ? "grid sm:grid-cols-[12rem_1fr]" : ""}`}>
    <div className={`relative bg-[#eef1eb] bg-cover bg-center ${view === "grid" ? "aspect-[4/3]" : "min-h-40"}`} style={{ backgroundImage: `url(${JSON.stringify(asset.url).slice(1, -1)})` }} role="img" aria-label={asset.altText || asset.originalFilename}><button type="button" onClick={onToggle} className="absolute right-3 top-3 grid size-9 place-items-center rounded-xl border border-white/80 bg-white/90 text-[var(--foreground)] shadow" aria-label={selected ? "إلغاء تحديد الصورة" : "تحديد الصورة"}>{selected ? <CheckSquare size={17} className="text-[var(--primary-strong)]" /> : <Square size={17} />}</button></div>
    <div className="space-y-3 p-4"><div><h3 className="truncate text-sm font-black" dir="ltr">{asset.originalFilename}</h3><p className="mt-1 truncate font-mono text-[9px] text-[var(--muted)]" dir="ltr">{asset.storagePath}</p></div>
      <div className="flex flex-wrap gap-1.5 text-[10px]"><span className="rounded-full bg-black/5 px-2 py-1">{asset.mimeType.replace("image/", "").toUpperCase()}</span><span className="rounded-full bg-black/5 px-2 py-1">{asset.width}×{asset.height}</span><span className="rounded-full bg-black/5 px-2 py-1">{(asset.sizeBytes / 1024).toFixed(0)} KB</span><span className="rounded-full bg-[#2f6fba]/8 px-2 py-1 text-[#275f9f]">{groupLabel}</span><span className="rounded-full bg-black/5 px-2 py-1">{asset.rightsStatus} · v{asset.version}</span><span className="rounded-full bg-black/5 px-2 py-1">{asset.status === "active" ? "مفعّل" : "معطّل"}</span></div>
      {asset.slotKey ? <p className="font-mono text-[10px] text-[var(--primary-strong)]" dir="ltr">{asset.slotKey}</p> : null}
      {asset.sourceText || asset.attribution ? <p className="text-[10px] leading-5 text-[var(--muted)]">{asset.sourceText ? `المصدر: ${asset.sourceText}` : ""}{asset.sourceText && asset.attribution ? " · " : ""}{asset.attribution ? `النسبة: ${asset.attribution}` : ""}</p> : null}
      <div className="rounded-xl border border-black/7 bg-black/[0.018] p-3 text-[10px] leading-5"><p><strong>{formatNumber(asset.usage.length)}</strong> استخدام · رُفعت {formatDate(asset.createdAt)}</p>{asset.createdBy ? <p className="truncate text-[var(--muted)]" dir="ltr">by {asset.createdBy}</p> : null}<p className="mt-1 text-[var(--muted)]">{asset.usage.length ? asset.usage.map((entry) => `${entry.label} (${entry.state === "draft" ? "مسودة" : "منشور"})`).join("، ") : "غير مستخدمة — يمكن حذفها بأمان"}</p></div>
      <div className="flex flex-wrap gap-2"><button type="button" onClick={() => void navigator.clipboard.writeText(asset.storagePath).then(() => onMessage({ tone: "success", text: "نُسخ مرجع الصورة." }))} className="button-secondary min-h-9 flex-1 px-2" title="نسخ المرجع"><Clipboard size={14} /></button><a href={asset.url} download className="button-secondary min-h-9 flex-1 px-2" title="تنزيل"><Download size={14} /></a><button type="button" disabled={busy} onClick={onReplace} className="button-secondary min-h-9 flex-1 px-2" title="استبدال">{busy ? <LoaderCircle size={14} className="animate-spin" /> : <RefreshCcw size={14} />}</button><button type="button" disabled={busy} onClick={onToggleStatus} className="button-secondary min-h-9 flex-1 px-2">{asset.status === "active" ? "تعطيل" : "تفعيل"}</button><button type="button" disabled={busy || asset.usage.length > 0} onClick={onRemove} className="button-danger min-h-9 flex-1 px-2" title={asset.usage.length ? "الصورة مستخدمة" : "حذف آمن"}><Trash2 size={14} /></button></div>
    </div>
  </article>;
}
