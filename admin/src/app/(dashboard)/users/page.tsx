import { ShieldCheck, UserRoundX, UsersRound } from "lucide-react";
import { DevelopmentDataNotice } from "@/components/ui/development-data-notice";
import { MetricCard } from "@/components/ui/metric-card";
import { PageHeader } from "@/components/ui/page-header";
import { SearchableDataTable, type TableColumn } from "@/components/ui/searchable-data-table";
import { getUsers } from "@/lib/data/admin-data";
import { formatNumber } from "@/lib/utils";

export const metadata = { title: "المستخدمون" };
export const dynamic = "force-dynamic";

export default async function UsersPage() {
  const data = await getUsers();
  const columns: TableColumn[] = [
    { key: "name", label: "المستخدم", className: "font-bold text-[#eef1f4]" }, { key: "username", label: "اسم الحساب" },
    { key: "level", label: "المستوى", format: "number" }, { key: "rating", label: "التقييم", format: "number" },
    { key: "role", label: "الدور", format: "role" }, { key: "status", label: "الحالة", format: "status" }, { key: "createdAt", label: "انضم", format: "date" },
  ];
  const rows = data.rows.map((row) => ({ ...row }));
  return (
    <div className="space-y-6">
      <PageHeader eyebrow="المجتمع والصلاحيات" title="المستخدمون" description="تتبّع الحسابات والمستوى والتقييم والحالة. قرارات الحظر والأدوار محمية بسياسات RLS وليست مجرد إخفاء في الواجهة." />
      {data.mode === "development" ? <DevelopmentDataNotice /> : null}
      <section className="grid grid-cols-2 gap-3 lg:grid-cols-3">
        <MetricCard label="النتائج المعروضة" value={formatNumber(data.rows.length)} change="أحدث الحسابات حسب الفلتر" icon={UsersRound} />
        <MetricCard label="الحسابات الموقوفة" value={formatNumber(data.rows.filter((row) => row.status !== "active").length)} change="موقوفة أو محظورة" icon={UserRoundX} accent="red" />
        <div className="col-span-2 lg:col-span-1"><MetricCard label="فريق الإدارة" value={formatNumber(data.rows.filter((row) => row.role !== "user").length)} change="مشرفون ومديرون" icon={ShieldCheck} accent="gold" /></div>
      </section>
      <SearchableDataTable rows={rows} columns={columns} searchPlaceholder="ابحث بالاسم أو اسم الحساب…" searchKeys={["name", "username"]} statusKey="status" emptyMessage="لا يوجد مستخدمون يطابقون البحث." />
    </div>
  );
}
