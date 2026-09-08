import { BellRing, Clock3, Send, UsersRound } from "lucide-react";
import { NotificationCampaignForm } from "@/components/notification-campaign-form";
import { DevelopmentDataNotice } from "@/components/ui/development-data-notice";
import { MetricCard } from "@/components/ui/metric-card";
import { PageHeader } from "@/components/ui/page-header";
import { SearchableDataTable, type TableColumn } from "@/components/ui/searchable-data-table";
import { requireAdminPage } from "@/lib/auth/context";
import { getNotifications } from "@/lib/data/admin-data";
import { formatNumber } from "@/lib/utils";

export const metadata = { title: "الإشعارات" };
export const dynamic = "force-dynamic";

export default async function NotificationsPage() {
  await requireAdminPage("admin");
  const data = await getNotifications();
  const columns: TableColumn[] = [
    { key: "title", label: "الحملة", className: "font-bold text-[#eef1f4]" }, { key: "type", label: "النوع" },
    { key: "audience", label: "الجمهور" }, { key: "scheduledAt", label: "الموعد", format: "date" }, { key: "createdAt", label: "أُنشئت", format: "date" }, { key: "status", label: "الحالة", format: "status" },
  ];
  return (
    <div className="space-y-6">
      <PageHeader eyebrow="العودة اليومية" title="الإشعارات والحملات" description="أنشئ رسائل عربية موجّهة تُحفظ في طابور موثوق قبل إرسالها عبر FCM، مع إمكانية الجدولة وتقسيم الجمهور." />
      {data.mode === "development" ? <DevelopmentDataNotice label="تعرض السجلات بيانات تطوير؛ إنشاء حملة سيعمل كمحاكاة حتى ربط Supabase ومعالج FCM." /> : null}
      <section className="grid grid-cols-2 gap-3 lg:grid-cols-3"><MetricCard label="الحملات الأخيرة" value={formatNumber(data.rows.length)} change="السجلات المعروضة" icon={BellRing} /><MetricCard label="في الطابور" value={formatNumber(data.rows.filter((row) => row.status === "queued").length)} change="بانتظار الموعد أو المعالج" icon={Clock3} accent="gold" /><div className="col-span-2 lg:col-span-1"><MetricCard label="تم إرسالها" value={formatNumber(data.rows.filter((row) => row.status === "sent").length)} change="عبر خدمة الإرسال" icon={Send} accent="blue" /></div></section>
      <div className="grid gap-4 2xl:grid-cols-[.85fr_1.4fr]">
        <NotificationCampaignForm />
        <SearchableDataTable rows={data.rows.map((row) => ({ ...row }))} columns={columns} searchPlaceholder="ابحث في الحملات…" searchKeys={["title", "type", "audience"]} statusKey="status" emptyMessage="لا توجد حملات بعد." />
      </div>
      <div className="surface-card flex items-start gap-3 p-4 text-[11px] leading-6 text-[#8e98a7]"><UsersRound size={17} className="mt-0.5 shrink-0 text-[#b6ff3b]" /><p>التقسيم يحدد جمهورًا في حقل JSON فقط؛ يجب على معالج FCM توسيع الجمهور والتحقق من تفضيلات كل مستخدم قبل الإرسال.</p></div>
    </div>
  );
}
