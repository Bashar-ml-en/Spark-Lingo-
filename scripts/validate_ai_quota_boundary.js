#!/usr/bin/env node
"use strict";

/**
 * Static safety checks for the AI quota boundary.
 *
 * This is intentionally not a replacement for staging migration/RLS tests.
 * It catches regressions that would otherwise make an authenticated client
 * capable of mutating quota state or release a reservation after an ambiguous
 * upstream submission. It reads source only and makes no network/database
 * request, so it is safe in local/CI validation.
 */

const fs = require("node:fs");
const path = require("node:path");

const repositoryRoot = path.resolve(__dirname, "..");
const migrationPath = path.join(
  repositoryRoot,
  "supabase",
  "migrations",
  "011_server_only_ai_quota_lifecycle.sql",
);
const edgeFunctionPath = path.join(
  repositoryRoot,
  "supabase",
  "functions",
  "sparky-ai",
  "index.ts",
);

function source(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function requireCondition(condition, message) {
  if (!condition) throw new Error(`AI quota boundary validation failed: ${message}`);
}

function requirePattern(value, pattern, message) {
  requireCondition(pattern.test(value), message);
}

const migration = source(migrationPath);
const edgeFunction = source(edgeFunctionPath);

for (const functionName of [
  "reserve_ai_quota(text)",
  "reserve_ai_quota(text, uuid)",
  "complete_ai_quota(uuid)",
  "release_ai_quota(uuid)",
]) {
  requirePattern(
    migration,
    new RegExp(
      `revoke\\s+all\\s+on\\s+function\\s+public\\.${functionName.replace(/[()]/g, "\\$&").replace(/, /g, ",\\s*")}\\s+from\\s+public,\\s*anon,\\s*authenticated,\\s*service_role`,
      "i",
    ),
    `legacy ${functionName} is not revoked from every Data API role`,
  );
}

for (const functionName of [
  "reserve_ai_quota_for_user(uuid, text, uuid)",
  "mark_ai_quota_provider_submission(uuid, uuid)",
  "complete_ai_quota_for_user(uuid, uuid)",
  "release_ai_quota_pre_send_failure(uuid, uuid)",
]) {
  const baseName = functionName.slice(0, functionName.indexOf("("));
  requirePattern(
    migration,
    new RegExp(`create\\s+or\\s+replace\\s+function\\s+public\\.${baseName}\\s*\\(`, "i"),
    `${functionName} is missing`,
  );
  requirePattern(
    migration,
    new RegExp(`grant\\s+execute\\s+on\\s+function\\s+public\\.${functionName.replace(/[()]/g, "\\$&").replace(/, /g, ",\\s*")}\\s+to\\s+service_role`, "i"),
    `${functionName} is not granted to service_role`,
  );
}

requirePattern(
  migration,
  /coalesce\(auth\.role\(\), ''\) <> 'service_role'/i,
  "server-only RPCs do not verify the service-role claim",
);
requirePattern(
  migration,
  /status in \('reserved', 'submitted', 'completed'\)/i,
  "submitted quota state is missing from the ledger",
);
requirePattern(
  migration,
  /status = 'reserved'\s+and provider_submission_started_at is null/i,
  "pre-send release is not constrained to unsubmitted reservations",
);

requirePattern(
  edgeFunction,
  /configuredValue\("SUPABASE_SERVICE_ROLE_KEY"\)/,
  "Edge Function does not use the hosted service-role secret for quota mutation",
);
for (const rpcName of [
  "reserve_ai_quota_for_user",
  "mark_ai_quota_provider_submission",
  "complete_ai_quota_for_user",
  "release_ai_quota_pre_send_failure",
]) {
  requirePattern(edgeFunction, new RegExp(`rpc\\("${rpcName}"`), `Edge Function does not use ${rpcName}`);
}
requireCondition(
  !/rpc\("(?:reserve_ai_quota|complete_ai_quota|release_ai_quota)"/.test(edgeFunction),
  "Edge Function still invokes a legacy client-callable quota RPC",
);

const authenticationIndex = edgeFunction.indexOf("const authenticated = await authenticate(req);");
const serverQuotaClientIndex = edgeFunction.indexOf("const quotaClient = createServerQuotaClient()");
requireCondition(
  authenticationIndex >= 0 && serverQuotaClientIndex > authenticationIndex,
  "server quota client is created before caller identity verification",
);

const reservationStart = edgeFunction.indexOf("async function withQuotaReservation");
const reservationEnd = edgeFunction.indexOf("function tutorSystemPrompt");
const reservationSource = edgeFunction.slice(reservationStart, reservationEnd);
const releaseIndex = reservationSource.indexOf("await releasePreSendQuota");
const preSendGuardIndex = reservationSource.lastIndexOf('if (submissionState === "not_started")', releaseIndex);
requireCondition(
  releaseIndex >= 0 && preSendGuardIndex >= 0 && preSendGuardIndex < releaseIndex,
  "reservation release is not guarded as a proven pre-submit failure",
);

const providerFetchStart = edgeFunction.indexOf("async function providerFetch");
const providerFetchEnd = edgeFunction.indexOf("function tutorSystemPrompt");
const providerFetchSource = edgeFunction.slice(providerFetchStart, providerFetchEnd);
const markerIndex = providerFetchSource.indexOf("await markProviderSubmission()");
const fetchIndex = providerFetchSource.indexOf("fetch(endpoint");
requireCondition(
  markerIndex >= 0 && fetchIndex > markerIndex,
  "provider fetch is not preceded by the persistent submission marker",
);
requireCondition(
  (edgeFunction.match(/\bfetch\(/g) ?? []).length === 1,
  "a direct provider fetch bypasses providerFetch()",
);

console.log("AI quota boundary static validation passed.");
