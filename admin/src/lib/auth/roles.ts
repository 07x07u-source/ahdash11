export const ADMIN_ROLES = ["moderator", "admin", "super_admin"] as const;
export const ALL_ROLES = ["user", ...ADMIN_ROLES] as const;

export type AppRole = (typeof ALL_ROLES)[number];
export type AdminRole = (typeof ADMIN_ROLES)[number];

const roleWeight: Record<AppRole, number> = {
  user: 0,
  moderator: 1,
  admin: 2,
  super_admin: 3,
};

export function isAppRole(value: unknown): value is AppRole {
  return typeof value === "string" && ALL_ROLES.includes(value as AppRole);
}

export function isAdminRole(value: unknown): value is AdminRole {
  return typeof value === "string" && ADMIN_ROLES.includes(value as AdminRole);
}

export function hasMinimumRole(role: AppRole, required: AdminRole): boolean {
  return roleWeight[role] >= roleWeight[required];
}

export const roleLabel: Record<AppRole, string> = {
  user: "مستخدم",
  moderator: "مشرف محتوى",
  admin: "مدير",
  super_admin: "مدير أعلى",
};
