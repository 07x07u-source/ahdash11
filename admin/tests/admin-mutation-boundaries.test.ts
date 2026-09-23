import { beforeEach, describe, expect, it, vi } from "vitest";

const { authorize, client } = vi.hoisted(() => ({ authorize: vi.fn(), client: vi.fn() }));
vi.mock("@/lib/auth/context", () => ({ authorizeAdminApi: authorize }));
vi.mock("@/lib/supabase/server", () => ({ createServerSupabaseClient: client }));
import { PATCH } from "@/app/api/settings/route";
import { POST as createVoucher } from "@/app/api/premium-vouchers/route";
import { POST as disableVoucher } from "@/app/api/premium-vouchers/[id]/disable/route";

beforeEach(() => {
  vi.clearAllMocks();
  authorize.mockResolvedValue({ context: { id: "admin" }, response: null });
});

describe("admin mutation boundaries", () => {
  it("rejects cross-origin voucher actions before checking credentials", async () => {
    const request = () => new Request("https://admin.example/api/premium-vouchers", { method: "POST", headers: { origin: "https://untrusted.example" } });
    expect((await createVoucher(request())).status).toBe(403);
    expect((await disableVoucher(request(), { params: Promise.resolve({ id: "unused" }) })).status).toBe(403);
    expect(authorize).not.toHaveBeenCalled();
  });

  it("prevents replacing structured game rules with a number", async () => {
    const update = vi.fn();
    client.mockResolvedValue({ from: () => ({ select: () => ({ in: async () => ({ error: null, data: [{ key: "party.rule_config", value: { primary_answer_seconds: 60 } }] }) }), update }) });
    const response = await PATCH(new Request("https://admin.example/api/settings", { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify({ settings: [{ key: "party.rule_config", value: 0 }] }) }));
    expect(response.status).toBe(400);
    expect(update).not.toHaveBeenCalled();
  });

  it("denies settings writes without an admin session", async () => {
    authorize.mockResolvedValue({ context: null, response: Response.json({ error: "Unauthorized" }, { status: 401 }) });
    expect((await PATCH(new Request("https://admin.example/api/settings", { method: "PATCH" }))).status).toBe(401);
    expect(client).not.toHaveBeenCalled();
  });
});
