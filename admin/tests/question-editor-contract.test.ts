import { describe, expect, it } from "vitest";
import {
  createPartyQuestionSchema,
  createQuestionSchema,
  toCreatePartyQuestionRpcParams,
  toCreateQuestionRpcParams,
} from "@/lib/questions/editor-contract";

describe("question editor contract", () => {
  it("maps an open-answer party question to the isolated practice RPC", () => {
    const input = createPartyQuestionSchema.parse({
      questionText: "من سجل هدف الفوز في المباراة؟",
      questionFormat: "open_answer",
      categoryId: "category-id",
      difficulty: "medium",
      correctAnswer: "اللاعب أحدعش",
      alternativeAnswers: ["أحدعش"],
      options: [],
      correctOptionPosition: null,
      pointValue: 200,
      explanation: "معلومة قصيرة موثقة.",
      sourceUrl: "https://example.com/source",
      sourceName: "المصدر الرسمي",
      season: "2026/27",
      imageUrl: "",
      mediaRightsStatus: "none",
    });
    expect(toCreatePartyQuestionRpcParams(input)).toMatchObject({
      p_question_format: "open_answer",
      p_correct_answer: "اللاعب أحدعش",
      p_alternative_answers: ["أحدعش"],
      p_options: [],
      p_point_value: 200,
    });
  });

  it("rejects an image question without rights metadata", () => {
    const result = createPartyQuestionSchema.safeParse({
      questionText: "من اللاعب الظاهر في الصورة؟",
      questionFormat: "image",
      categoryId: "category-id",
      difficulty: "easy",
      correctAnswer: "لاعب",
      alternativeAnswers: [],
      options: [],
      correctOptionPosition: null,
      pointValue: 100,
      imageUrl: "https://example.com/image.webp",
      mediaRightsStatus: "none",
    });
    expect(result.success).toBe(false);
  });

  it("maps competitive True/False to the isolated two-option RPC contract", () => {
    const input = createQuestionSchema.parse({
      questionText: "الفريق الأعلى نقاطًا يتصدر جدول الدوري.",
      gameplayType: "true-false",
      categoryId: "category-id",
      difficulty: "easy",
      options: ["صح", "خطأ"],
      correctOptionPosition: 1,
      pool: "competitive",
    });

    expect(toCreateQuestionRpcParams(input)).toEqual({
      p_question_text: input.questionText,
      p_gameplay_type: "true-false",
      p_category_id: "category-id",
      p_difficulty: "easy",
      p_options: ["صح", "خطأ"],
      p_correct_position: 1,
      p_offline_practice_eligible: false,
      p_competitive_eligible: true,
    });
  });

  it("rejects a True/False payload with four or reordered options", () => {
    const base = {
      questionText: "اختبار عقد الخيارات في وضع صح أو خطأ.",
      gameplayType: "true-false",
      categoryId: "category-id",
      difficulty: "medium",
      correctOptionPosition: 1,
      pool: "practice",
    } as const;
    expect(createQuestionSchema.safeParse({ ...base, options: ["صح", "خطأ", "ربما", "لاحقًا"] }).success).toBe(false);
    expect(createQuestionSchema.safeParse({ ...base, options: ["خطأ", "صح"] }).success).toBe(false);
  });

  it("keeps practice answer-key content out of competition", () => {
    const input = createQuestionSchema.parse({
      questionText: "سؤال تدريبي غير مصنف بخيارات كلاسيكية.",
      gameplayType: "classic",
      categoryId: "category-id",
      difficulty: "medium",
      options: ["أ", "ب", "ج", "د"],
      correctOptionPosition: 2,
      pool: "practice",
    });
    const params = toCreateQuestionRpcParams(input);
    expect(params.p_offline_practice_eligible).toBe(true);
    expect(params.p_competitive_eligible).toBe(false);
  });
});
