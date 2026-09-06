-- Sparky chat session persistence.
--
-- Purpose: chat transcripts currently live only in the client's 20-message
-- window and vanish when the app restarts. This gives Sparky durable
-- per-learner memory: one rolling session per (user, language), with the
-- most recent messages returned when the learner reopens the chat.
--
-- Privacy contract (matches the rest of the AI schema):
--   * RLS owner-only on both tables: a learner can read/write only rows
--     whose user_id matches their verified JWT.
--   * The hosted Edge Function uses the service-role client for writes
--     (it persists on behalf of the authenticated learner) and never
--     exposes another learner's rows.
--   * Content is learner chat text (already consented via the ai_processing
--     document) and is subject to the same retention purge policy.

create table if not exists public.ai_chat_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    language_code text not null
        check (language_code ~ '^[a-z]{2,3}(-[A-Za-z]{2})?$'),
    -- Human-readable title derived from the first exchange (not an
    -- AI-generated summary; kept deterministic and cheap).
    title text not null default '',
    message_count integer not null default 0
        check (message_count between 0 and 100000),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, language_code)
);

create index if not exists ai_chat_sessions_user_idx
    on public.ai_chat_sessions (user_id);

create table if not exists public.ai_chat_messages (
    id uuid primary key default gen_random_uuid(),
    session_id uuid not null references public.ai_chat_sessions(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    sender text not null check (sender in ('user', 'assistant')),
    content text not null
        check (char_length(content) between 1 and 4000),
    created_at timestamptz not null default now()
);

create index if not exists ai_chat_messages_session_idx
    on public.ai_chat_messages (session_id, created_at);

alter table public.ai_chat_sessions enable row level security;
alter table public.ai_chat_messages enable row level security;

create policy "learners manage own chat sessions"
    on public.ai_chat_sessions for all
    using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "learners manage own chat messages"
    on public.ai_chat_messages for all
    using (auth.uid() = user_id) with check (auth.uid() = user_id);
