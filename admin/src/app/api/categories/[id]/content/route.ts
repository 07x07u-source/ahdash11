import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { categoryContentSchema } from "@/lib/content/schema";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { rejectCrossOriginMutation } from "@/lib/security/request";

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const id = z.string().uuid().parse((await context.params).id);
    const body = categoryContentSchema.parse(await request.json());
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });

    let imageUrl: string | null = null;
    if (body.coverMediaId) {
      const { data: media, error: mediaError } = await supabase
        .from("media_assets")
        .select("storage_path, updated_at, mime_type, rights_status, asset_group")
        .eq("id", body.coverMediaId)
        .eq("status", "active")
        .single();
      if (mediaError || !media) return Response.json({ error: "صورة الغلاف غير موجودة." }, { status: 404 });
      if (!["image/jpeg", "image/png", "image/webp"].includes(String(media.mime_type)) || !["original", "generated", "licensed"].includes(String(media.rights_status)) || !["categories", "app-content"].includes(String(media.asset_group))) {
        return Response.json({ error: "صورة الفئة غير صالحة للنشر أو حقوقها غير مكتملة." }, { status: 400 });
      }
      const { data } = supabase.storage.from("app-content").getPublicUrl(String(media.storage_path));
      imageUrl = `${data.publicUrl}?v=${encodeURIComponent(String(media.updated_at))}`;
    }

    let { error } = await supabase.rpc("update_category_media_v5", {
      p_category_id: id,
      p_description_ar: body.descriptionAr,
      p_cover_media_id: body.coverMediaId,
      p_image_url: imageUrl,
      p_focal_x: body.focalX,
      p_focal_y: body.focalY,
    });
    if (error?.code === "42883") {
      ({ error } = await supabase.rpc("update_category_content", {
        p_category_id: id,
        p_description_ar: body.descriptionAr,
        p_cover_media_id: body.coverMediaId,
        p_image_url: imageUrl,
      }));
    }
    if (error) return Response.json({ error: error.code ? `تعذر تحديث محتوى القسم (رمز ${error.code}).` : "تعذر تحديث محتوى القسم." }, { status: 400 });
    return Response.json({ success: true, imageUrl });
  } catch (error) {
    if (error instanceof z.ZodError) return Response.json({ error: "بيانات القسم غير صالحة." }, { status: 400 });
    return Response.json({ error: "تعذر تحديث القسم." }, { status: 400 });
  }
}
