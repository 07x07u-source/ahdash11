import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

const migration = readFileSync(
  new URL(
    "../../supabase/migrations/20261003000100_league_question_catalog.sql",
    import.meta.url,
  ),
  "utf8",
);

type SeedQuestion = {
  source_key: string;
  category_slug: string;
  question_text: string;
  difficulty: "easy" | "medium" | "hard" | "expert";
  options: string[];
  correct_position: number;
  correct_answer: string;
  source_url: string | null;
  image_source_url: string | null;
};

function questions(): SeedQuestion[] {
  const payload = migration.match(
    /\$questions\$(\[[\s\S]*\])\$questions\$/,
  )?.[1];
  if (!payload) throw new Error("question seed payload is missing");
  return JSON.parse(payload) as SeedQuestion[];
}

describe("league question catalogue", () => {
  it("adds the six requested playable categories", () => {
    for (const slug of [
      "international-tournaments",
      "champions-league",
      "serie-a",
      "la-liga",
      "premier-league",
      "saudi-pro-league",
    ]) {
      expect(migration).toContain(`('${slug}'`);
    }
    expect(migration).toContain("'multiple_choice'");
    expect(migration).toContain("'published'::public.question_status");
  });

  it("contains 2,800 structurally valid and uniquely keyed questions", () => {
    const rows = questions();
    expect(rows).toHaveLength(2800);
    expect(new Set(rows.map((row) => row.source_key)).size).toBe(2800);
    expect(new Set(rows.map((row) => row.question_text)).size).toBe(2800);
    for (const row of rows) {
      expect(row.question_text.trim().length).toBeGreaterThanOrEqual(5);
      expect(row.options).toHaveLength(4);
      expect(new Set(row.options.map((option) => option.trim())).size).toBe(4);
      expect(row.correct_position).toBeGreaterThanOrEqual(1);
      expect(row.correct_position).toBeLessThanOrEqual(4);
      expect(row.options[row.correct_position - 1]).toBe(row.correct_answer);
      if (row.source_url) expect(row.source_url).toMatch(/^https:\/\//);
      if (row.image_source_url) expect(row.image_source_url).toMatch(/^https:\/\//);
    }
  });

  it("keeps unverified external images out of active game media", () => {
    expect(migration).toContain("'text'::public.question_type");
    expect(migration).toContain("'editorial_image_rights'");
    expect(migration).toContain("'unverified'");
    expect(migration).not.toContain("'image'::public.question_type");
  });
});
