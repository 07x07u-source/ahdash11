export const PARTY_CATEGORY_COUNT = 6;
export const PARTY_QUESTIONS_PER_CATEGORY = 6;
export const PARTY_HELPERS_PER_TEAM = 3;
export const PARTY_POINT_VALUES = [100, 200, 300] as const;

export type GameplayDifficulty = "easy" | "medium" | "hard" | "expert";
export type GameplayQuestionFormat =
  | "open_answer"
  | "multiple_choice"
  | "true_false"
  | "image"
  | "image_crop"
  | "image_blur";

export type GameplayCategory = {
  id: string;
  name: string;
  description: string;
  imageUrl: string | null;
  focalX: number;
  focalY: number;
  accessTier: string;
  freeRotation: boolean;
  featured: boolean;
  ready: boolean;
  questionCount: number;
};

export type GameplayQuestion = {
  id: string;
  categoryId: string;
  text: string;
  format: GameplayQuestionFormat;
  difficulty: GameplayDifficulty;
  pointValue: number;
  options: string[];
  correctOptionIndex: number;
  correctAnswer: string;
  alternativeAnswers: string[];
  explanation: string | null;
  imageUrl: string | null;
  gameplayType: "classic" | "true-false";
};

export type PartyHelperId = "two_chances" | "call_friend" | "risk" | "bench" | "pass";
export type PartyHelperTiming = "before_question" | "after_question";

export type PartyHelperDefinition = {
  id: PartyHelperId;
  name: string;
  description: string;
  timing: PartyHelperTiming;
  callFriendSeconds: number | null;
  correctMultiplier: number | null;
  wrongMultiplier: number | null;
};

export type PartyRules = {
  primaryAnswerSeconds: number;
  stealSeconds: number;
  allowSteal: boolean;
  incorrectPenalty: number;
  stealRewardMultiplier: number;
  stealWrongPenaltyMultiplier: number;
  pitOpponentPenaltyMultiplier: number;
  trapCorrectRewardMultiplier: number;
  trapWrongPenaltyMultiplier: number;
  callFriendSeconds: number;
};

export const defaultPartyRules: PartyRules = {
  primaryAnswerSeconds: 60,
  stealSeconds: 10,
  allowSteal: true,
  incorrectPenalty: 0,
  stealRewardMultiplier: 1,
  stealWrongPenaltyMultiplier: 0,
  pitOpponentPenaltyMultiplier: -1,
  trapCorrectRewardMultiplier: 1,
  trapWrongPenaltyMultiplier: -1,
  callFriendSeconds: 20,
};

export const defaultPartyHelpers: PartyHelperDefinition[] = [
  { id: "two_chances", name: "جاوب جوابين", description: "قولوا إجابتين بدل إجابة واحدة", timing: "after_question", callFriendSeconds: null, correctMultiplier: null, wrongMultiplier: null },
  { id: "call_friend", name: "اتصال بصديق", description: "مؤقت مستقل للاستعانة بصديق محلياً", timing: "after_question", callFriendSeconds: 20, correctMultiplier: null, wrongMultiplier: null },
  { id: "risk", name: "الحفرة", description: "الصواب يضغط على رصيد الخصم والخطأ يُحاسب فريقك", timing: "before_question", callFriendSeconds: null, correctMultiplier: 1, wrongMultiplier: 0 },
  { id: "bench", name: "استريح", description: "اختاروا لاعباً من الخصم ليخرج من السؤال", timing: "after_question", callFriendSeconds: null, correctMultiplier: null, wrongMultiplier: null },
  { id: "pass", name: "الفخ", description: "مرّروا السؤال للخصم؛ الخطأ يخصم منه", timing: "after_question", callFriendSeconds: null, correctMultiplier: null, wrongMultiplier: -1 },
];

const supportedFormats = new Set<GameplayQuestionFormat>([
  "open_answer",
  "multiple_choice",
  "true_false",
  "image",
  "image_crop",
  "image_blur",
]);

function text(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function finiteNumber(value: unknown, fallback: number) {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function stringList(value: unknown) {
  return Array.isArray(value) ? value.filter((item): item is string => typeof item === "string").map((item) => item.trim()).filter(Boolean) : [];
}

function record(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value) ? value as Record<string, unknown> : {};
}

export function parseGameplayCategory(row: Record<string, unknown>, health?: Record<string, unknown>): GameplayCategory | null {
  const id = text(row.id);
  const name = text(row.name_ar ?? row.name);
  if (!id || !name) return null;
  const easy = finiteNumber(health?.easy_count, 0);
  const medium = finiteNumber(health?.medium_count, 0);
  const hard = finiteNumber(health?.hard_count, 0);
  return {
    id,
    name,
    description: text(row.description_ar ?? row.description),
    imageUrl: text(row.image_url) || null,
    focalX: Math.min(1, Math.max(0, finiteNumber(row.cover_focal_x, 0.5))),
    focalY: Math.min(1, Math.max(0, finiteNumber(row.cover_focal_y, 0.5))),
    accessTier: text(row.access_tier) || "free",
    freeRotation: row.is_free_rotation === true,
    featured: row.is_featured === true,
    ready: easy >= 2 && medium >= 2 && hard >= 2,
    questionCount: easy + medium + hard,
  };
}

export function parseGameplayQuestion(row: Record<string, unknown>): GameplayQuestion | null {
  const id = text(row.id);
  const categoryId = text(row.category_id);
  const questionText = text(row.question_text);
  const rawFormat = text(row.question_format) || (text(row.question_type) === "image" ? "image" : "multiple_choice");
  if (!supportedFormats.has(rawFormat as GameplayQuestionFormat)) return null;
  const format = rawFormat as GameplayQuestionFormat;
  const difficultyValue = text(row.difficulty);
  const difficulty: GameplayDifficulty = difficultyValue === "easy" || difficultyValue === "medium" || difficultyValue === "hard" || difficultyValue === "expert" ? difficultyValue : "medium";
  const options = stringList(row.options);
  const correctOptionIndex = Math.trunc(finiteNumber(row.correct_option_index, 0));
  const correctAnswer = text(row.correct_answer) || options[correctOptionIndex] || "";
  const gameplayValue = text(row.gameplay_type ?? row.game_type);
  const gameplayType = gameplayValue === "true-false" ? "true-false" : "classic";
  if (!id || !categoryId || !questionText || !correctAnswer) return null;
  if ((format === "multiple_choice" || format === "true_false") && (options.length < 2 || correctOptionIndex < 0 || correctOptionIndex >= options.length)) return null;
  return {
    id,
    categoryId,
    text: questionText,
    format,
    difficulty,
    pointValue: difficulty === "easy" ? 100 : difficulty === "medium" ? 200 : 300,
    options,
    correctOptionIndex,
    correctAnswer,
    alternativeAnswers: stringList(row.alternative_answers),
    explanation: text(row.explanation) || null,
    imageUrl: text(row.image_url) || null,
    gameplayType,
  };
}

export function parsePartyHelper(row: Record<string, unknown>): PartyHelperDefinition | null {
  const id = text(row.id) as PartyHelperId;
  if (!defaultPartyHelpers.some((helper) => helper.id === id)) return null;
  const fallback = defaultPartyHelpers.find((helper) => helper.id === id)!;
  const config = record(row.rule_config);
  return {
    id,
    name: text(row.name_ar) || fallback.name,
    description: text(row.description_ar) || fallback.description,
    timing: row.timing === "before_question" ? "before_question" : "after_question",
    callFriendSeconds: id === "call_friend" ? finiteNumber(config.seconds, fallback.callFriendSeconds ?? 20) : null,
    correctMultiplier: id === "risk" ? finiteNumber(config.correct_multiplier, fallback.correctMultiplier ?? 1) : null,
    wrongMultiplier: id === "risk" || id === "pass" ? finiteNumber(config.wrong_multiplier, fallback.wrongMultiplier ?? 0) : null,
  };
}

export function parsePartyRules(value: unknown): PartyRules {
  const source = typeof value === "string" ? (() => { try { return record(JSON.parse(value)); } catch { return {}; } })() : record(value);
  const positive = (key: keyof PartyRules, fallback: number) => Math.max(1, Math.trunc(finiteNumber(source[key], fallback)));
  const integer = (key: keyof PartyRules, fallback: number) => Math.trunc(finiteNumber(source[key], fallback));
  return {
    primaryAnswerSeconds: positive("primaryAnswerSeconds", finiteNumber(source.primary_answer_seconds, defaultPartyRules.primaryAnswerSeconds)),
    stealSeconds: positive("stealSeconds", finiteNumber(source.steal_seconds, defaultPartyRules.stealSeconds)),
    allowSteal: source.allow_steal === undefined ? defaultPartyRules.allowSteal : source.allow_steal === true,
    incorrectPenalty: integer("incorrectPenalty", finiteNumber(source.incorrect_penalty, defaultPartyRules.incorrectPenalty)),
    stealRewardMultiplier: integer("stealRewardMultiplier", finiteNumber(source.steal_reward_multiplier, defaultPartyRules.stealRewardMultiplier)),
    stealWrongPenaltyMultiplier: integer("stealWrongPenaltyMultiplier", finiteNumber(source.steal_wrong_penalty_multiplier, defaultPartyRules.stealWrongPenaltyMultiplier)),
    pitOpponentPenaltyMultiplier: integer("pitOpponentPenaltyMultiplier", finiteNumber(source.pit_opponent_penalty_multiplier, defaultPartyRules.pitOpponentPenaltyMultiplier)),
    trapCorrectRewardMultiplier: integer("trapCorrectRewardMultiplier", finiteNumber(source.trap_correct_reward_multiplier, defaultPartyRules.trapCorrectRewardMultiplier)),
    trapWrongPenaltyMultiplier: integer("trapWrongPenaltyMultiplier", finiteNumber(source.trap_wrong_penalty_multiplier, defaultPartyRules.trapWrongPenaltyMultiplier)),
    callFriendSeconds: positive("callFriendSeconds", finiteNumber(source.call_friend_seconds, defaultPartyRules.callFriendSeconds)),
  };
}
