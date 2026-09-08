import { authorizeAdminApi } from "@/lib/auth/context";
import { socialReportReviewSchema, socialTeamModerationSchema } from "@/lib/social-football/schema";
import { rejectCrossOriginMutation } from "@/lib/security/request";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export async function PATCH(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;
  const body = await request.json().catch(() => null) as Record<string, unknown> | null;
  if (body && "reportId" in body) {
    const parsedReport = socialReportReviewSchema.safeParse(body);
    if (!parsedReport.success) return Response.json({ error: parsedReport.error.issues[0]?.message ?? "مراجعة البلاغ غير صالحة." }, { status: 400 });
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });
    const reportResult = await supabase.rpc("review_social_report", {
      p_report_id: parsedReport.data.reportId,
      p_status: parsedReport.data.status,
      p_admin_note: parsedReport.data.note,
    });
    if (reportResult.error) return Response.json({ error: `تعذر تحديث البلاغ (${reportResult.error.code ?? "unknown"}).` }, { status: 400 });
    return Response.json({ success: true });
  }
  const parsed = socialTeamModerationSchema.safeParse(body);
  if (!parsed.success) return Response.json({ error: parsed.error.issues[0]?.message ?? "إجراء الإشراف غير صالح." }, { status: 400 });
  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ error: "اتصال Supabase غير مهيأ." }, { status: 503 });
  const result = await supabase.rpc("moderate_social_team", {
    p_team_id: parsed.data.teamId,
    p_status: parsed.data.status,
    p_reason: parsed.data.reason,
  });
  if (result.error) return Response.json({ error: `تعذر تنفيذ الإجراء (${result.error.code ?? "unknown"}).` }, { status: 400 });
  return Response.json({ success: true });
}
