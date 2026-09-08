import "server-only";

import type { User } from "@supabase/supabase-js";
import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { isDevelopmentFallback } from "@/lib/supabase/config";
import { hasMinimumRole, isAdminRole, type AdminRole } from "./roles";

export interface AdminContext {
  id: string;
  email: string;
  displayName: string;
  role: AdminRole;
  isDevelopmentFallback: boolean;
  user: User | null;
}

const developmentAdmin: AdminContext = {
  id: "00000000-0000-0000-0000-000000000011",
  email: "dev@ahdash11.local",
  displayName: "مدير أحدعش",
  role: "super_admin",
  isDevelopmentFallback: true,
  user: null,
};

export async function getAdminContext(): Promise<AdminContext | null> {
  const supabase = await createServerSupabaseClient();

  if (!supabase) return isDevelopmentFallback ? developmentAdmin : null;

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) return null;

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("id, display_name, username, role")
    .eq("id", user.id)
    .single();

  if (profileError || !profile || !isAdminRole(profile.role)) return null;

  return {
    id: user.id,
    email: user.email ?? "",
    displayName: profile.display_name || profile.username || user.email || "مدير",
    role: profile.role,
    isDevelopmentFallback: false,
    user,
  };
}

export async function requireAdminPage(requiredRole: AdminRole = "moderator"): Promise<AdminContext> {
  const context = await getAdminContext();

  if (!context) redirect("/login");
  if (!hasMinimumRole(context.role, requiredRole)) redirect("/unauthorized");

  return context;
}

export async function authorizeAdminApi(requiredRole: AdminRole = "moderator") {
  const context = await getAdminContext();

  if (!context) {
    return { context: null, response: Response.json({ error: "يلزم تسجيل الدخول." }, { status: 401 }) };
  }

  if (!hasMinimumRole(context.role, requiredRole)) {
    return { context: null, response: Response.json({ error: "لا تملك الصلاحية المطلوبة." }, { status: 403 }) };
  }

  return { context, response: null };
}
