import Image from "next/image";
import Link from "next/link";
import { ArrowLeft, Check, Gamepad2, LayoutGrid, ShieldCheck, Smartphone, UsersRound } from "lucide-react";
import { gameFormats, gameModes, normalizeGameFormat } from "@/lib/site/game-modes";

export const metadata = {
  title: "طريقة اللعب",
  description: "تعرف على تجربة Party الكروية في أحدعش 11 وحالة اللعب على الموقع.",
};

export default async function GamesPage({ searchParams }: { searchParams: Promise<{ format?: string }> }) {
  const availableFormats = gameFormats.filter((format) => format.discoverableOnWebsite);
  const requestedFormat = normalizeGameFormat((await searchParams).format ?? "local-party");
  const selectedFormat = availableFormats.some((format) => format.slug === requestedFormat) ? requestedFormat : "local-party";
  const classic = gameModes.find((mode) => mode.slug === "classic")!;
  const soloSelected = selectedFormat === "practice";

  return (
    <div className="site-paper-section min-h-screen">
      <section className="games-hero">
        <div className="site-container games-hero-grid">
          <div>
            <span className="site-kicker"><Gamepad2 size={15} />طريقة اللعب</span>
            <h1>Party أولاً.<br /><em>وكرة القدم دائماً.</em></h1>
            <p>التجربة الرئيسية تجمع فريقين حول جهاز واحد. اختاروا ست فئات، جهّزوا المساعدات، ثم تنافسوا على 36 سؤالاً.</p>
          </div>
          <aside className="page-hero-visual">
            <figure className="page-hero-art page-hero-art-light">
              <Image
                src="/artwork/website-game-modes.png"
                alt="فريقان من قطع اللعب حول كرة قدم وست بطاقات فئات"
                fill
                priority
                sizes="(min-width: 1024px) 38vw, 90vw"
              />
              <figcaption><UsersRound size={16} />فريقان يتشاركان الجولة</figcaption>
            </figure>
            <div className="games-truth-card">
              <span><Smartphone size={22} /></span>
              <div><small>متاح الآن على الكمبيوتر</small><strong>Party وSolo بمحتوى أحدعش</strong><p>اللعب المحلي الأساسي أصبح حقيقياً، بينما بقية تكافؤ التطبيق يأتي في مراحل لاحقة.</p></div>
            </div>
          </aside>
        </div>
      </section>

      <section className="site-container site-section-space">
        <div className="games-format-strip">
          <div><span><UsersRound size={18} /></span><h2>اختَر إطار الجولة</h2><p>كلا المسارين محليان ويعملان للضيف على المتصفح نفسه.</p></div>
          <div className="games-format-list">
            {availableFormats.map((format) => (
              <Link href={`/games?format=${format.slug}`} key={format.slug} className={selectedFormat === format.slug ? "is-active" : ""} aria-current={selectedFormat === format.slug ? "page" : undefined}>
                <strong>{format.title}</strong><small>{format.description}</small>
              </Link>
            ))}
          </div>
        </div>

        <div className="games-product-grid">
          <article className="game-primary-card">
            <div className="game-primary-card-top"><span><LayoutGrid size={23} /></span><small>النمط المعتمد</small></div>
            <h2>{classic.title}</h2>
            <p>{soloSelected ? "تحدّ فردي كلاسيكي باختيار الفئات والصعوبة وعدد الأسئلة." : "Party محلي بفريقين وأسئلة نصية أو مصورة ومساعدات تغيّر قرار الجولة."} يستخدم الموقع الفئات والأسئلة المنشورة عبر عقود Supabase نفسها المستخدمة في التطبيق.</p>
            <ul>{soloSelected ? <><li><Check size={16} />فئات وصعوبة وعدد تختاره</li><li><Check size={16} />15 ثانية مع مكافأة سرعة</li><li><Check size={16} />نتيجة وأفضل رقم محلي</li></> : <><li><Check size={16} />ست فئات × ستة أسئلة</li><li><Check size={16} />ثلاث مساعدات لكل فريق</li><li><Check size={16} />كشف الإجابة، خطف ونقاط</li></>}</ul>
            <Link href={`/play?mode=classic&format=${selectedFormat}`} className="site-action">ابدأ كضيف <ArrowLeft size={17} /></Link>
          </article>

          <aside className="game-phase-note">
            <span><ShieldCheck size={24} /></span>
            <small>حدود اللعب المحلي</small>
            <h2>لا أسئلة تجريبية.</h2>
            <p>إذا لم يوفر الكتالوج حزمة صالحة، يظهر خطأ واضح ولا يملأ الموقع الجولة بمحتوى وهمي.</p>
            <div><ShieldCheck size={17} /><span>True/False والسرعة والأنماط المؤجلة غير مفعلة.</span></div>
          </aside>
        </div>
      </section>
    </div>
  );
}
