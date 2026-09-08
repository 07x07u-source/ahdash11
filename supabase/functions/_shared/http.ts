import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.49.8";

const configuredOrigins = (Deno.env.get("ALLOWED_ORIGINS") ?? "*")
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);

export function corsHeaders(request: Request): Record<string, string> {
  const origin = request.headers.get("origin") ?? "*";
  const allowedOrigin = configuredOrigins.includes("*") || configuredOrigins.includes(origin)
    ? origin
    : configuredOrigins[0] ?? "*";
  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

export function handlePreflight(request: Request): Response | null {
  return request.method === "OPTIONS" ? new Response("ok", { headers: corsHeaders(request) }) : null;
}

export function jsonResponse(request: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(request), "Content-Type": "application/json; charset=utf-8" },
  });
}

export function errorResponse(request: Request, error: unknown, status = 400): Response {
  const message = error instanceof Error ? error.message : "Unexpected error";
  return jsonResponse(request, { error: message }, status);
}

export async function readJson<T>(request: Request): Promise<T> {
  if (request.method !== "POST") throw new Error("POST required");
  const contentType = request.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) throw new Error("application/json required");
  return await request.json() as T;
}

export function userClient(request: Request): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const authorization = request.headers.get("Authorization");
  if (!url || !anonKey) throw new Error("Supabase environment is not configured");
  if (!authorization?.startsWith("Bearer ")) throw new Error("Authentication required");
  return createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function serviceClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) throw new Error("Service role environment is not configured");
  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function rpcError(error: { message?: string } | null): void {
  if (error) throw new Error(error.message ?? "Database operation failed");
}
