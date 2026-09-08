import { PremiumVoucherManager } from "@/components/premium-voucher-manager";
import { requireAdminPage } from "@/lib/auth/context";
import { getPremiumVouchers } from "@/lib/data/premium-voucher-data";
import { premiumVoucherActionsEnabled } from "@/lib/premium-vouchers/schema";

export default async function PremiumVouchersPage() {
  await requireAdminPage("admin");
  const data = await getPremiumVouchers();
  return <div className="space-y-6">
    <header><p className="mb-2 text-xs font-black text-[#5f8f0f]">PREMIUM · أداة داخلية آمنة</p><h1 className="text-3xl font-black text-[var(--foreground)]">قسائم Premium</h1><p className="mt-2 max-w-3xl text-sm leading-7 text-[var(--muted)]">إنشاء ومتابعة القسائم الترويجية غير المتجددة. الأسرار الخام تظهر بعد الإنشاء فقط، والاسترداد يخضع لوقت الخادم وقفل أحادي.</p></header>
    <PremiumVoucherManager initialRows={data.rows} backendAvailable={data.available} actionsEnabled={premiumVoucherActionsEnabled()} />
  </div>;
}
