/**
 * Durable chat memory for the sparky-ai Edge Function.
 *
 * One rolling session per (user, language), enforced by the unique index
 * from migration 013. After each successful chat turn the server appends
 * the learner's latest message and Sparky's reply; the `history` action
 * returns the most recent turns so a reopened app restores the thread.
 *
 * Privacy contract (same discipline as the rest of this function):
 * - Reads and writes go through the hosted service-role client only. The
 *   RLS policies are owner-only as a second boundary.
 * - Content persisted here is learner chat text already covered by the
 *   ai_processing consent document; audio is never stored.
 * - All failures degrade silently: persistence is pedagogy/UX, never a
 *   request fault.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export type PersistedChatMessage = {
  sender: "user" | "assistant";
  content: string;
};

type OperationalEmit = (event: {
  event: "ai_feedback_persistence_failure";
  request_id: string;
  action?: "chat" | "score";
  operation?: "read" | "write";
  code?: string;
}) => void;

const MAX_PERSISTED_CONTENT = 4000;

/**
 * Returns the rolling session id for (user, language), creating it on first
 * use. Best-effort: null on any failure so callers degrade to stateless.
 */
async function ensureSession(
  client: SupabaseClient,
  userId: string,
  languageCode: string,
): Promise<string | null> {
  const { data, error } = await client
    .from("ai_chat_sessions")
    .upsert(
      { user_id: userId, language_code: languageCode },
      { onConflict: "user_id,language_code" },
    )
    .select("id")
    .single();
  if (error || !data || typeof data.id !== "string") return null;
  return data.id;
}

/**
 * Appends the learner's latest message and Sparky's (marker-stripped) reply
 * to the rolling session. Never throws: a persistence failure weakens the
 * memory, never the learner's request.
 */
export async function persistChatTurn(
  client: SupabaseClient,
  userId: string,
  languageCode: string,
  userText: string,
  assistantText: string,
  requestId: string,
  emit: OperationalEmit,
): Promise<void> {
  try {
    const sessionId = await ensureSession(client, userId, languageCode);
    if (!sessionId) throw new Error("session_unavailable");

    const rows = [];
    const trimmedUser = userText.trim().slice(0, MAX_PERSISTED_CONTENT);
    const trimmedAssistant = assistantText.trim().slice(0, MAX_PERSISTED_CONTENT);
    // Explicit timestamps: a single insert statement otherwise stamps every
    // row with the same transaction now(), which makes intra-turn ordering
    // nondeterministic. The assistant reply is placed one millisecond after
    // the learner message so (created_at) ordering is always stable.
    const now = Date.now();
    if (trimmedUser) {
      rows.push({
        session_id: sessionId,
        user_id: userId,
        sender: "user",
        content: trimmedUser,
        created_at: new Date(now).toISOString(),
      });
    }
    if (trimmedAssistant) {
      rows.push({
        session_id: sessionId,
        user_id: userId,
        sender: "assistant",
        content: trimmedAssistant,
        created_at: new Date(now + 1).toISOString(),
      });
    }
    if (rows.length === 0) return;

    const { error } = await client.from("ai_chat_messages").insert(rows);
    if (error) throw new Error(error.code ?? "insert_failed");

    // Bookkeeping only: refresh the session's activity timestamp.
    // message_count is intentionally not maintained here (it stays at the
    // insert default); retrieval orders by created_at, never by the count.
    await client
      .from("ai_chat_sessions")
      .update({ updated_at: new Date().toISOString() })
      .eq("id", sessionId);
  } catch (_error) {
    emit({
      event: "ai_feedback_persistence_failure",
      request_id: requestId,
      action: "chat",
      operation: "write",
      code: "session_persistence",
    });
  }
}

/**
 * Returns the learner's most recent messages for a language, oldest first.
 * Best-effort: any failure returns an empty list rather than failing.
 */
export async function recentChatMessages(
  client: SupabaseClient,
  userId: string,
  languageCode: string,
  limit: number,
): Promise<PersistedChatMessage[]> {
  try {
    const { data: session, error: sessionError } = await client
      .from("ai_chat_sessions")
      .select("id")
      .eq("user_id", userId)
      .eq("language_code", languageCode)
      .single();
    if (sessionError || !session) return [];

    const { data: rows, error } = await client
      .from("ai_chat_messages")
      .select("sender,content,created_at")
      .eq("session_id", session.id)
      .order("created_at", { ascending: false })
      .limit(limit);
    if (error || !Array.isArray(rows)) return [];

    return rows
      .reverse()
      .filter(
        (row): row is { sender: "user" | "assistant"; content: string } =>
          typeof row.content === "string" && row.content.trim().length > 0 &&
          (row.sender === "user" || row.sender === "assistant"),
      )
      .map((row) => ({ sender: row.sender, content: row.content }));
  } catch {
    return [];
  }
}
