"use client";

import { Search } from "lucide-react";
import { useMemo, useState } from "react";
import { formatDate, formatNumber } from "@/lib/utils";
import { StatusBadge } from "./status-badge";

export interface TableColumn {
  key: string;
  label: string;
  format?: "text" | "number" | "date" | "status" | "boolean" | "duration" | "mode" | "role";
  className?: string;
}

type DataRow = Record<string, string | number | boolean | null>;

const translations: Record<string, string> = {
  active: "نشط", suspended: "موقوف مؤقتًا", banned: "محظور", user: "مستخدم", moderator: "مشرف", admin: "مدير", super_admin: "مدير أعلى",
  open: "مفتوح", reviewing: "قيد التحقق", resolved: "مغلق", dismissed: "مرفوض",
  finished: "مكتملة", question: "جارية", cancelled: "ملغاة", created: "جديدة", lobby: "ردهة", ready: "جاهزة",
  solo: "ضد النظام", quick_1v1: "1 ضد 1", friend_1v1: "مع صديق", team_2v2: "2 ضد 2",
  frame: "إطار", victory_effect: "تأثير انتصار", hint: "تلميح", badge: "شارة",
};

function toneForStatus(value: string) {
  if (["active", "resolved", "finished", "published", "completed"].includes(value)) return "success" as const;
  if (["open", "reviewing", "question", "ready", "suspended"].includes(value)) return "warning" as const;
  if (["banned", "cancelled", "failed"].includes(value)) return "danger" as const;
  return "neutral" as const;
}

function Cell({ value, format = "text" }: { value: DataRow[string]; format?: TableColumn["format"] }) {
  if (value === null || value === "") return <span className="text-[#566274]">—</span>;
  if (format === "number") return <>{formatNumber(Number(value))}</>;
  if (format === "date") return <>{formatDate(String(value))}</>;
  if (format === "boolean") return <StatusBadge tone={value ? "success" : "neutral"}>{value ? "مفعّل" : "متوقف"}</StatusBadge>;
  if (format === "duration") {
    const seconds = Number(value);
    return <span dir="ltr" className="font-mono text-xs">{Math.floor(seconds / 60)}:{String(seconds % 60).padStart(2, "0")}</span>;
  }
  if (format === "status") return <StatusBadge tone={toneForStatus(String(value))}>{translations[String(value)] ?? String(value)}</StatusBadge>;
  if (format === "mode" || format === "role") return <StatusBadge tone="neutral">{translations[String(value)] ?? String(value)}</StatusBadge>;
  return <>{String(value)}</>;
}

export function SearchableDataTable({
  rows,
  columns,
  searchPlaceholder,
  searchKeys,
  statusKey,
  emptyMessage = "لا توجد نتائج.",
}: {
  rows: DataRow[];
  columns: TableColumn[];
  searchPlaceholder: string;
  searchKeys: string[];
  statusKey?: string;
  emptyMessage?: string;
}) {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("all");
  const statuses = useMemo(() => statusKey ? [...new Set(rows.map((row) => String(row[statusKey])))].filter(Boolean) : [], [rows, statusKey]);
  const filtered = useMemo(() => rows.filter((row) => {
    const haystack = searchKeys.map((key) => String(row[key] ?? "")).join(" ").toLocaleLowerCase("ar");
    return (!query || haystack.includes(query.toLocaleLowerCase("ar"))) && (!statusKey || status === "all" || String(row[statusKey]) === status);
  }), [query, rows, searchKeys, status, statusKey]);

  return (
    <section className="surface-card overflow-hidden">
      <div className="flex flex-col gap-2 border-b border-white/7 p-4 sm:flex-row">
        <label className="relative min-w-0 flex-1 sm:max-w-sm">
          <Search size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#697586]" />
          <input value={query} onChange={(event) => setQuery(event.target.value)} className="field min-h-10 py-2 pr-9 text-xs" placeholder={searchPlaceholder} />
        </label>
        {statusKey && statuses.length ? (
          <select value={status} onChange={(event) => setStatus(event.target.value)} className="field min-h-10 min-w-40 py-2 text-xs sm:w-auto">
            <option value="all">كل الحالات</option>
            {statuses.map((value) => <option key={value} value={value}>{translations[value] ?? value}</option>)}
          </select>
        ) : null}
      </div>
      <div className="scrollbar-thin overflow-x-auto">
        <table className="data-table">
          <thead><tr>{columns.map((column) => <th key={column.key} className={column.className}>{column.label}</th>)}</tr></thead>
          <tbody>
            {filtered.map((row, index) => (
              <tr key={String(row.id ?? index)}>{columns.map((column) => <td key={column.key} className={column.className}><Cell value={row[column.key]} format={column.format} /></td>)}</tr>
            ))}
            {!filtered.length ? <tr><td colSpan={columns.length}><div className="grid place-items-center py-16 text-center"><Search size={27} className="mb-3 text-[#566274]" /><p className="text-xs font-bold text-[#8e98a7]">{emptyMessage}</p></div></td></tr> : null}
          </tbody>
        </table>
      </div>
    </section>
  );
}
