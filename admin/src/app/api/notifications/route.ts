import { authorizeAdminApi } from "@/lib/auth/context";
import { notificationCampaignSchema } from "@/lib/notifications/schema";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { rejectCrossOriginMutation } from "@/lib/security/request";

export async function POST(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("admin");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const body = notificationCampaignSchema.parse(await request.json());
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });

    const existing = await supabase
      .from("notifications")
      .select("id,status")
      .contains("data", { request_id: body.requestId })
      .maybeSingle();
    if (existing.error) {
      return Response.json({ error: safeDatabaseError(existing.error.code) }, { status: 400 });
    }
    if (existing.data) {
      return Response.json({ success: true, id: existing.data.id, duplicate: true, dispatchRequested: false });
    }

    const { data, error } = await supabase.from("notifications").insert({
      target_user_id: null,
      type: body.type,
      title_ar: body.title,
      body_ar: body.body,
      audience: { segment: body.audience },
      status: "queued",
      scheduled_at: body.scheduledAt ?? null,
      created_by: authorization.context.id,
      data: { source: "admin_campaign", deep_link: body.deepLink, request_id: body.requestId },
    }).select("id").single();
    if (error) return Response.json({ error: safeDatabaseError(error.code) }, { status: 400 });
    let dispatchRequested = false;
    if (!body.scheduledAt || Date.parse(body.scheduledAt) <= Date.now()) {
      const { error: dispatchError } = await supabase.functions.invoke("dispatch-notifications", {
        body: { notificationId: data.id },
      });
      dispatchRequested = !dispatchError;
    }
    return Response.json({
      success: true,
      id: data.id,
      dispatchRequested,
    });
  } catch {
    return Response.json({ error: "تحقق من العنوان والنص والوجهة والموعد." }, { status: 400 });
  }
}

function safeDatabaseError(code?: string) {
  if (code === "42501") return "لا تملك صلاحية إنشاء حملة إشعارات.";
  return code ? `تعذر حفظ الحملة (رمز ${code}).` : "تعذر حفظ الحملة.";
}
