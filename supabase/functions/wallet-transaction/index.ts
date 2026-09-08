import {
  errorResponse,
  handlePreflight,
  jsonResponse,
  readJson,
  rpcError,
  userClient,
} from "../_shared/http.ts";

type WalletBody =
  | { action: "purchase"; storeItemId: string; idempotencyKey: string; clientSequence?: number }
  | { action: "equip"; storeItemId: string; idempotencyKey: string; clientSequence?: number }
  | { action: "admin_adjust"; userId: string; amount: number; reason: string; idempotencyKey: string };

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;
  try {
    const body = await readJson<WalletBody>(request);
    const client = userClient(request);
    if (body.action === "purchase") {
      const { data, error } = await client.rpc("purchase_store_item_v2", {
        p_store_item_id: body.storeItemId,
        p_idempotency_key: body.idempotencyKey,
        p_client_sequence: body.clientSequence ?? null,
      });
      rpcError(error);
      return jsonResponse(request, data);
    }
    if (body.action === "equip") {
      const { data, error } = await client.rpc("equip_store_item_v2", {
        p_store_item_id: body.storeItemId,
        p_idempotency_key: body.idempotencyKey,
        p_client_sequence: body.clientSequence ?? null,
      });
      rpcError(error);
      return jsonResponse(request, data);
    }
    if (body.action === "admin_adjust") {
      if (!Number.isSafeInteger(body.amount) || body.amount === 0) {
        throw new Error("amount must be a non-zero integer");
      }
      const { data, error } = await client.rpc("admin_adjust_wallet", {
        p_user_id: body.userId,
        p_amount: body.amount,
        p_reason: body.reason,
        p_idempotency_key: body.idempotencyKey,
      });
      rpcError(error);
      return jsonResponse(request, data);
    }
    throw new Error("Unsupported wallet action");
  } catch (error) {
    return errorResponse(request, error);
  }
});
