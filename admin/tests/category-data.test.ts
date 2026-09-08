import { describe, expect, it, vi } from "vitest";
import { loadCategoryData, type CategoryDataSource } from "@/lib/data/category-data";

const category = {
  id: "11111111-1111-4111-8111-111111111111",
  name_ar: "الدوريات",
  slug: "leagues",
  parent_id: null,
  sort_order: 1,
  is_active: true,
  icon_key: "trophy",
  description_ar: "بطولات كرة القدم",
  image_url: null,
  cover_media_id: null,
  updated_at: "2026-08-28T09:00:00Z",
};

function source(overrides: Partial<CategoryDataSource> = {}): CategoryDataSource {
  return {
    list: vi.fn(async () => ({ data: [category], error: null })),
    count: vi.fn(async () => ({ count: 12, error: null })),
    ...overrides,
  };
}

describe("category Supabase loading", () => {
  it("reports missing environment without silently enabling demo rows", async () => {
    const result = await loadCategoryData(null, { configured: false, demoEnabled: false });
    expect(result.state).toBe("not_configured");
    expect(result.rows).toEqual([]);
  });

  it("loads categories and their question counts from the live source", async () => {
    const live = source();
    const result = await loadCategoryData(live, { configured: true, demoEnabled: false });
    expect(result.state).toBe("live");
    expect(result.rows[0]).toMatchObject({ name: "الدوريات", questionCount: 12 });
    expect(live.count).toHaveBeenCalledWith(category.id, false);
  });

  it("derives ready, media, and rights health from published Party questions", async () => {
    const base = ["easy", "easy", "medium", "medium", "hard", "hard"].map((difficulty) => ({
      difficulty,
      question_type: "text",
      image_url: null,
      media_rights_status: "none",
    }));
    const ready = await loadCategoryData(
      source({ health: vi.fn(async () => ({ data: base, error: null })) }),
      { configured: true, demoEnabled: false },
    );
    expect(ready.rows[0].health).toBe("READY");

    const rightsIssue = await loadCategoryData(
      source({ health: vi.fn(async () => ({ data: [...base, { difficulty: "easy", question_type: "image", image_url: "https://example.com/a.webp", media_rights_status: "unverified" }], error: null })) }),
      { configured: true, demoEnabled: false },
    );
    expect(rightsIssue.rows[0].health).toBe("RIGHTS ISSUE");
  });

  it("keeps a real empty category response empty", async () => {
    const result = await loadCategoryData(
      source({ list: vi.fn(async () => ({ data: [], error: null })) }),
      { configured: true, demoEnabled: false },
    );
    expect(result.state).toBe("live");
    expect(result.rows).toEqual([]);
  });

  it("uses subcategory_id when counting a child category", async () => {
    const child = { ...category, id: "22222222-2222-4222-8222-222222222222", parent_id: category.id };
    const live = source({ list: vi.fn(async () => ({ data: [child], error: null })) });
    await loadCategoryData(live, { configured: true, demoEnabled: false });
    expect(live.count).toHaveBeenCalledWith(child.id, true);
  });

  it("returns a real error and no demo data when the category query fails", async () => {
    const result = await loadCategoryData(
      source({ list: vi.fn(async () => ({ data: null, error: { code: "42501", message: "permission denied" } })) }),
      { configured: true, demoEnabled: false },
    );
    expect(result.state).toBe("error");
    expect(result.rows).toEqual([]);
    expect(result.detail).toContain("42501");
  });

  it("keeps live rows visible but exposes a partial state when a count fails", async () => {
    const result = await loadCategoryData(
      source({ count: vi.fn(async () => ({ count: null, error: { code: "42501" } })) }),
      { configured: true, demoEnabled: false },
    );
    expect(result.state).toBe("partial");
    expect(result.rows).toHaveLength(1);
  });

  it("uses demo rows only when explicitly enabled", async () => {
    const result = await loadCategoryData(null, { configured: false, demoEnabled: true });
    expect(result.state).toBe("demo");
    expect(result.rows.length).toBeGreaterThan(0);
  });
});
