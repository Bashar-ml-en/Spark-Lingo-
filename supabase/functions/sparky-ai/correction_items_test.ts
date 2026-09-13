/**
 * Unit tests for the correction-items module (correction_items.ts).
 *
 * Run locally:
 *   deno test --allow-env supabase/functions/sparky-ai/correction_items_test.ts
 *
 * The module shares the privacy boundary with error_patterns.ts: only
 * allow-listed class tokens and server-truncated AI corrective snippets
 * may ever be persisted. These tests pin that contract plus the
 * degrade-never-throw guarantee.
 */

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { persistCorrectionItem, recentCorrectionItems } from "./correction_items.ts";
import { ERROR_CLASSES } from "./error_patterns.ts";

type RpcCall = { fn: string; params: Record<string, unknown> };

function fakeClient(
  calls: RpcCall[],
  respond: (fn: string, params: Record<string, unknown>) => { data?: unknown; error?: { code: string } | null },
) {
  // deno-lint-ignore no-explicit-any
  return {
    rpc(fn: string, params: Record<string, unknown>) {
      calls.push({ fn, params });
      return Promise.resolve(respond(fn, params));
    },
    // deno-lint-ignore no-explicit-any
  } as any;
}

const emit = () => {};

Deno.test("persistCorrectionItem stores class + truncated top correction", async () => {
  const calls: RpcCall[] = [];
  const client = fakeClient(calls, () => ({ error: null }));
  const score = {
    estimated_band: "6.0",
    criteria: [
      { name: "Grammatical Range and Accuracy", note: "tense slips" },
      { name: "Fluency and Coherence", note: "fine" },
    ],
    top_correction: "Use 'went' instead of 'goed' for the past tense of 'go'.",
  };

  await persistCorrectionItem(client, "user-1", "ms", score, "req-1", emit);

  assertEquals(calls.length, 1);
  assertEquals(calls[0].fn, "record_learner_correction_item");
  assertEquals(calls[0].params.p_error_class, "grammar_accuracy");
  assertEquals(calls[0].params.p_criterion_name, "Grammatical Range and Accuracy");
  assertEquals(calls[0].params.p_corrected_form, score.top_correction);
  assertEquals(calls[0].params.p_source_action, "score");
});

Deno.test("persistCorrectionItem truncates to 200 chars and drops unmapped criteria", async () => {
  const calls: RpcCall[] = [];
  const client = fakeClient(calls, () => ({ error: null }));
  const longForm = "x".repeat(500);

  await persistCorrectionItem(
    client,
    "user-1",
    "ms",
    { criteria: [{ name: "Creativity", note: "n/a" }], top_correction: longForm },
    "req-1",
    emit,
  );
  // "Creativity" maps to no allow-listed class → nothing persisted.
  assertEquals(calls.length, 0);

  await persistCorrectionItem(
    client,
    "user-1",
    "ms",
    { criteria: [{ name: "Vocabulary Resource", note: "n/a" }], top_correction: longForm },
    "req-1",
    emit,
  );
  assertEquals(calls.length, 1);
  assertEquals((calls[0].params.p_corrected_form as string).length, 200);
  assertEquals(calls[0].params.p_error_class, "vocabulary_range");
});

Deno.test("persistCorrectionItem ignores empty or missing top_correction", async () => {
  const calls: RpcCall[] = [];
  const client = fakeClient(calls, () => ({ error: null }));
  const criteria = [{ name: "Grammar Accuracy", note: "n/a" }];

  await persistCorrectionItem(client, "u", "ms", { criteria, top_correction: "   " }, "r", emit);
  await persistCorrectionItem(client, "u", "ms", { criteria }, "r", emit);
  assertEquals(calls.length, 0);
});

Deno.test("persistCorrectionItem degrades silently on rpc error", async () => {
  const calls: RpcCall[] = [];
  const client = fakeClient(calls, () => ({ error: { code: "42501" } }));
  await persistCorrectionItem(
    client,
    "u",
    "ms",
    { criteria: [{ name: "Spelling", note: "n/a" }], top_correction: "Their → There" },
    "r",
    emit,
  );
  // Did not throw; one attempt recorded.
  assertEquals(calls.length, 1);
});

Deno.test("recentCorrectionItems validates rows against the allow-list", async () => {
  const client = fakeClient([], (fn) => {
    assertEquals(fn, "recent_learner_correction_items");
    return {
      data: [
        {
          error_class: "grammar_accuracy",
          criterion_name: "Grammar",
          corrected_form: "Use 'went'.",
          occurrences: 2,
          first_seen_at: "2026-09-01T00:00:00Z",
          last_seen_at: "2026-09-09T00:00:00Z",
        },
        { error_class: "NOT_ALLOWED", corrected_form: "x" }, // dropped
        { error_class: "pronunciation", corrected_form: "" }, // dropped: empty
        null, // dropped
        { error_class: "spelling_orthography", corrected_form: "y".repeat(201) }, // dropped: too long
      ],
      error: null,
    };
  });

  const items = await recentCorrectionItems(client, "u", "ms", "r", emit);
  assertEquals(items.length, 1);
  assertEquals(items[0].error_class, "grammar_accuracy");
  assertEquals(items[0].occurrences, 2);
});

Deno.test("recentCorrectionItems degrades to empty list on rpc error", async () => {
  const client = fakeClient([], () => ({ data: null, error: { code: "42501" } }));
  const items = await recentCorrectionItems(client, "u", "ms", "r", emit);
  assertEquals(items, []);
});

Deno.test("allow-list is shared with error_patterns taxonomy", () => {
  // The report contract only ever surfaces these tokens to the client.
  assertEquals(ERROR_CLASSES.includes("grammar_accuracy"), true);
  assertEquals(ERROR_CLASSES.length, 7);
});
