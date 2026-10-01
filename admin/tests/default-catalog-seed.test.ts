import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

const migration = readFileSync(new URL("../../supabase/migrations/20260926000100_default_six_category_catalog.sql", import.meta.url), "utf8");

describe("default six-category catalogue", () => {
  it("seeds six categories only when no playable catalogue exists", () => {
    expect(migration).toContain("if ready_category_count > 0 then");
    expect(migration).toContain("text-only catalogues may use icon_key");
    expect(migration).toContain("requires_cover");
    expect(migration.match(/seed-v1:[^']+/g)).toHaveLength(36);
    for (const slug of ["eagle-eye", "transfers", "leagues", "locker-room", "stadiums", "individual-awards"]) {
      expect(migration).toContain(`('${slug}'`);
    }
  });

  it("publishes answer-keyed multiple-choice questions for the Party RPC", () => {
    expect(migration).toContain("'published'::public.question_status");
    expect(migration).toContain("'multiple_choice'");
    expect(migration).toContain("offline_practice_eligible");
    expect(migration).toContain("competitive_eligible");
    expect(migration).toContain("question_key text unique not null");
    expect(migration).toContain("seed by its stable question_key");
  });
});
