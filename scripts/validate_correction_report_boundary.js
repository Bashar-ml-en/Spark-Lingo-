#!/usr/bin/env node
"use strict";

/**
 * Prevent correction-report regressions while Flutter and React Native share
 * the same server boundary. This is source-only; protected staging smoke
 * tests still prove the deployed RLS/RPC behavior.
 */

const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const paths = {
  migration: path.join(root, "supabase", "migrations", "016_correction_items.sql"),
  grants: path.join(root, "supabase", "migrations", "018_correction_items_rpc_grants.sql"),
  edge: path.join(root, "supabase", "functions", "sparky-ai", "index.ts"),
  client: path.join(root, "lib", "core", "services", "ai_service.dart"),
  reviewDeck: path.join(root, "lib", "core", "services", "correction_review_service.dart"),
  authConfig: path.join(root, "lib", "core", "constants", "auth_config.dart"),
};

function read(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function requirePattern(value, pattern, message) {
  if (!pattern.test(value)) {
    throw new Error(`Correction-report boundary validation failed: ${message}`);
  }
}

const migration = read(paths.migration);
const grants = read(paths.grants);
const edge = read(paths.edge);
const client = read(paths.client);
const reviewDeck = read(paths.reviewDeck);
const authConfig = read(paths.authConfig);

requirePattern(
  migration,
  /alter\s+table\s+public\.learner_correction_items\s+enable\s+row\s+level\s+security/i,
  "correction items do not have RLS enabled",
);
if (/create\s+policy[\s\S]*learner_correction_items/i.test(migration)) {
  throw new Error(
    "Correction-report boundary validation failed: correction items must not expose a client RLS policy.",
  );
}
for (const functionName of [
  "record_learner_correction_item",
  "recent_learner_correction_items",
]) {
  requirePattern(
    grants,
    new RegExp(
      `grant\\s+execute\\s+on\\s+function\\s+public\\.${functionName}\\s*\\([\\s\\S]*?\\)\\s+to\\s+service_role`,
      "i",
    ),
    `${functionName} is not explicitly limited to service_role`,
  );
}
requirePattern(
  migration,
  /coalesce\(auth\.role\(\), ''\) <> 'service_role'/i,
  "correction RPCs do not verify the service role",
);
requirePattern(edge, /type Action = [^;]*"report"/, "report action is not allow-listed");
requirePattern(edge, /if \(action === "history" \|\| action === "report"\)/, "report is not isolated as a read-only action");
requirePattern(edge, /recentCorrectionItems\(/, "report action does not use the server-only correction reader");
requirePattern(edge, /persistCorrectionItem\(/, "scoring does not persist bounded corrections server-side");
requirePattern(
  client,
  /Future<SessionReport> fetchSessionReport[\s\S]*?throw const AIServiceException\(\s*'Session report is temporarily unavailable\.'\s*,?\s*\)/,
  "client treats a failed report request as an empty report",
);
requirePattern(
  reviewDeck,
  /Future<bool> saveCorrection\(\{[\s\S]*?required String userId,/,
  "local correction cards are not user-scoped",
);
requirePattern(
  reviewDeck,
  /Future<void> clearDeck\(String userId\)/,
  "local correction cards cannot be cleared after account deletion",
);
requirePattern(
  authConfig,
  /'ENABLE_GOOGLE_OAUTH',\s*defaultValue:\s*false/,
  "Google OAuth is not disabled until explicitly configured",
);
requirePattern(
  authConfig,
  /environment\s*==\s*'development'\s*&&\s*_testConsentRequested/,
  "test consent can be enabled outside development",
);

const unsafeWebReleaseScript = path.join(root, "scripts", "build_web_release.sh");
if (fs.existsSync(unsafeWebReleaseScript)) {
  throw new Error(
    "Correction-report boundary validation failed: unsafe local production web-build script must not be committed.",
  );
}

console.log("Correction-report boundary validation passed.");
