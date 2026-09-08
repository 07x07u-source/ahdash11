import { normalizeArabicText, normalizeHeader, stableContentHash } from "./normalize";
import type { RawQuestionRow } from "./types";

const HEADER_ALIASES = {
  question: ["السوال", "question", "question text", "question_text"],
  option1: ["الخيار الاول", "الاجابه الاولي", "option 1", "option1", "option_1"],
  option2: ["الخيار الثاني", "الاجابه الثانيه", "option 2", "option2", "option_2"],
  option3: ["الخيار الثالث", "الاجابه الثالثه", "option 3", "option3", "option_3"],
  option4: ["الخيار الرابع", "الاجابه الرابعه", "option 4", "option4", "option_4"],
  correctAnswer: ["الاجابه الصحيحه", "الجواب الصحيح", "correct answer", "correct_answer", "correct option", "correct_option"],
  image: ["الصوره اختياري", "الصوره", "رابط الصوره", "image optional", "image", "image url", "image_url"],
  category: ["القسم", "الفئه", "التصنيف", "category", "category slug", "category_slug"],
  difficulty: ["الصعوبه", "difficulty", "level"],
  points: ["النقاط", "القيمه", "points", "point value", "point_value"],
  format: ["النوع", "نوع السؤال", "format", "type", "question format", "question_format"],
  explanation: ["الشرح", "معلومه اضافيه", "explanation", "fact"],
  alternatives: ["اجابات بديله", "alternative answers", "alternative_answers"],
  sourceName: ["المصدر", "اسم المصدر", "source", "source name", "source_name"],
  sourceUrl: ["رابط المصدر", "source url", "source_url"],
  season: ["الموسم", "season"],
  status: ["الحاله", "status"],
  mediaRights: ["حقوق الوسائط", "حاله الحقوق", "media rights", "media_rights_status"],
} as const;

type CanonicalHeader = keyof typeof HEADER_ALIASES;

const aliasLookup = new Map<string, CanonicalHeader>();
for (const [canonical, aliases] of Object.entries(HEADER_ALIASES) as [CanonicalHeader, readonly string[]][]) {
  for (const alias of aliases) aliasLookup.set(normalizeHeader(alias), canonical);
}

function canonicalizeRow(raw: RawQuestionRow): Partial<Record<CanonicalHeader, string>> {
  const canonical: Partial<Record<CanonicalHeader, string>> = {};
  for (const [header, value] of Object.entries(raw)) {
    const mapped = aliasLookup.get(normalizeHeader(header));
    if (mapped) canonical[mapped] = String(value ?? "").trim();
  }
  return canonical;
}

export interface ValidatedQuestionRow {
  questionText: string;
  options: [string, string, string, string];
  correctAnswer: string;
  correctOptionIndex: number;
  imageUrl: string | null;
  categoryHint: string | null;
  difficulty: "easy" | "medium" | "hard" | "expert" | null;
  questionFormat: "open_answer" | "multiple_choice" | "true_false" | "image";
  pointValue: 100 | 200 | 300;
  explanation: string | null;
  alternativeAnswers: string[];
  sourceName: string | null;
  sourceUrl: string | null;
  season: string | null;
  questionStatus: "draft" | "review" | "published";
  mediaRightsStatus: "unverified" | "original" | "generated" | "licensed";
  normalizedText: string;
  contentHash: string;
  errors: string[];
  warnings: string[];
}

export function validateQuestionRow(raw: RawQuestionRow): ValidatedQuestionRow {
  const row = canonicalizeRow(raw);
  const questionText = row.question?.trim() ?? "";
  const options = [row.option1 ?? "", row.option2 ?? "", row.option3 ?? "", row.option4 ?? ""] as [string, string, string, string];
  const correctAnswer = row.correctAnswer?.trim() ?? "";
  const imageUrl = row.image?.trim() || null;
  const formatValue = normalizeArabicText(row.format ?? "");
  const questionFormat = parseQuestionFormat(formatValue, Boolean(imageUrl));
  const difficulty = parseDifficulty(normalizeArabicText(row.difficulty ?? ""));
  const rawPoints = Number.parseInt(row.points ?? "", 10);
  const pointValue = ([100, 200, 300] as const).find((value) => value === rawPoints)
    ?? (difficulty === "easy" ? 100 : difficulty === "hard" || difficulty === "expert" ? 300 : 200);
  const questionStatus = parseQuestionStatus(normalizeArabicText(row.status ?? ""));
  const mediaRightsStatus = parseMediaRights(normalizeArabicText(row.mediaRights ?? ""));
  const errors: string[] = [];
  const warnings: string[] = [];

  if (row.format?.trim() && !isKnownQuestionFormat(formatValue)) {
    errors.push("نوع السؤال غير صالح.");
  }
  if (row.difficulty?.trim() && difficulty === null) {
    errors.push("مستوى الصعوبة غير صالح.");
  }
  if (row.sourceUrl?.trim() && !/^https:\/\//i.test(row.sourceUrl.trim())) {
    errors.push("رابط المصدر يجب أن يبدأ بـ https://.");
  }

  if (!questionText) errors.push("السؤال مفقود.");
  else if (normalizeArabicText(questionText).length < 6) warnings.push("نص السؤال قصير جدًا ويستحسن مراجعته.");

  const requiredOptionCount = questionFormat === "multiple_choice" ? 4 : questionFormat === "true_false" ? 2 : 0;
  options.slice(0, requiredOptionCount).forEach((option, index) => {
    if (!option.trim()) errors.push(`الخيار ${index + 1} مفقود.`);
  });

  const normalizedOptions = options.map(normalizeArabicText);
  const populatedOptions = normalizedOptions.slice(0, requiredOptionCount).filter(Boolean);
  if (populatedOptions.length === requiredOptionCount && new Set(populatedOptions).size !== requiredOptionCount) {
    errors.push(requiredOptionCount === 4 ? "يجب أن تكون الخيارات الأربعة مختلفة." : "يجب أن يكون الخياران مختلفين.");
  }
  const allPopulatedOptions = normalizedOptions.filter(Boolean);
  if (requiredOptionCount === 0 && allPopulatedOptions.length !== 0 && allPopulatedOptions.length !== 4) {
    errors.push("الأسئلة المفتوحة والصورية تقبل صفرًا أو أربعة خيارات فقط.");
  }

  if (!correctAnswer) {
    errors.push("الإجابة الصحيحة مفقودة.");
  }

  const normalizedCorrect = normalizeArabicText(correctAnswer);
  const correctMatches = normalizedOptions
    .map((option, index) => ({ option, index }))
    .filter(({ option }) => option && option === normalizedCorrect);

  const needsOptionMatch = requiredOptionCount > 0 || allPopulatedOptions.length === 4;
  if (needsOptionMatch && correctAnswer && correctMatches.filter(({ index }) => requiredOptionCount === 0 || index < requiredOptionCount).length === 0) {
    errors.push("الإجابة الصحيحة ليست ضمن الخيارات الأربعة.");
  } else if (correctMatches.length > 1) {
    errors.push("الإجابة الصحيحة تطابق أكثر من خيار.");
  }

  if (questionFormat === "image" && !imageUrl) {
    errors.push("سؤال الصورة يحتاج مسار وسائط.");
  } else if (imageUrl && !/^(https?:\/\/|\/|[\w\-. ]+\.(png|jpe?g|webp|gif))\S*$/i.test(imageUrl)) {
    errors.push("مسار الوسائط غير صالح أو غير موثّق.");
  }
  if (row.points?.trim() && ![100, 200, 300].includes(rawPoints)) {
    errors.push("قيمة النقاط يجب أن تكون 100 أو 200 أو 300.");
  }
  if (imageUrl && mediaRightsStatus === "unverified") {
    warnings.push("حقوق الوسائط غير موثقة؛ لن يكون السؤال جاهزًا للنشر.");
  }

  const normalizedText = normalizeArabicText(questionText);
  return {
    questionText,
    options,
    correctAnswer,
    correctOptionIndex: correctMatches[0]?.index ?? -1,
    imageUrl,
    categoryHint: row.category?.trim() || null,
    difficulty,
    questionFormat,
    pointValue,
    explanation: row.explanation?.trim() || null,
    alternativeAnswers: (row.alternatives ?? "").split(/[|،,;]/).map((value) => value.trim()).filter(Boolean),
    sourceName: row.sourceName?.trim() || null,
    sourceUrl: row.sourceUrl?.trim() || null,
    season: row.season?.trim() || null,
    questionStatus,
    mediaRightsStatus,
    normalizedText,
    contentHash: stableContentHash(normalizedText),
    errors,
    warnings,
  };
}

function parseQuestionFormat(value: string, hasImage: boolean): ValidatedQuestionRow["questionFormat"] {
  if (["open answer", "open_answer", "مفتوح", "اجابه مفتوحه"].includes(value)) return "open_answer";
  if (["true false", "true_false", "صح خطا", "صح او خطا"].includes(value)) return "true_false";
  if (["image", "صوره"].includes(value) || hasImage) return "image";
  return "multiple_choice";
}

function isKnownQuestionFormat(value: string): boolean {
  return [
    "open answer", "open_answer", "مفتوح", "اجابه مفتوحه",
    "multiple choice", "multiple_choice", "اختيارات", "اختيار من متعدد",
    "true false", "true_false", "صح خطا", "صح او خطا",
    "image", "صوره",
  ].includes(value);
}

function parseDifficulty(value: string): ValidatedQuestionRow["difficulty"] {
  if (["easy", "سهل"].includes(value)) return "easy";
  if (["medium", "متوسط"].includes(value)) return "medium";
  if (["hard", "صعب"].includes(value)) return "hard";
  if (["expert", "خبير"].includes(value)) return "expert";
  return null;
}

function parseQuestionStatus(value: string): ValidatedQuestionRow["questionStatus"] {
  if (["published", "منشور"].includes(value)) return "published";
  if (["review", "مراجعه"].includes(value)) return "review";
  return "draft";
}

function parseMediaRights(value: string): ValidatedQuestionRow["mediaRightsStatus"] {
  if (["original", "اصلي"].includes(value)) return "original";
  if (["generated", "مولد"].includes(value)) return "generated";
  if (["licensed", "مرخص"].includes(value)) return "licensed";
  return "unverified";
}

export function hasRecognizedQuestionHeaders(headers: string[]): boolean {
  const recognized = new Set(headers.map((header) => aliasLookup.get(normalizeHeader(header))).filter(Boolean));
  return recognized.has("question") && recognized.has("option1") && recognized.has("correctAnswer");
}
