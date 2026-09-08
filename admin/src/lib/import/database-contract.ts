import type { ProcessedImportRow } from "@/lib/import/types";

export function toImportRowDatabaseContract(row: ProcessedImportRow) {
  return {
    question_text: row.questionText,
    question_type: row.imageUrl ? "image" : "text",
    question_format: row.questionFormat ?? (row.imageUrl ? "image" : "multiple_choice"),
    options: row.options,
    correct_answer: row.correctAnswer,
    correct_option_position: row.correctOptionIndex + 1,
    image_url: row.imageUrl,
    point_value: row.pointValue ?? 200,
    explanation: row.explanation ?? null,
    alternative_answers: row.alternativeAnswers ?? [],
    source_name: row.sourceName ?? null,
    source_url: row.sourceUrl ?? null,
    question_status: row.questionStatus ?? "draft",
    media_rights_status: row.mediaRightsStatus ?? "unverified",
    normalized_text: row.normalizedText,
    content_hash: row.contentHash,
    category_id: row.classification.categoryId,
    subcategory_id: row.classification.subcategoryId,
    difficulty: row.classification.difficulty,
    tags: row.classification.tags,
    season: row.classification.season,
    club: row.classification.club,
    player: row.classification.player,
    competition: row.classification.competition,
    country: row.classification.country,
    suitable_modes: row.classification.suitableModes,
    needs_review: row.classification.needsReview,
  };
}

type CommitImportResult = {
  status?: unknown;
  error?: unknown;
  sqlstate?: unknown;
};

export function assertCommittedImportResult(value: unknown): asserts value is CommitImportResult {
  if (!value || typeof value !== "object") {
    throw new Error("أعاد الخادم نتيجة استيراد غير صالحة.");
  }

  const result = value as CommitImportResult;
  if (result.status !== "completed") {
    const detail = typeof result.error === "string" ? result.error : "تعذر تثبيت دفعة الاستيراد.";
    throw new Error(detail);
  }
}
