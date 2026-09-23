import {
  PARTY_CATEGORY_COUNT,
  PARTY_HELPERS_PER_TEAM,
  PARTY_QUESTIONS_PER_CATEGORY,
  type GameplayCategory,
  type GameplayQuestion,
  type PartyHelperDefinition,
  type PartyHelperId,
  type PartyRules,
} from "./contracts";

export type TeamIndex = 0 | 1;
export type PartyPhase = "board" | "answering" | "steal" | "revealed" | "result";
export type PartyAnswerContext = "primary" | "steal" | "pass";

export type PartyTeam = {
  name: string;
  players: string[];
  selectedHelpers: PartyHelperId[];
  usedHelpers: PartyHelperId[];
};

export type PartyBoardQuestion = GameplayQuestion & { used: boolean };
export type PartyBoardCategory = GameplayCategory & {
  ownerTeamIndex: TeamIndex;
  questions: PartyBoardQuestion[];
};

export type PartyScoreEvent = {
  questionId: string;
  teamDeltas: [number, number];
  previousTurn: TeamIndex;
  createdAt: number;
};

export type PartySession = {
  version: 1;
  id: string;
  createdAt: number;
  teams: [PartyTeam, PartyTeam];
  categories: PartyBoardCategory[];
  helpers: PartyHelperDefinition[];
  rules: PartyRules;
  timerSeconds: number | null;
  scores: [number, number];
  turnTeamIndex: TeamIndex;
  answeringTeamIndex: TeamIndex;
  phase: PartyPhase;
  answerContext: PartyAnswerContext;
  activeQuestionId: string | null;
  timerStartedAt: number | null;
  timerDurationSeconds: number | null;
  armedHelper: PartyHelperId | null;
  helperDetail: string | null;
  scoreEvents: PartyScoreEvent[];
  completedAt: number | null;
};

export class PartyPackError extends Error {}

function normalizeName(value: string) {
  return value.trim().replace(/\s+/g, " ");
}

export function validatePartyTeams(teams: readonly PartyTeam[]) {
  if (teams.length !== 2 || teams.some((team) => !normalizeName(team.name))) return "اكتب اسماً واضحاً لكل فريق.";
  if (teams.some((team) => [...normalizeName(team.name)].length > 24)) return "اسم الفريق يجب ألا يتجاوز 24 حرفاً.";
  if (normalizeName(teams[0].name).toLocaleLowerCase("ar") === normalizeName(teams[1].name).toLocaleLowerCase("ar")) return "اختر اسمين مختلفين للفريقين.";
  return null;
}

export function normalizePlayers(values: readonly string[]) {
  return values.map(normalizeName).filter(Boolean);
}

export function validatePlayerNames(values: readonly string[]) {
  const players = normalizePlayers(values);
  if (players.length < 2) return "أضف لاعبين اثنين على الأقل.";
  if (new Set(players.map((name) => name.toLocaleLowerCase("ar"))).size !== players.length) return "كل لاعب يجب أن يظهر مرة واحدة فقط.";
  return null;
}

function random(seed: number) {
  let value = seed >>> 0;
  return () => {
    value += 0x6d2b79f5;
    let result = value;
    result = Math.imul(result ^ result >>> 15, result | 1);
    result ^= result + Math.imul(result ^ result >>> 7, result | 61);
    return ((result ^ result >>> 14) >>> 0) / 4294967296;
  };
}

function shuffled<T>(values: readonly T[], seed: number) {
  const result = [...values];
  const next = random(seed);
  for (let index = result.length - 1; index > 0; index -= 1) {
    const target = Math.floor(next() * (index + 1));
    [result[index], result[target]] = [result[target], result[index]];
  }
  return result;
}

export function splitPartyPlayers(values: readonly string[], seed = Date.now()): [string[], string[]] {
  const validation = validatePlayerNames(values);
  if (validation) throw new PartyPackError(validation);
  const players = shuffled(normalizePlayers(values), seed);
  const teams: [string[], string[]] = [[], []];
  players.forEach((player, index) => teams[index % 2].push(player));
  return teams;
}

export function togglePartyCategory(selected: readonly string[], categoryId: string) {
  if (selected.includes(categoryId)) return selected.filter((id) => id !== categoryId);
  if (selected.length >= PARTY_CATEGORY_COUNT) return [...selected];
  return [...selected, categoryId];
}

function tier(question: GameplayQuestion) {
  return question.difficulty === "expert" ? "hard" : question.difficulty;
}

export function buildPartyBoard(categories: readonly GameplayCategory[], questions: readonly GameplayQuestion[], seed = Date.now()): PartyBoardCategory[] {
  if (categories.length !== PARTY_CATEGORY_COUNT || new Set(categories.map((category) => category.id)).size !== PARTY_CATEGORY_COUNT) {
    throw new PartyPackError("اختر 6 فئات مختلفة بالضبط.");
  }
  const usedIds = new Set<string>();
  const board = categories.map((category, categoryIndex) => {
    const selected: GameplayQuestion[] = [];
    for (const difficulty of ["easy", "medium", "hard"] as const) {
      const candidates = shuffled(
        questions.filter((question) => question.categoryId === category.id && tier(question) === difficulty && !usedIds.has(question.id)),
        seed + categoryIndex * 31 + difficulty.length,
      );
      if (candidates.length < 2) throw new PartyPackError(`فئة ${category.name} لا تملك سؤالين صالحين من مستوى ${difficulty}.`);
      for (const question of candidates.slice(0, 2)) {
        selected.push(question);
        usedIds.add(question.id);
      }
    }
    return {
      ...category,
      ownerTeamIndex: categoryIndex < PARTY_CATEGORY_COUNT / 2 ? 0 as const : 1 as const,
      questions: selected.map((question) => ({ ...question, used: false })),
    };
  });
  if (usedIds.size !== PARTY_CATEGORY_COUNT * PARTY_QUESTIONS_PER_CATEGORY) throw new PartyPackError("تعذر إنشاء 36 سؤالاً فريداً.");
  return board;
}

export function validatePartyHelpers(teams: readonly PartyTeam[], helpers: readonly PartyHelperDefinition[]) {
  const active = new Set(helpers.map((helper) => helper.id));
  if (teams.some((team) => team.selectedHelpers.length !== PARTY_HELPERS_PER_TEAM || new Set(team.selectedHelpers).size !== PARTY_HELPERS_PER_TEAM)) return "اختر 3 مساعدات مختلفة لكل فريق.";
  if (teams.some((team) => team.selectedHelpers.some((helper) => !active.has(helper)))) return "إحدى المساعدات المختارة غير متاحة.";
  for (let index = 0; index < 2; index += 1) {
    if (teams[index].selectedHelpers.includes("bench") && teams[1 - index].players.length === 0) return "مساعدة «استريح» تحتاج إلى لاعب في الفريق الخصم.";
  }
  return null;
}

export function createPartySession(input: {
  categories: readonly GameplayCategory[];
  questions: readonly GameplayQuestion[];
  teams: [PartyTeam, PartyTeam];
  helpers: PartyHelperDefinition[];
  rules: PartyRules;
  timerSeconds: number | null;
  seed?: number;
  now?: number;
}): PartySession {
  const teamError = validatePartyTeams(input.teams);
  if (teamError) throw new PartyPackError(teamError);
  const helperError = validatePartyHelpers(input.teams, input.helpers);
  if (helperError) throw new PartyPackError(helperError);
  const now = input.now ?? Date.now();
  return {
    version: 1,
    id: globalThis.crypto?.randomUUID?.() ?? `party-${now}`,
    createdAt: now,
    teams: input.teams.map((team) => ({ ...team, name: normalizeName(team.name), players: normalizePlayers(team.players), usedHelpers: [] })) as unknown as [PartyTeam, PartyTeam],
    categories: buildPartyBoard(input.categories, input.questions, input.seed ?? now),
    helpers: input.helpers,
    rules: input.rules,
    timerSeconds: input.timerSeconds,
    scores: [0, 0],
    turnTeamIndex: 0,
    answeringTeamIndex: 0,
    phase: "board",
    answerContext: "primary",
    activeQuestionId: null,
    timerStartedAt: null,
    timerDurationSeconds: null,
    armedHelper: null,
    helperDetail: null,
    scoreEvents: [],
    completedAt: null,
  };
}

export function partyQuestions(session: PartySession) {
  return session.categories.flatMap((category) => category.questions);
}

export function activePartyQuestion(session: PartySession) {
  return session.activeQuestionId ? partyQuestions(session).find((question) => question.id === session.activeQuestionId) ?? null : null;
}

export function canUsePartyHelper(session: PartySession, helperId: PartyHelperId) {
  if (session.phase === "result" || session.armedHelper) return false;
  const team = session.teams[session.turnTeamIndex];
  const helper = session.helpers.find((item) => item.id === helperId);
  if (!helper || !team.selectedHelpers.includes(helperId) || team.usedHelpers.includes(helperId)) return false;
  const correctTiming = helper.timing === "before_question" ? session.phase === "board" : session.phase === "answering";
  if (!correctTiming) return false;
  return helperId !== "bench" || session.teams[1 - session.turnTeamIndex].players.length > 0;
}

export function usePartyHelper(session: PartySession, helperId: PartyHelperId, detail: string | null, now = Date.now()): PartySession {
  if (!canUsePartyHelper(session, helperId)) return session;
  const teams = session.teams.map((team, index) => index === session.turnTeamIndex ? { ...team, usedHelpers: [...team.usedHelpers, helperId] } : team) as [PartyTeam, PartyTeam];
  const helper = session.helpers.find((item) => item.id === helperId)!;
  const pass = helperId === "pass";
  const call = helperId === "call_friend";
  return {
    ...session,
    teams,
    armedHelper: helperId,
    helperDetail: detail,
    answeringTeamIndex: pass ? (1 - session.turnTeamIndex) as TeamIndex : session.answeringTeamIndex,
    answerContext: pass ? "pass" : session.answerContext,
    timerStartedAt: call ? now : session.timerStartedAt,
    timerDurationSeconds: call ? helper.callFriendSeconds ?? session.rules.callFriendSeconds : session.timerDurationSeconds,
  };
}

export function choosePartyQuestion(session: PartySession, questionId: string, now = Date.now()): PartySession {
  if (session.phase !== "board") return session;
  const question = partyQuestions(session).find((item) => item.id === questionId);
  if (!question || question.used) return session;
  const pass = session.armedHelper === "pass";
  const call = session.armedHelper === "call_friend";
  const duration = call
    ? session.helpers.find((helper) => helper.id === "call_friend")?.callFriendSeconds ?? session.rules.callFriendSeconds
    : session.timerSeconds;
  return {
    ...session,
    phase: "answering",
    answerContext: pass ? "pass" : "primary",
    activeQuestionId: questionId,
    answeringTeamIndex: pass ? (1 - session.turnTeamIndex) as TeamIndex : session.turnTeamIndex,
    timerStartedAt: duration === null ? null : now,
    timerDurationSeconds: duration,
  };
}

export function offerPartySteal(session: PartySession, now = Date.now()): PartySession {
  if (session.phase !== "answering" || !session.activeQuestionId || !session.rules.allowSteal || session.answerContext === "pass") return session;
  const opponent = (1 - session.turnTeamIndex) as TeamIndex;
  return {
    ...session,
    phase: "steal",
    answerContext: "steal",
    answeringTeamIndex: opponent,
    helperDetail: `فرصة خطف لـ ${session.teams[opponent].name}`,
    timerStartedAt: now,
    timerDurationSeconds: session.rules.stealSeconds,
  };
}

export function revealPartyAnswer(session: PartySession): PartySession {
  if ((session.phase !== "answering" && session.phase !== "steal") || !session.activeQuestionId) return session;
  return { ...session, phase: "revealed", timerStartedAt: null, timerDurationSeconds: null };
}

export function expirePartyTimer(session: PartySession, now = Date.now()): PartySession {
  if ((session.phase !== "answering" && session.phase !== "steal") || session.timerStartedAt === null || session.timerDurationSeconds === null) return session;
  if (now < session.timerStartedAt + session.timerDurationSeconds * 1000) return session;
  return session.phase === "answering" && session.rules.allowSteal && session.answerContext !== "pass" ? offerPartySteal(session, now) : revealPartyAnswer(session);
}

function scoreDeltas(session: PartySession, awardedTeamIndex: TeamIndex | null): [number, number] {
  const question = activePartyQuestion(session);
  if (!question) return [0, 0];
  const result: [number, number] = [0, 0];
  if (awardedTeamIndex !== null) result[awardedTeamIndex] += question.pointValue;
  else if (session.answerContext === "primary" && session.armedHelper !== "pass") result[session.turnTeamIndex] += session.rules.incorrectPenalty;

  if (session.answerContext === "steal") {
    if (awardedTeamIndex === session.answeringTeamIndex) result[session.answeringTeamIndex] += question.pointValue * (session.rules.stealRewardMultiplier - 1);
    else if (awardedTeamIndex === null) result[session.answeringTeamIndex] += question.pointValue * session.rules.stealWrongPenaltyMultiplier;
  }
  if (session.armedHelper === "risk") {
    const helper = session.helpers.find((item) => item.id === "risk");
    if (awardedTeamIndex === session.turnTeamIndex) result[1 - session.turnTeamIndex] -= question.pointValue * Math.abs(helper?.correctMultiplier ?? Math.abs(session.rules.pitOpponentPenaltyMultiplier));
    else if (awardedTeamIndex === null) result[session.turnTeamIndex] += question.pointValue * (helper?.wrongMultiplier ?? session.rules.incorrectPenalty);
  }
  if (session.armedHelper === "pass") {
    if (awardedTeamIndex === session.answeringTeamIndex) result[session.answeringTeamIndex] += question.pointValue * (session.rules.trapCorrectRewardMultiplier - 1);
    else if (awardedTeamIndex === null) result[session.answeringTeamIndex] += question.pointValue * session.rules.trapWrongPenaltyMultiplier;
  }
  return result;
}

export function scorePartyQuestion(session: PartySession, awardedTeamIndex: TeamIndex | null, now = Date.now()): PartySession {
  const question = activePartyQuestion(session);
  if (session.phase !== "revealed" || !question) return session;
  if ((session.answerContext === "steal" || session.answerContext === "pass") && awardedTeamIndex !== null && awardedTeamIndex !== session.answeringTeamIndex) return session;
  const deltas = scoreDeltas(session, awardedTeamIndex);
  const categories = session.categories.map((category) => ({
    ...category,
    questions: category.questions.map((item) => item.id === question.id ? { ...item, used: true } : item),
  }));
  const complete = categories.flatMap((category) => category.questions).every((item) => item.used);
  const event: PartyScoreEvent = { questionId: question.id, teamDeltas: deltas, previousTurn: session.turnTeamIndex, createdAt: now };
  const nextTurn = (1 - session.turnTeamIndex) as TeamIndex;
  return {
    ...session,
    categories,
    scores: [session.scores[0] + deltas[0], session.scores[1] + deltas[1]],
    turnTeamIndex: nextTurn,
    answeringTeamIndex: nextTurn,
    phase: complete ? "result" : "board",
    answerContext: "primary",
    activeQuestionId: null,
    timerStartedAt: null,
    timerDurationSeconds: null,
    armedHelper: null,
    helperDetail: null,
    scoreEvents: [...session.scoreEvents, event],
    completedAt: complete ? now : null,
  };
}

export function undoPartyScore(session: PartySession): PartySession {
  const event = session.scoreEvents.at(-1);
  if (!event || (session.phase !== "board" && session.phase !== "result")) return session;
  return {
    ...session,
    categories: session.categories.map((category) => ({
      ...category,
      questions: category.questions.map((question) => question.id === event.questionId ? { ...question, used: false } : question),
    })),
    scores: [session.scores[0] - event.teamDeltas[0], session.scores[1] - event.teamDeltas[1]],
    turnTeamIndex: event.previousTurn,
    answeringTeamIndex: event.previousTurn,
    phase: "board",
    completedAt: null,
    scoreEvents: session.scoreEvents.slice(0, -1),
  };
}

export function partyWinner(session: PartySession): TeamIndex | null {
  if (session.scores[0] === session.scores[1]) return null;
  return session.scores[0] > session.scores[1] ? 0 : 1;
}
