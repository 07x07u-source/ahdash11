const PLAYER_RETURN_ROOTS = ["/", "/account", "/championships", "/games", "/legal", "/play", "/support"] as const;

const REMOVED_PLAYER_PATHS = [
  "/account/friends",
  "/account/store",
  "/friends",
  "/matchmaking",
  "/online",
  "/rooms",
] as const;

function matchesRoute(pathname: string, route: string) {
  return route === "/" ? pathname === "/" : pathname === route || pathname.startsWith(`${route}/`);
}

export function isAllowedPlayerReturnPath(pathname: string) {
  if (REMOVED_PLAYER_PATHS.some((route) => matchesRoute(pathname, route))) return false;
  return PLAYER_RETURN_ROOTS.some((route) => matchesRoute(pathname, route));
}

export function safeReturnPath(value: string | string[] | null | undefined, fallback = "/account") {
  const candidate = Array.isArray(value) ? value[0] : value;
  if (!candidate || !candidate.startsWith("/") || candidate.startsWith("//") || candidate.includes("\\")) return fallback;
  if (/[\u0000-\u001F\u007F]/.test(candidate)) return fallback;

  try {
    const base = new URL("https://player.ahdash.invalid");
    const parsed = new URL(candidate, base);
    if (parsed.origin !== base.origin || !isAllowedPlayerReturnPath(parsed.pathname)) return fallback;
    return `${parsed.pathname}${parsed.search}${parsed.hash}`;
  } catch {
    return fallback;
  }
}

export const PLAYER_AUTH_CALLBACK_PATH = "/auth/callback";
export const PLAYER_OAUTH_PROVIDERS = ["google", "apple"] as const;
export type PlayerOAuthProvider = (typeof PLAYER_OAUTH_PROVIDERS)[number];

export function buildPlayerAuthCallbackUrl(origin: string, returnTo: string) {
  const safeOrigin = new URL(origin).origin;
  const callback = new URL(PLAYER_AUTH_CALLBACK_PATH, safeOrigin);
  callback.searchParams.set("next", safeReturnPath(returnTo));
  return callback.toString();
}
