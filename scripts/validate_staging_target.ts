/**
 * Non-network staging deployment preflight.
 *
 * Run this before any Supabase CLI operation or staging smoke test. It reads
 * only target metadata and never prints URLs, project references, tokens, or
 * credentials.
 */

import { validateStagingTarget } from "./staging_target_guard.ts";

validateStagingTarget();
console.log("Staging target preflight passed.");
