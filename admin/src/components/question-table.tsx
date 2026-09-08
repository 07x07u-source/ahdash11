"use client";

import { Archive, Check, CircleHelp, EyeOff, LoaderCircle, Search, Send, Sparkles } from "lucide-react";
import { useMemo, useState } from "react";
import { StatusBadge } from "@/components/ui/status-badge";
import type { QuestionListItem } from "@/lib/data/admin-data";
import { cn, formatNumber } from "@/lib/utils";

const difficultyLabel: Record<string, string> = { easy: "سهل", medium: "متوسط", hard: "صعب", expert: "خبير" };
const statusLabel: Record<string, string> = { published: "منشور", review: "مراجعة", draft: "مسودة", archived: "مؤرشف" };

export function QuestionTable({ initialRows, canPublish }: { initialRows: QuestionListItem[]; canPublish: boolean }) {
  const [rows, setRows] = useState(initialRows);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("all");
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState("");

  const filtered = useMemo(() => rows.filter((row) => {
    const queryMatch = !query || `${row.text} ${row.category}`.toLocaleLowerCase("ar").includes(query.toLocaleLowerCase("ar"));
    return queryMatch && (status === "all" || row.status === status || (status === "review" && row.needsReview));
  }), [query, rows, status]);

  function toggle(id: string) {
    setSelected((current) => {
      const next = new Set(current);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }

  async function bulkAction(action: "publish" | "unpublish" | "archive" | "review") {
    if (!selected.size) return;
    setBusy(action);
    setMessage("");
    try {
      const response = await fetch("/api/questions/bulk", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ids: [...selected], action }),
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "تعذر تنفيذ الإجراء.");
      const nextStatus = { publish: "published", unpublish: "draft", archive: "archived", review: "review" }[action];
      setRows((current) => current.map((row) => selected.has(row.id) ? { ...row, status: nextStatus, needsReview: action === "review" } : row));
      setMessage(`تم تحديث ${payload.affected ?? selected.size} سؤال.`);
      setSelected(new Set());
    } catch (actionError) {
      setMessage(actionError instanceof Error ? actionError.message : "تعذر تنفيذ الإجراء.");
    } finally {
      setBusy(null);
    }
  }

  return (
    <section className="surface-card overflow-hidden">
      <div className="flex flex-col gap-3 border-b border-white/7 p-4 xl:flex-row xl:items-center xl:justify-between">
        <div className="flex flex-col gap-2 sm:flex-row">
          <label className="relative min-w-72">
            <Search size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#697586]" />
            <input value={query} onChange={(event) => setQuery(event.target.value)} className="field min-h-10 py-2 pr-9 text-xs" placeholder="ابحث في السؤال أو القسم…" />
          </label>
          <select value={status} onChange={(event) => setStatus(event.target.value)} className="field min-h-10 min-w-36 py-2 text-xs">
            <option value="all">كل الحالات</option><option value="published">منشور</option><option value="review">مراجعة</option><option value="draft">مسودة</option><option value="archived">مؤرشف</option>
          </select>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <span className="ml-1 text-[10px] font-bold text-[#697586]">{selected.size ? `${formatNumber(selected.size)} محدد` : "اختر أسئلة لإجراء جماعي"}</span>
          {canPublish ? <button type="button" onClick={() => void bulkAction("publish")} disabled={!selected.size || Boolean(busy)} className="button-secondary min-h-10 py-2 text-xs"><Send size={15} /> نشر</button> : null}
          <button type="button" onClick={() => void bulkAction("unpublish")} disabled={!selected.size || Boolean(busy)} className="button-secondary min-h-10 py-2 text-xs"><EyeOff size={15} /> إلغاء النشر</button>
          {canPublish ? <button type="button" onClick={() => void bulkAction("archive")} disabled={!selected.size || Boolean(busy)} className="button-danger min-h-10 py-2 text-xs"><Archive size={15} /> أرشفة</button> : null}
        </div>
      </div>
      {message ? <div className="border-b border-white/7 px-4 py-2 text-[11px] text-[#bcd58f]">{busy ? <LoaderCircle size={13} className="ml-2 inline animate-spin" /> : null}{message}</div> : null}
      <div className="scrollbar-thin overflow-x-auto">
        <table className="data-table min-w-[960px]">
          <thead><tr><th className="w-12"><span className="sr-only">تحديد</span></th><th>السؤال</th><th>النمط</th><th>القسم</th><th>الصعوبة</th><th>اللعب</th><th>الدقة</th><th>الحالة</th></tr></thead>
          <tbody>
            {filtered.map((row) => {
              const isSelected = selected.has(row.id);
              return (
                <tr key={row.id}>
                  <td><button type="button" onClick={() => toggle(row.id)} className={cn("grid size-7 place-items-center rounded-lg border", isSelected ? "border-[#b6ff3b] bg-[#b6ff3b] text-[#0b0f14]" : "border-white/15 text-transparent")} aria-label={isSelected ? "إلغاء التحديد" : "تحديد السؤال"}><Check size={14} /></button></td>
                  <td className="max-w-lg"><div className="flex items-start gap-2"><CircleHelp size={15} className="mt-0.5 shrink-0 text-[#687586]" /><span className="font-bold text-[#eef1f4]">{row.text}</span>{row.needsReview ? <Sparkles size={14} className="mt-0.5 shrink-0 text-[#ffc857]" aria-label="يحتاج مراجعة" /> : null}</div></td>
                  <td><StatusBadge tone={row.gameplayType === "true-false" ? "success" : "neutral"}>{row.gameplayType === "true-false" ? "صح أو خطأ" : "كلاسيك"}</StatusBadge></td>
                  <td>{row.category}</td>
                  <td><StatusBadge tone={row.difficulty === "expert" || row.difficulty === "hard" ? "warning" : "neutral"}>{difficultyLabel[row.difficulty] ?? row.difficulty}</StatusBadge></td>
                  <td>{formatNumber(row.played)}</td>
                  <td>{row.accuracy === null ? "—" : `${row.accuracy}%`}</td>
                  <td><StatusBadge tone={row.status === "published" ? "success" : row.status === "review" ? "warning" : "neutral"}>{statusLabel[row.status] ?? row.status}</StatusBadge></td>
                </tr>
              );
            })}
            {!filtered.length ? <tr><td colSpan={8}><div className="grid place-items-center py-16 text-center"><CircleHelp size={28} className="mb-3 text-[#566274]" /><p className="text-xs font-bold text-[#8e98a7]">لا توجد أسئلة تطابق البحث</p></div></td></tr> : null}
          </tbody>
        </table>
      </div>
    </section>
  );
}
