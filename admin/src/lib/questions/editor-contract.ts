import { z } from "zod";

export const createQuestionSchema = z
  .object({
    questionText: z.string().trim().min(5).max(1000),
    gameplayType: z.enum(["classic", "true-false"]),
    categoryId: z.string().min(1),
    difficulty: z.enum(["easy", "medium", "hard", "expert"]),
    options: z.array(z.string().trim().min(1).max(300)).min(2).max(4),
    correctOptionPosition: z.number().int().min(1).max(4),
    pool: z.enum(["competitive", "practice"]),
  })
  .superRefine((value, context) => {
    const expectedCount = value.gameplayType === "true-false" ? 2 : 4;
    if (value.options.length !== expectedCount) {
      context.addIssue({
        code: "custom",
        path: ["options"],
        message: `يتطلب هذا النمط ${expectedCount} خيارات.`,
      });
    }
    if (value.correctOptionPosition > expectedCount) {
      context.addIssue({
        code: "custom",
        path: ["correctOptionPosition"],
        message: "موضع الإجابة الصحيحة خارج الخيارات.",
      });
    }
    if (new Set(value.options).size !== value.options.length) {
      context.addIssue({ code: "custom", path: ["options"], message: "الخيارات يجب أن تكون مختلفة." });
    }
    if (
      value.gameplayType === "true-false" &&
      (value.options[0] !== "صح" || value.options[1] !== "خطأ")
    ) {
      context.addIssue({
        code: "custom",
        path: ["options"],
        message: "ترتيب خيارات صح أو خطأ ثابت: صح ثم خطأ.",
      });
    }
  });

export type CreateQuestionInput = z.infer<typeof createQuestionSchema>;

export function toCreateQuestionRpcParams(input: CreateQuestionInput) {
  return {
    p_question_text: input.questionText,
    p_gameplay_type: input.gameplayType,
    p_category_id: input.categoryId,
    p_difficulty: input.difficulty,
    p_options: input.options,
    p_correct_position: input.correctOptionPosition,
    p_offline_practice_eligible: input.pool === "practice",
    p_competitive_eligible: input.pool === "competitive",
  };
}

export const createPartyQuestionSchema = z
  .object({
    questionText: z.string().trim().min(5).max(1000),
    questionFormat: z.enum(["open_answer", "multiple_choice", "true_false", "image"]),
    categoryId: z.string().min(1),
    difficulty: z.enum(["easy", "medium", "hard", "expert"]),
    correctAnswer: z.string().trim().min(1).max(500),
    alternativeAnswers: z.array(z.string().trim().min(1).max(500)).max(12).default([]),
    options: z.array(z.string().trim().min(1).max(300)).max(4).default([]),
    correctOptionPosition: z.number().int().min(1).max(4).nullable().default(null),
    pointValue: z.number().int().min(50).max(1000).refine((value) => value % 50 === 0),
    explanation: z.string().trim().max(1200).optional().default(""),
    sourceUrl: z.union([z.literal(""), z.string().url().startsWith("https://")]).default(""),
    sourceName: z.string().trim().max(120).optional().default(""),
    season: z.string().trim().max(40).optional().default(""),
    imageUrl: z.union([z.literal(""), z.string().url().startsWith("https://")]).default(""),
    imageMediaId: z.union([z.literal(""), z.string().uuid()]).default(""),
    imageCaption: z.string().trim().max(300).optional().default(""),
    focalX: z.number().min(0).max(1).default(0.5),
    focalY: z.number().min(0).max(1).default(0.5),
    mediaRightsStatus: z.enum(["none", "original", "generated", "licensed"]).default("none"),
  })
  .superRefine((value, context) => {
    const expected = value.questionFormat === "multiple_choice" ? 4 : value.questionFormat === "true_false" ? 2 : 0;
    if (value.options.length !== expected) {
      context.addIssue({ code: "custom", path: ["options"], message: `تتطلب الصيغة ${expected} خيارات.` });
    }
    if (expected > 0 && (value.correctOptionPosition === null || value.correctOptionPosition > expected)) {
      context.addIssue({ code: "custom", path: ["correctOptionPosition"], message: "اختر الخيار الصحيح." });
    }
    if (value.questionFormat === "true_false" && (value.options[0] !== "صح" || value.options[1] !== "خطأ")) {
      context.addIssue({ code: "custom", path: ["options"], message: "ترتيب صح أو خطأ ثابت." });
    }
    if (value.questionFormat === "image" && (!value.imageUrl || !value.imageMediaId || value.mediaRightsStatus === "none")) {
      context.addIssue({ code: "custom", path: ["imageMediaId"], message: "اختر صورة موثقة الحقوق من مكتبة الوسائط." });
    }
  });

export type CreatePartyQuestionInput = z.infer<typeof createPartyQuestionSchema>;

export function toCreatePartyQuestionRpcParams(input: CreatePartyQuestionInput) {
  return {
    p_question_text: input.questionText,
    p_question_format: input.questionFormat,
    p_category_id: input.categoryId,
    p_difficulty: input.difficulty,
    p_correct_answer: input.correctAnswer,
    p_alternative_answers: input.alternativeAnswers,
    p_options: input.options,
    p_correct_position: input.correctOptionPosition,
    p_point_value: input.pointValue,
    p_explanation: input.explanation || null,
    p_source_url: input.sourceUrl || null,
    p_source_name: input.sourceName || null,
    p_season: input.season || null,
    p_image_url: input.imageUrl || null,
    p_media_rights_status: input.mediaRightsStatus,
  };
}
