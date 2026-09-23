import { describe, expect, it } from "vitest";
import { defaultPartyHelpers, defaultPartyRules, type GameplayCategory, type GameplayQuestion } from "@/lib/gameplay/contracts";
import {
  buildPartyBoard,
  canUsePartyHelper,
  choosePartyQuestion,
  createPartySession,
  expirePartyTimer,
  offerPartySteal,
  partyQuestions,
  partyWinner,
  revealPartyAnswer,
  scorePartyQuestion,
  splitPartyPlayers,
  togglePartyCategory,
  undoPartyScore,
  usePartyHelper,
  validatePartyHelpers,
  validatePartyTeams,
  type PartySession,
  type PartyTeam,
} from "@/lib/gameplay/party-engine";
import { deserializePartySession, isValidPartySession, serializePartySession } from "@/lib/gameplay/persistence";

function categories(): GameplayCategory[] {
  return Array.from({ length: 6 }, (_, index) => ({
    id: `category-${index + 1}`,
    name: `فئة ${index + 1}`,
    description: "",
    imageUrl: null,
    focalX: 0.5,
    focalY: 0.5,
    accessTier: "free",
    freeRotation: false,
    featured: false,
    ready: true,
    questionCount: 6,
  }));
}

function questions(): GameplayQuestion[] {
  return categories().flatMap((category) => (["easy", "medium", "hard"] as const).flatMap((difficulty) =>
    Array.from({ length: 2 }, (_, index) => ({
      id: `${category.id}-${difficulty}-${index}`,
      categoryId: category.id,
      text: `سؤال ${category.id} ${difficulty} ${index}`,
      format: "multiple_choice" as const,
      difficulty,
      pointValue: difficulty === "easy" ? 100 : difficulty === "medium" ? 200 : 300,
      options: ["أ", "ب", "ج", "د"],
      correctOptionIndex: 0,
      correctAnswer: "أ",
      alternativeAnswers: [],
      explanation: null,
      imageUrl: null,
      gameplayType: "classic" as const,
    })),
  ));
}

function teams(): [PartyTeam, PartyTeam] {
  return [
    { name: "المدرج", players: ["سلمان"], selectedHelpers: ["risk", "call_friend", "two_chances"], usedHelpers: [] },
    { name: "الدكة", players: ["خالد"], selectedHelpers: ["pass", "bench", "two_chances"], usedHelpers: [] },
  ];
}

function session(): PartySession {
  return createPartySession({ categories: categories(), questions: questions(), teams: teams(), helpers: defaultPartyHelpers, rules: defaultPartyRules, timerSeconds: 60, seed: 11, now: 1_000 });
}

describe("Party board and setup contracts", () => {
  it("enforces exactly six unique categories and caps category selection", () => {
    const selected = categories().reduce<string[]>((current, category) => togglePartyCategory(current, category.id), []);
    expect(selected).toHaveLength(6);
    expect(togglePartyCategory(selected, "category-7")).toEqual(selected);
    expect(() => buildPartyBoard(categories().slice(0, 5), questions(), 1)).toThrow("6 فئات");
    expect(() => buildPartyBoard([...categories().slice(0, 5), categories()[0]], questions(), 1)).toThrow("6 فئات");
  });

  it("creates a deterministic 6 × 6 board with two questions per tier and unique ids", () => {
    const board = buildPartyBoard(categories(), questions(), 11);
    expect(board).toHaveLength(6);
    expect(board.every((category) => category.questions.length === 6)).toBe(true);
    expect(new Set(board.flatMap((category) => category.questions.map((question) => question.id))).size).toBe(36);
    for (const category of board) {
      expect(category.questions.map((question) => question.pointValue).sort()).toEqual([100, 100, 200, 200, 300, 300]);
    }
    expect(buildPartyBoard(categories(), questions(), 11)).toEqual(board);
  });

  it("rejects an incomplete pack instead of fabricating questions", () => {
    expect(() => buildPartyBoard(categories(), questions().filter((question) => question.id !== "category-1-hard-1"), 11)).toThrow("لا تملك سؤالين صالحين");
  });

  it("validates two distinct teams, optional player split, and three helpers per team", () => {
    expect(validatePartyTeams(teams())).toBeNull();
    expect(validatePartyTeams([{ ...teams()[0], name: "نفسه" }, { ...teams()[1], name: " نفسه " }])).toContain("مختلفين");
    const split = splitPartyPlayers(["سلمان", "خالد", "نواف", "ماجد"], 11);
    expect(split[0]).toHaveLength(2);
    expect(split[1]).toHaveLength(2);
    expect(new Set(split.flat())).toEqual(new Set(["سلمان", "خالد", "نواف", "ماجد"]));
    expect(validatePartyHelpers(teams(), defaultPartyHelpers)).toBeNull();
    expect(validatePartyHelpers([{ ...teams()[0], selectedHelpers: ["risk"] }, teams()[1]], defaultPartyHelpers)).toContain("3 مساعدات");
    expect(validatePartyHelpers([teams()[0], { ...teams()[1], players: [] }], defaultPartyHelpers)).toBeNull();
    expect(validatePartyHelpers([{ ...teams()[0], players: [] }, teams()[1]], defaultPartyHelpers)).toContain("استريح");
  });
});

describe("Party question lifecycle", () => {
  it("runs question, timeout, steal, reveal, score, alternating turn, and undo", () => {
    const initial = session();
    const question = partyQuestions(initial)[0];
    const opened = choosePartyQuestion(initial, question.id, 2_000);
    expect(opened.phase).toBe("answering");
    expect(opened.timerDurationSeconds).toBe(60);
    expect(expirePartyTimer(opened, 61_999)).toBe(opened);
    const steal = expirePartyTimer(opened, 62_000);
    expect(steal.phase).toBe("steal");
    expect(steal.answeringTeamIndex).toBe(1);
    expect(steal.timerDurationSeconds).toBe(10);
    expect(offerPartySteal(steal)).toBe(steal);
    const revealed = expirePartyTimer(steal, 72_000);
    expect(revealed.phase).toBe("revealed");
    const scored = scorePartyQuestion(revealed, 1, 73_000);
    expect(scored.scores).toEqual([0, question.pointValue]);
    expect(scored.turnTeamIndex).toBe(1);
    expect(partyQuestions(scored).find((item) => item.id === question.id)?.used).toBe(true);
    expect(scorePartyQuestion(scored, 1)).toBe(scored);
    const undone = undoPartyScore(scored);
    expect(undone.scores).toEqual([0, 0]);
    expect(undone.turnTeamIndex).toBe(0);
    expect(partyQuestions(undone).find((item) => item.id === question.id)?.used).toBe(false);
  });

  it("allows one correctly-timed helper per question and keeps it used", () => {
    const initial = session();
    expect(canUsePartyHelper(initial, "risk")).toBe(true);
    expect(canUsePartyHelper(initial, "call_friend")).toBe(false);
    const armedRisk = usePartyHelper(initial, "risk", null, 1_500);
    expect(armedRisk.teams[0].usedHelpers).toEqual(["risk"]);
    expect(canUsePartyHelper(armedRisk, "call_friend")).toBe(false);
    const openedRisk = choosePartyQuestion(armedRisk, partyQuestions(armedRisk)[0].id, 2_000);
    const riskScored = scorePartyQuestion(revealPartyAnswer(openedRisk), 0);
    expect(riskScored.scores).toEqual([100, -100]);
    expect(canUsePartyHelper(riskScored, "risk")).toBe(false);

    const fresh = session();
    const opened = choosePartyQuestion(fresh, partyQuestions(fresh)[0].id, 5_000);
    expect(canUsePartyHelper(opened, "call_friend")).toBe(true);
    const called = usePartyHelper(opened, "call_friend", "صديق محلي", 6_000);
    expect(called.timerDurationSeconds).toBe(20);
    expect(called.helperDetail).toBe("صديق محلي");
    expect(canUsePartyHelper(called, "two_chances")).toBe(false);
  });

  it("applies pass and bench eligibility using the mobile-compatible rules", () => {
    const firstScored = scorePartyQuestion(revealPartyAnswer(choosePartyQuestion(session(), partyQuestions(session())[0].id, 2_000)), null);
    const opened = choosePartyQuestion(firstScored, partyQuestions(firstScored).find((question) => !question.used)!.id, 4_000);
    expect(opened.turnTeamIndex).toBe(1);
    expect(canUsePartyHelper(opened, "bench")).toBe(true);
    const passed = usePartyHelper(opened, "pass", null, 5_000);
    expect(passed.answeringTeamIndex).toBe(0);
    expect(passed.answerContext).toBe("pass");
    const penalized = scorePartyQuestion(revealPartyAnswer(passed), null);
    expect(penalized.scores[0]).toBe(-partyQuestions(opened).find((question) => question.id === opened.activeQuestionId)!.pointValue);
  });

  it("finishes with winner or tie, then restores the final question through undo", () => {
    const initial = session();
    const finalQuestion = partyQuestions(initial).at(-1)!;
    const almostDone: PartySession = {
      ...initial,
      categories: initial.categories.map((category) => ({ ...category, questions: category.questions.map((question) => ({ ...question, used: question.id !== finalQuestion.id })) })),
      activeQuestionId: finalQuestion.id,
      phase: "revealed",
      timerStartedAt: null,
      timerDurationSeconds: null,
    };
    const won = scorePartyQuestion(almostDone, 0, 9_000);
    expect(won.phase).toBe("result");
    expect(partyWinner(won)).toBe(0);
    expect(undoPartyScore(won).phase).toBe("board");
    const tied = scorePartyQuestion(almostDone, null, 9_000);
    expect(tied.phase).toBe("result");
    expect(partyWinner(tied)).toBeNull();
  });

  it("round-trips only valid versioned local sessions and supports a fresh replay", () => {
    const original = session();
    expect(isValidPartySession(original)).toBe(true);
    expect(deserializePartySession(serializePartySession(original))).toEqual(original);
    expect(deserializePartySession("{broken")).toBeNull();
    expect(deserializePartySession(JSON.stringify({ ...original, version: 2 }))).toBeNull();
    const replay = createPartySession({ categories: categories(), questions: questions(), teams: teams(), helpers: defaultPartyHelpers, rules: defaultPartyRules, timerSeconds: 60, seed: 12, now: 2_000 });
    expect(replay.id).not.toBe(original.id);
    expect(partyQuestions(replay).every((question) => !question.used)).toBe(true);
    expect(replay.scores).toEqual([0, 0]);
  });
});
