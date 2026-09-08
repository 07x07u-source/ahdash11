import { ContentManager } from "@/components/content-manager";
import { PageHeader } from "@/components/ui/page-header";
import { requireAdminPage } from "@/lib/auth/context";

export const metadata = { title: "محتوى التطبيق" };
export const dynamic = "force-dynamic";

export default async function ContentPage() {
  await requireAdminPage("moderator");
  return <div className="space-y-6"><PageHeader eyebrow="محتوى قابل للنشر" title="محتوى التطبيق" description="حرّر النصوص التسويقية والصور كمسودة، عاينها، ثم انشرها دون إصدار نسخة جديدة من التطبيق. لا تُعرض المسودات للمستخدمين." /><ContentManager /></div>;
}
