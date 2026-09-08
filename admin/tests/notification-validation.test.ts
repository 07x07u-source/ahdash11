import { describe, expect, it } from "vitest";
import { notificationCampaignSchema } from "@/lib/notifications/schema";

const valid = {
  title: "تحدي اليوم",
  body: "تحدٍ جديد بانتظارك الآن",
  type: "daily_challenge",
  audience: "active",
  deepLink: "/home",
  requestId: "123e4567-e89b-42d3-a456-426614174000",
  scheduledAt: null,
};

describe("notification campaign validation", () => {
  it("accepts a complete safe campaign", () => {
    expect(notificationCampaignSchema.safeParse(valid).success).toBe(true);
  });

  it("rejects empty copy", () => {
    expect(notificationCampaignSchema.safeParse({ ...valid, title: "", body: "" }).success).toBe(false);
  });

  it("rejects unknown or external deep links", () => {
    expect(notificationCampaignSchema.safeParse({ ...valid, deepLink: "https://example.test" }).success).toBe(false);
    expect(notificationCampaignSchema.safeParse({ ...valid, deepLink: "/admin" }).success).toBe(false);
  });

  it("rejects malformed scheduling and request ids", () => {
    expect(notificationCampaignSchema.safeParse({ ...valid, scheduledAt: "tomorrow" }).success).toBe(false);
    expect(notificationCampaignSchema.safeParse({ ...valid, requestId: "duplicate" }).success).toBe(false);
  });
});
