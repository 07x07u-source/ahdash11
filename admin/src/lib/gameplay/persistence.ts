import { PARTY_CATEGORY_COUNT, PARTY_HELPERS_PER_TEAM, PARTY_QUESTIONS_PER_CATEGORY } from "./contracts";
import { type PartySession, partyQuestions, validatePartyHelpers, validatePartyTeams } from "./party-engine";

export const PARTY_SESSION_STORAGE_KEY = "ahdash11:party-session:v1";
export const SOLO_PERSONAL_BEST_KEY = "ahdash11:solo-personal-best:v1";

function finite(value: unknown) {
  return typeof value === "number" && Number.isFinite(value);
}

export function isValidPartySession(value: unknown): value is PartySession {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  const session = value as PartySession;
  if (session.version !== 1 || !session.id || !finite(session.createdAt)) return false;
  if (!Array.isArray(session.teams) || session.teams.length !== 2 || validatePartyTeams(session.teams)) return false;
  if (!Array.isArray(session.helpers) || validatePartyHelpers(session.teams, session.helpers)) return false;
  if (session.teams.some((team) => team.selectedHelpers.length !== PARTY_HELPERS_PER_TEAM || team.usedHelpers.some((helper) => !team.selectedHelpers.includes(helper)))) return false;
  if (!Array.isArray(session.categories) || session.categories.length !== PARTY_CATEGORY_COUNT) return false;
  if (new Set(session.categories.map((category) => category.id)).size !== PARTY_CATEGORY_COUNT) return false;
  if (session.categories.some((category) => !Array.isArray(category.questions) || category.questions.length !== PARTY_QUESTIONS_PER_CATEGORY)) return false;
  const questions = session.categories.flatMap((category) => category.questions);
  if (questions.length !== 36 || new Set(questions.map((question) => question.id)).size !== 36) return false;
  if (questions.some((question) => !question.id || !question.categoryId || !question.text || !question.correctAnswer || !finite(question.pointValue) || typeof question.used !== "boolean")) return false;
  if (!Array.isArray(session.scores) || session.scores.length !== 2 || session.scores.some((score) => !finite(score))) return false;
  if (session.turnTeamIndex !== 0 && session.turnTeamIndex !== 1) return false;
  if (session.answeringTeamIndex !== 0 && session.answeringTeamIndex !== 1) return false;
  if (!["board", "answering", "steal", "revealed", "result"].includes(session.phase)) return false;
  if (!["primary", "steal", "pass"].includes(session.answerContext)) return false;
  if ((session.phase === "answering" || session.phase === "steal" || session.phase === "revealed") && !partyQuestions(session).some((question) => question.id === session.activeQuestionId && !question.used)) return false;
  if ((session.phase === "board" || session.phase === "result") && session.activeQuestionId !== null) return false;
  if (session.phase === "result" && !questions.every((question) => question.used)) return false;
  if (!session.rules || !finite(session.rules.primaryAnswerSeconds) || !finite(session.rules.stealSeconds)) return false;
  if (!Array.isArray(session.scoreEvents) || session.scoreEvents.some((event) => !event.questionId || !Array.isArray(event.teamDeltas) || event.teamDeltas.length !== 2 || event.teamDeltas.some((delta) => !finite(delta)))) return false;
  return true;
}

export function serializePartySession(session: PartySession) {
  if (!isValidPartySession(session)) throw new Error("Invalid Party session");
  return JSON.stringify(session);
}

export function deserializePartySession(source: string | null): PartySession | null {
  if (!source) return null;
  try {
    const value: unknown = JSON.parse(source);
    return isValidPartySession(value) ? value : null;
  } catch {
    return null;
  }
}

export function readPartySession(storage: Pick<Storage, "getItem"> = window.localStorage) {
  try {
    return deserializePartySession(storage.getItem(PARTY_SESSION_STORAGE_KEY));
  } catch {
    return null;
  }
}

export function writePartySession(session: PartySession, storage: Pick<Storage, "setItem"> = window.localStorage) {
  try {
    storage.setItem(PARTY_SESSION_STORAGE_KEY, serializePartySession(session));
    return true;
  } catch {
    return false;
  }
}

export function clearPartySession(storage: Pick<Storage, "removeItem"> = window.localStorage) {
  try {
    storage.removeItem(PARTY_SESSION_STORAGE_KEY);
  } catch {
    // Private browsing may deny local storage; gameplay remains in memory.
  }
}

export function readSoloPersonalBest(storage: Pick<Storage, "getItem"> = window.localStorage) {
  try {
    const value = Number(storage.getItem(SOLO_PERSONAL_BEST_KEY));
    return Number.isFinite(value) && value >= 0 ? Math.trunc(value) : 0;
  } catch {
    return 0;
  }
}

export function writeSoloPersonalBest(score: number, storage: Pick<Storage, "setItem"> = window.localStorage) {
  const safe = Math.max(0, Math.trunc(score));
  try {
    storage.setItem(SOLO_PERSONAL_BEST_KEY, String(safe));
  } catch {
    // A result remains valid when persistence is unavailable.
  }
  return safe;
}
