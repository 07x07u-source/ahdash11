import {
  errorResponse,
  handlePreflight,
  jsonResponse,
  readJson,
  rpcError,
  userClient,
} from "../_shared/http.ts";

type MatchmakingBody = {
  action?: "enqueue" | "cancel";
  categoryIds?: string[];
  questionCount?: number;
  region?: string | null;
  initialRange?: number;
  gameType?: "classic" | "true-false" | "speed";
};

function isMissingV2Function(error: { code?: string; message?: string } | null) {
  return error?.code === "PGRST202" ||
    error?.message?.includes("enqueue_matchmaking_v2") === true;
}

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;

  try {
    const body = await readJson<MatchmakingBody>(request);
    const client = userClient(request);
    if (body.action === "cancel") {
      const { data, error } = await client.rpc("cancel_matchmaking");
      rpcError(error);
      return jsonResponse(request, { status: "cancelled", removed: data === true });
    }

    if (body.categoryIds && !Array.isArray(body.categoryIds)) {
      throw new Error("categoryIds must be an array");
    }
    const gameType = body.gameType ?? "classic";
    if (!(gameType === "classic" || gameType === "true-false" || gameType === "speed")) {
      throw new Error("Unsupported gameType");
    }
    let { data, error } = await client.rpc("enqueue_matchmaking_v2", {
      p_category_ids: body.categoryIds ?? [],
      p_question_count: body.questionCount ?? 15,
      p_region: body.region?.trim() || null,
      p_initial_range: body.initialRange ?? 100,
      p_game_type: gameType,
    });
    if (gameType === "classic" && isMissingV2Function(error)) {
      ({ data, error } = await client.rpc("enqueue_matchmaking", {
        p_category_ids: body.categoryIds ?? [],
        p_question_count: body.questionCount ?? 15,
        p_region: body.region?.trim() || null,
        p_initial_range: body.initialRange ?? 100,
      }));
    }
    rpcError(error);
    return jsonResponse(request, data);
  } catch (error) {
    return errorResponse(request, error);
  }
});
