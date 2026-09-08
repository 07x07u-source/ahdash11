import {
  errorResponse,
  handlePreflight,
  jsonResponse,
  readJson,
  rpcError,
  serviceClient,
  userClient,
} from "../_shared/http.ts";

type DeleteBody = { reason?: string };

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;
  try {
    const body = await readJson<DeleteBody>(request);
    const client = userClient(request);
    const { data: authData, error: authError } = await client.auth.getUser();
    if (authError || !authData.user) throw new Error("Authentication required");
    const { data: deletionRequest, error: requestError } = await client.rpc("request_account_deletion", {
      p_reason: body.reason ?? null,
    });
    rpcError(requestError);

    const admin = serviceClient();
    const { error: deleteError } = await admin.auth.admin.deleteUser(authData.user.id, false);
    if (deleteError) {
      await admin.from("account_deletion_requests").update({
        status: "failed",
        processed_at: new Date().toISOString(),
        error_message: deleteError.message,
      }).eq("id", deletionRequest.request_id);
      await admin.from("profiles").update({ status: "active" }).eq("id", authData.user.id);
      throw new Error("Account deletion could not be completed");
    }
    return jsonResponse(request, { deleted: true });
  } catch (error) {
    return errorResponse(request, error);
  }
});
