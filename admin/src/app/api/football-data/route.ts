import { authorizeAdminApi } from "@/lib/auth/context";
import { footballDataCreateSchema, footballDataDeleteSchema, footballDataUpdateSchema } from "@/lib/social-football/schema";
import { rejectCrossOriginMutation } from "@/lib/security/request";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const tableByEntity = {
  country: "football_countries",
  league: "football_leagues",
  club: "football_clubs",
} as const;

export async function POST(request: Request) {
  const guard = await mutationGuard(request);
  if (guard.response) return guard.response;
  const parsed = footballDataCreateSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return Response.json({ error: parsed.error.issues[0]?.message ?? "بيانات Football Data غير صالحة." }, { status: 400 });
  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });
  const payload = createPayload(parsed.data);
  const result = await supabase
    .from(tableByEntity[parsed.data.entity])
    .insert(payload as never)
    .select("id")
    .single();
  if (result.error) return databaseError(result.error.code);
  return Response.json({ success: true, id: result.data.id }, { status: 201 });
}

export async function PATCH(request: Request) {
  const guard = await mutationGuard(request);
  if (guard.response) return guard.response;
  const parsed = footballDataUpdateSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return Response.json({ error: parsed.error.issues[0]?.message ?? "بيانات التحديث غير صالحة." }, { status: 400 });
  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });
  const payload = updatePayload(parsed.data);
  if (!Object.keys(payload).length) return Response.json({ error: "لا توجد حقول للتحديث." }, { status: 400 });
  const result = await supabase.from(tableByEntity[parsed.data.entity]).update(payload).eq("id", parsed.data.id).select("id").maybeSingle();
  if (result.error) return databaseError(result.error.code);
  if (!result.data) return Response.json({ error: "السجل غير موجود أو لا تملك الصلاحية." }, { status: 404 });
  return Response.json({ success: true });
}

export async function DELETE(request: Request) {
  const guard = await mutationGuard(request);
  if (guard.response) return guard.response;
  const parsed = footballDataDeleteSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return Response.json({ error: "هدف الحذف غير صالح." }, { status: 400 });
  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });
  const result = await supabase.from(tableByEntity[parsed.data.entity]).delete().eq("id", parsed.data.id).select("id").maybeSingle();
  if (result.error) return databaseError(result.error.code);
  if (!result.data) return Response.json({ error: "السجل غير موجود أو لا تملك الصلاحية." }, { status: 404 });
  return Response.json({ success: true });
}

async function mutationGuard(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return { response: crossOrigin };
  const authorization = await authorizeAdminApi("admin");
  return { response: authorization.response };
}

function createPayload(value: ReturnType<typeof footballDataCreateSchema.parse>) {
  if (value.entity === "country") {
    return { code: value.code, name_ar: value.nameAr, name_en: value.nameEn, is_featured: value.featured };
  }
  return {
    ...(value.entity === "league" ? { country_id: value.countryId } : { league_id: value.leagueId }),
    name_ar: value.nameAr,
    name_en: value.nameEn,
    short_name: value.shortName || null,
    visual_status: value.visualStatus,
    logo_url: value.visualStatus === "fallback" ? null : value.logoUrl,
    license_reference: value.visualStatus === "licensed" ? value.licenseReference : null,
    primary_color: value.primaryColor || null,
    secondary_color: value.secondaryColor || null,
  };
}

function updatePayload(value: ReturnType<typeof footballDataUpdateSchema.parse>) {
  const payload: Record<string, unknown> = {};
  if (value.nameAr !== undefined) payload.name_ar = value.nameAr;
  if (value.nameEn !== undefined) payload.name_en = value.nameEn;
  if (value.shortName !== undefined) payload.short_name = value.shortName || null;
  if (value.active !== undefined) payload.is_active = value.active;
  if (value.featured !== undefined) payload.is_featured = value.featured;
  if (value.visualStatus !== undefined) payload.visual_status = value.visualStatus;
  if (value.logoUrl !== undefined) payload.logo_url = value.visualStatus === "fallback" ? null : value.logoUrl;
  if (value.licenseReference !== undefined) payload.license_reference = value.visualStatus === "licensed" ? value.licenseReference : null;
  if (value.primaryColor !== undefined) payload.primary_color = value.primaryColor;
  if (value.secondaryColor !== undefined) payload.secondary_color = value.secondaryColor;
  return payload;
}

function databaseError(code?: string) {
  const message = code === "23503"
    ? "لا يمكن حذف السجل لأنه مرتبط ببيانات أخرى. عطّله بدلًا من ذلك."
    : code === "23505"
    ? "يوجد سجل مطابق من المزود أو الرمز نفسه."
    : code === "23514"
    ? "حالة الحقوق لا تطابق رابط الأصل أو مرجع الترخيص."
    : code === "42501"
    ? "تحتاج صلاحية Admin لإدارة Football Data."
    : `تعذر حفظ Football Data (${code ?? "unknown"}).`;
  return Response.json({ error: message }, { status: 400 });
}
