import Link from "next/link";
import { ArrowLeft, CircleHelp, Gamepad2, LockKeyhole, MessageCircle, ShieldCheck, Trophy } from "lucide-react";

export const metadata = {
  title: "المساعدة",
  description: "مركز مساعدة أحدعش 11 للحساب واللعب والبطولات والخصوصية.",
};

const topics = [
  { icon: Gamepad2, title: "اللعب والنتائج", copy: "الأسئلة، النقاط وحالات الانقطاع." },
  { icon: Trophy, title: "البطولات", copy: "الإنشاء، الانضمام وقواعد التعادل." },
  { icon: LockKeyhole, title: "الحساب وPremium", copy: "الدخول، الاشتراك واستعادة المشتريات." },
  { icon: ShieldCheck, title: "الخصوصية والأمان", copy: "البلاغات وطلبات البيانات والحذف." },
];

const questions = [
  ["كيف أنضم إلى بطولة؟", "افتح صفحة البطولات، اختر «عندي رمز»، ثم أدخل الرمز واسم الفريق. يلزم تسجيل الدخول أولاً."],
  ["أين ألعب Party؟", "Party وSolo المحليان متاحان على الكمبيوتر مباشرة من صفحة اللعب. وعلى الهاتف تظهر لك روابط تنزيل التطبيق."],
  ["كيف أبلغ عن مشكلة؟", "سجّل الدخول ثم افتح «الإبلاغ عن مشكلة» من مركز اللاعب، واكتب الصفحة وما حدث باختصار."],
  ["كيف أطلب حذف بياناتي؟", "راجع صفحة حقوق البيانات ثم تواصل عبر مسار الدعم بعد التحقق من ملكية الحساب."],
];

export default function SupportPage() {
  return (
    <div className="site-paper-section min-h-screen">
      <section className="support-hero"><div className="site-container py-12 sm:py-16"><span className="site-kicker"><CircleHelp size={15} />مركز المساعدة</span><h1>نحلّها قبل<br />الجولة القادمة.</h1><p>اختر القسم الأقرب لمشكلتك.</p></div></section>
      <section className="site-container py-12 sm:py-16">
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{topics.map((topic) => { const Icon = topic.icon; return <article key={topic.title} className="support-topic"><span><Icon size={22} /></span><h2>{topic.title}</h2><p>{topic.copy}</p></article>; })}</div>
        <div className="mt-12 grid gap-8 lg:grid-cols-[1fr_.72fr]">
          <section><span className="site-kicker site-kicker-dark">أسئلة متكررة</span><div className="mt-5 grid gap-3">{questions.map(([question, answer]) => <details key={question} className="support-faq"><summary>{question}<span>+</span></summary><p>{answer}</p></details>)}</div></section>
          <aside className="support-contact"><span><MessageCircle size={24} /></span><h2>ما لقيت الحل؟</h2><p>جهّز اسم المستخدم ورمز البطولة ووصفاً قصيراً للمشكلة. لا ترسل كلمة المرور أو بيانات البطاقة.</p><Link href="/legal/data-rights" className="site-action">طلبات البيانات <ArrowLeft size={17} /></Link><Link href="/legal" className="site-text-link">راجع السياسات</Link></aside>
        </div>
      </section>
    </div>
  );
}
