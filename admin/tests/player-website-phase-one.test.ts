import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  PLAYER_AUTH_CALLBACK_PATH,
  PLAYER_OAUTH_PROVIDERS,
  buildPlayerAuthCallbackUrl,
  safeReturnPath,
} from "@/lib/auth/redirects";
import { gameFormats, gameModes, normalizeGameFormat, normalizeGameMode } from "@/lib/site/game-modes";
import { playerFeatures } from "@/lib/site/player-features";
import { websitePremium } from "@/lib/site/premium";

function source(path: string) {
  return readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
}

describe("player website Phase 1 foundation", () => {
  it("keeps email authentication and exposes real Supabase OAuth actions", () => {
    const authForm = source("src/components/player-auth-form.tsx");
    expect(authForm).toContain("signInWithPassword");
    expect(authForm).toContain("signUp");
    expect(authForm).toContain("resetPasswordForEmail");
    expect(authForm).toContain("signInWithOAuth");
    expect(PLAYER_OAUTH_PROVIDERS).toEqual(["google", "apple"]);
    expect(PLAYER_AUTH_CALLBACK_PATH).toBe("/auth/callback");
  });

  it("builds the OAuth callback from the current origin and a safe return path", () => {
    const callback = new URL(buildPlayerAuthCallbackUrl("https://play.example.test/somewhere", "/play?mode=classic"));
    expect(callback.origin).toBe("https://play.example.test");
    expect(callback.pathname).toBe("/auth/callback");
    expect(callback.searchParams.get("next")).toBe("/play?mode=classic");
  });

  it("rejects external, malformed, and removed-feature return paths", () => {
    const rejected = [
      "https://example.com",
      "//example.com/path",
      "/\\example.com/path",
      "/online",
      "/matchmaking/queue",
      "/rooms/ABC",
      "/friends",
      "/account/friends",
      "/account/store",
    ];
    for (const value of rejected) expect(safeReturnPath(value)).toBe("/account");
    expect(safeReturnPath("/games?format=local-party")).toBe("/games?format=local-party");
    expect(safeReturnPath("/championships/create")).toBe("/championships/create");
  });

  it("keeps player mutation routes protected at the page boundary", () => {
    const protectedPages = [
      "src/app/(website)/championships/create/page.tsx",
      "src/app/(website)/championships/join/page.tsx",
      "src/app/(website)/account/page.tsx",
      "src/app/(website)/account/[feature]/page.tsx",
    ];
    for (const page of protectedPages) expect(source(page)).toContain("requirePlayerPage(");
  });

  it("does not expose Friends, Store, Online, or deferred game types as active website features", () => {
    expect(playerFeatures.map((feature) => feature.slug)).not.toContain("friends");
    expect(playerFeatures.map((feature) => feature.slug)).not.toContain("store");
    expect(gameModes.filter((mode) => mode.discoverableOnWebsite).map((mode) => mode.slug)).toEqual(["classic"]);
    expect(gameFormats.filter((format) => format.discoverableOnWebsite).map((format) => format.slug)).toEqual(["local-party", "practice"]);
    expect(normalizeGameMode("ordering")).toBe("classic");
    expect(normalizeGameFormat("team-challenge")).toBe("local-party");
  });

  it("uses only the approved Premium plans and benefits", () => {
    expect(websitePremium.plans).toEqual(["شهري", "سنوي"]);
    expect(websitePremium.benefits).toEqual(["فئات حصرية", "بلا إعلانات"]);
    const premiumSource = source("src/components/account-feature-surface.tsx");
    for (const forbidden of ["إحصائيات أوسع", "بطولات بخيارات إضافية", "مظهر Premium", "قسائم", "عملات"]) {
      expect(premiumSource).not.toContain(forbidden);
    }
  });

  it("keeps the player website shell separate from the staff Admin shell", () => {
    const websiteLayout = source("src/app/(website)/layout.tsx");
    const siteShell = source("src/components/site-shell.tsx");
    expect(websiteLayout).toContain("SiteShell");
    expect(websiteLayout).not.toContain("AppShell");
    expect(siteShell).not.toContain("/dashboard");
    expect(siteShell).not.toContain("app-shell");
  });

  it("describes the current product and browser limitation truthfully", () => {
    const homepage = source("src/app/(website)/page.tsx");
    expect(homepage).toContain("لعبة Party كروية سعودية");
    expect(homepage).toContain("36 سؤالاً");
    expect(homepage).toContain("Party وSolo المحليان متاحان على الكمبيوتر");
    expect(homepage).toContain("ابدأ Party كضيف");
    expect(homepage).not.toContain("يدعم الجوال");
    expect(homepage).not.toContain("ستة أنماط لعب");
  });
});
