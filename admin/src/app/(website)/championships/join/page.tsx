import { TournamentJoinForm } from "@/components/tournament-join-form";
import { requirePlayerPage } from "@/lib/auth/player";

export const metadata = { title: "الانضمام إلى بطولة" };
export const dynamic = "force-dynamic";

export default async function JoinTournamentPage() {
  await requirePlayerPage("/championships/join");
  return <div className="site-paper-section min-h-[calc(100vh-4.75rem)]"><div className="site-container py-10 sm:py-14"><div className="mx-auto max-w-xl"><span className="site-kicker site-kicker-dark">الانضمام للبطولة</span><h1 className="mt-4 text-4xl font-black tracking-[-0.04em] sm:text-5xl">مكانك محفوظ بالرمز.</h1><p className="mt-4 text-base leading-7 text-[#746b5f]">سجّل فريقك وانتظر موافقة منظم البطولة.</p><div className="mt-8"><TournamentJoinForm /></div></div></div></div>;
}
