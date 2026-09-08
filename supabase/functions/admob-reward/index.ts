import { jsonResponse, rpcError, serviceClient } from "../_shared/http.ts";

type VerifierKey = { keyId: number; base64: string };
type VerifierKeys = { keys?: VerifierKey[] };

const keyEndpoint = "https://www.gstatic.com/admob/reward/verifier-keys.json";
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
let cachedKeys: { expiresAt: number; value: VerifierKey[] } | null = null;

function base64UrlBytes(value: string): Uint8Array {
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
  return Uint8Array.from(atob(padded), (character) => character.charCodeAt(0));
}

function ownedArrayBuffer(bytes: Uint8Array): ArrayBuffer {
  return Uint8Array.from(bytes).buffer;
}

function readDerLength(bytes: Uint8Array, offset: number): [number, number] {
  const first = bytes[offset];
  if ((first & 0x80) === 0) return [first, offset + 1];
  const count = first & 0x7f;
  if (count < 1 || count > 2) throw new Error("Invalid ECDSA signature length");
  let length = 0;
  for (let index = 0; index < count; index += 1) length = (length << 8) | bytes[offset + 1 + index];
  return [length, offset + 1 + count];
}

function derEcdsaToRaw(signature: Uint8Array): Uint8Array {
  if (signature[0] !== 0x30) throw new Error("Invalid ECDSA signature");
  const [, sequenceStart] = readDerLength(signature, 1);
  let offset = sequenceStart;
  const values: Uint8Array[] = [];
  for (let part = 0; part < 2; part += 1) {
    if (signature[offset] !== 0x02) throw new Error("Invalid ECDSA integer");
    const [length, valueStart] = readDerLength(signature, offset + 1);
    let value = signature.slice(valueStart, valueStart + length);
    while (value.length > 32 && value[0] === 0) value = value.slice(1);
    if (value.length > 32) throw new Error("Invalid ECDSA integer size");
    const padded = new Uint8Array(32);
    padded.set(value, 32 - value.length);
    values.push(padded);
    offset = valueStart + length;
  }
  const raw = new Uint8Array(64);
  raw.set(values[0], 0);
  raw.set(values[1], 32);
  return raw;
}

async function verifierKeys(): Promise<VerifierKey[]> {
  if (cachedKeys && cachedKeys.expiresAt > Date.now()) return cachedKeys.value;
  const response = await fetch(keyEndpoint);
  if (!response.ok) throw new Error("Unable to fetch AdMob verifier keys");
  const payload = await response.json() as VerifierKeys;
  const keys = payload.keys?.filter((key) => Number.isInteger(key.keyId) && key.base64) ?? [];
  if (keys.length === 0) throw new Error("No AdMob verifier keys available");
  cachedKeys = { expiresAt: Date.now() + 23 * 60 * 60 * 1000, value: keys };
  return keys;
}

async function verifyCallback(request: Request): Promise<URLSearchParams> {
  const rawQuery = request.url.split("?", 2)[1] ?? "";
  const signatureMarker = "&signature=";
  const signatureIndex = rawQuery.indexOf(signatureMarker);
  if (signatureIndex < 1) throw new Error("Missing AdMob signature");
  const signedContent = rawQuery.slice(0, signatureIndex);
  const params = new URL(request.url).searchParams;
  const signatureValue = params.get("signature");
  const keyId = Number(params.get("key_id"));
  if (!signatureValue || !Number.isInteger(keyId)) throw new Error("Invalid AdMob signature metadata");
  const verifier = (await verifierKeys()).find((key) => key.keyId === keyId);
  if (!verifier) throw new Error("Unknown AdMob signing key");
  const key = await crypto.subtle.importKey(
    "spki",
    Uint8Array.from(atob(verifier.base64), (character) => character.charCodeAt(0)),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["verify"],
  );
  const valid = await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    ownedArrayBuffer(derEcdsaToRaw(base64UrlBytes(signatureValue))),
    new TextEncoder().encode(signedContent),
  );
  if (!valid) throw new Error("Invalid AdMob callback signature");
  return params;
}

Deno.serve(async (request) => {
  if (request.method !== "GET") return jsonResponse(request, { error: "GET required" }, 405);
  try {
    const params = await verifyCallback(request);
    const userId = params.get("user_id") ?? "";
    const transactionId = params.get("transaction_id")?.trim() ?? "";
    const adUnit = params.get("ad_unit")?.trim() ?? "";
    const rewardItem = params.get("reward_item")?.trim() ?? "";
    const rewardAmount = Number(params.get("reward_amount"));
    const timestamp = Number(params.get("timestamp"));
    if (!uuidPattern.test(userId)) throw new Error("Unmapped reward user");
    if (!transactionId || transactionId.length > 180) throw new Error("Invalid reward transaction");
    if (!Number.isFinite(rewardAmount) || rewardAmount <= 0) throw new Error("Invalid reward amount");
    if (!Number.isFinite(timestamp)) throw new Error("Invalid reward timestamp");
    const callbackAge = Date.now() - timestamp;
    if (callbackAge < -10 * 60 * 1000 || callbackAge > 48 * 60 * 60 * 1000) {
      throw new Error("Reward timestamp is outside the accepted window");
    }
    const allowedUnits = [
      Deno.env.get("ADMOB_REWARDED_ANDROID_ID"),
      Deno.env.get("ADMOB_REWARDED_IOS_ID"),
    ].map((value) => value?.trim()).filter((value): value is string => Boolean(value));
    if (allowedUnits.length === 0 || !allowedUnits.includes(adUnit)) throw new Error("Unexpected ad unit");
    const expectedItem = Deno.env.get("ADMOB_REWARD_ITEM")?.trim() || "coins";
    if (rewardItem !== expectedItem) throw new Error("Unexpected reward item");

    const callbackData: Record<string, string> = {};
    for (const [key, value] of params.entries()) {
      if (key !== "signature") callbackData[key] = value;
    }
    const client = serviceClient();
    const { data, error } = await client.rpc("claim_verified_admob_reward", {
      p_transaction_id: transactionId,
      p_user_id: userId,
      p_ad_unit_id: adUnit,
      p_reward_item: rewardItem,
      p_provider_reward_amount: rewardAmount,
      p_provider_timestamp: new Date(timestamp).toISOString(),
      p_callback_data: callbackData,
    });
    rpcError(error);
    return jsonResponse(request, { received: true, reward: data });
  } catch (error) {
    const message = error instanceof Error ? error.message : "AdMob verification failed";
    return jsonResponse(request, { error: message }, 400);
  }
});
