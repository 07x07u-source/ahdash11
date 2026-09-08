import { describe, expect, it } from "vitest";
import { tournamentAdminMutationSchema } from "@/lib/tournament/schema";

describe("tournament admin validation", () => {
  it("accepts only narrow non-destructive operational actions", () => {
    expect(tournamentAdminMutationSchema.parse({
      id: "00000000-0000-4000-8000-000000000011",
      action: "cancel",
    }).action).toBe("cancel");
    expect(() => tournamentAdminMutationSchema.parse({
      id: "00000000-0000-4000-8000-000000000011",
      action: "delete",
    })).toThrow();
  });

  it("rejects malformed tournament identifiers", () => {
    expect(() => tournamentAdminMutationSchema.parse({
      id: "not-a-uuid",
      action: "reopen",
    })).toThrow();
  });
});
