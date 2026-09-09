/**
 * Session error report → SRS loop for the sparky-ai Edge Function.
 *
 * After every AI-scored attempt (the `score` action) the server persists
 * the scorer's short `top_correction` alongside its dominant allow-listed
 * error class into the service-role-only `learner_correction_items`
 * ledger (migration 016). The `report` action aggregates the learner's
 * recent correction items plus recurring error-pattern counts into a
 * post-session report; the client renders it and offers "Add to review"
 * which converts items into on-device SM-2 flashcards.
 *
 * Privacy contract (same discipline as error_patterns.ts / migration 012):
 * - Only allow-listed class tokens, short criterion labels, and the
 *   server-truncated AI corrective snippet (<=200 chars) are stored.
 *   Learner prompts, full answers, transcripts, and audio never enter.
 * - All reads/writes go through the hosted service-role client; the table
 *   has RLS with zero policies, so any non-service access is denied.
 * - Failures here are pedagogical degradations, never request faults:
 *   both functions degrade silently and never throw.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { classifyCriterion, type ErrorClass, ERROR_CLASSES } from "./error_patterns.ts";

export type CorrectionItem = {
  error_class: ErrorClass;
  criterion_name: string;
  corrected_form: string;
  occurrences: number;
  first_seen_at: string;
  last_seen_at: string;
};

type OperationalEmit = (event: {
  event: "ai_feedback_persistence_failure";
  request_id: string;
  action?: "chat" | "score" | "report";
  operation?: "read" | "write";
  code?: string;
}) => void;

/** Server-side cap mirroring the DB check constraint. */
const MAX_CORRECTED_FORM = 200;
const MAX_REPORT_ITEMS = 20;

/**
 * Picks the dominant allow-listed class for a score payload by mapping its
 * criteria names (first mapped class wins — criteria arrive in scorer
 * priority order). Returns null when nothing maps.
 */
function dominantClass(
  score: Record<string, unknown>,
): { cls: ErrorClass; criterionName: string } | null {
  const criteria = score["criteria"];
  if (!Array.isArray(criteria)) return null;
  for (const criterion of criteria) {
    if (typeof criterion !== "object" || criterion === null) continue;
    const name = (criterion as Record<string, unknown>)["name"];
    if (typeof name !== "string") continue;
    const cls = classifyCriterion(name);
    if (cls) return { cls, criterionName: name.slice(0, 80) };
  }
  return null;
}

/**
 * Persists the scorer's top correction for later session reports.
 * Additive: never mutates the score payload, never throws.
 */
export async function persistCorrectionItem(
  quotaClient: SupabaseClient,
  userId: string,
  languageCode: string,
  score: Record<string, unknown>,
  requestId: string,
  emit: OperationalEmit,
): Promise<void> {
  try {
    const topCorrection = score["top_correction"];
    if (typeof topCorrection !== "string") return;
    const correctedForm = topCorrection.trim().slice(0, MAX_CORRECTED_FORM);
    if (correctedForm.length === 0) return;

    const dominant = dominantClass(score);
    if (!dominant) return; // unmapped scorer output is dropped, never stored raw

    const { error } = await quotaClient.rpc("record_learner_correction_item", {
      p_user_id: userId,
      p_language_code: languageCode,
      p_error_class: dominant.cls,
      p_criterion_name: dominant.criterionName,
      p_corrected_form: correctedForm,
      p_source_action: "score",
    });
    if (error) {
      emit({
        event: "ai_feedback_persistence_failure",
        request_id: requestId,
        action: "score",
        operation: "write",
        code: error.code ?? "unknown",
      });
    }
  } catch (_error) {
    emit({
      event: "ai_feedback_persistence_failure",
      request_id: requestId,
      action: "score",
      operation: "write",
      code: "unexpected_error",
    });
  }
}

/**
 * Reads the learner's recent correction items for the `report` action.
 * Best-effort: any failure returns an empty list so the report degrades
 * to the error-pattern summary rather than failing.
 */
export async function recentCorrectionItems(
  quotaClient: SupabaseClient,
  userId: string,
  languageCode: string,
  requestId: string,
  emit: OperationalEmit,
): Promise<CorrectionItem[]> {
  try {
    const { data, error } = await quotaClient.rpc("recent_learner_correction_items", {
      p_user_id: userId,
      p_language_code: languageCode,
      p_limit: MAX_REPORT_ITEMS,
    });
    if (error) {
      emit({
        event: "ai_feedback_persistence_failure",
        request_id: requestId,
        action: "report",
        operation: "read",
        code: error.code ?? "unknown",
      });
      return [];
    }
    if (!Array.isArray(data)) return [];
    const items: CorrectionItem[] = [];
    for (const row of data) {
      if (typeof row !== "object" || row === null) continue;
      const record = row as Record<string, unknown>;
      const cls = record["error_class"];
      const form = record["corrected_form"];
      if (
        typeof cls !== "string" ||
        !ERROR_CLASSES.includes(cls as ErrorClass) ||
        typeof form !== "string" ||
        form.length === 0 ||
        form.length > MAX_CORRECTED_FORM
      ) {
        continue; // defensive re-validation across the function boundary
      }
      items.push({
        error_class: cls as ErrorClass,
        criterion_name: typeof record["criterion_name"] === "string"
          ? (record["criterion_name"] as string).slice(0, 80)
          : "",
        corrected_form: form,
        occurrences: typeof record["occurrences"] === "number"
          ? record["occurrences"] as number
          : 1,
        first_seen_at: typeof record["first_seen_at"] === "string"
          ? record["first_seen_at"] as string
          : "",
        last_seen_at: typeof record["last_seen_at"] === "string"
          ? record["last_seen_at"] as string
          : "",
      });
    }
    return items;
  } catch (_error) {
    emit({
      event: "ai_feedback_persistence_failure",
      request_id: requestId,
      action: "report",
      operation: "read",
      code: "unexpected_error",
    });
    return [];
  }
}
