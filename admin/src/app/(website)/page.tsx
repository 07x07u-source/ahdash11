import Image from "next/image";
import Link from "next/link";
import {
  ArrowLeft,
  ArrowUpLeft,
  Check,
  CircleDot,
  Crown,
  Gamepad2,
  LayoutGrid,
  ShieldCheck,
  Trophy,
  UsersRound,
} from "lucide-react";
import { websitePremium } from "@/lib/site/premium";

export const metadata = {
  title: "أحدعش 11 — لعبة Party كروية",
  description: "لعبة أسئلة كرة قدم عربية لفريقين يلعبان معاً على جهاز واحد.",
};

const partySteps = [
  { number: "01", title: "اختاروا ست فئات", copy: "شكّلوا جولة تناسب معرفة المجموعة.", icon: LayoutGrid },
  { number: "02", title: "قسّموا فريقين", copy: "كل فريق باسم واضح ودور معروف.", icon: UsersRound },
  { number: "03", title: "جهّزوا المساعدات", copy: "ثلاث مساعدات لكل فريق قبل البداية.", icon: ShieldCheck },
  { number: "04", title: "احسموا 36 سؤالاً", copy: "تتبدل الأدوار وتُجمع النقاط حتى النهاية.", icon: Trophy },
];

const categories = ["سعودي", "عالمي", "تاريخ", "ملاعب", "أساطير", "انتقالات"];

export default function WebsiteHomePage() {
  return (
    <>
      <section className="site-hero">
        <div className="site-container site-hero-grid">
          <div className="site-hero-copy">
            <span className="site-kicker"><CircleDot size={14} />لعبة Party كروية سعودية</span>
            <h1 className="site-display">فريقان.<br />ست فئات.<br /><em>والملعب شاهد.</em></h1>
            <p>أحدعش 11 يجمع مجموعتك حول جهاز واحد: اختاروا الفئات، استخدموا المساعدات، وتنافسوا على 36 سؤالاً كروياً.</p>
            <div className="site-hero-actions">
              <Link href="/play?mode=classic&format=local-party" className="site-action"><Gamepad2 size={20} />ابدأ Party كضيف<ArrowLeft size={18} /></Link>
              <Link href="/games" className="site-action-secondary">اعرف طريقة اللعب</Link>
            </div>
            <div className="site-hero-proof" aria-label="ملخص التجربة">
              <span><Check size={16} />عربي وRTL أولاً</span>
              <span><Check size={16} />Party محلي</span>
              <span><Check size={16} />كرة قدم فقط</span>
            </div>
            <p className="site-availability-note"><ShieldCheck size={16} />Party وSolo المحليان متاحان على الكمبيوتر؛ بقية ميزات التطبيق تتطور على مراحل.</p>
          </div>

          <figure className="site-hero-art" aria-label="كرة قدم وكأس وبطاقات أسئلة تمثل جولة أحدعش">
            <div className="site-hero-art-media">
              <Image
                src="/artwork/website-hero-party.png"
                alt="كرة قدم سوداء وكأس ذهبي وبطاقات أسئلة بين فريقي اللعب"
                fill
                priority
                sizes="(min-width: 1280px) 520px, (min-width: 1024px) 42vw, 90vw"
              />
              <span className="site-hero-art-badge"><Trophy size={16} />جاهزة للجولة</span>
            </div>
            <figcaption className="site-hero-art-caption">
              <div><span>الجولة الكلاسيكية</span><strong>فريقان · جهاز واحد</strong></div>
              <div className="site-hero-art-stat"><strong>36</strong><span>سؤالاً</span></div>
              <div className="site-hero-art-stat"><strong>6</strong><span>فئات</span></div>
            </figcaption>
            <div className="site-hero-category-row" aria-label="أمثلة الفئات">
              {categories.map((category) => <span key={category}>{category}</span>)}
            </div>
          </figure>
        </div>
      </section>

      <section className="home-proof-rail" aria-label="حقائق تجربة اللعب">
        <div className="site-container home-proof-grid">
          <div><strong>2</strong><span>مسارا لعب متاحان</span></div>
          <div><strong>6</strong><span>فئات في Party</span></div>
          <div><strong>36</strong><span>سؤالاً في الجولة</span></div>
          <div><strong>0</strong><span>حسابات مطلوبة للعب المحلي</span></div>
        </div>
      </section>

      <section id="game-paths" className="site-paper-section" aria-labelledby="home-experiences-title">
        <div className="site-container site-section-space">
          <div className="home-experience-heading">
            <div><span className="site-kicker site-kicker-dark">اختر مسارك</span><h2 id="home-experiences-title">كل جمعة لها طريقتها.</h2></div>
            <p>ابدأ جولة محلية فوراً، تدرب وحدك، أو انتقل إلى بطولة بحسابك.</p>
          </div>
          <div className="home-experience-grid">
            <Link href="/play?mode=classic&format=local-party" className="home-experience-card is-primary">
              <Image src="/artwork/website-game-modes.png" alt="" fill sizes="(min-width: 1024px) 42vw, 90vw" />
              <span className="home-experience-shade" />
              <span className="home-experience-icon"><UsersRound size={21} /></span>
              <span className="home-experience-copy"><small>PARTY محلي</small><strong>جمعة الفريقين</strong><em>ست فئات و36 سؤالاً على جهاز واحد.</em></span>
              <span className="home-experience-arrow"><ArrowUpLeft size={20} /></span>
            </Link>
            <Link href="/play?mode=classic&format=practice" className="home-experience-card">
              <Image src="/artwork/website-hero-party.png" alt="" fill sizes="(min-width: 1024px) 27vw, 90vw" />
              <span className="home-experience-shade" />
              <span className="home-experience-icon"><Gamepad2 size={21} /></span>
              <span className="home-experience-copy"><small>SOLO</small><strong>تدريبك الخاص</strong><em>اختر الفئة والصعوبة وعدد الأسئلة.</em></span>
              <span className="home-experience-arrow"><ArrowUpLeft size={20} /></span>
            </Link>
            <Link href="/championships" className="home-experience-card">
              <Image src="/artwork/website-tournament.png" alt="" fill sizes="(min-width: 1024px) 27vw, 90vw" />
              <span className="home-experience-shade" />
              <span className="home-experience-icon"><Trophy size={21} /></span>
              <span className="home-experience-copy"><small>بطولة خاصة</small><strong>طريقك إلى الكأس</strong><em>أنشئ بطولة أو انضم إليها برمز.</em></span>
              <span className="home-experience-arrow"><ArrowUpLeft size={20} /></span>
            </Link>
          </div>

          <div className="home-section-divider" />
          <div className="site-section-heading">
            <div><span className="site-kicker site-kicker-dark">من البداية للنهاية</span><h2>جولة واضحة، بدون تشتيت.</h2></div>
            <p>نفس الفكرة الأساسية التي تميّز أحدعش: قرارات جماعية سريعة قبل أن يبدأ اختبار المعرفة.</p>
          </div>
          <div className="party-steps">
            {partySteps.map((step) => {
              const Icon = step.icon;
              return <article key={step.number} className="party-step"><span className="party-step-number">{step.number}</span><span className="party-step-icon"><Icon size={23} /></span><h3>{step.title}</h3><p>{step.copy}</p></article>;
            })}
          </div>
        </div>
      </section>

      <section className="site-story-section">
        <div className="site-container site-story-grid">
          <div>
            <span className="site-kicker">روح أحدعش</span>
            <h2>المعرفة في المنتصف.<br />والمجموعة حولها.</h2>
          </div>
          <div className="site-story-points">
            <article><span>01</span><div><h3>تجربة اجتماعية محلية</h3><p>لا غرف ولا بحث عن خصم؛ اجمعوا الفريقين وابدؤوا من المكان نفسه.</p></div></article>
            <article><span>02</span><div><h3>كرة قدم بهوية عربية</h3><p>سياق سعودي، قراءة RTL، وتفاصيل تحريرية هادئة بعيداً عن قوالب الألعاب الصاخبة.</p></div></article>
            <article><span>03</span><div><h3>اللعب المحلي للضيف</h3><p>ابدأ Party أو Solo بلا حساب؛ الحساب والبطولات والعمليات الخاصة تبقى محمية.</p></div></article>
          </div>
        </div>
      </section>

      <section className="site-paper-section">
        <div className="site-container site-section-space">
          <div className="premium-band">
            <div className="premium-mark"><Crown size={30} /></div>
            <div>
              <span>أحدعش PREMIUM</span>
              <h2>ميزة واضحة، بدون حشو.</h2>
              <p>{websitePremium.benefits.join(" · ")} — بخطتين {websitePremium.plans.join(" و")}.</p>
            </div>
            <Link href="/account/premium" className="site-action-secondary light">تعرّف على Premium <ArrowUpLeft size={18} /></Link>
          </div>
          <div className="site-legal-callout">
            <span><ShieldCheck size={20} /></span>
            <div><h3>قواعد مفهومة وخصوصية أولاً</h3><p>راجع الشروط وسياسات البيانات وقواعد البطولات قبل بدء المنافسة.</p></div>
            <Link href="/legal">المركز القانوني <ArrowLeft size={17} /></Link>
          </div>
        </div>
      </section>
    </>
  );
}
