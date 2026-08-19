/**
 * Staging-only RLS, consent, account-deletion, and AI-control smoke tests.
 *
 * This script contains no credentials or staging endpoint values and has no
 * production fallback. Its shared target guard includes a reviewed public
 * production project deny-list so a misconfigured staging variable fails
 * before the first request. It does not print environment values, bearer
 * tokens, API responses, or learner data. Run it only from a protected
 * `staging` CI environment with disposable test users; see
 * docs/CONSENT_AND_STAGING_SECURITY_OPERATIONS.md.
 */

import { validateStagingTarget } from "./staging_target_guard.ts";

type RuntimeExpectation = "disabled" | "enabled";

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required staging-only variable: ${name}`);
  return value;
}

// Re-run the same no-network guard immediately before this suite receives any
// network permission. This makes the standalone script fail closed as well.
const target = validateStagingTarget().url;
const anonKey = requiredEnvironment("SUPABASE_TEST_ANON_KEY");
const userAId = requiredEnvironment("SMOKE_USER_A_ID");
const userBId = requiredEnvironment("SMOKE_USER_B_ID");
const userAToken = requiredEnvironment("SMOKE_USER_A_ACCESS_TOKEN");
const userBToken = requiredEnvironment("SMOKE_USER_B_ACCESS_TOKEN");
const anonymousUserToken = requiredEnvironment("SMOKE_ANONYMOUS_ACCESS_TOKEN");
const runtimeExpectation = requiredEnvironment("SMOKE_EXPECT_AI_RUNTIME") as RuntimeExpectation;

if (runtimeExpectation !== "disabled" && runtimeExpectation !== "enabled") {
  throw new Error("SMOKE_EXPECT_AI_RUNTIME must be disabled or enabled.");
}

function endpoint(path: string): string {
  return new URL(path, target).toString();
}

function headers(token?: string, extra: HeadersInit = {}): Headers {
  const result = new Headers(extra);
  result.set("apikey", anonKey);
  result.set("Accept", "application/json");
  if (token) result.set("Authorization", `Bearer ${token}`);
  return result;
}

async function request(
  path: string,
  options: RequestInit = {},
  token?: string,
): Promise<Response> {
  const mergedHeaders = headers(token, options.headers);
  return await fetch(endpoint(path), { ...options, headers: mergedHeaders });
}

function assertStatus(
  response: Response,
  allowed: readonly number[],
  label: string,
): void {
  if (!allowed.includes(response.status)) {
    throw new Error(`${label} returned an unexpected HTTP status.`);
  }
}

async function jsonBody(response: Response): Promise<unknown> {
  try {
    return await response.json();
  } catch {
    throw new Error("A staging smoke endpoint returned an unreadable response.");
  }
}

function records(value: unknown): Record<string, unknown>[] {
  if (!Array.isArray(value) || !value.every((row) => row !== null && typeof row === "object")) {
    throw new Error("A staging smoke endpoint returned an unexpected data shape.");
  }
  return value as Record<string, unknown>[];
}

async function selectProfiles(token?: string, id?: string): Promise<Record<string, unknown>[]> {
  const filter = id ? `&id=eq.${encodeURIComponent(id)}` : "";
  const response = await request(
    `/rest/v1/profiles?select=id${filter}`,
    { method: "GET" },
    token,
  );
  
  // The anon role is not granted SELECT on profiles, so PostgREST returns 401/403/404.
  if (!token && (response.status === 401 || response.status === 403 || response.status === 404)) {
    return [];
  }
  
  assertStatus(response, [200], "profile read");
  return records(await jsonBody(response));
}

async function assertRlsIsolation(): Promise<void> {
  const anonymousProfiles = await selectProfiles();
  if (anonymousProfiles.length !== 0) {
    throw new Error("Anonymous access can read protected profiles.");
  }

  const aOwnProfile = await selectProfiles(userAToken, userAId);
  if (aOwnProfile.length !== 1 || aOwnProfile[0]["id"] !== userAId) {
    throw new Error("Test user A cannot read its own profile fixture.");
  }

  const bOwnProfile = await selectProfiles(userBToken, userBId);
  if (bOwnProfile.length !== 1 || bOwnProfile[0]["id"] !== userBId) {
    throw new Error("Test user B cannot read its own profile fixture.");
  }

  const aReadsB = await selectProfiles(userAToken, userBId);
  const bReadsA = await selectProfiles(userBToken, userAId);
  if (aReadsB.length !== 0 || bReadsA.length !== 0) {
    throw new Error("Cross-account profile read was not blocked by RLS.");
  }

  const anonymousConsent = await request(
    "/rest/v1/rpc/has_active_user_consent",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ p_document_key: "ai_processing" }),
    },
  );
  assertStatus(anonymousConsent, [401, 403], "anonymous consent RPC");
}

async function assertQuotaRpcBoundary(): Promise<void> {
  // Quota mutation must be impossible through a learner's Data API token. The
  // test uses random request IDs and never reaches an AI/provider endpoint.
  // 404 is acceptable here because PostgREST may hide a function with no
  // executable grant instead of returning a permission error.
  const requestId = crypto.randomUUID();
  const deniedStatuses = [401, 403, 404];
  const calls: Array<{ name: string; body: Record<string, string> }> = [
    {
      name: "legacy quota reservation",
      body: { p_action: "chat", p_request_id: requestId },
    },
    {
      name: "legacy quota completion",
      body: { p_request_id: requestId },
    },
    {
      name: "legacy quota release",
      body: { p_request_id: requestId },
    },
    {
      name: "server-only quota reservation",
      body: { p_user_id: userAId, p_action: "chat", p_request_id: requestId },
    },
    {
      name: "server-only provider-submission marker",
      body: { p_user_id: userAId, p_request_id: requestId },
    },
    {
      name: "server-only quota completion",
      body: { p_user_id: userAId, p_request_id: requestId },
    },
    {
      name: "server-only pre-send release",
      body: { p_user_id: userAId, p_request_id: requestId },
    },
  ];

  const routes = [
    "reserve_ai_quota",
    "complete_ai_quota",
    "release_ai_quota",
    "reserve_ai_quota_for_user",
    "mark_ai_quota_provider_submission",
    "complete_ai_quota_for_user",
    "release_ai_quota_pre_send_failure",
  ];

  for (let index = 0; index < calls.length; index += 1) {
    const response = await request(
      `/rest/v1/rpc/${routes[index]}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(calls[index].body),
      },
      userAToken,
    );
    assertStatus(response, deniedStatuses, calls[index].name);
  }
}

async function assertDeletionEndpointBindsIdentity(): Promise<void> {
  // An invalid confirmation plus an arbitrary second user id must not result
  // in a deletion. This request carries no delete-capable confirmation.
  const response = await request(
    "/functions/v1/delete-account",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ confirmation: "NOT_DELETE", user_id: userBId }),
    },
    userAToken,
  );
  assertStatus(response, [400], "account-deletion identity guard");
}

async function invokeAi(token?: string): Promise<Response> {
  return await request(
    "/functions/v1/sparky-ai?action=chat",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      // Runtime and consent checks occur before body parsing/provider calls.
      body: JSON.stringify({ targetLanguage: "en", messages: [] }),
    },
    token,
  );
}

async function assertAiControls(): Promise<void> {
  const unauthenticated = await invokeAi();
  assertStatus(unauthenticated, [401, 403], "unauthenticated AI request");

  const anonymous = await invokeAi(anonymousUserToken);
  assertStatus(anonymous, [403], "anonymous AI request");

  if (runtimeExpectation === "disabled") {
    const disabled = await invokeAi(userAToken);
    assertStatus(disabled, [503], "AI kill switch");
    return;
  }

  // A separately provisioned recoverable test account with no current AI
  // consent proves the server boundary without invoking an AI provider.
  const noConsentToken = requiredEnvironment("SMOKE_NO_CONSENT_ACCESS_TOKEN");
  const missingConsent = await invokeAi(noConsentToken);
  assertStatus(missingConsent, [403], "AI consent enforcement");
}

await assertRlsIsolation();
await assertQuotaRpcBoundary();
await assertDeletionEndpointBindsIdentity();
await assertAiControls();

console.log("Staging security smoke tests passed.");
