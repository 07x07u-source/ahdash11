import "server-only";

import { createServerSupabaseClient } from "@/lib/supabase/server";
import { mapVoucherRow, type PremiumVoucherRow } from "@/lib/premium-vouchers/schema";

export async function getPremiumVouchers(): Promise<{
  available: boolean;
  rows: PremiumVoucherRow[];
}> {
  const supabase = await createServerSupabaseClient();
  if (!supabase) return { available: false, rows: [] };

  const { data, error } = await supabase.rpc("admin_list_premium_vouchers", {
    p_limit: 100,
  });
  if (error || !Array.isArray(data)) return { available: false, rows: [] };
  return {
    available: true,
    rows: data
      .filter((row): row is Record<string, unknown> => Boolean(row) && typeof row === "object")
      .map(mapVoucherRow),
  };
}
