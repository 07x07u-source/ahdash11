import { classifyQuestion } from "./classification";
import { normalizeArabicText } from "./normalize";
import { questionSimilarity } from "./similarity";
import { validateQuestionRow } from "./validation";
import type {
  CategoryDescriptor,
  ExistingQuestion,
  ImportSummary,
  ProcessedImportRow,
  RawQuestionRow,
  SimilarQuestion,
} from "./types";

const SIMILARITY_THRESHOLD = 0.72;

export function processImportRows(
  rows: RawQuestionRow[],
  filename: string,
  categories: CategoryDescriptor[],
  existingQuestions: ExistingQuestion[] = [],
): { rows: ProcessedImportRow[]; summary: ImportSummary } {
  const exactExisting = new Map<string, ExistingQuestion>();
  for (const question of existingQuestions) {
    const normalized = question.normalizedText || normalizeArabicText(question.text);
    if (normalized) exactExisting.set(normalized, question);
  }

  const processed: ProcessedImportRow[] = [];
  const seenInFile = new Map<string, ProcessedImportRow>();

  rows.forEach((raw, index) => {
    const validated = validateQuestionRow(raw);
    let classification = classifyQuestion(validated.questionText, filename, categories);
    if (validated.categoryHint) {
      const normalizedHint = normalizeArabicText(validated.categoryHint);
      const explicitCategory = categories.find((category) =>
        category.id === validated.categoryHint
        || normalizeArabicText(category.slug) === normalizedHint
        || normalizeArabicText(category.name) === normalizedHint
      );
      if (explicitCategory) {
        const parent = explicitCategory.parentId
          ? categories.find((category) => category.id === explicitCategory.parentId)
          : explicitCategory;
        classification = {
          ...classification,
          categoryId: parent?.id ?? explicitCategory.id,
          categoryName: parent?.name ?? explicitCategory.name,
          subcategoryId: explicitCategory.parentId ? explicitCategory.id : null,
          subcategoryName: explicitCategory.parentId ? explicitCategory.name : null,
          confidence: 1,
          reason: "explicit_import_category",
          needsReview: false,
        };
      } else {
        validated.errors.push("القسم المحدد غير موجود أو غير صالح.");
      }
    }
    classification = {
      ...classification,
      difficulty: validated.difficulty ?? classification.difficulty,
      season: validated.season ?? classification.season,
    };
    const exactDatabaseMatch = exactExisting.get(validated.normalizedText);
    const exactFileMatch = seenInFile.get(validated.normalizedText);
    const similarQuestions: SimilarQuestion[] = [];

    if (validated.normalizedText && !exactDatabaseMatch && !exactFileMatch) {
      for (const candidate of existingQuestions) {
        const score = questionSimilarity(validated.normalizedText, candidate.normalizedText || candidate.text);
        if (score >= SIMILARITY_THRESHOLD && score < 1) {
          similarQuestions.push({ id: candidate.id, text: candidate.text, score, source: "database" });
        }
      }

      for (const candidate of processed) {
        const score = questionSimilarity(validated.normalizedText, candidate.normalizedText);
        if (score >= SIMILARITY_THRESHOLD && score < 1) {
          similarQuestions.push({ id: candidate.clientId, text: candidate.questionText, score, source: "current_file" });
        }
      }
    }

    similarQuestions.sort((left, right) => right.score - left.score);
    const strongestSimilar = similarQuestions.slice(0, 3);
    const warnings = [...validated.warnings];
    if (strongestSimilar.length) warnings.push(`يوجد سؤال مشابه بنسبة ${Math.round(strongestSimilar[0].score * 100)}٪.`);
    if (exactDatabaseMatch || exactFileMatch) warnings.push("السؤال مكرر حرفيًا.");

    let status: ProcessedImportRow["status"] = "valid";
    if (validated.errors.length) status = "invalid";
    else if (exactDatabaseMatch || exactFileMatch) status = "duplicate";
    else if (classification.needsReview || warnings.length) status = "needs_review";

    const processedRow: ProcessedImportRow = {
      clientId: `row-${index + 2}-${validated.contentHash}`,
      rowNumber: index + 2,
      raw,
      ...validated,
      status,
      warnings,
      classification: {
        ...classification,
        needsReview: status === "needs_review" || classification.needsReview,
      },
      duplicateQuestionId: exactDatabaseMatch?.id ?? null,
      similarQuestions: strongestSimilar,
    };

    processed.push(processedRow);
    if (validated.normalizedText && !seenInFile.has(validated.normalizedText)) {
      seenInFile.set(validated.normalizedText, processedRow);
    }
  });

  return {
    rows: processed,
    summary: {
      total: processed.length,
      valid: processed.filter((row) => row.status === "valid").length,
      invalid: processed.filter((row) => row.status === "invalid").length,
      review: processed.filter((row) => row.status === "needs_review").length,
      duplicate: processed.filter((row) => row.status === "duplicate").length,
    },
  };
}
