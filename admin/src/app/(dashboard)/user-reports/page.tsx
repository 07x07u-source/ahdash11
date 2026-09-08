import { UserProblemReports } from "@/components/user-problem-reports";
import { PageHeader } from "@/components/ui/page-header";
import { requireAdminPage } from "@/lib/auth/context";
import { getUserProblemReports } from "@/lib/data/monitoring-data";

export const metadata = { title: "بلاغات المستخدمين" };
export const dynamic = "force-dynamic";
export default async function UserReportsPage() { await requireAdminPage("moderator"); const data = await getUserProblemReports(); return <div className="space-y-6"><PageHeader eyebrow="الدعم" title="بلاغات المستخدمين" description="بلاغات يرسلها اللاعب من داخل التطبيق بمعلومات تشغيلية محدودة ومنقّحة، مع إمكانية ربطها بمشكلة تشغيلية موجودة." /><UserProblemReports {...data} /></div>; }
