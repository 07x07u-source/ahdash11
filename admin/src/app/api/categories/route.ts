import { authorizeAdminApi } from "@/lib/auth/context";
import { categoryCreateSchema } from "@/lib/content/schema";
import { rejectCrossOriginMutation } from "@/lib/security/request";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  const parsed = categoryCreateSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return Response.json({ error: "بيانات القسم غير صالحة." }, { status: 400 });

  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });

  if (parsed.data.parentId) {
    const parent = await supabase
      .from("categories")
      .select("id")
      .eq("id", parsed.data.parentId)
      .is("parent_id", null)
      .maybeSingle();
    if (parent.error || !parent.data) {
      return Response.json({ error: "القسم الرئيسي المحدد غير متاح." }, { status: 400 });
    }
  }

  let orderQuery = supabase
    .from("categories")
    .select("sort_order")
    .order("sort_order", { ascending: false })
    .limit(1);
  orderQuery = parsed.data.parentId
    ? orderQuery.eq("parent_id", parsed.data.parentId)
    : orderQuery.is("parent_id", null);
  const order = await orderQuery.maybeSingle();
  if (order.error) return Response.json({ error: databaseErrorMessage(order.error.code) }, { status: 400 });

  const result = await supabase
    .from("categories")
    .insert({
      name_ar: parsed.data.nameAr,
      slug: parsed.data.slug,
      parent_id: parsed.data.parentId,
      icon_key: parsed.data.iconKey,
      description_ar: parsed.data.descriptionAr,
      is_active: parsed.data.isActive,
      sort_order: Number(order.data?.sort_order ?? -1) + 1,
      group_key: parsed.data.groupKey,
      season_label: parsed.data.seasonLabel,
      question_formats: parsed.data.questionFormats,
      is_favorite_eligible: parsed.data.favoriteEligible,
      access_tier: parsed.data.accessTier,
      is_featured: parsed.data.featured,
      is_new: parsed.data.isNew,
      editorial_status: parsed.data.editorialStatus,
      is_free_rotation: parsed.data.freeRotation,
    })
    .select("id")
    .single();

  if (result.error) return Response.json({ error: databaseErrorMessage(result.error.code) }, { status: 400 });
  return Response.json({ success: true, id: result.data.id }, { status: 201 });
}

function databaseErrorMessage(code?: string) {
  if (code === "23505") return "المعرّف النصي مستخدم في قسم آخر.";
  if (code === "42501") return "لا تملك صلاحية تعديل الأقسام.";
  if (code === "42703") return "طبّق migration Party V2 الجديدة أولًا ثم أعد المحاولة.";
  return code ? `تعذر حفظ القسم (رمز ${code}).` : "تعذر حفظ القسم.";
}
