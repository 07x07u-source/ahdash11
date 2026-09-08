import {
  errorResponse,
  handlePreflight,
  jsonResponse,
  readJson,
  rpcError,
  userClient,
} from "../_shared/http.ts";

type RoomMode = "friend_1v1" | "team_2v2";
type CreateRoomBody = {
  mode: RoomMode;
  categoryIds?: string[];
  questionCount?: number;
  gameType?: "classic" | "true-false" | "speed";
};

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;
  try {
    const body = await readJson<CreateRoomBody>(request);
    if (!(["friend_1v1", "team_2v2"] as const).includes(body.mode)) throw new Error("Unsupported room mode");
    const gameType = body.gameType ?? "classic";
    if (!(gameType === "classic" || gameType === "true-false" || gameType === "speed")) {
      throw new Error("Unsupported gameType");
    }
    const client = userClient(request);
    const { data, error } = await client.rpc("create_room", {
      p_mode: body.mode,
      p_category_ids: body.categoryIds ?? [],
      p_question_count: body.questionCount ?? null,
      p_settings: {
        game_type: gameType,
        ...(gameType === "speed"
          ? { question_duration_ms: 7000 }
          : gameType === "true-false"
          ? { question_duration_ms: 10000 }
          : {}),
      },
    });
    rpcError(error);
    return jsonResponse(request, data, 201);
  } catch (error) {
    return errorResponse(request, error);
  }
});
