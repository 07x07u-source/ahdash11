import { describe, expect, it } from "vitest";
import {
  assertCommittedImportResult,
  toImportRowDatabaseContract,
} from "@/lib/import/database-contract";
import type { ProcessedImportRow } from "@/lib/import/types";

function row(imageUrl: string | null = null): ProcessedImportRow {
  return {
    clientId: "row-2",
    rowNumber: 2,
    raw: {},
    questionText: "من فاز بالمباراة؟",
    options: ["الأول", "الثاني", "الثالث", "الرابع"],
    correctAnswer: "الثاني",
    correctOptionIndex: 1,
    imageUrl,
    normalizedText: "من فاز بالمباراه",
    contentHash: "hash",
    status: "valid",
    errors: [],
    warnings: [],
    classification: {
      categoryId: "category-id",
      categoryName: "الدوري السعودي",
      subcategoryId: null,
      subcategoryName: null,
      confidence: 1,
      reason: "test",
      difficulty: "medium",
      tags: [],
      season: null,
      club: null,
      player: null,
      competition: null,
      country: "السعودية",
      suitableModes: ["solo"],
      needsReview: false,
    },
    duplicateQuestionId: null,
    similarQuestions: [],
  };
}

describe("import database contract", () => {
  it("maps the zero-based UI answer to the one-based PostgreSQL position", () => {
    const value = toImportRowDatabaseContract(row());
    expect(value.question_type).toBe("text");
    expect(value.correct_option_position).toBe(2);
    expect(value).not.toHaveProperty("correct_option_index");
  });

  it("uses the database image type only when image media exists", () => {
    expect(toImportRowDatabaseContract(row("https://example.test/q.webp")).question_type).toBe("image");
  });

  it("maps reviewed Party metadata into normalized import data", () => {
    const input = row();
    input.questionFormat = "open_answer";
    input.pointValue = 300;
    input.explanation = "معلومة موثقة";
    input.sourceUrl = "https://example.test/source";
    input.questionStatus = "review";
    const value = toImportRowDatabaseContract(input);
    expect(value.question_format).toBe("open_answer");
    expect(value.point_value).toBe(300);
    expect(value.question_status).toBe("review");
    expect(value.source_url).toBe("https://example.test/source");
  });

  it("rejects a failed RPC payload instead of reporting success", () => {
    expect(() => assertCommittedImportResult({ status: "failed", error: "invalid enum" })).toThrow(
      "invalid enum",
    );
    expect(() => assertCommittedImportResult({ status: "completed" })).not.toThrow();
  });
});
