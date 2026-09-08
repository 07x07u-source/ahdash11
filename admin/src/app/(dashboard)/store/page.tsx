import { Coins, PackageCheck, ShoppingBag } from "lucide-react";
import { DevelopmentDataNotice } from "@/components/ui/development-data-notice";
import { MetricCard } from "@/components/ui/metric-card";
import { PageHeader } from "@/components/ui/page-header";
import { SearchableDataTable, type TableColumn } from "@/components/ui/searchable-data-table";
import { getStoreItems } from "@/lib/data/admin-data";
import { formatNumber } from "@/lib/utils";

export const metadata = { title: "المتجر" };
export const dynamic = "force-dynamic";

export default async function StorePage() {
  const data = await getStoreItems();
  const columns: TableColumn[] = [
    { key: "name", label: "العنصر", className: "font-bold text-[#eef1f4]" }, { key: "type", label: "النوع", format: "mode" },
    { key: "rarity", label: "الندرة" }, { key: "price", label: "السعر بالعملات", format: "number" }, { key: "active", label: "التوفر", format: "boolean" },
  ];
  return (
    <div className="space-y-6">
      <PageHeader eyebrow="الاقتصاد الافتراضي" title="المتجر" description="إدارة العناصر التجميلية والتلميحات والأسعار والتوفر، مع إبقاء Ranked عادلًا ودون مزايا مدفوعة تغيّر نتيجة المباراة." />
      {data.mode === "development" ? <DevelopmentDataNotice /> : null}
      <section className="grid grid-cols-2 gap-3 lg:grid-cols-3"><MetricCard label="العناصر" value={formatNumber(data.rows.length)} change="كل عناصر الكتالوج" icon={ShoppingBag} /><MetricCard label="متاحة الآن" value={formatNumber(data.rows.filter((row) => row.active).length)} change="ظاهرة في التطبيق" icon={PackageCheck} accent="blue" /><div className="col-span-2 lg:col-span-1"><MetricCard label="متوسط السعر" value={formatNumber(Math.round(data.rows.reduce((sum, row) => sum + row.price, 0) / Math.max(data.rows.length, 1)))} change="عملة افتراضية" icon={Coins} accent="gold" /></div></section>
      <SearchableDataTable rows={data.rows.map((row) => ({ ...row }))} columns={columns} searchPlaceholder="ابحث باسم العنصر أو نوعه…" searchKeys={["name", "type", "rarity"]} emptyMessage="لا توجد عناصر تطابق البحث." />
    </div>
  );
}
