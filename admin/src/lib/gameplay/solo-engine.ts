import { type GameplayDifficulty, type GameplayQuestion } from "./contracts";

export type SoloSetup = {
  categoryIds: string[];
  difficulty: GameplayDifficulty;
  questionCount: number;
};

export type SoloAnswerRecord = {
  questionId: string;
  selectedIndex: number | null;
  correct: boolean;
  basePoints: number;
  speedBonus: number;
  responseTimeMs: number;
};

export type SoloSession = {
  version: 1;
  setup: SoloSetup;
  questions: GameplayQuestion[];
  currentIndex: number;
  phase: "answering" | "revealed" | "result";
  score: number;
  selectedIndex: number | null;
  records: SoloAnswerRecord[];
  questionStartedAt: number | null;
  timerSeconds: number;
  personalBest: number;
};

export class SoloPackError extends Error {}

export function createSoloSession(questions: readonly GameplayQuestion[], setup: SoloSetup, personalBest = 0, now = Date.now()): SoloSession {
  if (!setup.categoryIds.length) throw new SoloPackError("اختر فئة واحدة على الأقل.");
  if (!Number.isInteger(setup.questionCount) || setup.questionCount < 1 || setup.questionCount > 25) throw new SoloPackError("عدد الأسئلة غير صالح.");
  const eligible = questions.filter((question) => setup.categoryIds.includes(question.categoryId) && question.difficulty === setup.difficulty && question.gameplayType === "classic");
  const unique = [...new Map(eligible.map((question) => [question.id, question])).values()];
  if (unique.length < setup.questionCount) throw new SoloPackError("لا توجد أسئلة كافية لهذه الإعدادات.");
  return {
    version: 1,
    setup: { ...setup, categoryIds: [...new Set(setup.categoryIds)] },
    questions: unique.slice(0, setup.questionCount),
    currentIndex: 0,
    phase: "answering",
    score: 0,
    selectedIndex: null,
    records: [],
    questionStartedAt: now,
    timerSeconds: 15,
    personalBest: Math.max(0, Math.trunc(personalBest)),
  };
}

export function currentSoloQuestion(session: SoloSession) {
  return session.questions[session.currentIndex] ?? null;
}

export function answerSoloQuestion(session: SoloSession, selectedIndex: number | null, now = Date.now()): SoloSession {
  const question = currentSoloQuestion(session);
  if (session.phase !== "answering" || !question || session.questionStartedAt === null) return session;
  const responseTimeMs = Math.max(0, now - session.questionStartedAt);
  const correct = selectedIndex !== null && selectedIndex === question.correctOptionIndex;
  const remainingRatio = Math.max(0, Math.min(1, 1 - responseTimeMs / (session.timerSeconds * 1000)));
  const basePoints = correct ? 100 : 0;
  const speedBonus = correct ? Math.round(50 * remainingRatio) : 0;
  const record: SoloAnswerRecord = { questionId: question.id, selectedIndex, correct, basePoints, speedBonus, responseTimeMs };
  return {
    ...session,
    phase: "revealed",
    score: session.score + basePoints + speedBonus,
    selectedIndex,
    records: [...session.records, record],
    questionStartedAt: null,
  };
}

export function expireSoloTimer(session: SoloSession, now = Date.now()) {
  if (session.phase !== "answering" || session.questionStartedAt === null || now < session.questionStartedAt + session.timerSeconds * 1000) return session;
  return answerSoloQuestion(session, null, now);
}

export function advanceSoloQuestion(session: SoloSession, now = Date.now()): SoloSession {
  if (session.phase !== "revealed") return session;
  if (session.currentIndex + 1 >= session.questions.length) return { ...session, phase: "result", personalBest: Math.max(session.personalBest, session.score) };
  return { ...session, currentIndex: session.currentIndex + 1, phase: "answering", selectedIndex: null, questionStartedAt: now };
}

export function soloAccuracy(session: SoloSession) {
  if (!session.records.length) return 0;
  return session.records.filter((record) => record.correct).length / session.records.length;
}

export function soloLongestStreak(session: SoloSession) {
  let current = 0;
  let best = 0;
  for (const record of session.records) {
    current = record.correct ? current + 1 : 0;
    best = Math.max(best, current);
  }
  return best;
}
