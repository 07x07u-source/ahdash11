import { Activity, Clock3, Radio, Swords } from "lucide-react";
import { DevelopmentDataNotice } from "@/components/ui/development-data-notice";
import { MetricCard } from "@/components/ui/metric-card";
import { PageHeader } from "@/components/ui/page-header";
import { SearchableDataTable, type TableColumn } from "@/components/ui/searchable-data-table";
import { getMatches } from "@/lib/data/admin-data";
import { formatNumber } from "@/lib/utils";

export const metadata = { title: "المباريات" };
export const dynamic = "force-dynamic";

export default async function MatchesPage() {
  const data = await getMatches();
  const columns: TableColumn[] = [
    { key: "id", label: "المعرّف", className: "font-mono text-[#c9d0d9]" }, { key: "mode", label: "النمط", format: "mode" },
    { key: "players", label: "اللاعبون", format: "number" }, { key: "questions", label: "الأسئلة", format: "number" },
    { key: "duration", label: "المدة", format: "duration" }, { key: "createdAt", label: "بدأت", format: "date" }, { key: "status", label: "الحالة", format: "status" },
  ];
  const live = data.rows.filter((row) => ["created", "lobby", "ready", "countdown", "question", "answers_locked", "result", "next_question"].includes(row.status)).length;
  return (
    <div className="space-y-6">
      <PageHeader eyebrow="تشغيل اللعب" title="المباريات" description="سجل موحّد لجميع الأنماط وحالات آلة المباراة، مع مؤشرات تساعد على رصد الانقطاع والسلوك غير الطبيعي." />
      {data.mode === "development" ? <DevelopmentDataNotice /> : null}
      <section className="grid grid-cols-2 gap-3 lg:grid-cols-3"><MetricCard label="المعروضة" value={formatNumber(data.rows.length)} change="آخر النتائج" icon={Swords} /><MetricCard label="مباشرة الآن" value={formatNumber(live)} change="جلسات لم تنتهِ" icon={Radio} accent="red" /><div className="col-span-2 lg:col-span-1"><MetricCard label="مكتملة" value={formatNumber(data.rows.filter((row) => row.status === "finished").length)} change="نتائج محسوبة من الخادم" icon={Activity} accent="blue" /></div></section>
      <SearchableDataTable rows={data.rows.map((row) => ({ ...row }))} columns={columns} searchPlaceholder="ابحث بمعرّف المباراة…" searchKeys={["id", "mode"]} statusKey="status" emptyMessage="لا توجد مباريات تطابق البحث." />
      <div className="surface-card flex gap-3 p-4 text-[11px] leading-6 text-[#8e98a7]"><Clock3 size={17} className="mt-0.5 shrink-0 text-[#b6ff3b]" /><p>الأوقات والنتائج المعروضة تأتي من سجل الخادم؛ لا تُقبل النقاط أو أزمنة الإجابة القادمة من الهاتف كمصدر موثوق.</p></div>
    </div>
  );
}
