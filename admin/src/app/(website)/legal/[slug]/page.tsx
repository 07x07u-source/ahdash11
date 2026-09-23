import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowRight, CalendarDays, ChevronLeft, ShieldCheck } from "lucide-react";
import { getLegalDocument, legalDocuments } from "@/lib/site/legal";

type LegalPageProps = { params: Promise<{ slug: string }> };

export function generateStaticParams() {
  return legalDocuments.map((document) => ({ slug: document.slug }));
}

export async function generateMetadata({ params }: LegalPageProps): Promise<Metadata> {
  const document = getLegalDocument((await params).slug);
  if (!document) return {};
  return { title: document.shortTitle, description: document.summary };
}

export default async function LegalDocumentPage({ params }: LegalPageProps) {
  const document = getLegalDocument((await params).slug);
  if (!document) notFound();

  return (
    <div className="site-paper-section min-h-screen">
      <div className="site-container py-8 sm:py-12">
        <nav className="legal-breadcrumb" aria-label="مسار الصفحة"><Link href="/legal">المركز القانوني</Link><ChevronLeft size={14} /><span>{document.shortTitle}</span></nav>
        <article className="legal-document">
          <header>
            <span className="site-kicker site-kicker-dark"><ShieldCheck size={14} />وثيقة قانونية</span>
            <h1>{document.title}</h1>
            <p>{document.summary}</p>
            <span className="legal-date"><CalendarDays size={15} />آخر تحديث: 12 سبتمبر 2026</span>
          </header>
          <div className="legal-content">
            {document.sections.map((section, index) => <section key={section.title}><span>0{index + 1}</span><div><h2>{section.title}</h2>{section.paragraphs?.map((paragraph) => <p key={paragraph}>{paragraph}</p>)}{section.items ? <ul>{section.items.map((item) => <li key={item}>{item}</li>)}</ul> : null}</div></section>)}
          </div>
          <footer><p>هل تحتاج توضيحاً أو تريد ممارسة أحد حقوق البيانات؟</p><Link href="/support">تواصل مع الدعم <ArrowRight size={16} /></Link></footer>
        </article>
      </div>
    </div>
  );
}
