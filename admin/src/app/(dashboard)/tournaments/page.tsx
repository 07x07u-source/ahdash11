import { TournamentCenter } from "@/components/tournament-center";
import { PageHeader } from "@/components/ui/page-header";

export const metadata = { title: "البطولات" };
export const dynamic = "force-dynamic";

export default function TournamentsPage() {
  return <div className="space-y-6">
    <PageHeader eyebrow="تشغيل البطولات" title="مركز البطولات" description="راقب التسجيل والقرعة وتقدم مباريات خروج المغلوب، وتدخل إداريًا دون حذف سجل النتائج." />
    <TournamentCenter />
  </div>;
}
