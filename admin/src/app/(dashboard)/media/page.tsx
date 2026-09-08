import { MediaLibrary } from "@/components/media-library";
import { PageHeader } from "@/components/ui/page-header";
import { requireAdminPage } from "@/lib/auth/context";

export const metadata = { title: "مكتبة الوسائط" };
export const dynamic = "force-dynamic";

export default async function MediaPage() {
  await requireAdminPage("moderator");
  return <div className="space-y-6"><PageHeader eyebrow="Supabase Storage" title="مكتبة الوسائط" description="ارفع وعاين وابحث واستبدل الصور الإدارية. يتحقق الخادم من المحتوى الحقيقي للملف، وتُمنع إزالة أي صورة ما زالت مستخدمة." /><MediaLibrary /></div>;
}
