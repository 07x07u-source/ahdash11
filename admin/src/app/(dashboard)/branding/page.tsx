import { BrandingCenter } from "@/components/branding-center";
import { PageHeader } from "@/components/ui/page-header";
import { requireAdminPage } from "@/lib/auth/context";

export const metadata = { title: "هوية التطبيق" };
export const dynamic = "force-dynamic";
export default async function BrandingPage() { await requireAdminPage("moderator"); return <div className="space-y-6"><PageHeader eyebrow="Branding Center" title="هوية التطبيق والمظهر" description="أصول بصرية ومسودات ونشر آمن عبر مكتبة الوسائط. Design System الأساسي يبقى داخل التطبيق، بينما تتحكم هذه الصفحة في نقاط محددة ومتحقق منها." /><BrandingCenter /></div>; }
