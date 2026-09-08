import { Boxes, ChevronLeft, FolderTree, GripVertical, Layers3 } from "lucide-react";
import { CategoryContentEditor, CategoryCreateButton } from "@/components/category-content-editor";
import { PageHeader } from "@/components/ui/page-header";
import { StatusBadge } from "@/components/ui/status-badge";
import { SupabaseConnectionState } from "@/components/ui/supabase-connection-state";
import { getCategories } from "@/lib/data/admin-data";
import { formatDate, formatNumber } from "@/lib/utils";

export const metadata = { title: "الأقسام" };
export const dynamic = "force-dynamic";

export default async function CategoriesPage() {
  const data = await getCategories();
  const roots = data.rows.filter((row) => !row.parentId);
  const parentChoices = roots.map((row) => ({ id: row.id, name: row.name }));
  const mutationDisabled = data.state === "demo" || data.state === "error" || data.state === "not_configured";
  return (
    <div className="space-y-6">
      <PageHeader eyebrow="هيكلة المحتوى" title="الأقسام والتصنيفات الفرعية" description="إدارة فعلية للبنية التي يقرأها التطبيق: إنشاء وتعديل وتعطيل وترتيب وأغلفة، من دون بيانات وهمية أو مخطط موازٍ." />
      <SupabaseConnectionState state={data.state} checkedAt={data.checkedAt} detail={data.detail} />
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div><p className="text-sm font-black">{formatNumber(roots.length)} أقسام رئيسية</p><p className="mt-1 text-xs text-[var(--muted)]">{formatNumber(data.rows.length - roots.length)} تصنيفات فرعية</p></div>
        <CategoryCreateButton parents={parentChoices} disabled={mutationDisabled} />
      </div>
      {data.state === "error" || data.state === "not_configured" ? (
        <section className="surface-card grid min-h-64 place-items-center p-8 text-center">
          <div><FolderTree size={34} className="mx-auto text-[var(--muted)]" /><h2 className="mt-4 font-black">تعذر تحميل الأقسام</h2><p className="mt-2 text-xs text-[var(--muted)]">أعد المحاولة من حالة الاتصال أعلاه. لن تُعرض بيانات تجريبية بدل الخطأ.</p></div>
        </section>
      ) : null}
      {data.state !== "error" && data.state !== "not_configured" ? (
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        {roots.map((category) => {
          const children = data.rows.filter((row) => row.parentId === category.id);
          return (
            <article key={category.id} className="surface-card surface-card-hover overflow-hidden">
              <div className="flex items-start gap-3 p-5">
                <span className="grid size-11 shrink-0 place-items-center overflow-hidden rounded-md bg-[var(--surface-3)] bg-cover text-[var(--primary-strong)]" style={category.imageUrl ? { backgroundImage: `url(${JSON.stringify(category.imageUrl).slice(1, -1)})`, backgroundPosition: `${category.focalX * 100}% ${category.focalY * 100}%` } : undefined}>{category.imageUrl ? null : <Boxes size={21} />}</span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2"><h2 className="truncate text-sm font-black">{category.name}</h2><GripVertical size={16} className="text-[var(--muted)]" /></div>
                  <p className="mt-1 font-mono text-[9px] text-[var(--muted)]" dir="ltr">/{category.slug}</p>
                  <div className="mt-3 flex flex-wrap items-center gap-2"><StatusBadge tone={category.health === "READY" ? "success" : category.health === "ARCHIVED" ? "neutral" : "warning"}>{category.health}</StatusBadge><StatusBadge tone={category.mediaHealth === "READY" ? "success" : "warning"}>{category.mediaHealth}</StatusBadge><StatusBadge tone={category.accessTier === "premium" ? "warning" : "info"}>{category.accessTier.toUpperCase()}</StatusBadge>{category.featured ? <StatusBadge tone="success">مميز</StatusBadge> : null}{category.isNew ? <StatusBadge tone="info">جديد</StatusBadge> : null}<span className="text-[10px] text-[var(--muted)]">{formatNumber(category.questionCount)} سؤال</span><span className="text-[10px] text-[var(--muted)]">س {formatNumber(category.easyCount)} • م {formatNumber(category.mediumCount)} • ص {formatNumber(category.hardCount)}</span><span className="text-[10px] text-[var(--muted)]">الترتيب {formatNumber(category.sortOrder)}</span></div>
                  {category.description ? <p className="mt-2 line-clamp-2 text-[10px] leading-5 text-[var(--muted)]">{category.description}</p> : null}
                  <p className="mt-2 text-[9px] text-[var(--muted)]">آخر تحديث {formatDate(category.updatedAt)}</p>
                  <CategoryContentEditor id={category.id} name={category.name} slug={category.slug} parentId={category.parentId} iconKey={category.icon} description={category.description} imageUrl={category.imageUrl} coverMediaId={category.coverMediaId} focalX={category.focalX} focalY={category.focalY} active={category.active} sortOrder={category.sortOrder} parents={parentChoices} disabled={mutationDisabled} groupKey={category.groupKey} seasonLabel={category.seasonLabel} questionFormats={category.questionFormats} favoriteEligible={category.favoriteEligible} accessTier={category.accessTier} featured={category.featured} isNew={category.isNew} editorialStatus={category.editorialStatus} freeRotation={category.freeRotation} />
                </div>
              </div>
              <div className="border-t border-[var(--border)] bg-[var(--surface-3)] p-3">
                {children.length ? children.map((child) => (
                  <div key={child.id} className="rounded-lg border-b border-[var(--border)] px-2 py-2 last:border-0">
                    <div className="flex items-center gap-2 text-[11px]"><span className="size-8 shrink-0 bg-[var(--surface)] bg-cover" style={child.imageUrl ? { backgroundImage: `url(${JSON.stringify(child.imageUrl).slice(1, -1)})`, backgroundPosition: `${child.focalX * 100}% ${child.focalY * 100}%` } : undefined} /><ChevronLeft size={13} className="text-[var(--muted)]" /><span className="flex-1 font-bold">{child.name}</span><StatusBadge tone={child.mediaHealth === "READY" ? "success" : "warning"}>{child.mediaHealth}</StatusBadge><StatusBadge tone={child.active ? "success" : "neutral"}>{child.active ? "مفعّل" : "متوقف"}</StatusBadge><span className="text-[9px] text-[var(--muted)]">{formatNumber(child.questionCount)}</span></div>
                    <CategoryContentEditor compact id={child.id} name={child.name} slug={child.slug} parentId={child.parentId} iconKey={child.icon} description={child.description} imageUrl={child.imageUrl} coverMediaId={child.coverMediaId} focalX={child.focalX} focalY={child.focalY} active={child.active} sortOrder={child.sortOrder} parents={parentChoices} disabled={mutationDisabled} groupKey={child.groupKey} seasonLabel={child.seasonLabel} questionFormats={child.questionFormats} favoriteEligible={child.favoriteEligible} accessTier={child.accessTier} featured={child.featured} isNew={child.isNew} editorialStatus={child.editorialStatus} freeRotation={child.freeRotation} />
                  </div>
                )) : <p className="flex items-center gap-2 px-2 py-2 text-[10px] text-[var(--muted)]"><Layers3 size={13} /> لا توجد أقسام فرعية</p>}
              </div>
            </article>
          );
        })}
      </section>
      ) : null}
      <div className="surface-card flex items-start gap-3 p-4 text-xs text-[var(--muted)]"><FolderTree size={18} className="shrink-0 text-[var(--primary-strong)]" /><p className="leading-6">يُخزَّن التسلسل بعلاقة ذاتية عبر <span className="font-mono text-[var(--foreground)]">parent_id</span>. الحذف النهائي محمي بصلاحية Admin، ويُرفض تلقائيًا عند وجود أسئلة مرتبطة؛ استخدم التعطيل حينها.</p></div>
    </div>
  );
}
