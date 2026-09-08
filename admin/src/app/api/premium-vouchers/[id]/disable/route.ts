import { authorizeAdminApi } from "@/lib/auth/context";
import { premiumVoucherActionsEnabled } from "@/lib/premium-vouchers/schema";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export async function POST(_: Request, context: { params: Promise<{ id: string }> }) {
  const authorization = await authorizeAdminApi("admin");
  if (authorization.response) return authorization.response;
  if (!premiumVoucherActionsEnabled()) {
    return Response.json({ error: "إدارة القسائم متوقفة حتى اعتماد السياسة." }, { status: 403 });
  }
  const { id } = await context.params;
  if (!uuid.test(id)) return Response.json({ error: "معرّف غير صالح." }, { status: 400 });
  const supabase = await createServerSupabaseClient();
  if (!supabase) return Response.json({ error: "اتصال الخادم غير متاح." }, { status: 503 });

  const { data, error } = await supabase.rpc("admin_disable_premium_voucher", {
    p_voucher_id: id,
  });
  if (error) return Response.json({ error: "تعذر تعطيل القسيمة." }, { status: 502 });
  if (data !== true) return Response.json({ error: "القسيمة مستخدمة أو غير متاحة." }, { status: 409 });
  return Response.json({ disabled: true });
}
