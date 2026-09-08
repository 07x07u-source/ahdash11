import { describe, expect, it } from "vitest";
import { categoryCreateSchema, contentMutationSchema, localContentDefinitions, validateDraftForDefinition } from "../src/lib/content/schema";

describe("admin content validation", () => {
  it("accepts a stable content key and bounded copy", () => {
    const parsed = contentMutationSchema.parse({ action: "save", key: "home.hero.title", valueAr: "عنوان جديد", mediaId: null });
    expect(parsed.action).toBe("save");
    if (parsed.action !== "save") throw new Error("Expected save mutation");
    const definition = localContentDefinitions.find((item) => item.key === parsed.key)!;
    expect(validateDraftForDefinition(definition, parsed.valueAr, parsed.mediaId).valueAr).toBe("عنوان جديد");
  });

  it("rejects missing text and arbitrary keys", () => {
    const definition = localContentDefinitions.find((item) => item.key === "home.hero.title")!;
    expect(() => validateDraftForDefinition(definition, " ", null)).toThrow("النص مطلوب");
    expect(() => contentMutationSchema.parse({ action: "save", key: "content1", valueAr: "نص", mediaId: null })).toThrow();
  });

  it("does not allow images on text-only keys", () => {
    const definition = localContentDefinitions.find((item) => item.key === "home.hero.title")!;
    expect(() => validateDraftForDefinition(definition, "عنوان", "11111111-1111-4111-8111-111111111111")).toThrow("لا يقبل صورة");
  });

  it("strictly validates remote appearance and feature controls", () => {
    const accent = localContentDefinitions.find((item) => item.key === "appearance.accent.color")!;
    const feature = localContentDefinitions.find((item) => item.key === "feature.home.promotion")!;

    expect(validateDraftForDefinition(accent, "#2F6FBA", null).valueAr).toBe("#2F6FBA");
    expect(() => validateDraftForDefinition(accent, "#GGGGGG", null)).toThrow("Hex");
    expect(validateDraftForDefinition(feature, "true", null).valueAr).toBe("true");
    expect(() => validateDraftForDefinition(feature, "null", null)).toThrow("true أو false");
  });

  it("contains all managed branding and build-time app icon definitions", () => {
    const keys = new Set(localContentDefinitions.map((item) => item.key));
    expect(keys).toContain("branding.logo.primary");
    expect(keys).toContain("branding.login.artwork");
    expect(keys).toContain("branding.placeholder.default");
    expect(keys).toContain("branding.appicon.master");
    expect(keys).toContain("promotions.seasonal.image");
  });

  it("validates Party V2 category merchandising without accepting unknown formats", () => {
    const base = {
      nameAr: "نجوم الدوري السعودي",
      slug: "saudi-stars",
      parentId: null,
      iconKey: "star",
      descriptionAr: "لاعبون من موسم 2026/27",
      isActive: true,
      groupKey: "saudi",
      seasonLabel: "2026/27",
      questionFormats: ["open_answer", "image"],
      favoriteEligible: true,
      accessTier: "premium",
      featured: true,
      isNew: true,
      editorialStatus: "review",
      freeRotation: false,
    };
    expect(categoryCreateSchema.parse(base)).toMatchObject({ groupKey: "saudi", accessTier: "premium", editorialStatus: "review" });
    expect(() => categoryCreateSchema.parse({ ...base, questionFormats: ["unreleased_format"] })).toThrow();
  });
});
