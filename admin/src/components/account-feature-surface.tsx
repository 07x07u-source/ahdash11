"use client";

import { type FormEvent, useMemo, useState, useSyncExternalStore } from "react";
import Link from "next/link";
import {
  ArrowRight,
  BookmarkCheck,
  Check,
  Crown,
  Flag,
  KeyRound,
  Plus,
  Sparkles,
  Target,
  Trophy,
  UserRound,
} from "lucide-react";
import { createBrowserSupabaseClient } from "@/lib/supabase/client";
import { websitePremium } from "@/lib/site/premium";

type Feature = { slug: string; title: string; description: string };
type Player = { id: string; displayName: string; username: string; rating: number; favoriteClub: string | null };

const iconMap: Record<string, typeof BookmarkCheck> = {
  profile: UserRound,
  "saved-games": BookmarkCheck,
  tournaments: Trophy,
  "football-preferences": Target,
  premium: Crown,
  report: Flag,
};

export function AccountFeatureSurface({ feature, player }: { feature: Feature; player: Player }) {
  const Icon = iconMap[feature.slug] ?? Sparkles;
  return (
    <div className="site-paper-section min-h-screen">
      <div className="site-container py-8 sm:py-12">
        <Link href="/account" className="feature-back"><ArrowRight size={17} />مركز اللاعب</Link>
        <header className="feature-head"><span><Icon size={25} /></span><div><small>حساب {player.displayName}</small><h1>{feature.title}</h1><p>{feature.description}</p></div></header>
        <section className="feature-surface">{renderFeature(feature.slug, player)}</section>
      </div>
    </div>
  );
}

function renderFeature(slug: string, player: Player) {
  switch (slug) {
    case "profile": return <Profile player={player} />;
    case "saved-games": return <SavedGames />;
    case "tournaments": return <Tournaments />;
    case "football-preferences": return <FootballPreferences player={player} />;
    case "premium": return <Premium />;
    case "report": return <Report />;
    default: return null;
  }
}

function Profile({ player }: { player: Player }) {
  const [state, setState] = useState<"idle" | "busy" | "done" | "error">("idle");
  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setState("busy");
    const form = new FormData(event.currentTarget);
    const supabase = createBrowserSupabaseClient();
    if (!supabase) return setState("error");
    const { error } = await supabase.from("profiles").update({
      display_name: String(form.get("displayName") ?? "").trim(),
      username: String(form.get("username") ?? "").trim().replace(/^@/, ""),
    }).eq("id", player.id);
    setState(error ? "error" : "done");
  }
  return (
    <div className="profile-feature">
      <div className="profile-art"><span>{player.displayName.charAt(0)}</span><small>نقاط التصنيف</small><strong>{player.rating}</strong></div>
      <form onSubmit={save}>
        <label className="site-field"><span>الاسم الظاهر</span><input name="displayName" defaultValue={player.displayName} required minLength={2} maxLength={50} /></label>
        <label className="site-field"><span>اسم المستخدم</span><input name="username" defaultValue={player.username} required minLength={3} maxLength={24} dir="ltr" /></label>
        {state === "done" ? <p className="auth-alert is-success"><Check size={17} />تم تحديث الملف. حدّث الصفحة لرؤية الاسم في الشريط العلوي.</p> : null}
        {state === "error" ? <p className="auth-alert is-error" role="alert">تعذر الحفظ؛ قد يكون اسم المستخدم مستخدماً.</p> : null}
        <button type="submit" className="site-action" disabled={state === "busy"}>{state === "busy" ? "جاري الحفظ…" : "حفظ الملف"}</button>
      </form>
    </div>
  );
}

function subscribeSavedGames(callback: () => void) {
  window.addEventListener("storage", callback);
  return () => window.removeEventListener("storage", callback);
}

function SavedGames() {
  const raw = useSyncExternalStore(subscribeSavedGames, () => window.localStorage.getItem("ahdash11:saved-games") ?? "[]", () => "[]");
  const games = useMemo(() => {
    try {
      return JSON.parse(raw) as Array<{ id: string; modeTitle: string; formatTitle: string; score: number; total: number; playedAt: string }>;
    } catch {
      return [];
    }
  }, [raw]);
  if (!games.length) return <EmptyState icon={BookmarkCheck} title="لا توجد معاينة محفوظة" text="نتائج لعب الويب التجريبي تُحفظ محلياً في هذا المتصفح فقط." action="فتح طريقة اللعب" href="/games" />;
  return <div className="saved-list">{games.map((game) => <article key={game.id}><span>{game.score}/{game.total}</span><div><h2>{game.modeTitle}</h2><p>{game.formatTitle} · {new Intl.DateTimeFormat("ar-SA", { dateStyle: "medium" }).format(new Date(game.playedAt))}</p></div><Link href="/games">معاينة جديدة</Link></article>)}</div>;
}

function Tournaments() {
  return <div className="tournaments-feature"><article><span><Plus size={25} /></span><h2>بطولة خروج مغلوب</h2><p>أنشئ الأساسيات واحصل على رمز. الإدارة الكاملة للدورة تبقى في التطبيق حالياً.</p><Link href="/championships/create" className="site-action">إنشاء بطولة</Link></article><article><span><KeyRound size={25} /></span><h2>الانضمام برمز</h2><p>أدخل الرمز واسم الفريق لإرسال طلب تسجيل حقيقي.</p><Link href="/championships/join" className="site-action-secondary dark">إدخال رمز</Link></article></div>;
}

function FootballPreferences({ player }: { player: Player }) {
  const clubs = ["الهلال", "النصر", "الاتحاد", "الأهلي", "ريال مدريد", "برشلونة", "ليفربول", "مانشستر سيتي"];
  const [selected, setSelected] = useState(player.favoriteClub ?? "");
  const [saved, setSaved] = useState(false);
  async function save() {
    const supabase = createBrowserSupabaseClient();
    const { error } = supabase ? await supabase.from("profiles").update({ favorite_club: selected }).eq("id", player.id) : { error: new Error() };
    setSaved(!error);
  }
  return <><div className="preference-pitch"><Target size={44} /><div><h2>نادٍ مفضل واحد.</h2><p>يحفظ الموقع اختيارك في ملف اللاعب؛ التخصيص الموسع ليس متاحاً بعد.</p></div></div><div className="club-grid">{clubs.map((club) => <button type="button" key={club} className={selected === club ? "is-selected" : ""} onClick={() => { setSelected(club); setSaved(false); }}><span>{club.charAt(0)}</span>{club}{selected === club ? <Check size={17} /> : null}</button>)}</div><button type="button" className="site-action mt-6" disabled={!selected} onClick={save}>{saved ? <Check size={18} /> : <Target size={18} />}{saved ? "تم الحفظ" : "حفظ الاختيار"}</button></>;
}

function Premium() {
  return (
    <div className="premium-feature">
      <div className="premium-feature-copy">
        <span><Crown size={16} />11 Premium</span>
        <h2>فائدتان.<br />واضحتان.</h2>
        <ul>{websitePremium.benefits.map((benefit) => <li key={benefit}><Check size={17} />{benefit}</li>)}</ul>
        <p>صفحة الموقع تعريفية في هذه المرحلة؛ الشراء والاستعادة الفعليان غير متاحين هنا بعد.</p>
      </div>
      <div className="premium-plans" aria-label="خطط Premium المعتمدة">
        {websitePremium.plans.map((plan) => <span key={plan}><small>خطة</small><strong>{plan}</strong><i>السعر والتوفر حسب المتجر</i></span>)}
      </div>
    </div>
  );
}

function Report() {
  const [state, setState] = useState<"idle" | "busy" | "done" | "error">("idle");
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setState("busy");
    const form = new FormData(event.currentTarget);
    const supabase = createBrowserSupabaseClient();
    if (!supabase) return setState("error");
    const { error } = await supabase.rpc("submit_user_problem_report", {
      p_category: String(form.get("category")),
      p_description: String(form.get("description")),
      p_screen: String(form.get("screen") || "website"),
      p_app_version: "1.0.0",
      p_build_number: "web",
      p_platform: "web",
    });
    setState(error ? "error" : "done");
  }
  if (state === "done") return <EmptyState icon={Check} title="وصلنا بلاغك" text="شكراً لك. أُرسل البلاغ للمراجعة." href="/account" action="العودة للحساب" />;
  return <form className="report-form" onSubmit={submit}><div className="report-intro"><span><Flag size={26} /></span><div><h2>ما الذي حدث؟</h2><p>اذكر الصفحة، المشكلة، والنتيجة التي توقعتها.</p></div></div><label className="site-field"><span>نوع المشكلة</span><select name="category" defaultValue="gameplay"><option value="gameplay">اللعب أو البطولات</option><option value="login">تسجيل الدخول</option><option value="notification">الإشعارات</option><option value="purchase">Premium</option><option value="performance">الأداء</option><option value="other">أخرى</option></select></label><label className="site-field"><span>الصفحة أو الشاشة</span><input name="screen" placeholder="مثال: إنشاء بطولة" /></label><label className="site-field"><span>وصف مختصر</span><textarea name="description" required minLength={10} maxLength={1500} placeholder="اشرح المشكلة في سطرين أو ثلاثة…" /></label>{state === "error" ? <p className="auth-alert is-error" role="alert">تعذر إرسال البلاغ. حاول مجدداً.</p> : null}<button type="submit" className="site-action" disabled={state === "busy"}>{state === "busy" ? "جاري الإرسال…" : "إرسال البلاغ"}</button></form>;
}

function EmptyState({ icon: Icon, title, text, action, href }: { icon: typeof BookmarkCheck; title: string; text: string; action?: string; href?: string }) {
  return <div className="feature-empty"><span><Icon size={44} /></span><h2>{title}</h2><p>{text}</p>{action && href ? <Link href={href} className="site-action mt-5">{action}</Link> : null}</div>;
}
