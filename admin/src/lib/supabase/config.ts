export const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim() ?? "";
export const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim() ?? "";

export const hasSupabaseConfig = Boolean(supabaseUrl && supabaseAnonKey);

export const useDemoData =
  process.env.NODE_ENV !== "production" &&
  process.env.ADMIN_USE_DEMO_DATA === "true";

export const isDevelopmentFallback =
  process.env.NODE_ENV !== "production" &&
  process.env.ADMIN_DEV_BYPASS_AUTH !== "false" &&
  !hasSupabaseConfig;
