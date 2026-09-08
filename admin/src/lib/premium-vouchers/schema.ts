import { z } from "zod";

export const voucherTypeSchema = z.enum(["monthly_promo", "annual_promo"]);

export const createPremiumVoucherSchema = z.object({
  voucherType: voucherTypeSchema,
  quantity: z.coerce.number().int().min(1).max(50).default(1),
  internalNote: z.string().trim().max(500).optional().transform((value) => value || null),
});

export type VoucherType = z.infer<typeof voucherTypeSchema>;

export interface PremiumVoucherRow {
  id: string;
  voucherType: VoucherType;
  status: "unused" | "redeemed" | "expired" | "disabled";
  createdAt: string;
  redemptionDeadline: string;
  redeemedAt: string | null;
  promoExpiresAt: string | null;
  redeemedBy: string | null;
  internalNote: string | null;
}

export interface CreatedPremiumVoucher {
  id: string;
  code: string;
  voucherType: VoucherType;
}

export function premiumVoucherActionsEnabled(environment = process.env): boolean {
  const enabled = environment.PREMIUM_VOUCHERS_ENABLED === "true";
  const production = environment.NODE_ENV === "production";
  const approved = environment.PREMIUM_VOUCHERS_POLICY_APPROVED === "true";
  return enabled && (!production || approved);
}

export function mapVoucherRow(input: Record<string, unknown>): PremiumVoucherRow {
  const status = ["unused", "redeemed", "expired", "disabled"].includes(String(input.status))
    ? String(input.status) as PremiumVoucherRow["status"]
    : "expired";
  return {
    id: String(input.id),
    voucherType: voucherTypeSchema.parse(input.voucher_type),
    status,
    createdAt: String(input.created_at),
    redemptionDeadline: String(input.redemption_deadline),
    redeemedAt: input.redeemed_at ? String(input.redeemed_at) : null,
    promoExpiresAt: input.promo_expires_at ? String(input.promo_expires_at) : null,
    redeemedBy: input.redeemed_by ? String(input.redeemed_by) : null,
    internalNote: input.internal_note ? String(input.internal_note) : null,
  };
}

export function mapCreatedVoucher(input: Record<string, unknown>): CreatedPremiumVoucher {
  const code = String(input.code ?? "");
  if (!/^(?:[A-F0-9]{4}-){5}[A-F0-9]{4}$/.test(code)) {
    throw new Error("Server returned an invalid voucher shape");
  }
  return {
    id: String(input.id),
    code,
    voucherType: voucherTypeSchema.parse(input.voucher_type),
  };
}
