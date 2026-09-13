#!/usr/bin/env node
"use strict";

/**
 * Source-only regression guard for the learner progress boundary.
 *
 * It complements disposable Supabase migration/RLS testing. This guard makes
 * it difficult to accidentally restore a direct client write to XP, streak,
 * lesson progress, or daily-goal aggregates while React Native is built.
 */

const fs = require("node:fs");
const path = require("node:path");

const projectRoot = path.resolve(__dirname, "..");
const migrationPath = path.join(
  projectRoot,
  "supabase",
  "migrations",
  "017_learning_progress_rpc_hardening.sql",
);
const retentionServicePath = path.join(
  projectRoot,
  "lib",
  "core",
  "services",
  "retention_service.dart",
);
const databaseServicePath = path.join(
  projectRoot,
  "lib",
  "core",
  "services",
  "database_service.dart",
);

function source(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function requirePattern(value, pattern, message) {
  if (!pattern.test(value)) {
    throw new Error(`Learning-progress boundary validation failed: ${message}`);
  }
}

const migration = source(migrationPath);
const retentionService = source(retentionServicePath);
const databaseService = source(databaseServicePath);

requirePattern(
  migration,
  /revoke\s+all\s+on\s+table\s+public\.lesson_progress,\s*public\.xp_events,\s*public\.user_retention_stats\s+from\s+anon,\s*authenticated/i,
  "progress tables are not revoked from direct anonymous/authenticated mutation",
);

for (const tableName of [
  "lesson_progress",
  "xp_events",
  "user_retention_stats",
]) {
  requirePattern(
    migration,
    new RegExp(`grant\\s+select\\s+on\\s+table[\\s\\S]*?${tableName}[\\s\\S]*?to\\s+authenticated`, "i"),
    `${tableName} is not explicitly read-only for authenticated clients`,
  );
}

for (const signature of [
  "complete_lesson(text, text)",
  "award_xp(text, integer, text, date)",
  "xp_today(date)",
  "set_daily_goal(integer)",
]) {
  const escaped = signature
    .replace(/[()]/g, "\\$&")
    .replace(/, /g, ",\\s*");
  requirePattern(
    migration,
    new RegExp(
      `revoke\\s+all\\s+on\\s+function\\s+public\\.${escaped}\\s+from\\s+public,\\s*anon,\\s*service_role`,
      "i",
    ),
    `${signature} is not revoked from public, anonymous, and service roles`,
  );
  requirePattern(
    migration,
    new RegExp(
      `grant\\s+execute\\s+on\\s+function\\s+public\\.${escaped}\\s+to\\s+authenticated`,
      "i",
    ),
    `${signature} is not granted only to authenticated clients`,
  );
}

requirePattern(
  migration,
  /create\s+or\s+replace\s+function\s+public\.set_daily_goal\s*\(p_daily_goal_xp\s+integer\)[\s\S]*?security\s+definer[\s\S]*?auth\.uid\(\)[\s\S]*?p_daily_goal_xp\s*<\s*10[\s\S]*?p_daily_goal_xp\s*>\s*500[\s\S]*?insert\s+into\s+public\.user_retention_stats[\s\S]*?on\s+conflict\s*\(user_id\)\s+do\s+update/i,
  "daily-goal RPC is not authenticated, bounded, and server-authoritative",
);
requirePattern(
  retentionService,
  /rpc\(\s*'set_daily_goal'\s*,\s*params:\s*\{'p_daily_goal_xp':/,
  "Flutter daily-goal call does not use the server RPC",
);
if (/from\('user_retention_stats'\)\.upsert\(/.test(retentionService)) {
  throw new Error(
    "Learning-progress boundary validation failed: Flutter can directly upsert retention aggregates.",
  );
}
requirePattern(
  retentionService,
  /rpc\(\s*'award_xp'/,
  "Flutter XP award does not use the server RPC",
);
requirePattern(
  databaseService,
  /rpc\(\s*'complete_lesson'/,
  "Flutter lesson completion does not use the server RPC",
);

console.log("Learning-progress boundary validation passed.");
