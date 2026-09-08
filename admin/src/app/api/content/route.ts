import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { hasMinimumRole } from "@/lib/auth/roles";
import {
  contentMutationSchema,
  localContentDefinitions,
  validateDraftForDefinition,
  type LocalContentDefinition,
} from "@/lib/content/schema";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { rejectCrossOriginMutation } from "@/lib/security/request";

function fallbackItems() {
  return localContentDefinitions.map((item) => ({
    key: item.key,
    section: item.section,
    contentType: item.contentType,
    labelAr: item.labelAr,
    usageAr: item.usageAr,
    defaultTextAr: item.defaultTextAr,
    draftTextAr: item.defaultTextAr,
    publishedTextAr: item.defaultTextAr,
    draftMediaId: null,
    publishedMediaId: null,
    minLength: item.minLength,
    maxLength: item.maxLength,
    version: 0,
    draftUpdatedAt: null,
    publishedAt: null,
  }));
}

export async function GET() {
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  const supabase = await createServerSupabaseClient();
  if (!supabase) {
    return Response.json({ items: fallbackItems(), media: [], canPublish: true, developmentFallback: true });
  }

  const [contentResult, mediaResult] = await Promise.all([
    supabase.from("app_content").select("*").order("section").order("key"),
    supabase.from("media_assets").select("id, storage_path, alt_text, updated_at, asset_group, width, height, size_bytes, mime_type, rights_status, source_text, attribution").eq("status", "active").order("updated_at", { ascending: false }),
  ]);
  if (contentResult.error) return Response.json({ error: contentResult.error.message }, { status: 500 });
  if (mediaResult.error) return Response.json({ error: mediaResult.error.message }, { status: 500 });

  const media = (mediaResult.data ?? []).map((asset) => {
    const { data } = supabase.storage.from("app-content").getPublicUrl(String(asset.storage_path));
    return {
      id: String(asset.id),
      storagePath: String(asset.storage_path),
      altText: String(asset.alt_text ?? ""),
      assetGroup: String(asset.asset_group),
      width: Number(asset.width),
      height: Number(asset.height),
      sizeBytes: Number(asset.size_bytes),
      mimeType: String(asset.mime_type),
      rightsStatus: String(asset.rights_status ?? "original"),
      sourceText: asset.source_text ? String(asset.source_text) : null,
      attribution: asset.attribution ? String(asset.attribution) : null,
      url: `${data.publicUrl}?v=${encodeURIComponent(String(asset.updated_at))}`,
    };
  });

  return Response.json({
    items: (contentResult.data ?? []).map((item) => ({
      key: String(item.key),
      section: String(item.section),
      contentType: String(item.content_type),
      labelAr: String(item.label_ar),
      usageAr: String(item.usage_ar),
      defaultTextAr: item.default_text_ar === null ? null : String(item.default_text_ar),
      draftTextAr: item.draft_text_ar === null ? null : String(item.draft_text_ar),
      publishedTextAr: item.published_text_ar === null ? null : String(item.published_text_ar),
      draftMediaId: item.draft_media_id === null ? null : String(item.draft_media_id),
      publishedMediaId: item.published_media_id === null ? null : String(item.published_media_id),
      minLength: Number(item.min_length),
      maxLength: Number(item.max_length),
      version: Number(item.version),
      draftUpdatedAt: item.draft_updated_at === null ? null : String(item.draft_updated_at),
      publishedAt: item.published_at === null ? null : String(item.published_at),
    })),
    media,
    canPublish: hasMinimumRole(authorization.context.role, "admin"),
    developmentFallback: false,
  });
}

export async function PATCH(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const mutation = contentMutationSchema.parse(await request.json());
    if (mutation.action === "publish" && !hasMinimumRole(authorization.context.role, "admin")) {
      return Response.json({ error: "النشر يتطلب دور مدير أو أعلى." }, { status: 403 });
    }

    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ success: true, developmentFallback: true });

    if (mutation.action === "save") {
      const { data: row, error: definitionError } = await supabase
        .from("app_content")
        .select("key, section, content_type, label_ar, usage_ar, default_text_ar, min_length, max_length")
        .eq("key", mutation.key)
        .single();
      if (definitionError || !row) return Response.json({ error: "مفتاح المحتوى غير موجود." }, { status: 404 });

      const definition: LocalContentDefinition = {
        key: String(row.key),
        section: String(row.section),
        contentType: String(row.content_type) as LocalContentDefinition["contentType"],
        labelAr: String(row.label_ar),
        usageAr: String(row.usage_ar),
        defaultTextAr: row.default_text_ar === null ? null : String(row.default_text_ar),
        minLength: Number(row.min_length),
        maxLength: Number(row.max_length),
      };
      const validated = validateDraftForDefinition(definition, mutation.valueAr, mutation.mediaId);
      if (mutation.key === "branding.appicon.master" && validated.mediaId) {
        const { data: iconAsset, error: iconError } = await supabase
          .from("media_assets")
          .select("asset_group, width, height")
          .eq("id", validated.mediaId)
          .single();
        if (iconError || !iconAsset) return Response.json({ error: "ملف الأيقونة غير موجود." }, { status: 404 });
        if (iconAsset.asset_group !== "app-icons" || Number(iconAsset.width) !== Number(iconAsset.height) || Number(iconAsset.width) < 1024) {
          return Response.json({ error: "أيقونة التطبيق يجب أن تكون مربعة، 1024×1024 على الأقل، ومن مجموعة App Icons." }, { status: 400 });
        }
      }
      const { error } = await supabase.rpc("save_app_content_draft", {
        p_key: mutation.key,
        p_value_ar: validated.valueAr,
        p_media_id: validated.mediaId,
      });
      if (error) throw new Error(error.message);
    } else if (mutation.action === "reset") {
      const { error } = await supabase.rpc("reset_app_content_draft", { p_key: mutation.key });
      if (error) throw new Error(error.message);
    } else {
      const { error } = await supabase.rpc("publish_app_content", { p_key: mutation.key });
      if (error) throw new Error(error.message);
    }

    return Response.json({ success: true, developmentFallback: false });
  } catch (error) {
    if (error instanceof z.ZodError) return Response.json({ error: "بيانات المحتوى غير صالحة." }, { status: 400 });
    return Response.json({ error: error instanceof Error ? error.message : "تعذر حفظ المحتوى." }, { status: 400 });
  }
}
