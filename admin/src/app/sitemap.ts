import type { MetadataRoute } from "next";

const origin = "https://ahdash11.com";
const lastModified = new Date("2026-09-26");

const routes = [
  "/",
  "/games",
  "/play",
  "/championships",
  "/support",
  "/legal",
  "/legal/privacy",
  "/legal/terms",
  "/legal/community",
  "/legal/tournament-rules",
  "/legal/refunds",
  "/legal/cookies",
  "/legal/data-rights",
  "/mobile-app",
] as const;

export default function sitemap(): MetadataRoute.Sitemap {
  return routes.map((path) => ({
    url: `${origin}${path}`,
    lastModified,
    changeFrequency: path.startsWith("/legal") ? "yearly" : "weekly",
    priority: path === "/" ? 1 : path.startsWith("/legal") ? 0.5 : 0.8,
  }));
}
