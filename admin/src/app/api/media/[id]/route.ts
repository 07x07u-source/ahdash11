import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { buildMediaStoragePath, mediaGroups, MediaValidationError, validateImageUpload, verifyImageDecodes } from "@/lib/media/validation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { rejectCrossOriginMutation } from "@/lib/security/request";

const idSchema = z.string().uuid();
const metadataSchema = z.object({ group: z.enum(mediaGroups), altText: z.string().trim().max(160) });
const stateSchema = z.object({ status: z.enum(["active", "archived"]) });

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const id = idSchema.parse((await context.params).id);
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ error: "الحذف غير متاح في وضع البيانات التجريبية." }, { status: 503 });

    const { data: asset, error: assetError } = await supabase.from("media_assets").select("storage_path").eq("id", id).single();
    if (assetError || !asset) return Response.json({ error: "الصورة غير موجودة." }, { status: 404 });

    const { data: usages, error: usageError } = await supabase.from("media_asset_usage").select("usage_label, usage_state").eq("media_id", id).limit(10);
    if (usageError) throw new Error(usageError.message);
    if (usages?.length) {
      return Response.json({ error: "لا يمكن حذف صورة مستخدمة. استبدلها من أماكن الاستخدام أولًا.", usage: usages }, { status: 409 });
    }

    const { error: deleteError } = await supabase.from("media_assets").delete().eq("id", id);
    if (deleteError) throw new Error(deleteError.message);
    const { error: storageError } = await supabase.storage.from("app-content").remove([String(asset.storage_path)]);

    return Response.json({ success: true, cleanupWarning: storageError?.message ?? null });
  } catch (error) {
    if (error instanceof z.ZodError) return Response.json({ error: "معرّف الصورة غير صالح." }, { status: 400 });
    return Response.json({ error: error instanceof Error ? error.message : "تعذر حذف الصورة." }, { status: 400 });
  }
}

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  let uploadedPath: string | null = null;
  try {
    const id = idSchema.parse((await context.params).id);
    if (request.headers.get("content-type")?.includes("application/json")) {
      const state = stateSchema.parse(await request.json());
      const supabase = await createServerSupabaseClient();
      if (!supabase) return Response.json({ error: "التعديل غير متاح في وضع البيانات التجريبية." }, { status: 503 });
      const { error } = await supabase.from("media_assets").update({
        status: state.status,
        updated_by: authorization.context.id,
      }).eq("id", id);
      if (error) throw new Error(error.message);
      return Response.json({ success: true, status: state.status });
    }
    const form = await request.formData();
    const file = form.get("file");
    if (!(file instanceof File)) return Response.json({ error: "اختر صورة الاستبدال." }, { status: 400 });
    const metadata = metadataSchema.parse({ group: form.get("group"), altText: form.get("altText") ?? "" });
    if (file.name.length > 180) return Response.json({ error: "اسم الملف طويل جدًا." }, { status: 400 });

    const bytes = new Uint8Array(await file.arrayBuffer());
    const image = validateImageUpload({ bytes, filename: file.name, declaredMimeType: file.type });
    await verifyImageDecodes(bytes, image);
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ error: "الاستبدال غير متاح في وضع البيانات التجريبية." }, { status: 503 });

    const { data: previous, error: previousError } = await supabase.from("media_assets").select("storage_path").eq("id", id).single();
    if (previousError || !previous) return Response.json({ error: "الصورة غير موجودة." }, { status: 404 });

    uploadedPath = buildMediaStoragePath(metadata.group, image.extension, crypto.randomUUID());
    const { error: uploadError } = await supabase.storage.from("app-content").upload(uploadedPath, bytes, {
      cacheControl: "31536000",
      contentType: image.mimeType,
      upsert: false,
    });
    if (uploadError) throw new Error(uploadError.message);

    const { data: publicData } = supabase.storage.from("app-content").getPublicUrl(uploadedPath);
    const versionedUrl = `${publicData.publicUrl}?v=${encodeURIComponent(new Date().toISOString())}`;
    const { error: replaceError } = await supabase.rpc("replace_media_asset", {
      p_media_id: id,
      p_storage_path: uploadedPath,
      p_original_filename: file.name,
      p_mime_type: image.mimeType,
      p_size_bytes: image.sizeBytes,
      p_width: image.width,
      p_height: image.height,
      p_alt_text: metadata.altText,
      p_asset_group: metadata.group,
      p_public_url: versionedUrl,
    });
    if (replaceError) {
      await supabase.storage.from("app-content").remove([uploadedPath]);
      uploadedPath = null;
      throw new Error(replaceError.message);
    }

    const { error: cleanupError } = await supabase.storage.from("app-content").remove([String(previous.storage_path)]);
    return Response.json({ success: true, url: versionedUrl, cleanupWarning: cleanupError?.message ?? null });
  } catch (error) {
    if (error instanceof z.ZodError || error instanceof MediaValidationError) {
      return Response.json({ error: error instanceof Error ? error.message : "بيانات الصورة غير صالحة." }, { status: 400 });
    }
    return Response.json({ error: error instanceof Error ? error.message : "تعذر استبدال الصورة.", uploadedPath }, { status: 400 });
  }
}
