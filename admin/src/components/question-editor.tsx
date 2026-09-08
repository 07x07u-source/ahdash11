"use client";

import { CirclePlus, ImageIcon, LoaderCircle } from "lucide-react";
import { useRouter } from "next/navigation";
import { FormEvent, useEffect, useMemo, useState } from "react";
import type { CategoryListItem } from "@/lib/data/category-data";

type QuestionFormat = "open_answer" | "multiple_choice" | "true_false" | "image";
interface MediaChoice { id: string; url: string; altText: string; storagePath: string; assetGroup: string; rightsStatus: string; width: number; height: number }

const pointByDifficulty = { easy: 100, medium: 200, hard: 300, expert: 300 } as const;

export function QuestionEditor({ categories }: { categories: CategoryListItem[] }) {
  const router = useRouter();
  const topLevelCategories = useMemo(
    () => categories.filter((category) => category.parentId === null && category.active),
    [categories],
  );
  const [questionFormat, setQuestionFormat] = useState<QuestionFormat>("open_answer");
  const [questionText, setQuestionText] = useState("");
  const [categoryId, setCategoryId] = useState(topLevelCategories[0]?.id ?? "");
  const [difficulty, setDifficulty] = useState<keyof typeof pointByDifficulty>("medium");
  const [pointValue, setPointValue] = useState(200);
  const [correctAnswer, setCorrectAnswer] = useState("");
  const [alternativeAnswers, setAlternativeAnswers] = useState("");
  const [options, setOptions] = useState<string[]>([]);
  const [correctOptionPosition, setCorrectOptionPosition] = useState<number | null>(null);
  const [explanation, setExplanation] = useState("");
  const [sourceUrl, setSourceUrl] = useState("");
  const [sourceName, setSourceName] = useState("");
  const [season, setSeason] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [imageMediaId, setImageMediaId] = useState("");
  const [imageCaption, setImageCaption] = useState("");
  const [focalX, setFocalX] = useState(0.5);
  const [focalY, setFocalY] = useState(0.5);
  const [media, setMedia] = useState<MediaChoice[]>([]);
  const [mediaRightsStatus, setMediaRightsStatus] = useState("none");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");

  useEffect(() => {
    void fetch("/api/content", { cache: "no-store" })
      .then((response) => response.json())
      .then((data: { media?: MediaChoice[] }) => setMedia((data.media ?? []).filter((asset) => ["categories", "app-content"].includes(asset.assetGroup))));
  }, []);

  function changeFormat(next: QuestionFormat) {
    setQuestionFormat(next);
    setOptions(next === "true_false" ? ["صح", "خطأ"] : next === "multiple_choice" ? ["", "", "", ""] : []);
    setCorrectOptionPosition(next === "true_false" ? 1 : null);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setMessage("");
    try {
      const response = await fetch("/api/questions", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          questionText,
          questionFormat,
          categoryId,
          difficulty,
          correctAnswer,
          alternativeAnswers: alternativeAnswers.split("\n").map((value) => value.trim()).filter(Boolean),
          options,
          correctOptionPosition,
          pointValue,
          explanation,
          sourceUrl,
          sourceName,
          season,
          imageUrl,
          imageMediaId,
          imageCaption,
          focalX,
          focalY,
          mediaRightsStatus,
        }),
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "تعذر إنشاء السؤال.");
      setMessage("تم إنشاء المسودة. راجع المصدر والإجابة ثم انشرها.");
      setQuestionText("");
      setCorrectAnswer("");
      setAlternativeAnswers("");
      setExplanation("");
      setOptions(questionFormat === "true_false" ? ["صح", "خطأ"] : questionFormat === "multiple_choice" ? ["", "", "", ""] : []);
      router.refresh();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "تعذر إنشاء السؤال.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <details className="surface-card group" open>
      <summary className="flex cursor-pointer list-none items-center gap-3 border-b border-white/7 p-4 text-sm font-black text-[#eef1f4]">
        <CirclePlus size={18} className="text-[#b6ff3b]" /> إنشاء مسودة سؤال للجلسات
      </summary>
      <form onSubmit={submit} className="grid gap-4 p-4 xl:grid-cols-3">
        <label className="xl:col-span-2">
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">نص السؤال</span>
          <textarea required minLength={5} maxLength={1000} value={questionText} onChange={(event) => setQuestionText(event.target.value)} className="field min-h-24 resize-y" />
        </label>
        <label>
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">الإجابة الصحيحة</span>
          <textarea required maxLength={500} value={correctAnswer} onChange={(event) => setCorrectAnswer(event.target.value)} className="field min-h-24 resize-y" />
        </label>
        <label>
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">الصيغة</span>
          <select value={questionFormat} onChange={(event) => changeFormat(event.target.value as QuestionFormat)} className="field">
            <option value="open_answer">إجابة مفتوحة — الافتراضي</option>
            <option value="multiple_choice">اختيار متعدد</option>
            <option value="true_false">صح أو خطأ</option>
            <option value="image">سؤال صورة</option>
          </select>
        </label>
        <label>
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">القسم</span>
          <select required value={categoryId} onChange={(event) => setCategoryId(event.target.value)} className="field">
            {!topLevelCategories.length ? <option value="">لا توجد أقسام متاحة</option> : null}
            {topLevelCategories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
          </select>
        </label>
        <label>
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">الصعوبة والنقاط</span>
          <div className="flex gap-2">
            <select value={difficulty} onChange={(event) => { const next = event.target.value as keyof typeof pointByDifficulty; setDifficulty(next); setPointValue(pointByDifficulty[next]); }} className="field">
              <option value="easy">سهل</option><option value="medium">متوسط</option><option value="hard">صعب</option><option value="expert">خبير</option>
            </select>
            <input type="number" min={50} max={1000} step={50} value={pointValue} onChange={(event) => setPointValue(Number(event.target.value))} className="field" aria-label="قيمة النقاط" />
          </div>
        </label>

        {options.length ? (
          <fieldset className="grid gap-3 xl:col-span-3 sm:grid-cols-2">
            <legend className="mb-2 text-xs font-bold text-[#aab2bf]">الخيارات</legend>
            {options.map((option, index) => (
              <label key={`${questionFormat}-${index}`} className="flex items-center gap-2">
                <input type="radio" name="correct-option" required checked={correctOptionPosition === index + 1} onChange={() => { setCorrectOptionPosition(index + 1); setCorrectAnswer(options[index] ?? ""); }} />
                <input required maxLength={300} readOnly={questionFormat === "true_false"} value={option} onChange={(event) => setOptions((current) => current.map((value, optionIndex) => optionIndex === index ? event.target.value : value))} className="field" placeholder={`الخيار ${index + 1}`} />
              </label>
            ))}
          </fieldset>
        ) : null}

        <label>
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">إجابات بديلة — كل إجابة في سطر</span>
          <textarea maxLength={1600} value={alternativeAnswers} onChange={(event) => setAlternativeAnswers(event.target.value)} className="field min-h-20" />
        </label>
        <label>
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">تفسير قصير بعد الكشف</span>
          <textarea maxLength={1200} value={explanation} onChange={(event) => setExplanation(event.target.value)} className="field min-h-20" />
        </label>
        <label>
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">الموسم</span>
          <input maxLength={40} value={season} onChange={(event) => setSeason(event.target.value)} className="field" placeholder="Evergreen أو 2026/27" />
        </label>
        <label>
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">اسم المصدر</span>
          <input maxLength={120} value={sourceName} onChange={(event) => setSourceName(event.target.value)} className="field" placeholder="FIFA / UEFA / الموقع الرسمي" />
        </label>
        <label>
          <span className="mb-2 block text-xs font-bold text-[#aab2bf]">رابط المصدر HTTPS</span>
          <input type="url" value={sourceUrl} onChange={(event) => setSourceUrl(event.target.value)} className="field" placeholder="https://…" />
        </label>
        {questionFormat === "image" ? <section className="space-y-3 border-y border-[var(--border)] py-4 xl:col-span-3"><div className="flex items-center justify-between gap-3"><div><p className="text-xs font-black">وسائط السؤال</p><p className="mt-1 text-[10px] text-[var(--muted)]">اختر أصلًا موثق الحقوق من المكتبة؛ لا تُقبل روابط صور عشوائية.</p></div><a href="/media" className="button-secondary text-xs"><ImageIcon size={14} />فتح المكتبة</a></div><div className="grid gap-3 lg:grid-cols-[1fr_1fr]"><div className="space-y-3"><select required value={imageMediaId} onChange={(event) => { const asset = media.find((item) => item.id === event.target.value); setImageMediaId(event.target.value); setImageUrl(asset?.url ?? ""); setMediaRightsStatus(asset?.rightsStatus ?? "none"); }} className="field"><option value="">اختر صورة موثقة</option>{media.map((asset) => <option key={asset.id} value={asset.id}>{asset.altText || asset.storagePath} · {asset.rightsStatus}</option>)}</select><input value={imageCaption} maxLength={300} onChange={(event) => setImageCaption(event.target.value)} className="field" placeholder="تعليق تحريري اختياري" /><div className="grid gap-3 sm:grid-cols-2"><label className="text-[10px] font-bold">القص الأفقي · {Math.round(focalX * 100)}%<input type="range" min="0" max="1" step="0.01" value={focalX} onChange={(event) => setFocalX(Number(event.target.value))} className="mt-2 w-full accent-[var(--primary)]" /></label><label className="text-[10px] font-bold">القص العمودي · {Math.round(focalY * 100)}%<input type="range" min="0" max="1" step="0.01" value={focalY} onChange={(event) => setFocalY(Number(event.target.value))} className="mt-2 w-full accent-[var(--primary)]" /></label></div></div><div className="aspect-[3/2] bg-[var(--surface-3)] bg-cover" style={imageUrl ? { backgroundImage: `url(${JSON.stringify(imageUrl).slice(1, -1)})`, backgroundPosition: `${focalX * 100}% ${focalY * 100}%` } : undefined}>{!imageUrl ? <div className="grid h-full place-items-center text-[var(--muted)]"><ImageIcon size={30} /></div> : null}</div></div></section> : null}
        <div className="flex items-center gap-3 xl:col-span-3">
          <button type="submit" disabled={busy || !categoryId} className="button-primary">
            {busy ? <LoaderCircle size={16} className="animate-spin" /> : <CirclePlus size={16} />} حفظ كمسودة مراجعة
          </button>
          {message ? <p role="status" className="text-xs font-bold text-[#bcd58f]">{message}</p> : null}
        </div>
      </form>
    </details>
  );
}
