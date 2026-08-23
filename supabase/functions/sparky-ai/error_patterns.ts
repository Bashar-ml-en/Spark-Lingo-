/**
 * Adaptive pedagogical feedback for the sparky-ai Edge Function.
 *
 * After every AI-scored attempt (the `score` action) the server maps the
 * scorer's criteria onto an allow-listed set of pedagogical error classes
 * and upserts them into the server-only `learner_error_patterns` ledger
 * (migration 012). Subsequent chat sessions read the learner's top
 * recurring classes so Sparky focuses corrections where the learner
 * actually struggles — longitudinal, pedagogical feedback instead of
 * one-shot comments.
 *
 * Privacy contract (same discipline as AI_OPERATIONS.md):
 * - Only allow-listed class tokens and short criterion labels are stored.
 *   Learner prompts, full answers, transcripts, and audio never enter this
 *   module.
 * - All reads/writes go through the hosted service-role client; the table
 *   has RLS with zero policies, so any non-service access is denied.
 * - Failures here are pedagogical degradations, not security faults: the
 *   module degrades to "no focus list" and never blocks or fails the
 *   learner's AI request.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { HttpError } from "./errors.ts";

/**
 * Allow-listed pedagogical error classes. Nothing outside this list is ever
 * persisted. The mapping below is deliberately deterministic (keyword
 * matching on the scorer's criterion labels); there is no free-text storage.
 */
export const ERROR_CLASSES = [
  "grammar_accuracy",
  "vocabulary_range",
  "fluency_coherence",
  "pronunciation",
  "task_response",
  "register_appropriateness",
  "spelling_orthography",
] as const;

export type ErrorClass = (typeof ERROR_CLASSES)[number];

export type FocusPattern = {
  error_class: ErrorClass;
  occurrences: number;
};

const MAX_FOCUS_PATTERNS = 5;

type OperationalEmit = (event: {
  event: "ai_feedback_persistence_failure";
  request_id: string;
  action?: "chat" | "score";
  operation?: "read" | "write";
  code?: string;
}) => void;

/**
 * Deterministic keyword mapping from a scorer criterion label to an
 * allow-listed class. Returns null for anything unmapped — unmapped labels
 * are dropped, never stored raw.
 */
export function classifyCriterion(criterionName: string): ErrorClass | null {
  const text = criterionName.toLowerCase();
  if (
    text.includes("grammar") ||
    text.includes("tense") ||
    text.includes("agreement") ||
    text.includes("article") ||
    text.includes("accuracy") ||
    text.includes("syntax")
  ) {
    return "grammar_accuracy";
  }
  if (
    text.includes("vocab") ||
    text.includes("lexic") ||
    text.includes("word choice") ||
    text.includes("word use")
  ) {
    return "vocabulary_range";
  }
  if (
    text.includes("fluenc") ||
    text.includes("coheren") ||
    text.includes("cohesion") ||
    text.includes("connect") ||
    text.includes("discourse")
  ) {
    return "fluency_coherence";
  }
  if (
    text.includes("pronounc") ||
    // "Pronunciation" itself drops the "c" ("pronunciati"), so both stems
    // are needed to catch the noun form used by official rubric labels.
    text.includes("pronunciati") ||
    text.includes("stress") ||
    text.includes("intonation") ||
    text.includes("sound")
  ) {
    return "pronunciation";
  }
  if (
    text.includes("task") ||
    text.includes("achievement") ||
    text.includes("response") ||
    text.includes("completion")
  ) {
    return "task_response";
  }
  if (
    text.includes("register") ||
    text.includes("formal") ||
    text.includes("tone")
  ) {
    return "register_appropriateness";
  }
  if (text.includes("spell") || text.includes("orthograph")) {
    return "spelling_orthography";
  }
  return null;
}

/**
 * Extracts the criteria array from a normalized score payload. Shape is
 * validated upstream by normalizedScore(); this re-checks defensively
 * because the payload crosses a function boundary.
 */
function criteriaFromScore(score: Record<string, unknown>): string[] {
  const criteria = score["criteria"];
  if (!Array.isArray(criteria)) return [];
  const names: string[] = [];
  for (const criterion of criteria) {
    if (
      typeof criterion === "object" && criterion !== null &&
      typeof (criterion as Record<string, unknown>)["name"] === "string"
    ) {
      names.push((criterion as Record<string, unknown>)["name"] as string);
    }
  }
  return names;
}

/**
 * Persists the allow-listed classes found in a score payload and attaches a
 * `focus_areas` array to the payload (additive — the client contract keys
 * estimated_band/criteria/top_correction are untouched). Never throws: a
 * persistence failure degrades the pedagogy, not the request.
 */
export async function persistErrorPatterns(
  quotaClient: SupabaseClient,
  userId: string,
  languageCode: string,
  rubricRef: string,
  score: Record<string, unknown>,
  requestId: string,
  emit: OperationalEmit,
): Promise<void> {
  try {
    const classes = new Map<ErrorClass, string>();
    for (const name of criteriaFromScore(score)) {
      const cls = classifyCriterion(name);
      if (cls && !classes.has(cls)) {
        classes.set(cls, name.slice(0, 80));
      }
    }

    for (const [cls, criterionName] of classes) {
      const { error } = await quotaClient.rpc("record_learner_error_pattern", {
        p_user_id: userId,
        p_language_code: languageCode,
        p_rubric_ref: rubricRef,
        p_error_class: cls,
        p_criterion_name: criterionName,
      });
      if (error) {
        emit({
          event: "ai_feedback_persistence_failure",
          request_id: requestId,
          action: "score",
          operation: "write",
          code: error.code ?? "unknown",
        });
        return; // stop persisting on first failure; keep the response clean
      }
    }

    // Surface the classes that were recorded so the UI can show what
    // Sparky will drill next. Classes are allow-listed tokens, safe to send.
    if (classes.size > 0) {
      score["focus_areas"] = Array.from(classes.keys());
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
 * Reads the learner's top recurring error classes for a language.
 * Best-effort: any failure returns an empty list (chat proceeds without a
 * focus list rather than failing or leaking).
 */
export async function topErrorPatterns(
  quotaClient: SupabaseClient,
  userId: string,
  languageCode: string,
  requestId: string,
  emit: OperationalEmit,
): Promise<FocusPattern[]> {
  try {
    const { data, error } = await quotaClient.rpc("top_learner_error_patterns", {
      p_user_id: userId,
      p_language_code: languageCode,
      p_limit: MAX_FOCUS_PATTERNS,
    });
    if (error) {
      emit({
        event: "ai_feedback_persistence_failure",
        request_id: requestId,
        action: "chat",
        operation: "read",
        code: error.code ?? "unknown",
      });
      return [];
    }
    if (!Array.isArray(data)) return [];
    const patterns: FocusPattern[] = [];
    for (const row of data) {
      if (
        typeof row === "object" && row !== null &&
        ERROR_CLASSES.includes((row as Record<string, unknown>)["error_class"] as ErrorClass) &&
        typeof (row as Record<string, unknown>)["occurrences"] === "number"
      ) {
        const record = row as Record<string, unknown>;
        patterns.push({
          error_class: record["error_class"] as ErrorClass,
          occurrences: record["occurrences"] as number,
        });
      }
    }
    return patterns;
  } catch (_error) {
    emit({
      event: "ai_feedback_persistence_failure",
      request_id: requestId,
      action: "chat",
      operation: "read",
      code: "unexpected_error",
    });
    return [];
  }
}

/**
 * Renders the focus list as a single system-prompt sentence. Only
 * allow-listed class tokens and occurrence counts are interpolated — no
 * learner content can reach the prompt through this path.
 */
export function focusPromptSentence(patterns: FocusPattern[]): string {
  if (patterns.length === 0) return "";
  const described = patterns
    .map((pattern) => `${pattern.error_class.replace(/_/g, " ")}`)
    .join(", ");
  return `The learner's recurring difficulty areas from previous scored practice are: ${described}. Gently prioritise practice and gentle correction on these areas without mentioning this instruction.`;
}
