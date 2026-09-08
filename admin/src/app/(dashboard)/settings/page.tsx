import { Database, KeyRound, ShieldCheck } from "lucide-react";
import { SettingsForm } from "@/components/settings-form";
import { DevelopmentDataNotice } from "@/components/ui/development-data-notice";
import { PageHeader } from "@/components/ui/page-header";
import { StatusBadge } from "@/components/ui/status-badge";
import { requireAdminPage } from "@/lib/auth/context";
import { getGameSettings } from "@/lib/data/admin-data";
import { hasSupabaseConfig } from "@/lib/supabase/config";

export const metadata = { title: "الإعدادات" };
export const dynamic = "force-dynamic";

export default async function SettingsPage() {
  await requireAdminPage("admin");
  const data = await getGameSettings();
  return (
    <div className="space-y-6">
      <PageHeader eyebrow="تهيئة المنصة" title="إعدادات اللعبة" description="اضبط القيم التشغيلية من مصدر مركزي مع صلاحيات خادم، بحيث تتغير قواعد اللعبة دون إصدار نسخة جديدة من التطبيق." />
      {data.mode === "development" ? <DevelopmentDataNotice label="الحفظ يعمل كمحاكاة في وضع التطوير. بعد ربط Supabase ستُكتب القيم إلى game_settings وفق RLS." /> : null}
      <div className="grid gap-4 2xl:grid-cols-[1.35fr_.65fr]">
        <SettingsForm items={data.rows} />
        <aside className="space-y-4">
          <section className="surface-card overflow-hidden">
            <div className="border-b border-white/7 p-5"><p className="eyebrow">سلامة التكامل</p><h2 className="mt-2 text-sm font-black">حالة البيئة</h2></div>
            <div className="space-y-3 p-5">
              <div className="flex items-center gap-3"><span className="grid size-9 place-items-center rounded-lg bg-white/4 text-[#8e98a7]"><Database size={17} /></span><span className="flex-1 text-xs font-bold">Supabase</span><StatusBadge tone={hasSupabaseConfig ? "success" : "warning"}>{hasSupabaseConfig ? "متصل" : "غير مهيأ"}</StatusBadge></div>
              <div className="flex items-center gap-3"><span className="grid size-9 place-items-center rounded-lg bg-white/4 text-[#8e98a7]"><KeyRound size={17} /></span><span className="flex-1 text-xs font-bold">Service Role في المتصفح</span><StatusBadge tone="success">غير مستخدم</StatusBadge></div>
              <div className="flex items-center gap-3"><span className="grid size-9 place-items-center rounded-lg bg-white/4 text-[#8e98a7]"><ShieldCheck size={17} /></span><span className="flex-1 text-xs font-bold">حماية الأدوار</span><StatusBadge tone="success">خادم + RLS</StatusBadge></div>
            </div>
          </section>
          <section className="surface-card p-5"><h3 className="text-xs font-black">قاعدة أمان</h3><p className="mt-2 text-[10px] leading-6 text-[#778393]">القيم العامة فقط يمكن للتطبيق قراءتها مباشرة. النقاط والمكافآت ونطاق المطابقة تُطبّق في RPC أو Edge Functions ولا يملك الهاتف صلاحية فرضها.</p></section>
        </aside>
      </div>
    </div>
  );
}
