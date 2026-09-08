import Image from "next/image";
import Link from "next/link";
import { ShieldX } from "lucide-react";

export const metadata = { title: "صلاحية غير كافية" };

export default function UnauthorizedPage() {
  return (
    <main className="brand-grid grid min-h-screen place-items-center px-4">
      <section className="surface-card max-w-md p-8 text-center">
        <Image src="/branding/logo-symbol.png" alt="" width={56} height={56} className="mx-auto mb-5 rounded-xl bg-white object-contain p-1" />
        <ShieldX size={38} className="mx-auto mb-4 text-[#ff4d57]" />
        <h1 className="text-2xl font-black">الصلاحية غير كافية</h1>
        <p className="mt-3 text-sm leading-7 text-[#8e98a7]">حسابك مسجّل، لكنه لا يملك دور مشرف يسمح بدخول هذه الصفحة. اطلب من المدير الأعلى تحديث دورك.</p>
        <Link href="/login" className="button-secondary mt-6">العودة لتسجيل الدخول</Link>
      </section>
    </main>
  );
}
