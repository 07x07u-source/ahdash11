import { PageHeader } from "@/components/ui/page-header";
import { StatusBadge } from "@/components/ui/status-badge";
import { requireAdminPage } from "@/lib/auth/context";
import { getAuditRows } from "@/lib/data/monitoring-data";
import { formatDate } from "@/lib/utils";

export const metadata = { title: "سجل التدقيق" };
export const dynamic = "force-dynamic";
export default async function AuditPage() { await requireAdminPage("admin"); const data = await getAuditRows(); return <div className="space-y-6"><PageHeader eyebrow="الأمان والمساءلة" title="سجل التدقيق" description="من نفّذ الإجراء، وماذا غيّر، وعلى أي كيان، ومتى؛ دون فتح JSON تقني أو بيانات حساسة افتراضيًا." />{!data.available ? <div className="surface-card p-8 text-center text-sm text-[var(--muted)]">سجل التدقيق غير متاح أو لا توجد صلاحية لقراءته.</div> : <div className="surface-card overflow-x-auto"><table className="data-table"><thead><tr><th>الإجراء</th><th>الكيان</th><th>المعرّف</th><th>المنفّذ</th><th>التاريخ</th></tr></thead><tbody>{data.rows.map((row) => <tr key={row.id}><td><StatusBadge tone="info">{actionLabel(row.action)}</StatusBadge></td><td>{entityLabel(row.entityType)}</td><td className="font-mono text-xs" dir="ltr">{row.entityId?.slice(0, 24) ?? "—"}</td><td><span className="block text-xs font-bold">{row.actorName ?? (row.actorId ? "مستخدم إداري" : "النظام")}</span>{row.actorId ? <span className="font-mono text-[9px] text-[var(--muted)]" dir="ltr">{row.actorId.slice(0, 8)}</span> : null}</td><td>{formatDate(row.createdAt)}</td></tr>)}</tbody></table>{!data.rows.length ? <p className="p-10 text-center text-sm text-[var(--muted)]">لا توجد إجراءات مسجلة بعد.</p> : null}</div>}</div>; }

function actionLabel(value: string) { const labels: Record<string, string> = { "content.published": "نشر محتوى", "content.draft_saved": "حفظ مسودة", "category.content_updated": "تحديث تصنيف", "media.created": "إضافة وسائط", "media.updated": "تحديث وسائط", "media.deleted": "حذف وسائط", "import.committed": "اعتماد استيراد", "profile.role_changed": "تغيير صلاحية" }; return labels[value] ?? value.replaceAll("_", " "); }
function entityLabel(value: string) { const labels: Record<string, string> = { profile: "مستخدم", category: "تصنيف", media_asset: "وسائط", app_content: "محتوى التطبيق", import_batch: "دفعة استيراد", wallet: "محفظة" }; return labels[value] ?? value; }
