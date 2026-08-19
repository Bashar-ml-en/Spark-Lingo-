import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const JSON_CONTENT_TYPE = "application/json; charset=utf-8";
const MAX_BODY_BYTES = 256 * 1024;
const MAX_SIGNATURE_AGE_SECONDS = 5 * 60;
const SUPPORTED_ENTITLEMENT_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "NON_RENEWING_PURCHASE",
  "CANCELLATION",
  "UNCANCELLATION",
  "EXPIRATION",
  "BILLING_ISSUE",
  "SUBSCRIPTION_PAUSED",
  "PRODUCT_CHANGE",
  "SUBSCRIPTION_EXTENDED",
  "REFUND_REVERSED",
]);

type JsonRecord = Record<string, unknown>;
type BillingWebhookConfig = {
  authorization: string;
  signingSecret: string;
  allowedAppIds: Set<string>;
  allowedEntitlementIds: Set<string>;
  allowedEnvironments: Set<string>;
  supabaseUrl: string;
  serviceRoleKey: string;
};
type ParsedEvent = {
  eventId: string;
  eventType: string;
  customerIds: string[];
  entitlementIds: string[];
  environment: string;
  productId: string | null;
  eventAt: string;
  expiresAt: string | null;
};

class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly publicMessage: string,
  ) {
    super(publicMessage);
  }
}

function jsonResponse(payload: JsonRecord, status: number): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Cache-Control": "no-store",
      "Content-Type": JSON_CONTENT_TYPE,
    },
  });
}

function configuredValue(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new HttpError(
      503,
      "configuration_error",
      "Billing verification is temporarily unavailable.",
    );
  }
  return value;
}

function configuredCsv(name: string, maximumValues: number): Set<string> {
  const values = new Set(
    configuredValue(name)
      .split(",")
      .map((value) => value.trim())
      .filter(Boolean),
  );
  if (values.size === 0 || values.size > maximumValues
    || [...values].some((value) => value.length > 256 || value === "*")) {
    throw new HttpError(
      503,
      "configuration_error",
      "Billing verification is temporarily unavailable.",
    );
  }
  return values;
}

function billingConfig(): BillingWebhookConfig {
  // The webhook remains off until an approved operator explicitly turns it on
  // in hosted Edge Function secrets. Anything other than the exact value true
  // fails closed.
  if (Deno.env.get("BILLING_WEBHOOK_ENABLED")?.trim().toLowerCase() !== "true") {
    throw new HttpError(
      503,
      "billing_disabled",
      "Billing verification is temporarily unavailable.",
    );
  }

  return {
    authorization: configuredValue("REVENUECAT_WEBHOOK_AUTHORIZATION"),
    signingSecret: configuredValue("REVENUECAT_WEBHOOK_SIGNING_SECRET"),
    allowedAppIds: configuredCsv("REVENUECAT_ALLOWED_APP_IDS", 20),
    allowedEntitlementIds: configuredCsv("REVENUECAT_ALLOWED_ENTITLEMENT_IDS", 20),
    allowedEnvironments: configuredCsv("REVENUECAT_ALLOWED_ENVIRONMENTS", 2),
    supabaseUrl: configuredValue("SUPABASE_URL"),
    serviceRoleKey: configuredValue("SUPABASE_SERVICE_ROLE_KEY"),
  };
}

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function assertRequestSize(req: Request): void {
  const contentLength = req.headers.get("content-length");
  if (!contentLength) return;
  const bytes = Number(contentLength);
  if (!Number.isFinite(bytes) || bytes < 0 || bytes > MAX_BODY_BYTES) {
    throw new HttpError(413, "request_too_large", "The request is too large.");
  }
}

async function readRawBody(req: Request): Promise<Uint8Array> {
  assertRequestSize(req);
  const reader = req.body?.getReader();
  if (!reader) return new Uint8Array();

  const chunks: Uint8Array[] = [];
  let totalBytes = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      totalBytes += value.byteLength;
      if (totalBytes > MAX_BODY_BYTES) {
        await reader.cancel();
        throw new HttpError(413, "request_too_large", "The request is too large.");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }

  const body = new Uint8Array(totalBytes);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return body;
}

function constantTimeEqual(left: Uint8Array, right: Uint8Array): boolean {
  // Avoid an early exit on mismatched bytes. The length check is unavoidable
  // because HMAC-SHA256 has a fixed expected length.
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference === 0;
}

function concatenate(left: Uint8Array, right: Uint8Array): Uint8Array {
  const result = new Uint8Array(left.length + right.length);
  result.set(left, 0);
  result.set(right, left.length);
  return result;
}

function hexToBytes(value: string): Uint8Array | null {
  if (!/^[0-9a-f]{64}$/i.test(value)) return null;
  const result = new Uint8Array(value.length / 2);
  for (let index = 0; index < value.length; index += 2) {
    const byte = Number.parseInt(value.slice(index, index + 2), 16);
    if (!Number.isFinite(byte)) return null;
    result[index / 2] = byte;
  }
  return result;
}

function signatureParts(header: string | null): { timestamp: string; signature: Uint8Array } {
  if (!header || header.length > 512) {
    throw new HttpError(401, "invalid_signature", "Unauthorized billing webhook.");
  }

  const parts = new Map<string, string>();
  for (const segment of header.split(",")) {
    const separator = segment.indexOf("=");
    if (separator <= 0) {
      throw new HttpError(401, "invalid_signature", "Unauthorized billing webhook.");
    }
    const key = segment.slice(0, separator).trim();
    const value = segment.slice(separator + 1).trim();
    if (!key || !value || parts.has(key)) {
      throw new HttpError(401, "invalid_signature", "Unauthorized billing webhook.");
    }
    parts.set(key, value);
  }

  const timestamp = parts.get("t");
  const signature = parts.get("v1");
  const suppliedSignature = signature ? hexToBytes(signature) : null;
  if (!timestamp || !/^\d{10,13}$/.test(timestamp) || !suppliedSignature) {
    throw new HttpError(401, "invalid_signature", "Unauthorized billing webhook.");
  }

  const timestampSeconds = Number(timestamp);
  if (!Number.isSafeInteger(timestampSeconds)
    || Math.abs(Date.now() / 1000 - timestampSeconds) > MAX_SIGNATURE_AGE_SECONDS) {
    throw new HttpError(401, "expired_signature", "Unauthorized billing webhook.");
  }
  return { timestamp, signature: suppliedSignature };
}

async function verifyRequest(
  req: Request,
  rawBody: Uint8Array,
  config: BillingWebhookConfig,
): Promise<void> {
  const authorization = req.headers.get("authorization");
  const expectedAuthorization = new TextEncoder().encode(config.authorization);
  const suppliedAuthorization = new TextEncoder().encode(authorization ?? "");
  if (!constantTimeEqual(suppliedAuthorization, expectedAuthorization)) {
    throw new HttpError(401, "invalid_authorization", "Unauthorized billing webhook.");
  }

  const { timestamp, signature } = signatureParts(
    req.headers.get("x-revenuecat-webhook-signature"),
  );
  const encoder = new TextEncoder();
  const hmacKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(config.signingSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signedPayload = concatenate(encoder.encode(`${timestamp}.`), rawBody);
  const expectedSignature = new Uint8Array(
    await crypto.subtle.sign("HMAC", hmacKey, signedPayload),
  );
  if (!constantTimeEqual(signature, expectedSignature)) {
    throw new HttpError(401, "invalid_signature", "Unauthorized billing webhook.");
  }
}

function requiredText(record: JsonRecord, key: string, maximumLength: number): string {
  const value = record[key];
  if (typeof value !== "string") {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }
  const normalized = value.trim();
  if (!normalized || normalized.length > maximumLength || normalized.includes("\u0000")) {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }
  return normalized;
}

function optionalText(record: JsonRecord, key: string, maximumLength: number): string | null {
  const value = record[key];
  if (value === undefined || value === null) return null;
  if (typeof value !== "string") {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }
  const normalized = value.trim();
  if (!normalized || normalized.length > maximumLength || normalized.includes("\u0000")) {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }
  return normalized;
}

function uniqueTextValues(
  values: unknown[],
  maximumValues: number,
  maximumLength: number,
): string[] {
  if (values.length === 0 || values.length > maximumValues) {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }
  const normalized = new Set<string>();
  for (const value of values) {
    if (typeof value !== "string") {
      throw new HttpError(400, "invalid_event", "The billing event is invalid.");
    }
    const text = value.trim();
    if (!text || text.length > maximumLength || text.includes("\u0000")) {
      throw new HttpError(400, "invalid_event", "The billing event is invalid.");
    }
    normalized.add(text);
  }
  if (normalized.size === 0 || normalized.size > maximumValues) {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }
  return [...normalized];
}

function timestampFromMilliseconds(value: unknown, required: boolean): string | null {
  if (value === null || value === undefined) {
    if (required) {
      throw new HttpError(400, "invalid_event", "The billing event is invalid.");
    }
    return null;
  }
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value <= 0) {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime()) || parsed.getUTCFullYear() < 2020 || parsed.getUTCFullYear() > 2200) {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }
  return parsed.toISOString();
}

function parseEvent(rawBody: Uint8Array, config: BillingWebhookConfig): ParsedEvent | null {
  const content = new TextDecoder("utf-8", { fatal: true }).decode(rawBody);
  let payload: unknown;
  try {
    payload = JSON.parse(content);
  } catch {
    throw new HttpError(400, "invalid_json", "The billing event is invalid.");
  }
  if (!isRecord(payload) || payload.api_version !== "1.0" || !isRecord(payload.event)) {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }

  const event = payload.event;
  const eventType = requiredText(event, "type", 64).toUpperCase();
  // RevenueCat can add event types. A valid, verified event outside the
  // entitlement lifecycle is acknowledged but can never change access.
  if (!SUPPORTED_ENTITLEMENT_EVENTS.has(eventType)) return null;

  const appId = requiredText(event, "app_id", 256);
  const environment = requiredText(event, "environment", 32).toUpperCase();
  if (!config.allowedAppIds.has(appId) || !config.allowedEnvironments.has(environment)) {
    throw new HttpError(403, "event_not_allowed", "Unauthorized billing webhook.");
  }
  if (environment !== "SANDBOX" && environment !== "PRODUCTION") {
    throw new HttpError(400, "invalid_event", "The billing event is invalid.");
  }

  const aliases = event.aliases === undefined || event.aliases === null
    ? []
    : Array.isArray(event.aliases)
    ? event.aliases
    : (() => {
      throw new HttpError(400, "invalid_event", "The billing event is invalid.");
    })();
  const customerIds = uniqueTextValues(
    [requiredText(event, "app_user_id", 256), optionalText(event, "original_app_user_id", 256), ...aliases]
      .filter((value): value is string => value !== null),
    32,
    256,
  );

  const listedEntitlements = event.entitlement_ids === undefined || event.entitlement_ids === null
    ? []
    : Array.isArray(event.entitlement_ids)
    ? event.entitlement_ids
    : (() => {
      throw new HttpError(400, "invalid_event", "The billing event is invalid.");
    })();
  const legacyEntitlement = optionalText(event, "entitlement_id", 128);
  const rawEntitlements = [...listedEntitlements];
  if (legacyEntitlement != null) rawEntitlements.push(legacyEntitlement);
  if (rawEntitlements.length === 0) return null;
  const entitlementIds = uniqueTextValues(rawEntitlements, 20, 128)
    .filter((id) => config.allowedEntitlementIds.has(id));
  if (entitlementIds.length === 0) return null;

  return {
    eventId: requiredText(event, "id", 256),
    eventType,
    customerIds,
    entitlementIds,
    environment,
    productId: optionalText(event, "product_id", 256),
    eventAt: timestampFromMilliseconds(event.event_timestamp_ms, true)!,
    expiresAt: timestampFromMilliseconds(event.expiration_at_ms, false),
  };
}

async function sha256Hex(value: Uint8Array): Promise<string> {
  const hash = new Uint8Array(await crypto.subtle.digest("SHA-256", value) as ArrayBuffer);
  return [...hash].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function safeLog(event: string, fields: Record<string, string | boolean | number> = {}): void {
  // Do not add raw webhook bodies, subscriber IDs, transaction IDs, receipts,
  // authorization headers, or secrets to billing logs.
  console.log(JSON.stringify({ event, ...fields }));
}

serve(async (req) => {
  const requestId = crypto.randomUUID();
  try {
    if (req.method !== "POST") {
      throw new HttpError(405, "method_not_allowed", "Use POST for this endpoint.");
    }
    const contentType = req.headers.get("content-type")?.toLowerCase() ?? "";
    if (!contentType.startsWith("application/json")) {
      throw new HttpError(415, "unsupported_media_type", "The billing event must be JSON.");
    }

    const config = billingConfig();
    const rawBody = await readRawBody(req);
    await verifyRequest(req, rawBody, config);
    const parsed = parseEvent(rawBody, config);
    if (parsed === null) {
      safeLog("billing_webhook_ignored", { request_id: requestId });
      return jsonResponse({ received: true, processed: false }, 200);
    }

    const payloadHash = await sha256Hex(rawBody);
    const client = createClient(config.supabaseUrl, config.serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false },
    });
    for (const entitlementId of parsed.entitlementIds) {
      const { error } = await client.rpc("apply_revenuecat_entitlement_event", {
        p_event_id: parsed.eventId,
        p_event_type: parsed.eventType,
        p_customer_ids: parsed.customerIds,
        p_entitlement_id: entitlementId,
        p_environment: parsed.environment,
        p_product_id: parsed.productId,
        p_event_at: parsed.eventAt,
        p_expires_at: parsed.expiresAt,
        p_payload_sha256: payloadHash,
      });
      if (error) {
        // Do not acknowledge a verified lifecycle event that was not stored:
        // RevenueCat retries non-2xx responses, giving a newly-linked account
        // or a transient database issue a chance to recover safely.
        safeLog("billing_webhook_persist_failed", {
          request_id: requestId,
          event_type: parsed.eventType,
        });
        throw new HttpError(
          503,
          "billing_persistence_unavailable",
          "Billing verification is temporarily unavailable.",
        );
      }
    }

    safeLog("billing_webhook_processed", {
      request_id: requestId,
      event_type: parsed.eventType,
      entitlement_count: parsed.entitlementIds.length,
    });
    return jsonResponse({ received: true, processed: true }, 200);
  } catch (error) {
    const failure = error instanceof HttpError
      ? error
      : new HttpError(500, "internal_error", "Billing verification is temporarily unavailable.");
    safeLog("billing_webhook_failed", {
      request_id: requestId,
      status: failure.status,
      code: failure.code,
    });
    return jsonResponse(
      { error: failure.publicMessage, code: failure.code, request_id: requestId },
      failure.status,
    );
  }
});
