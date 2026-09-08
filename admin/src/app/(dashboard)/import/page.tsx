import { FileQuestion, History, Sparkles } from "lucide-react";
import { ImportWorkbench } from "@/components/import/import-workbench";
import { PageHeader } from "@/components/ui/page-header";
import { requireAdminPage } from "@/lib/auth/context";
import { hasMinimumRole } from "@/lib/auth/roles";

export const metadata = { title: "استيراد الأسئلة" };

export default async function ImportPage() {
  const admin = await requireAdminPage("moderator");

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="محرّك المحتوى"
        title="استيراد الأسئلة"
        description="حوّل ملفًا بسيطًا إلى أسئلة مصنّفة وجاهزة للنشر، مع كشف الأخطاء والتكرار والتشابه قبل أن يدخل أي محتوى إلى اللعبة."
        actions={
          <div className="flex items-center gap-2 rounded-xl border border-[#b6ff3b]/14 bg-[#b6ff3b]/5 px-3 py-2 text-[10px] font-bold text-[#b8db7c]">
            <Sparkles size={15} className="text-[#b6ff3b]" /> مصنّف القواعد v1
          </div>
        }
      />

      <ImportWorkbench canPublish={hasMinimumRole(admin.role, "admin")} />

      <section className="grid gap-3 md:grid-cols-3">
        <article className="surface-card p-4">
          <FileQuestion size={18} className="mb-3 text-[#b6ff3b]" />
          <h3 className="text-xs font-black">صيغة بسيطة</h3>
          <p className="mt-2 text-[10px] leading-5 text-[#778393]">السؤال، أربعة خيارات، الإجابة الصحيحة، وصورة اختيارية. بقية البيانات يستنتجها النظام.</p>
        </article>
        <article className="surface-card p-4">
          <Sparkles size={18} className="mb-3 text-[#ffc857]" />
          <h3 className="text-xs font-black">تصنيف قابل للتبديل</h3>
          <p className="mt-2 text-[10px] leading-5 text-[#778393]">الخدمة مستقلة وتعتمد قواعد وبيانات الأقسام؛ يمكن إضافة LLM لاحقًا دون تغيير واجهة الاستيراد.</p>
        </article>
        <article className="surface-card p-4">
          <History size={18} className="mb-3 text-sky-300" />
          <h3 className="text-xs font-black">أثر تدقيق كامل</h3>
          <p className="mt-2 text-[10px] leading-5 text-[#778393]">تُحفظ الدفعة وكل صف ونتيجة تصنيف وقرار مراجعة لسهولة الرجوع والمحاسبة.</p>
        </article>
      </section>
    </div>
  );
}
