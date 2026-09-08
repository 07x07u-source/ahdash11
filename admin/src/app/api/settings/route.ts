import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { rejectCrossOriginMutation } from "@/lib/security/request";

const schema = z.object({
  settings: z.array(z.object({
    key: z.string().regex(/^[a-z][a-z0-9_.-]{1,79}$/),
    value: z.number().finite().min(0).max(1_000_000),
  })).min(1).max(50),
});

export async function PATCH(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("admin");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const body = schema.parse(await request.json());
    const supabase = await createServerSupabaseClient();
    if (!supabase) return Response.json({ success: true, developmentFallback: true, affected: body.settings.length });

    for (const setting of body.settings) {
      const { data, error } = await supabase
        .from("game_settings")
        .update({ value: setting.value, updated_by: authorization.context.id })
        .eq("key", setting.key)
        .select("key")
        .maybeSingle();
      if (error) throw new Error(error.message);
      if (!data) throw new Error(`Unknown setting: ${setting.key}`);
    }
    return Response.json({ success: true, developmentFallback: false, affected: body.settings.length });
  } catch (error) {
    if (error instanceof z.ZodError) return Response.json({ error: "إحدى القيم غير صالحة." }, { status: 400 });
    return Response.json({ error: error instanceof Error ? error.message : "تعذر حفظ الإعدادات." }, { status: 400 });
  }
}
