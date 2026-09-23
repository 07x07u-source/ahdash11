import { describe, expect, it } from "vitest";
import { parseGameplayQuestion, type GameplayQuestion } from "@/lib/gameplay/contracts";
import { advanceSoloQuestion, answerSoloQuestion, createSoloSession, expireSoloTimer, soloAccuracy, soloLongestStreak } from "@/lib/gameplay/solo-engine";

function questions(count = 15): GameplayQuestion[] {
  return Array.from({ length: count }, (_, index) => ({
    id: `solo-${index}`,
    categoryId: index % 2 ? "cat-b" : "cat-a",
    text: `سؤال Solo ${index}`,
    format: "multiple_choice",
    difficulty: "medium",
    pointValue: 200,
    options: ["أ", "ب", "ج", "د"],
    correctOptionIndex: index % 4,
    correctAnswer: ["أ", "ب", "ج", "د"][index % 4],
    alternativeAnswers: [],
    explanation: null,
    imageUrl: null,
    gameplayType: "classic",
  }));
}

describe("Solo / Classic gameplay", () => {
  it("parses the current Supabase Solo RPC row without a fabricated answer", () => {
    const parsed = parseGameplayQuestion({
      id: "rpc-question",
      category_id: "cat-a",
      question_text: "من صاحب الإجابة؟",
      question_type: "text",
      gameplay_type: "classic",
      difficulty: "medium",
      options: ["أ", "ب", "ج", "د"],
      correct_option_index: 2,
    });
    expect(parsed?.correctAnswer).toBe("ج");
    expect(parseGameplayQuestion({ id: "bad", category_id: "cat-a", question_text: "ناقص" })).toBeNull();
    expect(parseGameplayQuestion({ id: "deferred", category_id: "cat-a", question_text: "رتّب", question_format: "ordering", correct_answer: "أ" })).toBeNull();
  });

  it("honors category, difficulty, and requested question count", () => {
    const setup = { categoryIds: ["cat-a", "cat-b"], difficulty: "medium" as const, questionCount: 11 };
    const session = createSoloSession(questions(), setup, 320, 1_000);
    expect(session.questions).toHaveLength(11);
    expect(session.setup).toEqual(setup);
    expect(session.personalBest).toBe(320);
    expect(session.timerSeconds).toBe(15);
    expect(() => createSoloSession(questions(), { ...setup, difficulty: "hard" }, 0, 1_000)).toThrow("أسئلة كافية");
  });

  it("scores a correct answer with a 0–50 speed bonus and never scores twice", () => {
    const setup = { categoryIds: ["cat-a", "cat-b"], difficulty: "medium" as const, questionCount: 5 };
    const initial = createSoloSession(questions(), setup, 0, 1_000);
    const answered = answerSoloQuestion(initial, initial.questions[0].correctOptionIndex, 8_500);
    expect(answered.phase).toBe("revealed");
    expect(answered.score).toBe(125);
    expect(answered.records[0]).toMatchObject({ correct: true, basePoints: 100, speedBonus: 25, responseTimeMs: 7_500 });
    expect(answerSoloQuestion(answered, 0, 9_000)).toBe(answered);
  });

  it("records wrong answers and timer expiry without points", () => {
    const setup = { categoryIds: ["cat-a", "cat-b"], difficulty: "medium" as const, questionCount: 5 };
    const initial = createSoloSession(questions(), setup, 0, 1_000);
    expect(expireSoloTimer(initial, 15_999)).toBe(initial);
    const expired = expireSoloTimer(initial, 16_000);
    expect(expired.score).toBe(0);
    expect(expired.records[0]).toMatchObject({ selectedIndex: null, correct: false });
  });

  it("advances to result, calculates accuracy/streak, persists best in state, and replays fresh", () => {
    const setup = { categoryIds: ["cat-a", "cat-b"], difficulty: "medium" as const, questionCount: 3 };
    let session = createSoloSession(questions(), setup, 20, 1_000);
    session = advanceSoloQuestion(answerSoloQuestion(session, session.questions[0].correctOptionIndex, 2_000), 3_000);
    session = advanceSoloQuestion(answerSoloQuestion(session, session.questions[1].correctOptionIndex, 4_000), 5_000);
    session = answerSoloQuestion(session, (session.questions[2].correctOptionIndex + 1) % 4, 6_000);
    expect(soloAccuracy(session)).toBeCloseTo(2 / 3);
    expect(soloLongestStreak(session)).toBe(2);
    session = advanceSoloQuestion(session, 7_000);
    expect(session.phase).toBe("result");
    expect(session.personalBest).toBe(session.score);
    const replay = createSoloSession(questions(), session.setup, session.personalBest, 8_000);
    expect(replay.phase).toBe("answering");
    expect(replay.score).toBe(0);
    expect(replay.records).toEqual([]);
  });
});
