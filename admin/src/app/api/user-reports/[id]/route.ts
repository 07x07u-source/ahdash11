import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { rejectCrossOriginMutation } from "@/lib/security/request";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const schema = z.object({ status: z.enum(["new", "in_review", "resolved", "rejected"]), note: z.string().trim().max(2000).nullable(), linkedIssueId: z.string().uuid().nullable() });
export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  const originError = rejectCrossOriginMutation(request); if (originError) return originError;
  const authorization = await authorizeAdminApi("moderator"); if (authorization.response) return authorization.response;
  try { const { id } = await context.params; const reportId = z.string().uuid().parse(id); const body = schema.parse(await request.json()); const supabase = await createServerSupabaseClient(); if (!supabase) return Response.json({ error: "Supabase غير متصل." }, { status: 503 }); const { error } = await supabase.rpc("review_user_problem_report", { p_report_id: reportId, p_status: body.status, p_admin_note: body.note, p_linked_issue_id: body.linkedIssueId }); if (error) throw new Error(error.message); return Response.json({ success: true }); }
  catch (error) { if (error instanceof z.ZodError) return Response.json({ error: "بيانات الطلب غير صالحة." }, { status: 400 }); return Response.json({ error: error instanceof Error ? error.message : "تعذر تحديث البلاغ." }, { status: 400 }); }
}
