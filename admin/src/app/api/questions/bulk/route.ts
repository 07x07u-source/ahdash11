import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { hasMinimumRole } from "@/lib/auth/roles";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { rejectCrossOriginMutation } from "@/lib/security/request";

const schema = z.object({
  ids: z.array(z.string().min(1)).min(1).max(500),
  action: z.enum(["publish", "unpublish", "archive", "review"]),
});

export async function PATCH(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const body = schema.parse(await request.json());
    if ((body.action === "publish" || body.action === "archive") && !hasMinimumRole(authorization.context.role, "admin")) {
      return Response.json({ error: "هذا الإجراء يتطلب دور مدير أو أعلى." }, { status: 403 });
    }

    const supabase = await createServerSupabaseClient();
    if (!supabase || body.ids.every((id) => id.startsWith("q-"))) {
      return Response.json({ success: true, developmentFallback: true, affected: body.ids.length });
    }

    const nextStatus = {
      publish: "published",
      unpublish: "draft",
      archive: "archived",
      review: "review",
    }[body.action];

    const { data, error } = await supabase
      .from("questions")
      .update({
        status: nextStatus,
        needs_review: body.action === "review",
        published_at: body.action === "publish" ? new Date().toISOString() : undefined,
      })
      .in("id", body.ids)
      .select("id");
    if (error) throw new Error(error.message);

    return Response.json({ success: true, developmentFallback: false, affected: data?.length ?? 0 });
  } catch (error) {
    if (error instanceof z.ZodError) return Response.json({ error: "الطلب غير صالح." }, { status: 400 });
    return Response.json({ error: error instanceof Error ? error.message : "تعذر تحديث الأسئلة." }, { status: 400 });
  }
}
