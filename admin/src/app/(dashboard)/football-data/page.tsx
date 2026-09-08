import { DatabaseZap, ShieldCheck } from "lucide-react";
import { FootballDataManager } from "@/components/football-data-manager";
import { PageHeader } from "@/components/ui/page-header";
import { SupabaseConnectionState } from "@/components/ui/supabase-connection-state";
import { getFootballCatalogData } from "@/lib/data/social-football-data";

export const metadata = { title: "Football Data" };
export const dynamic = "force-dynamic";

export default async function FootballDataPage() {
  const data = await getFootballCatalogData();
  const disabled = data.state !== "live";
  return <div className="space-y-6">
    <PageHeader eyebrow="بيانات كرة القدم" title="Football Data & Rights" description="دليل الدول والدوريات والأندية الذي يقرأه التطبيق. لا يظهر أي شعار إلا بحالة Custom أو Licensed مستوفية للمرجع." />
    <SupabaseConnectionState state={data.state} checkedAt={data.checkedAt} detail={data.detail} />
    <div className="grid gap-3 sm:grid-cols-3"><Metric icon={<DatabaseZap size={18} />} label="الدول" value={data.countries.length} /><Metric icon={<DatabaseZap size={18} />} label="الدوريات" value={data.leagues.length} /><Metric icon={<ShieldCheck size={18} />} label="الأندية المرخّصة/المخصصة" value={data.clubs.filter((row) => row.visualStatus !== "fallback").length} /></div>
    <FootballDataManager countries={data.countries} leagues={data.leagues} clubs={data.clubs} disabled={disabled} />
    <div className="surface-card p-4 text-xs leading-6 text-[var(--muted)]"><strong className="text-[var(--foreground)]">سياسة العرض:</strong> Fallback يولّد شارة نصية من ألوان السجل ولا يقبل رابط شعار. Custom يتطلب أصلًا مملوكًا. Licensed يتطلب رابطًا ومرجع ترخيص. عمليات الإدارة تسجَّل في audit_logs بعد تطبيق migration.</div>
  </div>;
}

function Metric({ icon, label, value }: { icon: React.ReactNode; label: string; value: number }) {
  return <div className="surface-card flex items-center gap-3 p-4"><span className="grid size-10 place-items-center rounded-xl bg-[var(--surface-3)] text-[var(--primary-strong)]">{icon}</span><div><strong className="block text-xl">{value.toLocaleString("ar-SA")}</strong><span className="text-[10px] text-[var(--muted)]">{label}</span></div></div>;
}
