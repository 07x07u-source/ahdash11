import { describe, expect, it } from "vitest";
import {
  createPremiumVoucherSchema,
  mapCreatedVoucher,
  mapVoucherRow,
  premiumVoucherActionsEnabled,
} from "../src/lib/premium-vouchers/schema";

describe("Premium voucher admin contract", () => {
  it("accepts only monthly and annual promo vouchers with bounded quantity", () => {
    expect(createPremiumVoucherSchema.parse({ voucherType: "monthly_promo", quantity: 1 }).quantity).toBe(1);
    expect(createPremiumVoucherSchema.parse({ voucherType: "annual_promo", quantity: 50 }).quantity).toBe(50);
    expect(() => createPremiumVoucherSchema.parse({ voucherType: "weekly", quantity: 1 })).toThrow();
    expect(() => createPremiumVoucherSchema.parse({ voucherType: "monthly_promo", quantity: 51 })).toThrow();
  });

  it("requires explicit policy approval in production", () => {
    expect(premiumVoucherActionsEnabled({ NODE_ENV: "production", PREMIUM_VOUCHERS_ENABLED: "true" })).toBe(false);
    expect(premiumVoucherActionsEnabled({ NODE_ENV: "production", PREMIUM_VOUCHERS_ENABLED: "true", PREMIUM_VOUCHERS_POLICY_APPROVED: "true" })).toBe(true);
    expect(premiumVoucherActionsEnabled({ NODE_ENV: "development", PREMIUM_VOUCHERS_ENABLED: "true" })).toBe(true);
  });

  it("validates high-entropy server code shape without persisting it in rows", () => {
    const created = mapCreatedVoucher({ id: "v1", code: "AB12-CD34-EF56-7890-ABCD-EF12", voucher_type: "monthly_promo" });
    expect(created.code).toHaveLength(29);
    const row = mapVoucherRow({ id: "v1", voucher_type: "monthly_promo", status: "unused", created_at: "2026-09-07T00:00:00Z", redemption_deadline: "2027-03-07T00:00:00Z" });
    expect(row).not.toHaveProperty("code");
    expect(row).not.toHaveProperty("codeHash");
  });
});
