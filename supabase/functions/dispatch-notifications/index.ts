import { handlePreflight, jsonResponse, readJson, serviceClient, userClient } from "../_shared/http.ts";

type DispatchBody = { notificationId?: string; batchSize?: number };
type NotificationRow = {
  id: string;
  target_user_id: string | null;
  type: string;
  title_ar: string;
  body_ar: string;
  data: Record<string, unknown>;
  audience: { segment?: string };
};
type Recipient = { id: string; timezone: string | null };
type DeviceToken = { id: string; user_id: string; token: string };
type Preference = Record<string, unknown> & {
  user_id: string;
  quiet_hours_start?: string | null;
  quiet_hours_end?: string | null;
};

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

async function getGoogleAccessToken(): Promise<string> {
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL")?.trim();
  const rawPrivateKey = Deno.env.get("FCM_PRIVATE_KEY")?.trim();
  if (!clientEmail || !rawPrivateKey) throw new Error("FCM service account is not configured");

  const privateKey = rawPrivateKey.replaceAll("\\n", "\n");
  const pem = privateKey.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (character) => character.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const now = Math.floor(Date.now() / 1000);
  const encoder = new TextEncoder();
  const header = base64Url(encoder.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = base64Url(encoder.encode(JSON.stringify({
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })));
  const unsigned = `${header}.${claims}`;
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(unsigned));
  const assertion = `${unsigned}.${base64Url(new Uint8Array(signature))}`;
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const payload = await response.json() as { access_token?: string; error_description?: string };
  if (!response.ok || !payload.access_token) {
    throw new Error(payload.error_description ?? "Unable to authorize Firebase messaging");
  }
  return payload.access_token;
}

async function authorize(request: Request): Promise<boolean> {
  const authorization = request.headers.get("authorization") ?? "";
  const dispatchSecret = Deno.env.get("NOTIFICATION_DISPATCH_SECRET")?.trim();
  if (dispatchSecret && authorization === `Bearer ${dispatchSecret}`) return true;
  try {
    const client = userClient(request);
    const { data, error } = await client.auth.getUser();
    if (error || !data.user) return false;
    const admin = serviceClient();
    const { data: profile } = await admin.from("profiles").select("role,status").eq("id", data.user.id)
      .single();
    return profile?.status === "active" && ["admin", "super_admin"].includes(profile.role);
  } catch (_) {
    return false;
  }
}

function preferenceKey(notification: NotificationRow): string | null {
  if (typeof notification.data.social_event === "string") return "teams";
  if (notification.data.category === "promotion") return "promotions";
  switch (notification.type) {
    case "friend_request":
      return "friend_requests";
    case "match_invite":
      return "match_invites";
    case "challenge":
    case "daily_challenge":
      return "challenges";
    case "reward":
      return "rewards";
    case "season":
      return "season_events";
    case "announcement":
      return "announcements";
    default:
      return null;
  }
}

function minutes(value: string): number {
  const [hours, mins] = value.split(":").map(Number);
  return hours * 60 + mins;
}

function isQuietNow(recipient: Recipient, preference?: Preference): boolean {
  const start = preference?.quiet_hours_start;
  const end = preference?.quiet_hours_end;
  if (!start || !end) return false;
  try {
    const parts = new Intl.DateTimeFormat("en-GB", {
      timeZone: recipient.timezone || "UTC",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }).formatToParts(new Date());
    const hour = Number(parts.find((part) => part.type === "hour")?.value ?? 0) % 24;
    const minute = Number(parts.find((part) => part.type === "minute")?.value ?? 0);
    const current = hour * 60 + minute;
    const startMinutes = minutes(start);
    const endMinutes = minutes(end);
    return startMinutes <= endMinutes
      ? current >= startMinutes && current < endMinutes
      : current >= startMinutes || current < endMinutes;
  } catch (_) {
    return false;
  }
}

async function recipientsFor(
  notification: NotificationRow,
  batchSize: number,
): Promise<{ recipients: Recipient[]; cursor: string | null; hasMore: boolean }> {
  const admin = serviceClient();
  if (notification.target_user_id) {
    const { data, error } = await admin.from("profiles").select("id,timezone")
      .eq("id", notification.target_user_id).eq("status", "active").maybeSingle();
    if (error) throw new Error(error.message);
    return { recipients: data ? [data as Recipient] : [], cursor: null, hasMore: false };
  }

  const internalCursor = typeof notification.data._dispatch_cursor === "string"
    ? notification.data._dispatch_cursor
    : null;
  const segment = notification.audience?.segment ?? "all";
  let query = admin.from("profiles").select("id,timezone,last_seen_at")
    .eq("status", "active").order("id", { ascending: true }).limit(batchSize);
  if (internalCursor && uuidPattern.test(internalCursor)) query = query.gt("id", internalCursor);
  const now = Date.now();
  if (segment === "active") {
    query = query.gte("last_seen_at", new Date(now - 30 * 86_400_000).toISOString());
  } else if (segment === "inactive_7d") {
    query = query.or(`last_seen_at.is.null,last_seen_at.lt.${new Date(now - 7 * 86_400_000).toISOString()}`);
  }
  const { data, error } = await query;
  if (error) throw new Error(error.message);
  const scanned = (data ?? []) as Array<Recipient & { last_seen_at?: string | null }>;
  let recipients: Recipient[] = scanned;
  if (segment === "premium" && scanned.length > 0) {
    const { data: subscriptions, error: subscriptionError } = await admin.from("subscriptions")
      .select("user_id").in("user_id", scanned.map((row) => row.id))
      .in("status", ["trialing", "active", "grace_period"]);
    if (subscriptionError) throw new Error(subscriptionError.message);
    const premiumIds = new Set((subscriptions ?? []).map((row) => row.user_id as string));
    recipients = scanned.filter((row) => premiumIds.has(row.id));
  }
  return {
    recipients,
    cursor: scanned.at(-1)?.id ?? internalCursor,
    hasMore: scanned.length === batchSize,
  };
}

function publicData(data: Record<string, unknown>, notification: NotificationRow): Record<string, string> {
  const result: Record<string, string> = {
    notification_id: notification.id,
    type: notification.type,
  };
  for (const [key, value] of Object.entries(data)) {
    if (key.startsWith("_dispatch_")) continue;
    result[key] = typeof value === "string" ? value : JSON.stringify(value);
  }
  return result;
}

async function sendMessage(
  accessToken: string,
  projectId: string,
  token: DeviceToken,
  notification: NotificationRow,
): Promise<{ ok: boolean; permanent: boolean; messageId?: string; code?: string }> {
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        token: token.token,
        notification: { title: notification.title_ar, body: notification.body_ar },
        data: publicData(notification.data, notification),
        android: { priority: "high" },
        apns: { headers: { "apns-priority": "10" }, payload: { aps: { sound: "default" } } },
      },
    }),
  });
  const payload = await response.json() as {
    name?: string;
    error?: { status?: string; details?: Array<{ errorCode?: string }> };
  };
  if (response.ok) return { ok: true, permanent: false, messageId: payload.name };
  const code = payload.error?.details?.find((detail) => detail.errorCode)?.errorCode ??
    payload.error?.status ?? `HTTP_${response.status}`;
  const permanent = response.status === 404 ||
    ["UNREGISTERED", "INVALID_ARGUMENT", "SENDER_ID_MISMATCH"].includes(code);
  return { ok: false, permanent, code };
}

async function dispatchOne(
  notification: NotificationRow,
  batchSize: number,
  accessToken: string,
  projectId: string,
) {
  const admin = serviceClient();
  const page = await recipientsFor(notification, batchSize);
  const recipientById = new Map(page.recipients.map((recipient) => [recipient.id, recipient]));
  const recipientIds = [...recipientById.keys()];
  const preferenceByUser = new Map<string, Preference>();
  const tokens: DeviceToken[] = [];
  if (recipientIds.length > 0) {
    const [{ data: preferences, error: preferenceError }, { data: tokenRows, error: tokenError }] =
      await Promise.all([
        admin.from("notification_preferences").select("*").in("user_id", recipientIds),
        admin.from("device_tokens").select("id,user_id,token").in("user_id", recipientIds).eq(
          "is_active",
          true,
        ),
      ]);
    if (preferenceError) throw new Error(preferenceError.message);
    if (tokenError) throw new Error(tokenError.message);
    for (const preference of preferences ?? []) {
      preferenceByUser.set(preference.user_id as string, preference as Preference);
    }
    tokens.push(...(tokenRows ?? []) as DeviceToken[]);
  }

  const existing = new Map<string, string>();
  if (tokens.length > 0) {
    const { data, error } = await admin.from("notification_deliveries")
      .select("device_token_id,status").eq("notification_id", notification.id)
      .in("device_token_id", tokens.map((token) => token.id));
    if (error) throw new Error(error.message);
    for (const row of data ?? []) existing.set(row.device_token_id as string, row.status as string);
  }

  const setting = preferenceKey(notification);
  let sent = 0;
  let failed = 0;
  let deferred = false;
  const eligible: DeviceToken[] = [];
  for (const token of tokens) {
    if (["sent", "skipped"].includes(existing.get(token.id) ?? "")) continue;
    const recipient = recipientById.get(token.user_id)!;
    const preference = preferenceByUser.get(token.user_id);
    if (setting && preference?.[setting] === false) {
      await admin.from("notification_deliveries").upsert({
        notification_id: notification.id,
        device_token_id: token.id,
        status: "skipped",
        error_code: "USER_PREFERENCE",
        attempted_at: new Date().toISOString(),
      }, { onConflict: "notification_id,device_token_id" });
      continue;
    }
    if (isQuietNow(recipient, preference)) {
      deferred = true;
      continue;
    }
    eligible.push(token);
  }

  for (let offset = 0; offset < eligible.length; offset += 20) {
    const chunk = eligible.slice(offset, offset + 20);
    const results = await Promise.all(chunk.map(async (token) => ({
      token,
      result: await sendMessage(accessToken, projectId, token, notification),
    })));
    for (const { token, result } of results) {
      if (result.ok) sent += 1;
      else failed += 1;
      if (!result.ok && !result.permanent) deferred = true;
      const { error } = await admin.from("notification_deliveries").upsert({
        notification_id: notification.id,
        device_token_id: token.id,
        status: result.ok ? "sent" : "failed",
        provider_message_id: result.messageId ?? null,
        error_code: result.code ?? null,
        attempted_at: new Date().toISOString(),
      }, { onConflict: "notification_id,device_token_id" });
      if (error) throw new Error(error.message);
      if (!result.ok && result.permanent) {
        await admin.from("device_tokens").update({ is_active: false }).eq("id", token.id);
      }
    }
  }

  const priorSent = Number(notification.data._dispatch_sent ?? 0);
  const priorFailed = Number(notification.data._dispatch_failed ?? 0);
  const complete = !deferred && !page.hasMore;
  const nextData = {
    ...notification.data,
    _dispatch_cursor: deferred ? notification.data._dispatch_cursor ?? null : page.cursor,
    _dispatch_sent: priorSent + sent,
    _dispatch_failed: priorFailed + failed,
  };
  const status = complete
    ? (priorSent + sent > 0 || priorFailed + failed === 0 ? "sent" : "failed")
    : "queued";
  const { error: updateError } = await admin.from("notifications").update({
    data: nextData,
    status,
    sent_at: complete ? new Date().toISOString() : null,
  }).eq("id", notification.id).eq("status", "queued");
  if (updateError) throw new Error(updateError.message);
  return { id: notification.id, sent, failed, deferred, complete, status };
}

Deno.serve(async (request) => {
  const preflight = handlePreflight(request);
  if (preflight) return preflight;
  if (!await authorize(request)) return jsonResponse(request, { error: "Unauthorized" }, 401);
  try {
    const body = await readJson<DispatchBody>(request);
    const batchSize = Math.max(1, Math.min(500, Math.trunc(body.batchSize ?? 200)));
    if (body.notificationId && !uuidPattern.test(body.notificationId)) {
      return jsonResponse(request, { error: "Invalid notification id" }, 400);
    }
    const projectId = Deno.env.get("FCM_PROJECT_ID")?.trim();
    if (!projectId) throw new Error("FCM project is not configured");
    const admin = serviceClient();
    let query = admin.from("notifications").select("id,target_user_id,type,title_ar,body_ar,data,audience")
      .eq("status", "queued")
      .or(`scheduled_at.is.null,scheduled_at.lte.${new Date().toISOString()}`)
      .order("created_at", { ascending: true }).limit(body.notificationId ? 1 : 10);
    if (body.notificationId) query = query.eq("id", body.notificationId);
    const { data, error } = await query;
    if (error) throw new Error(error.message);
    if (!data?.length) return jsonResponse(request, { processed: 0, results: [] });
    const accessToken = await getGoogleAccessToken();
    const results = [];
    for (const notification of data as NotificationRow[]) {
      results.push(await dispatchOne(notification, batchSize, accessToken, projectId));
    }
    return jsonResponse(request, { processed: results.length, results });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Notification dispatch failed";
    return jsonResponse(request, { error: message }, 400);
  }
});
