import { normalizeArabicText } from "./normalize";
import type { CategoryDescriptor, ClassificationResult, QuestionDifficulty } from "./types";

const FALLBACK_CATEGORIES: CategoryDescriptor[] = [
  { id: "dev-eye", slug: "eagle-eye", name: "عين الصقر", parentId: null, keywords: ["صوره", "شعار", "قميص", "طقم", "تعرف علي النادي", "من اللاعب"] },
  { id: "dev-transfer", slug: "transfers", name: "سوق الانتقالات", parentId: null, keywords: ["انتقال", "انتقل", "النادي السابق", "مسيره", "قيمه الانتقال", "زملاء"] },
  { id: "dev-leagues", slug: "leagues", name: "الدوريات والبطولات", parentId: null, keywords: ["دوري", "بطوله", "كاس العالم", "ابطال اوروبا", "اليورو", "روشن"] },
  { id: "dev-dressing", slug: "dressing-room", name: "غرفة الملابس", parentId: null, keywords: ["مدرب", "تشكيله", "رقم القميص", "تصريح", "غرفه الملابس"] },
  { id: "dev-stadiums", slug: "stadiums", name: "الملاعب", parentId: null, keywords: ["ملعب", "استاد", "سعه", "انفيلد", "كامب نو"] },
  { id: "dev-awards", slug: "awards", name: "الجوائز الفردية", parentId: null, keywords: ["كره ذهبيه", "حذاء ذهبي", "هداف", "جائزه", "افضل لاعب"] },
];

const entityCatalog = {
  clubs: ["الهلال", "النصر", "الاتحاد", "الاهلي", "ليفربول", "ريال مدريد", "برشلونه", "مانشستر سيتي", "مانشستر يونايتد", "بايرن ميونخ", "باريس سان جيرمان"],
  players: ["كريستيانو رونالدو", "رونالدو", "ليونيل ميسي", "ميسي", "سالم الدوسري", "كريم بنزيما", "محمد صلاح", "نيمار", "كيليان مبابي", "مبابي", "ارلينغ هالاند", "هالاند"],
  competitions: ["دوري روشن", "الدوري الانجليزي", "الدوري الاسباني", "الدوري الايطالي", "دوري ابطال اوروبا", "كاس العالم", "اليورو"],
  countries: ["السعوديه", "انجلترا", "اسبانيا", "ايطاليا", "المانيا", "فرنسا", "البرازيل", "الارجنتين"],
};

export function getFallbackCategories(): CategoryDescriptor[] {
  return FALLBACK_CATEGORIES.map((category) => ({ ...category, keywords: [...category.keywords] }));
}

function matchedEntity(normalizedText: string, entities: string[]): string | null {
  return entities.find((entity) => normalizedText.includes(normalizeArabicText(entity))) ?? null;
}

function estimateDifficulty(text: string): QuestionDifficulty {
  const normalized = normalizeArabicText(text);
  const years = normalized.match(/\b(19|20)\d{2}\b/g) ?? [];

  if (/ترتيب مسير|بالترتيب|قيمه انتقال|في اي دقيقه|من سجل اولا/.test(normalized) || years.length >= 2) return "expert";
  if (/في اي عام|اي موسم|كم مره|من كان المدرب|نهائي/.test(normalized) || years.length === 1) return "hard";
  if (/من اللاعب|رقم القميص|اي نادي|من سجل/.test(normalized)) return "medium";
  return "easy";
}

function scoreCategory(category: CategoryDescriptor, text: string, filename: string): { score: number; matches: string[] } {
  const normalizedText = normalizeArabicText(text);
  const normalizedFilename = normalizeArabicText(filename);
  const candidates = [category.name, category.slug, ...category.keywords].map(normalizeArabicText).filter(Boolean);
  const matches = [...new Set(candidates.filter((keyword) => normalizedText.includes(keyword)))];
  const fileMatches = candidates.filter((keyword) => normalizedFilename.includes(keyword)).length;
  return { score: matches.length * 2 + fileMatches, matches };
}

export function classifyQuestion(
  questionText: string,
  filename: string,
  categories: CategoryDescriptor[] = FALLBACK_CATEGORIES,
): ClassificationResult {
  const usableCategories = categories.length ? categories : FALLBACK_CATEGORIES;
  const roots = usableCategories.filter((category) => !category.parentId);
  const rankedRoots = roots
    .map((category) => ({ category, ...scoreCategory(category, questionText, filename) }))
    .sort((left, right) => right.score - left.score);
  const bestRoot = rankedRoots[0];

  const subcategories = bestRoot
    ? usableCategories.filter((category) => category.parentId === bestRoot.category.id)
    : [];
  const bestSubcategory = subcategories
    .map((category) => ({ category, ...scoreCategory(category, questionText, filename) }))
    .sort((left, right) => right.score - left.score)[0];

  const score = bestRoot?.score ?? 0;
  const confidence = score === 0 ? 0.18 : Math.min(0.96, 0.48 + score * 0.11 + (bestSubcategory?.score ? 0.08 : 0));
  const normalized = normalizeArabicText(questionText);
  const club = matchedEntity(normalized, entityCatalog.clubs);
  const player = matchedEntity(normalized, entityCatalog.players);
  const competition = matchedEntity(normalized, entityCatalog.competitions);
  const country = matchedEntity(normalized, entityCatalog.countries);
  const season = normalized.match(/\b(19|20)\d{2}(?:\s*[-/]\s*\d{2,4})?\b/)?.[0] ?? null;
  const tagCandidates = [club, player, competition, country, season].filter((value): value is string => Boolean(value));

  return {
    categoryId: score > 0 ? bestRoot.category.id : null,
    categoryName: score > 0 ? bestRoot.category.name : "غير مصنّف",
    subcategoryId: bestSubcategory?.score ? bestSubcategory.category.id : null,
    subcategoryName: bestSubcategory?.score ? bestSubcategory.category.name : null,
    confidence: Number(confidence.toFixed(2)),
    reason: score > 0 ? `تطابق قواعد: ${bestRoot.matches.slice(0, 3).join("، ") || "اسم الملف"}` : "لم تجد القواعد كلمات دالّة كافية.",
    difficulty: estimateDifficulty(questionText),
    tags: [...new Set(tagCandidates)],
    season,
    club,
    player,
    competition,
    country,
    suitableModes: ["solo", "quick_1v1", "friend_1v1", "team_2v2"],
    needsReview: confidence < 0.6,
  };
}
