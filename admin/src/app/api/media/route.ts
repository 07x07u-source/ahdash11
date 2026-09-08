import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import {
  buildMediaStoragePath,
  mediaGroups,
  MediaValidationError,
  validateImageUpload,
  verifyImageDecodes,
} from "@/lib/media/validation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { rejectCrossOriginMutation } from "@/lib/security/request";

const metadataSchema = z.object({
  group: z.enum(mediaGroups),
  altText: z.string().trim().max(160),
  slotKey: z.string().trim().regex(/^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*){1,4}$/).optional().or(z.literal("")),
  rightsStatus: z.enum(["original", "generated", "licensed"]),
  sourceText: z.string().trim().max(500).optional().or(z.literal("")),
  attribution: z.string().trim().max(500).optional().or(z.literal("")),
});

export async function GET(request: Request) {
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ assets: [], developmentFallback: true });

  const url = new URL(request.url);
  const search = url.searchParams.get("q")?.trim().slice(0, 80) ?? "";
  const group = url.searchParams.get("group");
  let query = supabase.from("media_assets").select("*").order("updated_at", { ascending: false }).limit(200);
  if (search) query = query.ilike("original_filename", `%${search.replace(/[\\%_]/g, "")}%`);
  if (group && mediaGroups.includes(group as (typeof mediaGroups)[number])) query = query.eq("asset_group", group);

  const [assetsResult, usageResult] = await Promise.all([
    query,
    supabase.from("media_asset_usage").select("media_id, usage_type, usage_id, usage_label, usage_state"),
  ]);
  if (assetsResult.error) return Response.json({ error: assetsResult.error.message }, { status: 500 });
  if (usageResult.error) return Response.json({ error: usageResult.error.message }, { status: 500 });

  const usage = usageResult.data ?? [];
  const assets = (assetsResult.data ?? []).map((asset) => {
    const { data } = supabase.storage.from("app-content").getPublicUrl(String(asset.storage_path));
    return {
      id: String(asset.id),
      originalFilename: String(asset.original_filename),
      storagePath: String(asset.storage_path),
      mimeType: String(asset.mime_type),
      sizeBytes: Number(asset.size_bytes),
      width: Number(asset.width),
      height: Number(asset.height),
      altText: String(asset.alt_text ?? ""),
      assetGroup: String(asset.asset_group),
      slotKey: asset.slot_key ? String(asset.slot_key) : null,
      rightsStatus: String(asset.rights_status ?? "original"),
      sourceText: asset.source_text ? String(asset.source_text) : null,
      attribution: asset.attribution ? String(asset.attribution) : null,
      status: String(asset.status),
      version: Number(asset.version ?? 1),
      createdAt: String(asset.created_at),
      createdBy: asset.created_by ? String(asset.created_by) : null,
      updatedAt: String(asset.updated_at),
      url: `${data.publicUrl}?v=${encodeURIComponent(String(asset.updated_at))}`,
      usage: usage.filter((entry) => entry.media_id === asset.id).map((entry) => ({
        type: String(entry.usage_type),
        id: String(entry.usage_id),
        label: String(entry.usage_label),
        state: String(entry.usage_state),
      })),
    };
  });
  return Response.json({ assets, developmentFallback: false });
}

export async function POST(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const form = await request.formData();
    const file = form.get("file");
    if (!(file instanceof File)) return Response.json({ error: "اختر ملف صورة صالحًا." }, { status: 400 });
    const metadata = metadataSchema.parse({
      group: form.get("group"), altText: form.get("altText") ?? "",
      slotKey: form.get("slotKey") ?? "", rightsStatus: form.get("rightsStatus") ?? "original",
      sourceText: form.get("sourceText") ?? "", attribution: form.get("attribution") ?? "",
    });
    if (file.name.length > 180) return Response.json({ error: "اسم الملف طويل جدًا." }, { status: 400 });

    const bytes = new Uint8Array(await file.arrayBuffer());
    const image = validateImageUpload({ bytes, filename: file.name, declaredMimeType: file.type });
    await verifyImageDecodes(bytes, image);
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ error: "رفع الصور غير متاح في وضع البيانات التجريبية." }, { status: 503 });

    const id = crypto.randomUUID();
    const storagePath = buildMediaStoragePath(metadata.group, image.extension, id);
    const { error: uploadError } = await supabase.storage.from("app-content").upload(storagePath, bytes, {
      cacheControl: "31536000",
      contentType: image.mimeType,
      upsert: false,
    });
    if (uploadError) throw new Error(uploadError.message);

    const { data: asset, error: insertError } = await supabase.from("media_assets").insert({
      id,
      storage_path: storagePath,
      original_filename: file.name,
      mime_type: image.mimeType,
      size_bytes: image.sizeBytes,
      width: image.width,
      height: image.height,
      alt_text: metadata.altText,
      asset_group: metadata.group,
      slot_key: metadata.slotKey || null,
      rights_status: metadata.rightsStatus,
      source_text: metadata.sourceText || null,
      attribution: metadata.attribution || null,
      created_by: authorization.context.id,
      updated_by: authorization.context.id,
    }).select("*").single();
    if (insertError) {
      await supabase.storage.from("app-content").remove([storagePath]);
      throw new Error(insertError.message);
    }

    const { data: publicData } = supabase.storage.from("app-content").getPublicUrl(storagePath);
    return Response.json({
      success: true,
      asset: { ...asset, url: `${publicData.publicUrl}?v=${encodeURIComponent(String(asset.updated_at))}`, usage: [] },
    }, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError || error instanceof MediaValidationError) {
      return Response.json({ error: error instanceof Error ? error.message : "بيانات الصورة غير صالحة." }, { status: 400 });
    }
    return Response.json({ error: error instanceof Error ? error.message : "تعذر رفع الصورة." }, { status: 400 });
  }
}
