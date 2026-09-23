import { TournamentCreateForm } from "@/components/tournament-create-form";
import { requirePlayerPage } from "@/lib/auth/player";

export const metadata = {
  title: "إنشاء بطولة",
  description: "جهّز بطولة كرة قدم خاصة وشارك رمزها مع أصدقائك.",
};

export const dynamic = "force-dynamic";

export default async function CreateTournamentPage() {
  await requirePlayerPage("/championships/create");
  return (
    <div className="site-paper-section min-h-screen">
      <div className="site-container py-10 sm:py-14">
        <div className="max-w-2xl"><span className="site-kicker site-kicker-dark">استوديو البطولة</span><h1 className="mt-4 text-4xl font-black tracking-[-0.04em] sm:text-5xl">ابنِ المنافسة بطريقتك.</h1><p className="mt-4 text-base leading-7 text-[#746b5f]">اضبط الأساسيات ثم شارك رمزاً واحداً مع المجموعة.</p></div>
        <div className="mt-9"><TournamentCreateForm /></div>
      </div>
    </div>
  );
}
