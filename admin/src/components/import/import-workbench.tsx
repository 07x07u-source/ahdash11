"use client";

import {
  AlertTriangle,
  ArrowLeft,
  Check,
  CheckCheck,
  ChevronDown,
  CircleCheckBig,
  CircleDashed,
  CircleX,
  CloudUpload,
  Download,
  FileSpreadsheet,
  FileUp,
  LoaderCircle,
  RotateCcw,
  Search,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import { ChangeEvent, DragEvent, useMemo, useRef, useState } from "react";
import { StatusBadge } from "@/components/ui/status-badge";
import type { ParseImportResponse, ProcessedImportRow, QuestionDifficulty } from "@/lib/import/types";
import { cn, formatNumber } from "@/lib/utils";

type Filter = "all" | "valid" | "needs_review" | "invalid" | "duplicate";

interface RowEdit {
  categoryId?: string | null;
  difficulty?: QuestionDifficulty;
}

const difficultyLabels: Record<QuestionDifficulty, string> = {
  easy: "سهل",
  medium: "متوسط",
  hard: "صعب",
  expert: "خبير",
};

const statusMeta = {
  valid: { label: "جاهز", tone: "success" as const },
  needs_review: { label: "يحتاج مراجعة", tone: "warning" as const },
  invalid: { label: "خطأ", tone: "danger" as const },
  duplicate: { label: "مكرر", tone: "info" as const },
  skipped: { label: "متجاوز", tone: "neutral" as const },
};

const steps = ["رفع الملف", "التحقق", "التصنيف", "المراجعة", "الاستيراد"];

function SummaryCard({ label, value, tone }: { label: string; value: number; tone: "green" | "gold" | "red" | "blue" }) {
  const color = {
    green: "text-[#b6ff3b] bg-[#b6ff3b]/8 border-[#b6ff3b]/15",
    gold: "text-[#ffc857] bg-[#ffc857]/8 border-[#ffc857]/15",
    red: "text-[#ff747d] bg-[#ff4d57]/8 border-[#ff4d57]/15",
    blue: "text-sky-300 bg-sky-400/8 border-sky-400/15",
  }[tone];
  return (
    <div className={cn("rounded-xl border p-3", color)}>
      <strong className="block text-xl font-black" dir="ltr">{formatNumber(value)}</strong>
      <span className="mt-1 block text-[10px] font-bold opacity-75">{label}</span>
    </div>
  );
}

export function ImportWorkbench({ canPublish }: { canPublish: boolean }) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragging, setDragging] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [result, setResult] = useState<ParseImportResponse | null>(null);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState<Filter>("all");
  const [query, setQuery] = useState("");
  const [approvedReviewRows, setApprovedReviewRows] = useState<Set<string>>(new Set());
  const [edits, setEdits] = useState<Record<string, RowEdit>>({});
  const [committing, setCommitting] = useState(false);
  const [commitMessage, setCommitMessage] = useState("");

  async function upload(file: File) {
    setUploading(true);
    setError("");
    setCommitMessage("");
    try {
      const formData = new FormData();
      formData.append("file", file);
      const response = await fetch("/api/import/parse", { method: "POST", body: formData });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "تعذر تحليل الملف.");
      setResult(payload as ParseImportResponse);
      setApprovedReviewRows(new Set());
      setEdits({});
      setFilter("all");
    } catch (uploadError) {
      setError(uploadError instanceof Error ? uploadError.message : "تعذر رفع الملف.");
    } finally {
      setUploading(false);
    }
  }

  function receiveFiles(files: FileList | null) {
    const file = files?.[0];
    if (file) void upload(file);
  }

  function drop(event: DragEvent<HTMLDivElement>) {
    event.preventDefault();
    setDragging(false);
    receiveFiles(event.dataTransfer.files);
  }

  function downloadTemplate() {
    const rows = [
      ["السؤال", "الخيار الأول", "الخيار الثاني", "الخيار الثالث", "الخيار الرابع", "الإجابة الصحيحة", "الصورة - اختياري"],
      ["أين يقع ملعب أنفيلد؟", "لندن", "ليفربول", "مانشستر", "مدريد", "ليفربول", ""],
    ];
    const csv = `\uFEFF${rows.map((row) => row.map((cell) => `"${cell.replaceAll('"', '""')}"`).join(",")).join("\r\n")}`;
    const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
    const link = document.createElement("a");
    link.href = url;
    link.download = "ahdash-11-question-template.csv";
    link.click();
    URL.revokeObjectURL(url);
  }

  const visibleRows = useMemo(() => {
    if (!result) return [];
    const normalizedQuery = query.trim().toLocaleLowerCase("ar");
    return result.rows.filter((row) => {
      const matchesFilter = filter === "all" || row.status === filter;
      const matchesQuery = !normalizedQuery || row.questionText.toLocaleLowerCase("ar").includes(normalizedQuery);
      return matchesFilter && matchesQuery;
    });
  }, [filter, query, result]);

  function toggleReview(row: ProcessedImportRow) {
    if (row.status !== "needs_review") return;
    setApprovedReviewRows((current) => {
      const next = new Set(current);
      if (next.has(row.clientId)) next.delete(row.clientId);
      else next.add(row.clientId);
      return next;
    });
  }

  function approveAllVisible() {
    setApprovedReviewRows((current) => {
      const next = new Set(current);
      visibleRows.filter((row) => row.status === "needs_review").forEach((row) => next.add(row.clientId));
      return next;
    });
  }

  function setRowEdit(clientId: string, patch: RowEdit) {
    setEdits((current) => ({ ...current, [clientId]: { ...current[clientId], ...patch } }));
  }

  async function commit(publish: boolean) {
    if (!result) return;
    setCommitting(true);
    setError("");
    try {
      const decisions = result.rows
        .filter((row) => row.status === "needs_review" && approvedReviewRows.has(row.clientId))
        .map((row) => ({
          rowNumber: row.rowNumber,
          action: "approve" as const,
          categoryId: edits[row.clientId]?.categoryId ?? row.classification.categoryId,
          difficulty: edits[row.clientId]?.difficulty ?? row.classification.difficulty,
        }));
      const response = await fetch("/api/import/commit", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ batchId: result.batchId, publish, approveAllReview: false, decisions }),
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "تعذر إكمال الاستيراد.");
      setCommitMessage(payload.message || "اكتمل الاستيراد بنجاح.");
    } catch (commitError) {
      setError(commitError instanceof Error ? commitError.message : "تعذر إكمال الاستيراد.");
    } finally {
      setCommitting(false);
    }
  }

  function reset() {
    setResult(null);
    setError("");
    setCommitMessage("");
    setQuery("");
    if (inputRef.current) inputRef.current.value = "";
  }

  const readyCount = result ? result.summary.valid + approvedReviewRows.size : 0;
  const activeStep = commitMessage ? 5 : result ? 4 : uploading ? 2 : 1;

  return (
    <div className="space-y-5">
      <ol className="surface-card grid grid-cols-5 overflow-hidden p-2" aria-label="مراحل الاستيراد">
        {steps.map((step, index) => {
          const stepNumber = index + 1;
          const complete = activeStep > stepNumber;
          const active = activeStep === stepNumber;
          return (
            <li key={step} className={cn("relative flex min-w-0 flex-col items-center gap-1.5 rounded-xl px-1 py-2 text-center sm:flex-row sm:justify-center sm:py-3", active && "bg-[#b6ff3b]/8")}>
              <span className={cn("grid size-6 shrink-0 place-items-center rounded-full border text-[10px] font-black", complete ? "border-[#b6ff3b] bg-[#b6ff3b] text-[#0b0f14]" : active ? "border-[#b6ff3b]/50 text-[#b6ff3b]" : "border-white/10 text-[#566274]")}>
                {complete ? <Check size={13} /> : stepNumber}
              </span>
              <span className={cn("hidden text-[10px] font-bold sm:block lg:text-xs", active ? "text-[#d6ff94]" : complete ? "text-[#aeb7c4]" : "text-[#566274]")}>{step}</span>
            </li>
          );
        })}
      </ol>

      {!result ? (
        <section className="surface-card p-4 sm:p-6">
          <div
            onDragEnter={(event) => { event.preventDefault(); setDragging(true); }}
            onDragOver={(event) => event.preventDefault()}
            onDragLeave={() => setDragging(false)}
            onDrop={drop}
            className={cn(
              "relative grid min-h-80 place-items-center rounded-2xl border border-dashed p-6 text-center transition",
              dragging ? "border-[#b6ff3b] bg-[#b6ff3b]/6" : "border-white/15 bg-[#0b0f14]/40 hover:border-[#b6ff3b]/35",
            )}
          >
            <input ref={inputRef} type="file" accept=".csv,.xlsx" className="sr-only" onChange={(event: ChangeEvent<HTMLInputElement>) => receiveFiles(event.target.files)} />
            <div className="max-w-lg">
              <span className="mx-auto mb-5 grid size-16 place-items-center rounded-2xl border border-[#b6ff3b]/16 bg-[#b6ff3b]/8 text-[#b6ff3b]">
                {uploading ? <LoaderCircle size={28} className="animate-spin" /> : <CloudUpload size={29} />}
              </span>
              <h2 className="text-xl font-black">{uploading ? "نحلّل الملف ونراجع صفوفه…" : "اسحب ملف الأسئلة هنا"}</h2>
              <p className="mx-auto mt-2 max-w-md text-xs leading-6 text-[#8e98a7]">CSV أو Excel حتى 10MB. يكفي سبعة أعمدة بسيطة؛ التصنيف والصعوبة والوسوم يضيفها النظام تلقائيًا.</p>
              <div className="mt-6 flex flex-wrap justify-center gap-2">
                <button type="button" onClick={() => inputRef.current?.click()} disabled={uploading} className="button-primary">
                  <FileUp size={17} /> اختيار ملف
                </button>
                <button type="button" onClick={downloadTemplate} disabled={uploading} className="button-secondary">
                  <Download size={17} /> تنزيل نموذج CSV
                </button>
              </div>
              <div className="mt-6 flex flex-wrap justify-center gap-x-5 gap-y-2 text-[10px] font-bold text-[#687586]">
                <span className="flex items-center gap-1.5"><ShieldCheck size={14} className="text-[#b6ff3b]" /> لا يُنشر شيء قبل موافقتك</span>
                <span className="flex items-center gap-1.5"><Sparkles size={14} className="text-[#ffc857]" /> لا يحتاج API ذكاء اصطناعي</span>
              </div>
            </div>
          </div>
        </section>
      ) : (
        <>
          <section className="surface-card p-4 sm:p-5">
            <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
              <div className="flex min-w-0 items-center gap-3">
                <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-[#b6ff3b]/9 text-[#b6ff3b]"><FileSpreadsheet size={21} /></span>
                <div className="min-w-0">
                  <p className="truncate text-sm font-black">{result.filename}</p>
                  <p className="mt-1 text-[10px] text-[#697586]">دفعة {result.batchId} · {result.developmentFallback ? "محاكاة تطوير" : "محفوظة في Supabase"}</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 xl:w-[30rem]">
                <SummaryCard label="جاهز" value={result.summary.valid} tone="green" />
                <SummaryCard label="للمراجعة" value={result.summary.review} tone="gold" />
                <SummaryCard label="أخطاء" value={result.summary.invalid} tone="red" />
                <SummaryCard label="مكرر" value={result.summary.duplicate} tone="blue" />
              </div>
            </div>
          </section>

          <section className="surface-card overflow-hidden">
            <div className="flex flex-col gap-3 border-b border-white/7 p-4 xl:flex-row xl:items-center xl:justify-between">
              <div className="flex flex-wrap gap-1.5">
                {([
                  ["all", "الكل", result.summary.total],
                  ["valid", "جاهز", result.summary.valid],
                  ["needs_review", "مراجعة", result.summary.review],
                  ["invalid", "أخطاء", result.summary.invalid],
                  ["duplicate", "مكرر", result.summary.duplicate],
                ] as [Filter, string, number][]).map(([value, label, count]) => (
                  <button key={value} type="button" onClick={() => setFilter(value)} className={cn("rounded-lg px-3 py-2 text-[11px] font-bold transition", filter === value ? "bg-[#b6ff3b]/10 text-[#cfff7d]" : "text-[#7d8998] hover:bg-white/4 hover:text-white")}>
                    {label} <span className="mr-1 opacity-60">{formatNumber(count)}</span>
                  </button>
                ))}
              </div>
              <div className="flex flex-col gap-2 sm:flex-row">
                <label className="relative min-w-64">
                  <Search size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#697586]" />
                  <input value={query} onChange={(event) => setQuery(event.target.value)} className="field min-h-10 py-2 pr-9 text-xs" placeholder="ابحث داخل الملف…" />
                </label>
                <button type="button" onClick={approveAllVisible} className="button-secondary min-h-10 py-2 text-xs">
                  <CheckCheck size={16} /> اعتماد صفوف المراجعة الظاهرة
                </button>
              </div>
            </div>

            <div className="scrollbar-thin overflow-x-auto">
              <table className="data-table min-w-[1120px]">
                <thead>
                  <tr>
                    <th className="w-12">اعتماد</th>
                    <th className="w-14">الصف</th>
                    <th>السؤال والخيارات</th>
                    <th className="w-48">التصنيف</th>
                    <th className="w-32">الصعوبة</th>
                    <th className="w-28">الثقة</th>
                    <th className="w-32">الحالة</th>
                  </tr>
                </thead>
                <tbody>
                  {visibleRows.map((row) => {
                    const meta = statusMeta[row.status];
                    const selected = row.status === "valid" || approvedReviewRows.has(row.clientId);
                    const categoryValue = edits[row.clientId]?.categoryId ?? row.classification.categoryId ?? "";
                    const difficultyValue = edits[row.clientId]?.difficulty ?? row.classification.difficulty;
                    return (
                      <tr key={row.clientId}>
                        <td>
                          <button
                            type="button"
                            onClick={() => toggleReview(row)}
                            disabled={row.status !== "needs_review"}
                            className={cn("grid size-7 place-items-center rounded-lg border transition", selected ? "border-[#b6ff3b] bg-[#b6ff3b] text-[#0b0f14]" : "border-white/15 text-transparent", row.status !== "needs_review" && row.status !== "valid" && "opacity-30")}
                            aria-label={selected ? "معتمد" : "اعتماد الصف"}
                          >
                            <Check size={14} strokeWidth={3} />
                          </button>
                        </td>
                        <td className="font-mono text-[#697586]">{row.rowNumber}</td>
                        <td className="max-w-xl">
                          <details className="group">
                            <summary className="flex cursor-pointer list-none items-start gap-2 font-bold text-[#eef1f4]">
                              <ChevronDown size={15} className="mt-0.5 shrink-0 text-[#697586] transition group-open:rotate-180" />
                              <span>{row.questionText || "—"}</span>
                            </summary>
                            <div className="mr-6 mt-3 grid grid-cols-2 gap-1.5 text-[11px]">
                              {row.options.map((option, optionIndex) => (
                                <span key={`${row.clientId}-${optionIndex}`} className={cn("rounded-lg border px-2.5 py-1.5", optionIndex === row.correctOptionIndex ? "border-[#b6ff3b]/20 bg-[#b6ff3b]/7 text-[#cfff7d]" : "border-white/7 bg-white/[0.02] text-[#8e98a7]")}>
                                  {optionIndex + 1}. {option || "خيار مفقود"}
                                </span>
                              ))}
                              {row.errors.map((item) => <p key={item} className="col-span-2 flex items-center gap-1.5 text-[#ff858d]"><CircleX size={12} />{item}</p>)}
                              {row.warnings.map((item) => <p key={item} className="col-span-2 flex items-center gap-1.5 text-[#e3bf6a]"><AlertTriangle size={12} />{item}</p>)}
                              {row.similarQuestions[0] ? <p className="col-span-2 rounded-lg bg-sky-400/5 p-2 text-sky-200/75">الأقرب: «{row.similarQuestions[0].text}» ({Math.round(row.similarQuestions[0].score * 100)}٪)</p> : null}
                            </div>
                          </details>
                        </td>
                        <td>
                          <select
                            value={categoryValue}
                            onChange={(event) => setRowEdit(row.clientId, { categoryId: event.target.value || null })}
                            disabled={row.status === "invalid" || row.status === "duplicate"}
                            className="field min-h-9 py-1.5 text-[11px] disabled:opacity-50"
                          >
                            <option value="">غير مصنّف</option>
                            {result.categories.filter((category) => !category.parentId).map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
                          </select>
                          <p className="mt-1.5 line-clamp-1 text-[9px] text-[#647082]" title={row.classification.reason}>{row.classification.reason}</p>
                        </td>
                        <td>
                          <select value={difficultyValue} onChange={(event) => setRowEdit(row.clientId, { difficulty: event.target.value as QuestionDifficulty })} disabled={row.status === "invalid" || row.status === "duplicate"} className="field min-h-9 py-1.5 text-[11px] disabled:opacity-50">
                            {Object.entries(difficultyLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
                          </select>
                        </td>
                        <td>
                          <div className="flex items-center gap-2">
                            <span className="h-1.5 w-12 overflow-hidden rounded-full bg-white/7"><span className={cn("block h-full rounded-full", row.classification.confidence >= 0.6 ? "bg-[#b6ff3b]" : "bg-[#ffc857]")} style={{ width: `${Math.round(row.classification.confidence * 100)}%` }} /></span>
                            <span className="font-mono text-[10px] text-[#8e98a7]">{Math.round(row.classification.confidence * 100)}%</span>
                          </div>
                        </td>
                        <td><StatusBadge tone={meta.tone}>{meta.label}</StatusBadge></td>
                      </tr>
                    );
                  })}
                  {!visibleRows.length ? (
                    <tr><td colSpan={7}><div className="grid place-items-center py-14 text-center"><CircleDashed size={27} className="mb-3 text-[#566274]" /><p className="text-xs font-bold text-[#8e98a7]">لا توجد صفوف تطابق هذا العرض</p></div></td></tr>
                  ) : null}
                </tbody>
              </table>
            </div>
          </section>

          {error ? <p role="alert" className="rounded-xl border border-[#ff4d57]/20 bg-[#ff4d57]/8 p-3 text-xs text-[#ff9298]">{error}</p> : null}

          {commitMessage ? (
            <section className="surface-card flex flex-col items-center p-8 text-center">
              <span className="mb-4 grid size-14 place-items-center rounded-full bg-[#b6ff3b]/10 text-[#b6ff3b]"><CircleCheckBig size={28} /></span>
              <h3 className="text-xl font-black">اكتملت الدفعة</h3>
              <p className="mt-2 max-w-lg text-xs leading-6 text-[#8e98a7]">{commitMessage}</p>
              <button type="button" onClick={reset} className="button-secondary mt-5"><RotateCcw size={16} /> استيراد ملف آخر</button>
            </section>
          ) : (
            <section className="surface-card flex flex-col gap-4 p-4 sm:flex-row sm:items-center sm:justify-between sm:p-5">
              <div>
                <p className="text-sm font-black">جاهز لاستيراد <span className="text-[#b6ff3b]">{formatNumber(readyCount)}</span> سؤال</p>
                <p className="mt-1 text-[10px] leading-5 text-[#697586]">الصفوف الخاطئة والمكررة وغير المعتمدة لن تُحفظ كأسئلة. يمكنك إعادة الملف بعد إصلاحها.</p>
              </div>
              <div className="flex flex-wrap gap-2">
                <button type="button" onClick={reset} disabled={committing} className="button-secondary"><RotateCcw size={16} /> ملف آخر</button>
                <button type="button" onClick={() => void commit(false)} disabled={committing || readyCount === 0} className="button-secondary">
                  {committing ? <LoaderCircle size={16} className="animate-spin" /> : <FileUp size={16} />} استيراد للمراجعة
                </button>
                {canPublish ? (
                  <button type="button" onClick={() => void commit(true)} disabled={committing || readyCount === 0} className="button-primary">
                    {committing ? <LoaderCircle size={16} className="animate-spin" /> : <CheckCheck size={16} />} استيراد ونشر <ArrowLeft size={15} />
                  </button>
                ) : null}
              </div>
            </section>
          )}
        </>
      )}

      {error && !result ? <p role="alert" className="rounded-xl border border-[#ff4d57]/20 bg-[#ff4d57]/8 p-4 text-xs leading-6 text-[#ff9298]">{error}</p> : null}
    </div>
  );
}
