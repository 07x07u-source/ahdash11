import Link from "next/link";
import { ArrowLeft, BookOpenCheck, Database, FileText, ShieldCheck, Trophy } from "lucide-react";
import { legalDocuments } from "@/lib/site/legal";

export const metadata = {
  title: "المركز القانوني",
  description: "سياسات أحدعش 11 وشروط الاستخدام والخصوصية وقواعد البطولات.",
};

const iconBySlug = { terms: FileText, privacy: ShieldCheck, community: BookOpenCheck, "tournament-rules": Trophy, refunds: FileText, cookies: Database, "data-rights": Database };

export default function LegalHubPage() {
  return (
    <div className="site-paper-section min-h-screen">
      <section className="legal-hero"><div className="site-container py-12 sm:py-16"><span className="site-kicker"><ShieldCheck size={15} />المركز القانوني</span><h1>واضحة من أول جولة.</h1><p>الشروط والسياسات التي تنظّم استخدام أحدعش وتحمي اللاعبين.</p></div></section>
      <section className="site-container py-12 sm:py-16">
        <div className="legal-review-note"><strong>ملاحظة ما قبل الإطلاق التجاري</strong><span>تُستكمل بيانات الكيان المشغّل وعنوانه ووسائل التواصل النظامية بعد اعتمادها، ثم تُراجع هذه النصوص من مستشار قانوني.</span></div>
        <div className="mt-8 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {legalDocuments.map((document) => {
            const Icon = iconBySlug[document.slug as keyof typeof iconBySlug] ?? FileText;
            return <Link key={document.slug} href={`/legal/${document.slug}`} className="legal-card"><span><Icon size={22} /></span><h2>{document.shortTitle}</h2><p>{document.summary}</p><i>اقرأ الوثيقة <ArrowLeft size={16} /></i></Link>;
          })}
        </div>
      </section>
    </div>
  );
}
