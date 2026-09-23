import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

function source(path: string) {
  return readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
}

describe("player website Phase 2 product boundaries", () => {
  it("lets guests enter local Party and Solo while private routes remain account-guarded", () => {
    const playPage = source("src/app/(website)/play/page.tsx");
    expect(playPage).not.toContain("requirePlayerPage(");
    expect(playPage).toContain("PlayExperience");
    for (const page of [
      "src/app/(website)/championships/create/page.tsx",
      "src/app/(website)/championships/join/page.tsx",
      "src/app/(website)/account/page.tsx",
      "src/app/(website)/account/[feature]/page.tsx",
    ]) expect(source(page)).toContain("requirePlayerPage(");
    const playerContext = source("src/lib/auth/player.ts");
    expect(playerContext).toContain("user.is_anonymous === true");
    expect(playerContext).toContain("provider === \"anonymous\"");
  });

  it("uses a real anonymous Supabase identity and the existing pack/RLS contracts", () => {
    const catalog = source("src/lib/gameplay/catalog.ts");
    expect(catalog).toContain("signInAnonymously");
    expect(catalog).toContain('rpc("get_party_category_health")');
    expect(catalog).toContain('rpc("get_party_question_pack"');
    expect(catalog).toContain('rpc("get_solo_question_pack"');
    expect(catalog).toContain('rpc("record_solo_answer"');
    expect(catalog).not.toMatch(/questionsByMode|demoQuestions|mockQuestions|fallbackQuestions/i);
  });

  it("keeps only Party and Solo / Classic discoverable", () => {
    const play = source("src/components/play-experience.tsx");
    const games = source("src/app/(website)/games/page.tsx");
    expect(play).toContain("PartyExperience");
    expect(play).toContain("SoloExperience");
    for (const forbidden of ["لعب أونلاين", "ابحث عن خصم", "1 ضد 1", "2 ضد 2"]) {
      expect(play).not.toContain(forbidden);
      expect(games).not.toContain(forbidden);
    }
  });

  it("exposes setup, helper, timer, reveal, score, undo, resume, result, and replay UI states", () => {
    const party = source("src/components/gameplay/party-experience.tsx");
    for (const marker of ["اختاروا ست فئات", "سمّوا الفريقين", "ثلاث مساعدات لكل فريق", "GameplayTimer", "كشف الإجابة", "scorePartyQuestion", "undoPartyScore", "readPartySession", "متابعة الجولة", "إعادة بنفس الإعداد"]) {
      expect(party).toContain(marker);
    }
    const solo = source("src/components/gameplay/solo-experience.tsx");
    for (const marker of ["مستوى الصعوبة", "عدد الأسئلة", "GameplayTimer", "answerSoloQuestion", "أفضل نتيجة", "إعادة الجولة"]) {
      expect(solo).toContain(marker);
    }
  });
});
