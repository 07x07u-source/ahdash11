"use client";

import { useRouter } from "next/navigation";
import { FormEvent, useState, useTransition } from "react";
import { DatabaseZap, LoaderCircle, Plus, Power, Trash2 } from "lucide-react";
import type { FootballClubRow, FootballCountryRow, FootballLeagueRow } from "@/lib/data/social-football-data";

export function FootballDataManager({ countries, leagues, clubs, disabled }: {
  countries: FootballCountryRow[];
  leagues: FootballLeagueRow[];
  clubs: FootballClubRow[];
  disabled: boolean;
}) {
  const router = useRouter();
  const [entity, setEntity] = useState<"country" | "league" | "club">("club");
  const [message, setMessage] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  async function create(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const values = new FormData(event.currentTarget);
    const visualStatus = String(values.get("visualStatus") ?? "fallback");
    const common = {
      nameAr: String(values.get("nameAr") ?? ""),
      nameEn: String(values.get("nameEn") ?? ""),
    };
    const body = entity === "country"
      ? { entity, ...common, code: String(values.get("code") ?? ""), featured: false }
      : {
          entity,
          ...common,
          ...(entity === "league" ? { countryId: String(values.get("parentId") ?? "") } : { leagueId: String(values.get("parentId") ?? "") }),
          shortName: String(values.get("shortName") ?? "") || null,
          visualStatus,
          logoUrl: visualStatus === "fallback" ? null : String(values.get("logoUrl") ?? "") || null,
          licenseReference: visualStatus === "licensed" ? String(values.get("licenseReference") ?? "") || null : null,
          primaryColor: String(values.get("primaryColor") ?? "") || null,
          secondaryColor: null,
        };
    setMessage(null);
    const response = await fetch("/api/football-data", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
    const result = await response.json() as { error?: string };
    if (!response.ok) return setMessage(result.error ?? "تعذر إنشاء السجل.");
    event.currentTarget.reset();
    setMessage("تم حفظ السجل مع حالة الحقوق المحددة.");
    startTransition(() => router.refresh());
  }

  async function mutate(entityType: "country" | "league" | "club", id: string, active: boolean) {
    setMessage(null);
    const response = await fetch("/api/football-data", { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify({ entity: entityType, id, active }) });
    const result = await response.json() as { error?: string };
    if (!response.ok) return setMessage(result.error ?? "تعذر تحديث السجل.");
    startTransition(() => router.refresh());
  }

  async function remove(entityType: "country" | "league" | "club", id: string) {
    if (!window.confirm("حذف نهائي؟ إذا كان السجل مرتبطًا فسيُرفض الحذف ويجب تعطيله.")) return;
    setMessage(null);
    const response = await fetch("/api/football-data", { method: "DELETE", headers: { "content-type": "application/json" }, body: JSON.stringify({ entity: entityType, id }) });
    const result = await response.json() as { error?: string };
    if (!response.ok) return setMessage(result.error ?? "تعذر حذف السجل.");
    startTransition(() => router.refresh());
  }

  const parentRows = entity === "league" ? countries : leagues;
  return <div className="space-y-5">
    <section className="surface-card p-5">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3"><div><h2 className="font-black">إضافة إلى الدليل الكروي</h2><p className="mt-1 text-[10px] text-[var(--muted)]">الشعار لا يظهر في التطبيق إلا عند Custom أو Licensed.</p></div><DatabaseZap size={22} className="text-[var(--primary-strong)]" /></div>
      <div className="mb-4 flex gap-2">{(["country", "league", "club"] as const).map((value) => <button key={value} type="button" onClick={() => setEntity(value)} className={`rounded-lg px-3 py-2 text-xs font-bold ${entity === value ? "bg-[var(--primary)] text-black" : "bg-[var(--surface-3)]"}`}>{value === "country" ? "دولة" : value === "league" ? "دوري" : "نادي"}</button>)}</div>
      <form onSubmit={create} className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        {entity === "country" ? <input name="code" required maxLength={3} placeholder="رمز الدولة SA" className="field" dir="ltr" /> : <select name="parentId" required className="field"><option value="">{entity === "league" ? "اختر الدولة" : "اختر الدوري"}</option>{parentRows.map((row) => <option key={row.id} value={row.id}>{row.nameAr}</option>)}</select>}
        <input name="nameAr" required minLength={2} maxLength={100} placeholder="الاسم العربي" className="field" />
        <input name="nameEn" required minLength={2} maxLength={100} placeholder="English name" className="field" dir="ltr" />
        {entity !== "country" ? <><input name="shortName" maxLength={24} placeholder="الاسم المختصر" className="field" /><select name="visualStatus" defaultValue="fallback" className="field"><option value="fallback">Fallback — شارة مولّدة</option><option value="custom">Custom — أصل مملوك</option><option value="licensed">Licensed — أصل مرخّص</option></select><input name="logoUrl" type="url" placeholder="رابط الشعار للحالات المسموحة" className="field" dir="ltr" /><input name="licenseReference" placeholder="مرجع الترخيص عند Licensed" className="field" /><input name="primaryColor" pattern="#[0-9A-Fa-f]{6}" placeholder="#B6FF3B" className="field" dir="ltr" /></> : null}
        <button disabled={disabled || pending} className="inline-flex min-h-11 items-center justify-center gap-2 rounded-xl bg-[var(--primary)] px-4 text-xs font-black text-black disabled:opacity-50"><Plus size={16} />إضافة آمنة</button>
      </form>
      {message ? <p role="status" className="mt-3 text-xs font-bold text-[var(--muted)]">{message}</p> : null}
    </section>
    <section className="surface-card overflow-hidden">
      <div className="border-b border-[var(--border)] p-4"><h2 className="font-black">الأندية وحالة الحقوق</h2></div>
      <div className="overflow-x-auto"><table className="w-full min-w-[760px] text-right text-xs"><thead className="bg-[var(--surface-3)] text-[10px] text-[var(--muted)]"><tr><th className="p-3">النادي</th><th className="p-3">الدوري</th><th className="p-3">الحالة البصرية</th><th className="p-3">مرجع الحقوق</th><th className="p-3">النشر</th><th className="p-3">إجراءات</th></tr></thead><tbody>{clubs.map((club) => <tr key={club.id} className="border-t border-[var(--border)]"><td className="p-3"><strong>{club.nameAr}</strong><span className="block text-[9px] text-[var(--muted)]" dir="ltr">{club.nameEn}</span></td><td className="p-3">{leagues.find((league) => league.id === club.leagueId)?.nameAr ?? "—"}</td><td className="p-3"><RightsBadge value={club.visualStatus} /></td><td className="max-w-56 truncate p-3 text-[10px]">{club.visualStatus === "licensed" ? club.licenseReference ?? "مرجع مفقود" : club.visualStatus === "custom" ? "أصل مخصص" : "لا يستخدم شعارًا"}</td><td className="p-3">{club.active ? "منشور" : "متوقف"}</td><td className="p-3"><div className="flex gap-1"><button type="button" disabled={disabled || pending} onClick={() => void mutate("club", club.id, !club.active)} title={club.active ? "تعطيل" : "تفعيل"} className="grid size-9 place-items-center rounded-lg bg-[var(--surface-3)]"><Power size={14} /></button><button type="button" disabled={disabled || pending} onClick={() => void remove("club", club.id)} title="حذف" className="grid size-9 place-items-center rounded-lg bg-red-500/8 text-red-600"><Trash2 size={14} /></button></div></td></tr>)}</tbody></table></div>
      {!clubs.length ? <p className="p-8 text-center text-xs text-[var(--muted)]">لا توجد أندية فعلية في الدليل. لن نعرض بيانات وهمية.</p> : null}
      {pending ? <p className="flex items-center gap-2 p-3 text-xs"><LoaderCircle size={14} className="animate-spin" />تحديث البيانات…</p> : null}
    </section>
  </div>;
}

function RightsBadge({ value }: { value: string }) {
  const label = value === "licensed" ? "Licensed" : value === "custom" ? "Custom" : "Fallback";
  const color = value === "licensed" ? "bg-emerald-500/10 text-emerald-700" : value === "custom" ? "bg-blue-500/10 text-blue-700" : "bg-amber-500/10 text-amber-700";
  return <span className={`inline-flex rounded-full px-2 py-1 text-[9px] font-black ${color}`}>{label}</span>;
}
