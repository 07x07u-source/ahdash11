import { authorizeAdminApi } from "@/lib/auth/context";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const authorization = await authorizeAdminApi("moderator"); if (authorization.response) return authorization.response;
  const value = new URL(request.url).searchParams.get("q")?.trim().slice(0, 80) ?? "";
  if (value.length < 2) return Response.json({ results: [] });
  const safe = value.replace(/[^\p{L}\p{N}\s@.-]/gu, "").trim();
  if (!safe) return Response.json({ results: [] });
  const supabase = await createServerSupabaseClient(); if (!supabase) return Response.json({ results: [] });
  const [users, questions, categories, content, media] = await Promise.all([
    supabase.from("profiles").select("id,display_name,username").or(`display_name.ilike.%${safe}%,username.ilike.%${safe}%`).limit(5),
    supabase.from("questions").select("id,question_text,status").ilike("question_text", `%${safe}%`).limit(5),
    supabase.from("categories").select("id,name_ar,slug").or(`name_ar.ilike.%${safe}%,slug.ilike.%${safe}%`).limit(5),
    supabase.from("app_content").select("key,label_ar,section").or(`label_ar.ilike.%${safe}%,key.ilike.%${safe}%`).limit(5),
    supabase.from("media_assets").select("id,original_filename,asset_group").ilike("original_filename", `%${safe}%`).limit(5),
  ]);
  const results = [
    ...(users.data ?? []).map((row) => ({ type: "user", id: String(row.id), title: String(row.display_name ?? row.username), subtitle: `@${row.username}`, href: "/users" })),
    ...(questions.data ?? []).map((row) => ({ type: "question", id: String(row.id), title: String(row.question_text), subtitle: String(row.status), href: "/questions" })),
    ...(categories.data ?? []).map((row) => ({ type: "category", id: String(row.id), title: String(row.name_ar), subtitle: String(row.slug), href: "/categories" })),
    ...(content.data ?? []).map((row) => ({ type: "content", id: String(row.key), title: String(row.label_ar), subtitle: String(row.section), href: "/content" })),
    ...(media.data ?? []).map((row) => ({ type: "media", id: String(row.id), title: String(row.original_filename), subtitle: String(row.asset_group), href: "/media" })),
  ];
  return Response.json({ results });
}
