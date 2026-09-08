import { describe, expect, it } from "vitest";
import { validateQuestionRow } from "@/lib/import/validation";

const validRow = {
  "السؤال": "أين يقع ملعب أنفيلد؟",
  "الخيار الأول": "لندن",
  "الخيار الثاني": "ليفربول",
  "الخيار الثالث": "مانشستر",
  "الخيار الرابع": "مدريد",
  "الإجابة الصحيحة": "ليفربول",
};

describe("validateQuestionRow", () => {
  it("accepts the minimal Arabic spreadsheet format", () => {
    const result = validateQuestionRow(validRow);
    expect(result.errors).toEqual([]);
    expect(result.correctOptionIndex).toBe(1);
    expect(result.normalizedText).toBe("اين يقع ملعب انفيلد");
  });

  it("rejects a correct answer that is not one of the options", () => {
    const result = validateQuestionRow({ ...validRow, "الإجابة الصحيحة": "روما" });
    expect(result.errors).toContain("الإجابة الصحيحة ليست ضمن الخيارات الأربعة.");
  });

  it("rejects duplicate options after Arabic normalization", () => {
    const result = validateQuestionRow({ ...validRow, "الخيار الأول": "ليفربول" });
    expect(result.errors).toContain("يجب أن تكون الخيارات الأربعة مختلفة.");
  });

  it("accepts an open-answer row with Party metadata and no fake options", () => {
    const result = validateQuestionRow({
      "السؤال": "من سجل هدف نهائي البطولة؟",
      "الإجابة الصحيحة": "سالم الدوسري",
      "نوع السؤال": "مفتوح",
      "الصعوبة": "صعب",
      "النقاط": "300",
      "المصدر": "الاتحاد الرسمي",
      "رابط المصدر": "https://example.test/source",
      "الموسم": "2025/26",
    });
    expect(result.errors).toEqual([]);
    expect(result.questionFormat).toBe("open_answer");
    expect(result.pointValue).toBe(300);
    expect(result.difficulty).toBe("hard");
  });

  it("rejects unsupported points and an unverified media path", () => {
    const result = validateQuestionRow({
      ...validRow,
      "النقاط": "175",
      "الصورة": "javascript:bad",
      "نوع السؤال": "صورة",
    });
    expect(result.errors).toContain("قيمة النقاط يجب أن تكون 100 أو 200 أو 300.");
    expect(result.errors).toContain("مسار الوسائط غير صالح أو غير موثّق.");
  });
});
