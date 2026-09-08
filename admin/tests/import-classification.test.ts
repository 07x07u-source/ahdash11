import { describe, expect, it } from "vitest";
import { classifyQuestion, getFallbackCategories } from "@/lib/import/classification";
import { processImportRows } from "@/lib/import/processor";
import { questionSimilarity } from "@/lib/import/similarity";

describe("rule-based classification", () => {
  it("classifies stadium questions without an external AI service", () => {
    const result = classifyQuestion("أين يقع ملعب أنفيلد؟", "questions.csv", getFallbackCategories());
    expect(result.categoryName).toBe("الملاعب");
    expect(result.confidence).toBeGreaterThanOrEqual(0.6);
  });

  it("marks unclear questions for human review", () => {
    const result = classifyQuestion("من هو صاحب هذا الإنجاز؟", "misc.xlsx", getFallbackCategories());
    expect(result.categoryId).toBeNull();
    expect(result.needsReview).toBe(true);
  });
});

describe("duplicate and similarity detection", () => {
  const baseRow = {
    "السؤال": "أين يقع ملعب أنفيلد؟",
    "الخيار الأول": "لندن",
    "الخيار الثاني": "ليفربول",
    "الخيار الثالث": "مانشستر",
    "الخيار الرابع": "مدريد",
    "الإجابة الصحيحة": "ليفربول",
  };

  it("normalizes spelling variants before similarity scoring", () => {
    expect(questionSimilarity("أين يقع ملعب أنفيلد؟", "اين يقع ملعب انفيلد")).toBe(1);
  });

  it("detects exact duplicates inside the uploaded file", () => {
    const result = processImportRows([baseRow, baseRow], "stadiums.csv", getFallbackCategories());
    expect(result.rows[1].status).toBe("duplicate");
    expect(result.summary.duplicate).toBe(1);
  });
});
