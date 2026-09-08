import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { rejectCrossOriginMutation } from "@/lib/security/request";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const schema = z.object({
  id: z.enum(["two_chances", "call_friend", "risk", "bench", "pass"]),
  nameAr: z.string().trim().min(1).max(40),
  descriptionAr: z.string().trim().min(1).max(180),
  iconKey: z.string().trim().min(1).max(40).regex(/^[a-z0-9_]+$/),
  timing: z.enum(["before_question", "after_question"]),
  active: z.boolean(),
  config: z.record(z.string(), z.unknown()),
});

export async function PATCH(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("admin");
  if (authorization.response || !authorization.context) return authorization.response;
  try {
    const input = schema.parse(await request.json());
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ success: true, developmentFallback: true });
    const { error } = await supabase.from("party_help_tools").update({
      name_ar: input.nameAr,
      description_ar: input.descriptionAr,
      icon_key: input.iconKey,
      timing: input.timing,
      rule_config: input.config,
      is_active: input.active,
      updated_at: new Date().toISOString(),
    }).eq("id", input.id);
    if (error) throw new Error(error.message);
    return Response.json({ success: true, developmentFallback: false });
  } catch (error) {
    if (error instanceof z.ZodError) return Response.json({ error: "بيانات المساعدة غير صالحة." }, { status: 400 });
    return Response.json({ error: error instanceof Error ? error.message : "تعذر حفظ المساعدة." }, { status: 400 });
  }
}
