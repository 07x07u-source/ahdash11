import { LockKeyhole, ShieldAlert } from "lucide-react";
import { SocialModerationManager } from "@/components/social-moderation-manager";
import { PageHeader } from "@/components/ui/page-header";
import { SupabaseConnectionState } from "@/components/ui/supabase-connection-state";
import { getSocialModerationData } from "@/lib/data/social-football-data";

export const metadata = { title: "Social" };
export const dynamic = "force-dynamic";

export default async function SocialPage() {
  const data = await getSocialModerationData();
  return <div className="space-y-6">
    <PageHeader eyebrow="السلامة الاجتماعية" title="Social Moderation" description="إشراف محدود على الفِرق الخاصة والبلاغات، بلا استكشاف عام أو قراءة دردشات لأن V1 لا يحتوي دردشة أصلًا." />
    <SupabaseConnectionState state={data.state} checkedAt={data.checkedAt} detail={data.detail} />
    <div className="grid gap-3 sm:grid-cols-2"><div className="surface-card flex items-center gap-3 p-4"><LockKeyhole className="text-[var(--primary-strong)]" /><div><strong className="block text-xl">{data.teams.length.toLocaleString("ar-SA")}</strong><span className="text-[10px] text-[var(--muted)]">فرق خاصة ضمن آخر 100 سجل</span></div></div><div className="surface-card flex items-center gap-3 p-4"><ShieldAlert className="text-amber-600" /><div><strong className="block text-xl">{data.reports.filter((row) => row.status === "open").length.toLocaleString("ar-SA")}</strong><span className="text-[10px] text-[var(--muted)]">بلاغات مفتوحة</span></div></div></div>
    <SocialModerationManager data={data} disabled={data.state !== "live"} />
  </div>;
}
