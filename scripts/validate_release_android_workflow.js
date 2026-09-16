#!/usr/bin/env node
"use strict";

/**
 * Static, no-network regression guard for the reusable Android release
 * workflow. It prevents a future edit from reintroducing production defaults,
 * mutable manual dispatch, APK-only store output, or an unprotected source.
 */

const fs = require("node:fs");
const path = require("node:path");

const workflowPath = path.join(
  __dirname,
  "..",
  ".github",
  "workflows",
  "release-android.yml",
);
const workflow = fs.readFileSync(workflowPath, "utf8");

function requireFragment(fragment) {
  if (!workflow.includes(fragment)) {
    throw new Error(
      `Android release workflow is missing required safety control: ${fragment}`,
    );
  }
}

function rejectFragment(fragment, message) {
  if (workflow.includes(fragment)) throw new Error(message);
}

for (const fragment of [
  "workflow_call:",
  "permissions:",
  "contents: read",
  "verify-release-source:",
  'test "$EXPECTED_REF_TYPE" = "tag"',
  'test "$EXPECTED_PROTECTED" = "true"',
  'git describe --exact-match --tags HEAD',
  "environment: production",
  "Build signed production Android App Bundle",
  "flutter build appbundle --release",
  "build/app/outputs/bundle/release/app-release.aab",
  "SUPABASE_PRODUCTION_URL",
  "SUPABASE_PRODUCTION_PUBLISHABLE_KEY",
  "SUPABASE_PRODUCTION_PROJECT_REF",
  "SPARK_LINGO_PRODUCTION_PROJECT_REF",
  "TERMS_OF_SERVICE_URL",
  "PRIVACY_POLICY_URL",
  "REVENUECAT_GOOGLE_KEY",
  "FLUTTER_SDK_SHA256",
  "sha256sum --check",
  "actions/checkout@",
  "actions/setup-java@",
  "actions/upload-artifact@",
]) {
  requireFragment(fragment);
}

for (const expression of [
  /workflow_dispatch:/,
  /flutter build apk/i,
  /flutter-apk/i,
  /SUPABASE_URL:\s*"?\$\{SUPABASE_URL:-/,
  /SUPABASE_PUBLISHABLE_KEY:\s*"?\$\{SUPABASE_PUBLISHABLE_KEY:-/,
  /\.supabase\.co/,
  /sb_publishable_/,
  /dioisitgohusggmwowft/,
  /stlzixqtvtfyrcbjappr/,
]) {
  if (expression.test(workflow)) {
    throw new Error(
      `Android release workflow contains a forbidden mutable/default production value: ${expression}`,
    );
  }
}

for (const action of ["actions/checkout", "actions/setup-java", "actions/upload-artifact"]) {
  const matches = [...workflow.matchAll(new RegExp(`${action}@([^\\s#]+)`, "g"))];
  if (matches.length === 0 || matches.some((match) => !/^[0-9a-f]{40}$/i.test(match[1]))) {
    throw new Error(`${action} must be pinned to a full commit SHA.`);
  }
}

console.log("Android release workflow static validation passed.");
