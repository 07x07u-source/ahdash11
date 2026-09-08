import { CircleCheckBig, MessageSquareWarning, Siren } from "lucide-react";
import { DevelopmentDataNotice } from "@/components/ui/development-data-notice";
import { MetricCard } from "@/components/ui/metric-card";
import { PageHeader } from "@/components/ui/page-header";
import { SearchableDataTable, type TableColumn } from "@/components/ui/searchable-data-table";
import { getReports } from "@/lib/data/admin-data";
import { formatNumber } from "@/lib/utils";

export const metadata = { title: "البلاغات" };
export const dynamic = "force-dynamic";

export default async function ReportsPage() {
  const data = await getReports();
  const columns: TableColumn[] = [
    { key: "question", label: "السؤال", className: "max-w-lg font-bold text-[#eef1f4]" }, { key: "reason", label: "سبب البلاغ" },
    { key: "reporter", label: "المبلّغ" }, { key: "createdAt", label: "التاريخ", format: "date" }, { key: "status", label: "الحالة", format: "status" },
  ];
  return (
    <div className="space-y-6">
      <PageHeader eyebrow="ضبط الجودة" title="بلاغات الأسئلة" description="راجع بلاغات الإجابة والصورة والوضوح والتكرار، واربط القرار بالسؤال الأصلي ليبقى سجل التدقيق واضحًا." />
      {data.mode === "development" ? <DevelopmentDataNotice /> : null}
      <section className="grid grid-cols-2 gap-3 lg:grid-cols-3"><MetricCard label="بلاغات مفتوحة" value={formatNumber(data.rows.filter((row) => row.status === "open").length)} change="بانتظار الفرز" icon={Siren} accent="red" /><MetricCard label="قيد التحقق" value={formatNumber(data.rows.filter((row) => row.status === "reviewing").length)} change="لدى فريق المحتوى" icon={MessageSquareWarning} accent="gold" /><div className="col-span-2 lg:col-span-1"><MetricCard label="أُغلقت" value={formatNumber(data.rows.filter((row) => row.status === "resolved").length)} change="تم اتخاذ قرار" icon={CircleCheckBig} /></div></section>
      <SearchableDataTable rows={data.rows.map((row) => ({ ...row }))} columns={columns} searchPlaceholder="ابحث في السؤال أو سبب البلاغ…" searchKeys={["question", "reason", "reporter"]} statusKey="status" emptyMessage="لا توجد بلاغات تطابق البحث." />
    </div>
  );
}
