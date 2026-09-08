import {
  errorResponse,
  handlePreflight,
  jsonResponse,
  readJson,
  rpcError,
  userClient,
} from "../_shared/http.ts";

type CommitBody = { batchId: string; publish?: boolean };

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;
  try {
    const body = await readJson<CommitBody>(request);
    if (!body.batchId) throw new Error("batchId is required");
    const client = userClient(request);
    const { data, error } = await client.rpc("commit_import_batch", {
      p_batch_id: body.batchId,
      p_publish: body.publish ?? false,
    });
    rpcError(error);
    const status = data?.status === "failed" ? 422 : 200;
    return jsonResponse(request, data, status);
  } catch (error) {
    return errorResponse(request, error);
  }
});
