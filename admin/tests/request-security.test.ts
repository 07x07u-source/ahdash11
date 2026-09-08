import { describe, expect, it } from "vitest";
import { rejectCrossOriginMutation } from "../src/lib/security/request";

describe("admin mutation origin checks", () => {
  it("accepts same-origin browser requests", () => {
    const request = new Request("https://admin.ahdash11.app/api/content", {
      method: "PATCH",
      headers: { origin: "https://admin.ahdash11.app" },
    });
    expect(rejectCrossOriginMutation(request)).toBeNull();
  });

  it("rejects cross-origin mutation attempts", () => {
    const request = new Request("https://admin.ahdash11.app/api/content", {
      method: "PATCH",
      headers: { origin: "https://attacker.example" },
    });
    expect(rejectCrossOriginMutation(request)?.status).toBe(403);
  });

  it("allows server-to-server requests without a browser Origin header", () => {
    expect(rejectCrossOriginMutation(new Request("https://admin.ahdash11.app/api/content"))).toBeNull();
  });
});
