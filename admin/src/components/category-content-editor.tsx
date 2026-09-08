"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowDown, ArrowUp, Eye, EyeOff, ImageIcon, LoaderCircle, Pencil, Plus, Save, Trash2, X } from "lucide-react";

interface MediaChoice {
  id: string; url: string; altText: string; storagePath: string; assetGroup: string;
  width: number; height: number; mimeType: string; rightsStatus: string;
  sourceText: string | null; attribution: string | null;
}
interface ParentChoice { id: string; name: string }
interface CategoryEditorProps {
  id: string; name: string; slug: string; parentId: string | null; iconKey: string;
  description: string; imageUrl: string | null; coverMediaId: string | null;
  focalX: number; focalY: number;
  active: boolean; sortOrder: number; parents: ParentChoice[]; compact?: boolean; disabled?: boolean;
  groupKey: string; seasonLabel: string | null; questionFormats: string[];
  favoriteEligible: boolean; accessTier: "free" | "premium"; featured: boolean;
  isNew: boolean; editorialStatus: "draft" | "review" | "published" | "archived"; freeRotation: boolean;
}

const groupOptions = [["saudi", "السعودية"], ["leagues", "الدوريات"], ["clubs", "الأندية"], ["competitions", "البطولات"], ["national_teams", "المنتخبات"], ["players", "اللاعبون"], ["history", "التاريخ"], ["images", "تحديات الصور"], ["audio_video", "صوت وفيديو"], ["tactics", "تكتيك"], ["other", "أخرى"]] as const;
const formatOptions = [["open_answer", "إجابة مفتوحة"], ["multiple_choice", "اختيارات"], ["true_false", "صح/خطأ"], ["image", "صورة"], ["zoom_image", "صورة مقرّبة"], ["focus_memory", "تركيز/ذاكرة"], ["audio", "صوت"], ["reversed_audio", "صوت معكوس"], ["video", "فيديو"], ["career_path", "مسيرة لاعب"], ["player_number", "رقم اللاعب"], ["first_name", "الاسم الأول"], ["player_crop", "جزء من لاعب"], ["silhouette", "ظل اللاعب"], ["club_league", "نادي/دوري"], ["kit", "القميص"], ["ordering", "ترتيب"], ["multi_clue", "تلميحات"], ["hidden_player", "لاعب مخفي"], ["drawing", "ارسمها"]] as const;

export function CategoryContentEditor(props: CategoryEditorProps) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState(props.name);
  const [slug, setSlug] = useState(props.slug);
  const [parentId, setParentId] = useState(props.parentId ?? "");
  const [iconKey, setIconKey] = useState(props.iconKey);
  const [description, setDescription] = useState(props.description);
  const [mediaId, setMediaId] = useState(props.coverMediaId ?? "");
  const [focalX, setFocalX] = useState(props.focalX);
  const [focalY, setFocalY] = useState(props.focalY);
  const [active, setActive] = useState(props.active);
  const [groupKey, setGroupKey] = useState(props.groupKey);
  const [seasonLabel, setSeasonLabel] = useState(props.seasonLabel ?? "");
  const [questionFormats, setQuestionFormats] = useState(props.questionFormats);
  const [favoriteEligible, setFavoriteEligible] = useState(props.favoriteEligible);
  const [accessTier, setAccessTier] = useState<"free" | "premium">(props.accessTier);
  const [featured, setFeatured] = useState(props.featured);
  const [isNew, setIsNew] = useState(props.isNew);
  const [editorialStatus, setEditorialStatus] = useState(props.editorialStatus);
  const [freeRotation, setFreeRotation] = useState(props.freeRotation);
  const [media, setMedia] = useState<MediaChoice[]>([]);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!open || media.length) return;
    void fetch("/api/content", { cache: "no-store" })
      .then((response) => response.json())
      .then((data: { media?: MediaChoice[] }) => setMedia((data.media ?? []).filter((asset) => asset.assetGroup === "categories" || asset.assetGroup === "app-content")));
  }, [media.length, open]);

  async function mutate(sortOrder = props.sortOrder) {
    if (active && editorialStatus === "published" && !mediaId) {
      setOpen(true); setMessage("أضف صورة للفئة قبل النشر."); return;
    }
    setBusy(true); setMessage(null);
    try {
      const contentResponse = await fetch(`/api/categories/${props.id}/content`, {
        method: "PATCH", headers: { "content-type": "application/json" },
        body: JSON.stringify({ descriptionAr: description || null, coverMediaId: mediaId || null, focalX, focalY }),
      });
      const contentData = (await contentResponse.json()) as { error?: string };
      if (!contentResponse.ok) throw new Error(contentData.error ?? "حُفظت البيانات وتعذر تحديث الغلاف.");
      const coreResponse = await fetch(`/api/categories/${props.id}`, {
        method: "PATCH", headers: { "content-type": "application/json" },
        body: JSON.stringify({ nameAr: name, slug, parentId: parentId || null, iconKey: iconKey || null, descriptionAr: description || null, isActive: active, sortOrder, groupKey, seasonLabel: seasonLabel || null, questionFormats, favoriteEligible, accessTier, featured, isNew, editorialStatus, freeRotation }),
      });
      const coreData = (await coreResponse.json()) as { error?: string };
      if (!coreResponse.ok) throw new Error(coreData.error ?? "تعذر تحديث القسم.");
      setMessage("حُفظ القسم وسيظهر التحديث في التطبيق دون Build جديد.");
      router.refresh();
    } catch (error) { setMessage(error instanceof Error ? error.message : "تعذر تحديث القسم."); }
    finally { setBusy(false); }
  }

  async function remove() {
    if (!window.confirm(`حذف «${props.name}» نهائيًا؟ إذا كان مرتبطًا بأسئلة سيُرفض الحذف.`)) return;
    setBusy(true); setMessage(null);
    try {
      const response = await fetch(`/api/categories/${props.id}`, { method: "DELETE" });
      const data = (await response.json()) as { error?: string };
      if (!response.ok) throw new Error(data.error ?? "تعذر حذف القسم.");
      router.refresh();
    } catch (error) { setMessage(error instanceof Error ? error.message : "تعذر حذف القسم."); }
    finally { setBusy(false); }
  }

  if (!open) return (
    <div className={props.compact ? "flex items-center gap-1" : "mt-3 flex flex-wrap items-center gap-2"}>
      <button type="button" disabled={props.disabled} onClick={() => setOpen(true)} className="button-secondary min-h-8 px-2.5 py-1.5 text-[10px]"><Pencil size={12} /> معاينة وتعديل</button>
      {!props.compact ? <>
        <button type="button" disabled={props.disabled || busy} onClick={() => { setActive(!active); setOpen(true); }} className="button-secondary min-h-8 px-2.5 py-1.5 text-[10px]">{props.active ? <EyeOff size={12} /> : <Eye size={12} />}{props.active ? "تعطيل" : "تفعيل"}</button>
        <button type="button" disabled={props.disabled || busy} onClick={() => void mutate(Math.max(0, props.sortOrder - 1))} className="button-secondary min-h-8 px-2 py-1.5" aria-label="تحريك لأعلى"><ArrowUp size={12} /></button>
        <button type="button" disabled={props.disabled || busy} onClick={() => void mutate(props.sortOrder + 1)} className="button-secondary min-h-8 px-2 py-1.5" aria-label="تحريك لأسفل"><ArrowDown size={12} /></button>
      </> : null}
    </div>
  );

  const selectedAsset = media.find((asset) => asset.id === mediaId);
  const previewUrl = selectedAsset?.url ?? (mediaId === props.coverMediaId ? props.imageUrl : null);
  const objectPosition = `${Math.round(focalX * 100)}% ${Math.round(focalY * 100)}%`;
  const mediaState = !mediaId ? "NO IMAGE" : selectedAsset || previewUrl ? "READY" : "DRAFT";
  return (
    <div className="mt-4 space-y-3 rounded-xl border border-[var(--border)] bg-[var(--surface-3)] p-3">
      <div className="flex items-center justify-between gap-3"><span className="text-xs font-black">تحرير القسم</span><button type="button" onClick={() => setOpen(false)} className="text-[var(--muted)]" aria-label="إغلاق"><X size={16} /></button></div>
      <div className="grid gap-2 sm:grid-cols-2">
        <label className="text-[10px] font-bold">الاسم العربي<input className="field mt-1" value={name} maxLength={80} onChange={(event) => setName(event.target.value)} /></label>
        <label className="text-[10px] font-bold">المعرّف النصي<input className="field mt-1 font-mono" dir="ltr" value={slug} maxLength={64} onChange={(event) => setSlug(event.target.value.toLowerCase())} /></label>
        <label className="text-[10px] font-bold">القسم الرئيسي<select className="field mt-1" value={parentId} onChange={(event) => setParentId(event.target.value)}><option value="">قسم رئيسي</option>{props.parents.filter((parent) => parent.id !== props.id).map((parent) => <option key={parent.id} value={parent.id}>{parent.name}</option>)}</select></label>
        <label className="text-[10px] font-bold">مفتاح الأيقونة<input className="field mt-1 font-mono" dir="ltr" value={iconKey} maxLength={64} onChange={(event) => setIconKey(event.target.value)} /></label>
      </div>
      <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-4">
        <label className="text-[10px] font-bold">مجموعة العرض<select className="field mt-1" value={groupKey} onChange={(event) => setGroupKey(event.target.value)}>{groupOptions.map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
        <label className="text-[10px] font-bold">الموسم<input className="field mt-1" value={seasonLabel} maxLength={40} onChange={(event) => setSeasonLabel(event.target.value)} placeholder="2026/27" /></label>
        <label className="text-[10px] font-bold">الوصول<select className="field mt-1" value={accessTier} onChange={(event) => setAccessTier(event.target.value as "free" | "premium")}><option value="free">Free</option><option value="premium">Premium</option></select></label>
        <label className="text-[10px] font-bold">الحالة التحريرية<select className="field mt-1" value={editorialStatus} onChange={(event) => setEditorialStatus(event.target.value as "draft" | "review" | "published" | "archived")}><option value="draft">Draft</option><option value="review">Review</option><option value="published">Published</option><option value="archived">Archived</option></select></label>
      </div>
      <fieldset className="rounded-lg border border-[var(--border)] p-3"><legend className="px-1 text-[10px] font-black">صيغ الأسئلة المسموحة</legend><div className="flex flex-wrap gap-3">{formatOptions.map(([value, label]) => <label key={value} className="flex items-center gap-1.5 text-[10px]"><input type="checkbox" checked={questionFormats.includes(value)} onChange={(event) => setQuestionFormats((current) => event.target.checked ? [...new Set([...current, value])] : current.length > 1 ? current.filter((item) => item !== value) : current)} />{label}</label>)}</div></fieldset>
      <textarea value={description} maxLength={500} onChange={(event) => setDescription(event.target.value)} placeholder="وصف القسم" className="field min-h-20 resize-y text-xs leading-5" />
      <section className="space-y-3 border-y border-[var(--border)] py-4">
        <div className="flex flex-wrap items-center justify-between gap-3"><div><p className="text-xs font-black">صورة الفئة</p><p className="mt-1 text-[10px] text-[var(--muted)]">صورة واحدة معتمدة، تتكيف مع القصّ العريض والمضغوط.</p></div><span className={`border px-2 py-1 text-[9px] font-black ${mediaState === "READY" ? "border-[var(--primary)] text-[var(--primary-strong)]" : "border-[var(--gold)] text-[var(--gold)]"}`}>{mediaState}</span></div>
        <div className="grid gap-3 xl:grid-cols-[1fr_auto]">
          <select value={mediaId} onChange={(event) => setMediaId(event.target.value)} className="field text-xs"><option value="">بدون صورة — يمنع النشر</option>{media.map((asset) => <option key={asset.id} value={asset.id}>{asset.altText || asset.storagePath} · {asset.rightsStatus}</option>)}</select>
          <a href="/media" className="button-secondary text-xs"><ImageIcon size={14} /> رفع أو اختيار أصل جديد</a>
        </div>
        <div className="grid gap-3 sm:grid-cols-[3fr_2fr]">
          {["aspect-[3/2]", "aspect-[4/3]"].map((ratio, index) => <div key={ratio}><p className="mb-1 text-[9px] font-bold text-[var(--muted)]">{index === 0 ? "معاينة عريضة" : "معاينة مضغوطة"}</p><div className={`${ratio} overflow-hidden border border-[var(--border)] bg-[var(--surface)] bg-cover`} style={previewUrl ? { backgroundImage: `url(${JSON.stringify(previewUrl).slice(1, -1)})`, backgroundPosition: objectPosition } : undefined}>{!previewUrl ? <div className="grid h-full place-items-center text-[var(--muted)]"><ImageIcon size={24} /></div> : null}</div></div>)}
        </div>
        <div className="grid gap-3 sm:grid-cols-2"><label className="text-[10px] font-bold">موضع القص الأفقي · {Math.round(focalX * 100)}%<input type="range" min="0" max="1" step="0.01" value={focalX} onChange={(event) => setFocalX(Number(event.target.value))} className="mt-2 w-full accent-[var(--primary)]" /></label><label className="text-[10px] font-bold">موضع القص العمودي · {Math.round(focalY * 100)}%<input type="range" min="0" max="1" step="0.01" value={focalY} onChange={(event) => setFocalY(Number(event.target.value))} className="mt-2 w-full accent-[var(--primary)]" /></label></div>
        {selectedAsset ? <p className="text-[9px] leading-5 text-[var(--muted)]">{selectedAsset.width}×{selectedAsset.height} · {selectedAsset.mimeType} · الحقوق: {selectedAsset.rightsStatus}{selectedAsset.attribution ? ` · ${selectedAsset.attribution}` : ""}</p> : null}
      </section>
      <div className="flex flex-wrap gap-4 text-xs font-bold"><label className="flex items-center gap-2"><input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} /> متاح داخل التطبيق</label><label className="flex items-center gap-2"><input type="checkbox" checked={favoriteEligible} onChange={(event) => setFavoriteEligible(event.target.checked)} /> يقبل المفضلة</label><label className="flex items-center gap-2"><input type="checkbox" checked={featured} onChange={(event) => setFeatured(event.target.checked)} /> مميز</label><label className="flex items-center gap-2"><input type="checkbox" checked={isNew} onChange={(event) => setIsNew(event.target.checked)} /> جديد</label><label className="flex items-center gap-2"><input type="checkbox" checked={freeRotation} onChange={(event) => setFreeRotation(event.target.checked)} /> ضمن التدوير المجاني</label></div>
      {message ? <p role="status" className="text-[10px] leading-5 text-[var(--primary-strong)]">{message}</p> : null}
      <div className="flex flex-wrap gap-2"><button type="button" disabled={busy} onClick={() => void mutate()} className="button-primary text-xs">{busy ? <LoaderCircle size={14} className="animate-spin" /> : <Save size={14} />} حفظ</button><button type="button" disabled={busy} onClick={() => void remove()} className="button-danger text-xs"><Trash2 size={14} /> حذف نهائي</button></div>
    </div>
  );
}

export function CategoryCreateButton({ parents, disabled = false }: { parents: ParentChoice[]; disabled?: boolean }) {
  const router = useRouter();
  const [open, setOpen] = useState(false); const [busy, setBusy] = useState(false); const [message, setMessage] = useState<string | null>(null);
  const [name, setName] = useState(""); const [slug, setSlug] = useState(""); const [parentId, setParentId] = useState(""); const [iconKey, setIconKey] = useState("folder"); const [description, setDescription] = useState("");
  async function create() {
    setBusy(true); setMessage(null);
    try {
      const response = await fetch("/api/categories", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ nameAr: name, slug, parentId: parentId || null, iconKey: iconKey || null, descriptionAr: description || null, isActive: true }) });
      const data = (await response.json()) as { error?: string }; if (!response.ok) throw new Error(data.error ?? "تعذر إنشاء القسم.");
      setOpen(false); setName(""); setSlug(""); setDescription(""); setParentId(""); router.refresh();
    } catch (error) { setMessage(error instanceof Error ? error.message : "تعذر إنشاء القسم."); }
    finally { setBusy(false); }
  }
  if (!open) return <button type="button" disabled={disabled} onClick={() => setOpen(true)} className="button-primary"><Plus size={16} /> قسم جديد</button>;
  return (
    <section className="surface-card space-y-3 p-4 sm:p-5">
      <div className="flex items-center justify-between"><h2 className="font-black">قسم جديد</h2><button type="button" onClick={() => setOpen(false)} aria-label="إغلاق" className="text-[var(--muted)]"><X size={18} /></button></div>
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4"><input className="field" value={name} maxLength={80} onChange={(event) => setName(event.target.value)} placeholder="الاسم العربي" /><input className="field font-mono" dir="ltr" value={slug} maxLength={64} onChange={(event) => setSlug(event.target.value.toLowerCase())} placeholder="slug" /><select className="field" value={parentId} onChange={(event) => setParentId(event.target.value)}><option value="">قسم رئيسي</option>{parents.map((parent) => <option key={parent.id} value={parent.id}>{parent.name}</option>)}</select><input className="field font-mono" dir="ltr" value={iconKey} maxLength={64} onChange={(event) => setIconKey(event.target.value)} placeholder="icon_key" /></div>
      <textarea className="field min-h-20 resize-y" value={description} maxLength={500} onChange={(event) => setDescription(event.target.value)} placeholder="وصف اختياري" />
      {message ? <p role="alert" className="text-xs text-[var(--danger)]">{message}</p> : null}<button type="button" disabled={busy} onClick={() => void create()} className="button-primary">{busy ? <LoaderCircle size={15} className="animate-spin" /> : <Save size={15} />} إنشاء</button>
    </section>
  );
}
