import { z } from "zod";

export const notificationDeepLinks = [
  "/home",
  "/notifications",
  "/profile",
  "/store",
  "/ranking",
  "/friends",
] as const;

export const notificationCampaignSchema = z.object({
  title: z.string().trim().min(3).max(80),
  body: z.string().trim().min(5).max(240),
  type: z.enum(["daily_challenge", "reward", "season", "announcement", "system"]),
  audience: z.enum(["all", "active", "premium", "inactive_7d"]),
  deepLink: z.enum(notificationDeepLinks),
  requestId: z.string().uuid(),
  scheduledAt: z.string().datetime().nullable().optional(),
});
