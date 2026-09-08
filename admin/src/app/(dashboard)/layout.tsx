import { AppShell } from "@/components/app-shell";
import { requireAdminPage } from "@/lib/auth/context";

export const dynamic = "force-dynamic";

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const admin = await requireAdminPage();
  return <AppShell admin={admin}>{children}</AppShell>;
}
