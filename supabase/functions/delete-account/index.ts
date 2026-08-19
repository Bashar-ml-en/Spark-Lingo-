import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const JSON_CONTENT_TYPE = "application/json; charset=utf-8";
const MAX_BODY_BYTES = 4 * 1024;

class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly publicMessage: string,
  ) {
    super(publicMessage);
  }
}

function configuredValue(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new HttpError(503, "configuration_error", "Account deletion is temporarily unavailable.");
  }
  return value;
}

function corsHeaders(req: Request): Record<string, string> {
  const headers: Record<string, string> = {
    "Access-Control-Allow-Headers": "authorization, apikey, x-client-info, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Cache-Control": "no-store",
    "Vary": "Origin",
  };
  const origin = req.headers.get("origin");
  if (!origin) return headers;

  const allowed = new Set(
    (Deno.env.get("ALLOWED_ORIGINS") ?? "")
      .split(",")
      .map((value) => value.trim())
      .filter(Boolean),
  );
  if (!allowed.has(origin)) {
    throw new HttpError(403, "origin_not_allowed", "This web origin is not allowed.");
  }
  return { ...headers, "Access-Control-Allow-Origin": origin };
}

function jsonResponse(payload: Record<string, unknown>, status: number, cors: Record<string, string>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...cors, "Content-Type": JSON_CONTENT_TYPE },
  });
}

function assertRequestSize(req: Request): void {
  const header = req.headers.get("content-length");
  if (!header) return;
  const byteLength = Number(header);
  if (!Number.isFinite(byteLength) || byteLength < 0 || byteLength > MAX_BODY_BYTES) {
    throw new HttpError(413, "request_too_large", "The request is too large.");
  }
}

async function boundedRequest(req: Request): Promise<Request> {
  assertRequestSize(req);
  const reader = req.body?.getReader();
  if (!reader) {
    return new Request(req.url, { method: req.method, headers: req.headers, body: new Uint8Array() });
  }

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
  const headers = new Headers(req.headers);
  headers.set("content-length", String(totalBytes));
  return new Request(req.url, { method: req.method, headers, body });
}

async function authenticatedUser(req: Request) {
  const authorization = req.headers.get("authorization") ?? "";
  const accessToken = authorization.match(/^Bearer\s+(.+)$/i)?.[1]?.trim();
  if (!accessToken || accessToken.length > 4_096) {
    throw new HttpError(401, "authentication_required", "Sign in to manage your account.");
  }

  const userClient = createClient(
    configuredValue("SUPABASE_URL"),
    configuredValue("SUPABASE_ANON_KEY"),
    {
      auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false },
      global: { headers: { Authorization: `Bearer ${accessToken}` } },
    },
  );
  const { data, error } = await userClient.auth.getUser(accessToken);
  if (error || !data.user) {
    throw new HttpError(401, "authentication_required", "Sign in to manage your account.");
  }
  return data.user;
}

async function confirmedDeletion(req: Request): Promise<void> {
  const contentType = req.headers.get("content-type")?.toLowerCase() ?? "";
  if (!contentType.startsWith("application/json")) {
    throw new HttpError(415, "unsupported_media_type", "Account deletion requires JSON.");
  }
  try {
    const body: unknown = await req.json();
    if (typeof body !== "object" || body === null || Array.isArray(body)
      || (body as Record<string, unknown>).confirmation !== "DELETE") {
      throw new HttpError(400, "confirmation_required", "Confirm account deletion before continuing.");
    }
  } catch (error) {
    if (error instanceof HttpError) throw error;
    throw new HttpError(400, "invalid_json", "The request body is not valid JSON.");
  }
}

serve(async (req) => {
  const requestId = crypto.randomUUID();
  let cors: Record<string, string> = { "Cache-Control": "no-store" };

  try {
    cors = corsHeaders(req);
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }
    if (req.method !== "POST") {
      throw new HttpError(405, "method_not_allowed", "Use POST for this endpoint.");
    }

    const user = await authenticatedUser(req);
    await confirmedDeletion(await boundedRequest(req));

    // The user ID comes only from a verified JWT. The service-role credential
    // never reaches a client and is used only for this admin operation.
    const adminClient = createClient(
      configuredValue("SUPABASE_URL"),
      configuredValue("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false } },
    );
    const { error } = await adminClient.auth.admin.deleteUser(user.id);
    if (error) {
      console.error(JSON.stringify({ event: "account_delete_error", request_id: requestId, code: error.code ?? "unknown" }));
      throw new HttpError(503, "account_delete_failed", "Account deletion could not be completed.");
    }

    console.info(JSON.stringify({ event: "account_deleted", request_id: requestId }));
    return jsonResponse({ deleted: true }, 200, cors);
  } catch (error) {
    const failure = error instanceof HttpError
      ? error
      : new HttpError(500, "internal_error", "The request could not be completed.");
    console.error(JSON.stringify({
      event: "delete_account_request_error",
      request_id: requestId,
      status: failure.status,
      code: failure.code,
    }));
    return jsonResponse(
      { error: failure.publicMessage, code: failure.code, request_id: requestId },
      failure.status,
      cors,
    );
  }
});
