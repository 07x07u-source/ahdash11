import Link from "next/link";
import { ArrowLeft, BookmarkCheck, Crown, Flag, ShieldCheck, Swords, Target, Trophy, UserRound } from "lucide-react";
import { PlayerLogoutButton } from "@/components/player-logout-button";
import { requirePlayerPage } from "@/lib/auth/player";
import { playerFeatures } from "@/lib/site/player-features";

export const metadata = { title: "حسابي" };
export const dynamic = "force-dynamic";

const icons = { profile: UserRound, "saved-games": BookmarkCheck, tournaments: Trophy, "football-preferences": Target, premium: Crown, report: Flag };

export default async function AccountPage() {
  const player = await requirePlayerPage("/account");
  return (
    <div className="site-paper-section min-h-screen">
      <div className="site-container py-8 sm:py-12">
        <section className="account-hero">
          <div className="account-avatar">{player.displayName.charAt(0)}</div>
          <div className="account-identity"><span><ShieldCheck size={14} />جلسة لاعب نشطة</span><h1>{player.displayName}</h1><p dir="ltr">@{player.username}</p></div>
          <div className="account-stats"><span><small>المستوى</small><strong>{player.level}</strong></span><span><small>XP</small><strong>{player.xp}</strong></span><span><small>التصنيف</small><strong>{player.rating}</strong></span></div>
          <PlayerLogoutButton />
        </section>

        <div className="account-actions"><Link href="/games" className="site-action"><Swords size={18} />ابدأ جولة</Link><Link href="/championships/create" className="site-action-secondary dark">أنشئ بطولة <ArrowLeft size={17} /></Link></div>

        <div className="site-section-heading mt-12"><div><span className="site-kicker site-kicker-dark">مركز اللاعب</span><h2>المتاح فعلاً، في مكان واحد.</h2></div><p>يعرض الموقع في هذه المرحلة المسارات الحقيقية أو الجزئية بوضوح، دون إظهار ميزات مؤجلة كأنها جاهزة.</p></div>
        <div className="account-feature-grid">
          {playerFeatures.map((feature) => { const Icon = icons[feature.slug]; return <Link href={`/account/${feature.slug}`} key={feature.slug} className={`account-feature-card feature-${feature.slug}`}><span><Icon size={22} /></span><div><h2>{feature.title}</h2><p>{feature.description}</p></div><ArrowLeft size={18} /></Link>; })}
        </div>
      </div>
    </div>
  );
}
