import Image from "next/image";
import Link from "next/link";
import { ArrowLeft, Check, KeyRound, LockKeyhole, Plus, ShieldCheck, Smartphone, Trophy } from "lucide-react";

export const metadata = {
  title: "البطولات",
  description: "أنشئ بطولة خروج مغلوب أو أرسل طلب انضمام برمز في أحدعش 11.",
};

export default function TournamentsPage() {
  return (
    <div className="site-paper-section min-h-screen">
      <section className="tournaments-hero">
        <div className="site-container tournaments-hero-grid">
          <div>
            <span className="site-kicker"><Trophy size={15} />البطولات</span>
            <h1>المنافسة تبدأ<br /><em>برمز واضح.</em></h1>
            <p>أنشئ بطولة خروج مغلوب أو انضم إلى بطولة تعرف رمزها. يلزم حساب لاعب لإتمام أي إجراء.</p>
          </div>
          <aside className="page-hero-visual">
            <figure className="page-hero-art">
              <Image
                src="/artwork/website-tournament.png"
                alt="كأس ذهبي في نهاية مسار بطولة خروج مغلوب كروية"
                fill
                priority
                sizes="(min-width: 1024px) 38vw, 90vw"
              />
              <figcaption><Trophy size={16} />من دور البداية إلى الكأس</figcaption>
            </figure>
            <div className="tournament-auth-note"><LockKeyhole size={22} /><div><strong>حسابك أولاً</strong><span>الإنشاء والانضمام محميان بجلسة Supabase حقيقية.</span></div></div>
          </aside>
        </div>
      </section>

      <section className="site-container site-section-space">
        <div className="tournament-paths">
          <article>
            <span><Plus size={25} /></span>
            <small>للمنظّم</small>
            <h2>أنشئ بطولة خاصة</h2>
            <p>اضبط الاسم والموعد والسعة ضمن نظام خروج المغلوب المدعوم، ثم شارك رمز الانضمام.</p>
            <ul><li><Check size={16} />خروج مغلوب فقط</li><li><Check size={16} />رمز انضمام خاص</li></ul>
            <Link href="/championships/create" className="site-action">إنشاء بطولة <ArrowLeft size={17} /></Link>
          </article>
          <article>
            <span><KeyRound size={25} /></span>
            <small>للمشارك</small>
            <h2>عندك رمز؟</h2>
            <p>أدخل رمز المنظّم واسم فريقك لإرسال طلب التسجيل دون استعراض بطولات وهمية.</p>
            <ul><li><Check size={16} />تحقق من الرمز</li><li><Check size={16} />طلب تسجيل حقيقي</li></ul>
            <Link href="/championships/join" className="site-action-secondary dark">الانضمام برمز <ArrowLeft size={17} /></Link>
          </article>
        </div>

        <div className="tournament-scope-note">
          <span><Smartphone size={22} /></span>
          <div><strong>دورة البطولة الكاملة ما زالت في التطبيق</strong><p>الموقع لا يدّعي حالياً توفر الاستكشاف المباشر أو إدارة القرعة والشجرة والنتائج كاملة. توسيع هذه الدورة جزء من مرحلة لاحقة.</p></div>
          <ShieldCheck size={20} />
        </div>
      </section>
    </div>
  );
}
