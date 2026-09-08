import { PartyHelpManager, type PartyHelpItem } from "@/components/party-help-manager";
import { PageHeader } from "@/components/ui/page-header";
import { requireAdminPage } from "@/lib/auth/context";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const metadata = { title: "لعبة الجلسة" };
export const dynamic = "force-dynamic";

const fallback: PartyHelpItem[] = [
  { id: "two_chances", nameAr: "فرصتين", descriptionAr: "يسمح للفريق بإعطاء إجابتين", iconKey: "looks_two", timing: "after_question", active: true, config: {} },
  { id: "call_friend", nameAr: "استنجد", descriptionAr: "استعانة بصديق لمدة 20 ثانية", iconKey: "phone", timing: "after_question", active: true, config: { seconds: 20 } },
  { id: "risk", nameAr: "مخاطرة", descriptionAr: "مضاعفة عند الصواب وخصم القيمة عند الخطأ", iconKey: "trending_up", timing: "before_question", active: true, config: { correct_multiplier: 2, wrong_multiplier: -1 } },
  { id: "bench", nameAr: "على الدكة", descriptionAr: "إبعاد لاعب من الخصم لهذا السؤال", iconKey: "event_seat", timing: "after_question", active: true, config: { requires_player_names: true } },
  { id: "pass", nameAr: "مرّرها", descriptionAr: "تمرير السؤال للفريق الآخر", iconKey: "redo", timing: "after_question", active: true, config: { wrong_multiplier: -1 } },
];

export default async function PartyGamePage() {
  await requireAdminPage("admin");
  const supabase = await createServerSupabaseClient();
  const result = supabase ? await supabase.from("party_help_tools").select("id, name_ar, description_ar, icon_key, timing, is_active, rule_config").order("sort_order") : null;
  const items = result?.data?.length ? result.data.map((row) => ({ id: String(row.id) as PartyHelpItem["id"], nameAr: String(row.name_ar), descriptionAr: String(row.description_ar), iconKey: String(row.icon_key), timing: String(row.timing) as PartyHelpItem["timing"], active: Boolean(row.is_active), config: (row.rule_config ?? {}) as Record<string, unknown> })) : fallback;
  return <div className="space-y-6"><PageHeader eyebrow="قواعد الجلسة" title="لعبة الجلسة والمساعدات" description="إدارة كتالوج المساعدات. أرقام الجولة والنقاط والمؤقت موجودة في إعدادات اللعب المركزية." /><PartyHelpManager initialItems={items} /></div>;
}
