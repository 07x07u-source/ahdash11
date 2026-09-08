import { describe, expect, it } from "vitest";
import {
  footballDataCreateSchema,
  footballDataUpdateSchema,
  socialTeamModerationSchema,
  socialReportReviewSchema,
} from "../src/lib/social-football/schema";

const id = "11111111-1111-4111-8111-111111111111";

describe("football data rights validation", () => {
  it("accepts a fallback club without a logo", () => {
    expect(footballDataCreateSchema.parse({
      entity: "club",
      leagueId: id,
      nameAr: "نادي الاختبار",
      nameEn: "Test Club",
      shortName: "TST",
      visualStatus: "fallback",
      logoUrl: null,
      licenseReference: null,
      primaryColor: "#B6FF3B",
      secondaryColor: null,
    }).entity).toBe("club");
  });

  it("rejects a logo in fallback state", () => {
    expect(() => footballDataCreateSchema.parse({
      entity: "club",
      leagueId: id,
      nameAr: "نادي الاختبار",
      nameEn: "Test Club",
      visualStatus: "fallback",
      logoUrl: "https://example.com/logo.png",
    })).toThrow("الحالة البديلة");
  });

  it("requires a license reference for licensed visuals", () => {
    expect(() => footballDataCreateSchema.parse({
      entity: "league",
      countryId: id,
      nameAr: "دوري الاختبار",
      nameEn: "Test League",
      visualStatus: "licensed",
      logoUrl: "https://example.com/logo.png",
      licenseReference: null,
    })).toThrow("مرجع الترخيص");
  });

  it("keeps country updates free of logo rights fields", () => {
    expect(() => footballDataUpdateSchema.parse({
      entity: "country",
      id,
      visualStatus: "custom",
    })).toThrow("الدول لا تحمل");
  });
});

describe("social moderation validation", () => {
  it("requires a reason when suspending a private team", () => {
    expect(() => socialTeamModerationSchema.parse({
      teamId: id,
      status: "suspended",
      reason: null,
    })).toThrow("سبب الإجراء");
  });

  it("allows restoring a team without retaining a reason", () => {
    expect(socialTeamModerationSchema.parse({
      teamId: id,
      status: "active",
      reason: null,
    }).status).toBe("active");
  });

  it("accepts only bounded social report review states", () => {
    expect(socialReportReviewSchema.parse({
      reportId: id,
      status: "resolved",
      note: "تمت المراجعة",
    }).status).toBe("resolved");
    expect(() => socialReportReviewSchema.parse({
      reportId: id,
      status: "deleted",
      note: null,
    })).toThrow();
  });
});
