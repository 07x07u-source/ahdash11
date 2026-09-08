import {
  errorResponse,
  handlePreflight,
  jsonResponse,
  readJson,
  rpcError,
  userClient,
} from "../_shared/http.ts";

type JoinRoomBody = { code: string; preferredTeam?: "a" | "b" };

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;
  try {
    const body = await readJson<JoinRoomBody>(request);
    const code = String(body.code ?? "").trim();
    if (!/^\d{6}$/.test(code)) throw new Error("Room code must contain six digits");
    const client = userClient(request);
    const { data, error } = await client.rpc("join_room", {
      p_code: code,
      p_preferred_team: body.preferredTeam ?? null,
    });
    rpcError(error);
    return jsonResponse(request, data);
  } catch (error) {
    return errorResponse(request, error);
  }
});
