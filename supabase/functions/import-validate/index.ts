import {
  errorResponse,
  handlePreflight,
  jsonResponse,
  readJson,
  rpcError,
  userClient,
} from "../_shared/http.ts";

type ImportBody = {
  batchId?: string;
  filename?: string;
  sourceType?: "csv" | "xlsx" | "manual";
  categoryHintId?: string;
  rows?: Record<string, unknown>[];
};

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;
  try {
    const body = await readJson<ImportBody>(request);
    const client = userClient(request);
    let batchId = body.batchId;
    if (!batchId) {
      if (!body.filename || !body.sourceType || !Array.isArray(body.rows) || body.rows.length === 0) {
        throw new Error("filename, sourceType, and non-empty rows are required for a new batch");
      }
      if (body.rows.length > 5000) throw new Error("A batch may contain at most 5000 rows");
      const { data: authData, error: authError } = await client.auth.getUser();
      if (authError || !authData.user) throw new Error("Authentication required");
      const { data: batch, error: batchError } = await client.from("import_batches").insert({
        filename: body.filename,
        source_type: body.sourceType,
        category_hint_id: body.categoryHintId ?? null,
        total_rows: body.rows.length,
        created_by: authData.user.id,
      }).select("id").single();
      rpcError(batchError);
      if (!batch) throw new Error("Import batch was not created");
      batchId = batch.id as string;
      const stagedRows = body.rows.map((rawData, index) => ({
        batch_id: batchId,
        row_number: index + 1,
        raw_data: rawData,
      }));
      const { error: rowsError } = await client.from("import_rows").insert(stagedRows);
      rpcError(rowsError);
    }
    const { data, error } = await client.rpc("validate_import_batch", { p_batch_id: batchId });
    rpcError(error);
    return jsonResponse(request, data, 200);
  } catch (error) {
    return errorResponse(request, error);
  }
});
