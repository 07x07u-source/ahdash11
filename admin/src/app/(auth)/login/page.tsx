import Image from "next/image";
import { redirect } from "next/navigation";
import { ShieldCheck } from "lucide-react";
import { LoginForm } from "@/components/login-form";
import { getAdminContext } from "@/lib/auth/context";

export const metadata = { title: "تسجيل الدخول" };
export const dynamic = "force-dynamic";

export default async function LoginPage() {
  const context = await getAdminContext();
  if (context) redirect("/dashboard");

  return (
    <main className="brand-grid relative grid min-h-screen place-items-center overflow-hidden px-4 py-10">
      <div className="relative w-full max-w-md">
        <div className="mb-7 flex flex-col items-center text-center">
          <span className="mb-4 grid h-20 w-56 place-items-center overflow-hidden border-y border-[var(--border)]">
            <Image src="/branding/logo-horizontal.png" alt="شعار أحدعش" width={210} height={68} className="h-16 w-auto object-contain" priority />
          </span>
          <p className="mt-1 text-xs font-bold text-[#697586]">مركز التحكم والتشغيل</p>
        </div>

        <section className="surface-card p-6 sm:p-8">
          <div className="mb-6">
            <p className="eyebrow mb-2">منطقة محمية</p>
            <h2 className="text-xl font-black">مرحبًا بعودتك</h2>
            <p className="mt-2 text-xs leading-6 text-[#8e98a7]">الدخول متاح للمشرفين المصرّح لهم فقط. تُطبّق الصلاحيات على الخادم وقاعدة البيانات.</p>
          </div>
          <LoginForm />
          <div className="mt-6 flex items-center gap-2 border-t border-white/7 pt-5 text-[10px] leading-5 text-[#697586]">
            <ShieldCheck size={15} className="shrink-0 text-[#b6ff3b]" />
            الجلسة مؤمّنة عبر Supabase Auth ولا تحفظ اللوحة كلمات المرور.
          </div>
        </section>
      </div>
    </main>
  );
}
