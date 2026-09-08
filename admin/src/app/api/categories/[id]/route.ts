import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { categoryUpdateSchema } from "@/lib/content/schema";
import { rejectCrossOriginMutation } from "@/lib/security/request";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  const id = z.string().uuid().safeParse((await context.params).id);
  const body = categoryUpdateSchema.safeParse(await request.json().catch(() => null));
  if (!id.success || !body.success || body.data.parentId === id.data) {
    return Response.json({ error: "بيانات القسم غير صالحة." }, { status: 400 });
  }

  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });

  if (body.data.parentId) {
    const parent = await supabase
      .from("categories")
      .select("id")
      .eq("id", body.data.parentId)
      .is("parent_id", null)
      .maybeSingle();
    if (parent.error || !parent.data) {
      return Response.json({ error: "القسم الرئيسي المحدد غير متاح." }, { status: 400 });
    }
  }

  const result = await supabase
    .from("categories")
    .update({
      name_ar: body.data.nameAr,
      slug: body.data.slug,
      parent_id: body.data.parentId,
      icon_key: body.data.iconKey,
      description_ar: body.data.descriptionAr,
      is_active: body.data.isActive,
      sort_order: body.data.sortOrder,
      group_key: body.data.groupKey,
      season_label: body.data.seasonLabel,
      question_formats: body.data.questionFormats,
      is_favorite_eligible: body.data.favoriteEligible,
      access_tier: body.data.accessTier,
      is_featured: body.data.featured,
      is_new: body.data.isNew,
      editorial_status: body.data.editorialStatus,
      is_free_rotation: body.data.freeRotation,
    })
    .eq("id", id.data)
    .select("id")
    .maybeSingle();

  if (result.error) return Response.json({ error: databaseErrorMessage(result.error.code) }, { status: 400 });
  if (!result.data) return Response.json({ error: "القسم غير موجود." }, { status: 404 });
  return Response.json({ success: true });
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("admin");
  if (authorization.response || !authorization.context) return authorization.response;

  const id = z.string().uuid().safeParse((await context.params).id);
  if (!id.success) return Response.json({ error: "معرّف القسم غير صالح." }, { status: 400 });

  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });
  const result = await supabase.from("categories").delete().eq("id", id.data).select("id").maybeSingle();
  if (result.error) return Response.json({ error: databaseErrorMessage(result.error.code, true) }, { status: 400 });
  if (!result.data) return Response.json({ error: "القسم غير موجود أو لا تملك صلاحية حذفه." }, { status: 404 });
  return Response.json({ success: true });
}

function databaseErrorMessage(code?: string, deleting = false) {
  if (code === "23505") return "المعرّف النصي مستخدم في قسم آخر.";
  if (code === "23503" && deleting) return "لا يمكن حذف قسم مرتبط بأسئلة. عطّله بدلًا من ذلك.";
  if (code === "42501") return "لا تملك صلاحية تعديل الأقسام.";
  if (code === "42703") return "طبّق migration Party V2 الجديدة أولًا ثم أعد المحاولة.";
  return code ? `تعذر تنفيذ العملية (رمز ${code}).` : "تعذر تنفيذ العملية.";
}
