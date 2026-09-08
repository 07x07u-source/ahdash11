import {
  errorResponse,
  handlePreflight,
  jsonResponse,
  readJson,
  rpcError,
  serviceClient,
} from "../_shared/http.ts";

type RevenueCatEvent = {
  type?: string;
  app_user_id?: string;
  entitlement_id?: string;
  entitlement_ids?: string[];
  product_id?: string;
  original_transaction_id?: string;
  store?: string;
  purchased_at_ms?: number;
  expiration_at_ms?: number;
  cancellation_at_ms?: number;
  event_timestamp_ms?: number;
};

type RevenueCatBody = { event?: RevenueCatEvent };

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function toIso(value?: number): string | null {
  if (!value || !Number.isFinite(value)) return null;
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? null : date.toISOString();
}

function statusFor(type: string): string | null {
  switch (type) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "UNCANCELLATION":
    case "PRODUCT_CHANGE":
    case "NON_RENEWING_PURCHASE":
    case "SUBSCRIPTION_EXTENDED":
    case "TEMPORARY_ENTITLEMENT_GRANT":
      return "active";
    case "BILLING_ISSUE":
      return "grace_period";
    case "SUBSCRIPTION_PAUSED":
      return "paused";
    case "CANCELLATION":
      return "cancelled";
    case "EXPIRATION":
      return "expired";
    case "REFUND":
      return "refunded";
    default:
      return null;
  }
}

function platformFor(store?: string): "ios" | "android" | "unknown" {
  if (store === "APP_STORE" || store === "MAC_APP_STORE") return "ios";
  if (store === "PLAY_STORE") return "android";
  return "unknown";
}

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;
  try {
    const configuredSecret = Deno.env.get("REVENUECAT_WEBHOOK_AUTH")?.trim();
    const authorization = request.headers.get("authorization") ?? "";
    if (!configuredSecret || authorization !== `Bearer ${configuredSecret}`) {
      return jsonResponse(request, { error: "Unauthorized" }, 401);
    }

    const body = await readJson<RevenueCatBody>(request);
    const event = body.event;
    if (!event) throw new Error("RevenueCat event is required");

    const eventType = event.type?.trim().toUpperCase() ?? "";
    const status = statusFor(eventType);
    if (!status) {
      return jsonResponse(request, { received: true, ignored: true, eventType });
    }

    const userId = event.app_user_id?.trim() ?? "";
    if (!uuidPattern.test(userId)) {
      return jsonResponse(request, { received: true, ignored: true, reason: "unmapped_app_user" });
    }

    const configuredEntitlement = Deno.env.get("REVENUECAT_ENTITLEMENT_ID")?.trim();
    if (!configuredEntitlement) throw new Error("RevenueCat entitlement is not configured");
    const eventEntitlements = new Set(
      [
        ...(event.entitlement_ids ?? []),
        ...(event.entitlement_id ? [event.entitlement_id] : []),
      ].map((value) => value.trim()).filter(Boolean),
    );
    if (eventEntitlements.size > 0 && !eventEntitlements.has(configuredEntitlement)) {
      return jsonResponse(request, { received: true, ignored: true, reason: "entitlement_mismatch" });
    }
    const entitlementIds = [configuredEntitlement];

    const client = serviceClient();
    let applied = 0;
    for (const entitlementId of entitlementIds) {
      const { data, error } = await client.rpc("apply_revenuecat_subscription_event", {
        p_user_id: userId,
        p_entitlement_id: entitlementId,
        p_product_id: event.product_id ?? "unknown",
        p_original_transaction_id: event.original_transaction_id ?? null,
        p_status: status,
        p_platform: platformFor(event.store),
        p_purchased_at: toIso(event.purchased_at_ms),
        p_current_period_ends_at: toIso(event.expiration_at_ms),
        p_cancelled_at: toIso(event.cancellation_at_ms),
        p_event_at: toIso(event.event_timestamp_ms) ?? new Date().toISOString(),
        p_raw_event: event,
      });
      rpcError(error);
      if (data === true) applied += 1;
    }

    return jsonResponse(request, {
      received: true,
      eventType,
      entitlements: entitlementIds.length,
      applied,
    });
  } catch (error) {
    return errorResponse(request, error);
  }
});
