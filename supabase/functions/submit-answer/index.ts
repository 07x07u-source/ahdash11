import {
  errorResponse,
  handlePreflight,
  jsonResponse,
  readJson,
  rpcError,
  userClient,
} from "../_shared/http.ts";

type SubmitBody = {
  matchQuestionId: string;
  optionId: string;
  idempotencyKey: string;
  clientSequence: number;
};

function isMissingV2Function(error: { code?: string; message?: string } | null) {
  return error?.code === "PGRST202" ||
    error?.message?.includes("submit_match_answer_v2") === true;
}

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;
  try {
    const body = await readJson<SubmitBody>(request);
    if (!body.matchQuestionId || !body.optionId) throw new Error("matchQuestionId and optionId are required");
    if (!body.idempotencyKey || body.idempotencyKey.length < 16 || body.idempotencyKey.length > 200) {
      throw new Error("A valid idempotencyKey is required");
    }
    if (!Number.isSafeInteger(body.clientSequence) || body.clientSequence <= 0) {
      throw new Error("clientSequence must be a positive integer");
    }
    const client = userClient(request);
    let { data: submission, error } = await client.rpc("submit_match_answer_v2", {
      p_match_question_id: body.matchQuestionId,
      p_match_option_id: body.optionId,
      p_idempotency_key: body.idempotencyKey,
      p_client_sequence: body.clientSequence,
    });

    // Compatibility during a rolling deploy: the immutable earlier migration may
    // already be live while gameplay_contract_v2 is still being applied.
    if (isMissingV2Function(error)) {
      ({ data: submission, error } = await client.rpc("submit_match_answer", {
        p_match_question_id: body.matchQuestionId,
        p_match_option_id: body.optionId,
      }));
    }
    rpcError(error);

    // Safe early reveal succeeds only after every human answered or the server timer elapsed.
    const { data: result, error: revealError } = await client.rpc("reveal_match_question", {
      p_match_question_id: body.matchQuestionId,
    });
    return jsonResponse(request, {
      submission,
      ...(revealError ? { result: null } : { result }),
    });
  } catch (error) {
    return errorResponse(request, error);
  }
});
