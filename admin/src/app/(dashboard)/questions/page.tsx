import Link from "next/link";
import { FileUp } from "lucide-react";
import { QuestionEditor } from "@/components/question-editor";
import { QuestionTable } from "@/components/question-table";
import { DevelopmentDataNotice } from "@/components/ui/development-data-notice";
import { PageHeader } from "@/components/ui/page-header";
import { requireAdminPage } from "@/lib/auth/context";
import { hasMinimumRole } from "@/lib/auth/roles";
import { getCategories, getQuestions } from "@/lib/data/admin-data";

export const metadata = { title: "الأسئلة" };
export const dynamic = "force-dynamic";

export default async function QuestionsPage() {
  const [admin, data, categories] = await Promise.all([
    requireAdminPage("moderator"),
    getQuestions(),
    getCategories(),
  ]);
  return (
    <div className="space-y-6">
      <PageHeader eyebrow="بنك المحتوى" title="الأسئلة" description="ابحث وراجع وانشر الأسئلة، وتابع الأداء الفعلي لكل سؤال دون تعريض الإجابة الصحيحة لواجهة اللاعب."
        actions={<Link href="/import" className="button-primary"><FileUp size={16} /> استيراد أسئلة</Link>} />
      {data.mode === "development" ? <DevelopmentDataNotice /> : null}
      <QuestionEditor categories={categories.rows} />
      <QuestionTable initialRows={data.rows} canPublish={hasMinimumRole(admin.role, "admin")} />
    </div>
  );
}
