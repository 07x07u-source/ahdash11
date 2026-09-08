import { authorizeAdminApi } from "@/lib/auth/context";
import {
  createPremiumVoucherSchema,
  mapCreatedVoucher,
  premiumVoucherActionsEnabled,
} from "@/lib/premium-vouchers/schema";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  const authorization = await authorizeAdminApi("admin");
  if (authorization.response) return authorization.response;
  if (!premiumVoucherActionsEnabled()) {
    return Response.json(
      { error: "إنشاء القسائم متوقف حتى اعتماد مراجعة سياسات المتاجر." },
      { status: 403 },
    );
  }

  const parsed = createPremiumVoucherSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) {
    return Response.json({ error: "بيانات القسيمة غير صالحة." }, { status: 400 });
  }
  const supabase = await createServerSupabaseClient();
  if (!supabase) {
    return Response.json({ error: "اتصال الخادم غير متاح." }, { status: 503 });
  }

  const { data, error } = await supabase.rpc("admin_create_premium_vouchers", {
    p_voucher_type: parsed.data.voucherType,
    p_quantity: parsed.data.quantity,
    p_internal_note: parsed.data.internalNote,
  });
  if (error || !Array.isArray(data)) {
    return Response.json({ error: "تعذر إنشاء القسيمة بأمان." }, { status: 502 });
  }

  // Raw codes are returned to this authorized response once and never logged.
  return Response.json({ vouchers: data.map((row) => mapCreatedVoucher(row as Record<string, unknown>)) });
}
