import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { rejectCrossOriginMutation } from "@/lib/security/request";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const schema = z.object({ status: z.enum(["open", "resolved"]), note: z.string().trim().max(2000).nullable() });

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  const originError = rejectCrossOriginMutation(request); if (originError) return originError;
  const authorization = await authorizeAdminApi("admin"); if (authorization.response) return authorization.response;
  try {
    const { id } = await context.params;
    const issueId = z.string().uuid().parse(id);
    const body = schema.parse(await request.json());
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ error: "Supabase غير متصل." }, { status: 503 });
    const { error } = await supabase.rpc("review_app_error_issue", { p_issue_id: issueId, p_status: body.status, p_internal_note: body.note });
    if (error) throw new Error(error.message);
    return Response.json({ success: true });
  } catch (error) {
    if (error instanceof z.ZodError) return Response.json({ error: "بيانات الطلب غير صالحة." }, { status: 400 });
    return Response.json({ error: error instanceof Error ? error.message : "تعذر تحديث المشكلة." }, { status: 400 });
  }
}
