export type QuestionDifficulty = "easy" | "medium" | "hard" | "expert";
export type MatchMode = "solo" | "quick_1v1" | "friend_1v1" | "team_2v2";
export type ImportRowStatus = "valid" | "invalid" | "needs_review" | "duplicate" | "skipped";

export interface RawQuestionRow {
  [key: string]: unknown;
}

export interface CategoryDescriptor {
  id: string;
  slug: string;
  name: string;
  parentId: string | null;
  keywords: string[];
}

export interface ExistingQuestion {
  id: string;
  text: string;
  normalizedText?: string | null;
}

export interface SimilarQuestion {
  id: string;
  text: string;
  score: number;
  source: "database" | "current_file";
}

export interface ClassificationResult {
  categoryId: string | null;
  categoryName: string;
  subcategoryId: string | null;
  subcategoryName: string | null;
  confidence: number;
  reason: string;
  difficulty: QuestionDifficulty;
  tags: string[];
  season: string | null;
  club: string | null;
  player: string | null;
  competition: string | null;
  country: string | null;
  suitableModes: MatchMode[];
  needsReview: boolean;
}

export interface ProcessedImportRow {
  clientId: string;
  rowNumber: number;
  raw: RawQuestionRow;
  questionText: string;
  options: [string, string, string, string];
  correctAnswer: string;
  correctOptionIndex: number;
  imageUrl: string | null;
  questionFormat?: "open_answer" | "multiple_choice" | "true_false" | "image";
  pointValue?: 100 | 200 | 300;
  explanation?: string | null;
  alternativeAnswers?: string[];
  sourceName?: string | null;
  sourceUrl?: string | null;
  questionStatus?: "draft" | "review" | "published";
  mediaRightsStatus?: "unverified" | "original" | "generated" | "licensed";
  normalizedText: string;
  contentHash: string;
  status: ImportRowStatus;
  errors: string[];
  warnings: string[];
  classification: ClassificationResult;
  duplicateQuestionId: string | null;
  similarQuestions: SimilarQuestion[];
}

export interface ImportSummary {
  total: number;
  valid: number;
  invalid: number;
  review: number;
  duplicate: number;
}

export interface ParseImportResponse {
  batchId: string;
  filename: string;
  sourceType: "csv" | "xlsx";
  developmentFallback: boolean;
  rows: ProcessedImportRow[];
  categories: CategoryDescriptor[];
  summary: ImportSummary;
}
