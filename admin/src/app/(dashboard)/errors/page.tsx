import { ErrorMonitor } from "@/components/error-monitor";
import { PageHeader } from "@/components/ui/page-header";
import { requireAdminPage } from "@/lib/auth/context";
import { hasMinimumRole } from "@/lib/auth/roles";
import { getErrorMonitoringData } from "@/lib/data/monitoring-data";

export const metadata = { title: "مشاكل التطبيق" };
export const dynamic = "force-dynamic";

export default async function ErrorsPage() {
  const admin = await requireAdminPage("moderator");
  const data = await getErrorMonitoringData();
  return <div className="space-y-6"><PageHeader eyebrow="مراقبة تشغيلية" title="مشاكل التطبيق" description="أحداث منقّحة ومجمّعة حسب البصمة من النسخ الحقيقية. Crashlytics يبقى مخصصًا للأعطال، وهذه الصفحة للأخطاء التشغيلية المسجلة في Supabase." /><ErrorMonitor data={data} canResolve={hasMinimumRole(admin.role, "admin")} /></div>;
}
