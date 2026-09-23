import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { type NextRequest, NextResponse } from "next/server";
import { hasSupabaseConfig, supabaseAnonKey, supabaseUrl } from "@/lib/supabase/config";

export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });

  const pathname = request.nextUrl.pathname;
  const userAgent = request.headers.get("user-agent") ?? "";
  const isPhone = /Android|iPhone|iPod|IEMobile|Opera Mini|Mobile/i.test(userAgent);
  const isPublicWebsite = pathname === "/" || ["/games", "/play", "/championships", "/support", "/legal", "/account"].some((prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`));

  if (isPhone && isPublicWebsite && pathname !== "/mobile-app") {
    return NextResponse.rewrite(new URL("/mobile-app", request.url));
  }

  if (!hasSupabaseConfig) return response;

  const supabase = createServerClient(supabaseUrl, supabaseAnonKey, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll(cookiesToSet: { name: string; value: string; options: CookieOptions }[]) {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
      },
    },
  });

  await supabase.auth.getUser();
  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|branding/|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};
