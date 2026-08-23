-- Adaptive pedagogical feedback: per-learner recurring error-pattern ledger.
--
-- Purpose: after every AI-scored practice attempt (the sparky-ai `score`
-- action), the Edge Function persists which ALLOW-LISTED error classes the
-- learner hit. Subsequent scoring and chat sessions read the learner's top
-- recurring patterns so Sparky's feedback adapts to them. This is the
-- feedback loop that existing apps lack: corrections become longitudinal
-- and pedagogical instead of one-shot.
--
-- Privacy contract (matches AI_OPERATIONS.md):
--   * This table stores pedagogical class tokens and short criterion names,
--     never learner prompts, full answers, transcripts, or audio.
--   * Mutations and reads are service-role-only, exactly like the quota
--     lifecycle in 011_server_only_ai_quota_lifecycle.sql. A user JWT, the
--     anon key, or a browser must never be able to read or write another
--     learner's patterns.
--   * Rows are bounded per (user, language, class) and eligible for the
--     retention purge policy once OPS-001's schedule covers them.

create table if not exists public.learner_error_patterns (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    language_code text not null
        check (language_code ~ '^[a-z]{2,3}(-[A-Za-z]{2})?$'),
    rubric_ref text not null
        check (char_length(rubric_ref) between 1 and 120),
    -- Server-matched allow-list token, e.g. 'grammar_agreement'. The Edge
    -- Function maps free-form criteria onto this list; nothing unlisted is
    -- stored.
    error_class text not null
        check (char_length(error_class) between 1 and 60),
    -- Short criterion label echoed from the scorer (length-capped, used for
    -- display and dedupe context; not a prompt or answer).
    criterion_name text not null default ''
        check (char_length(criterion_name) between 0 and 80),
    occurrences integer not null default 1
        check (occurrences between 1 and 100000),
    first_seen_at timestamptz not null default now(),
    last_seen_at timestamptz not null default now(),
    unique (user_id, language_code, error_class)
);

create index if not exists learner_error_patterns_user_lang_idx
    on public.learner_error_patterns (user_id, language_code, occurrences desc);

-- No Data API access for learners or the public role. The hosted Edge
-- Function uses the service-role secret for both mutation and read.
revoke all on table public.learner_error_patterns
    from public, anon, authenticated;

alter table public.learner_error_patterns enable row level security;
-- Deliberately no policies: RLS with zero policies denies all non-service
-- access, fail-closed, matching the containment intent of 011.

-- Upsert one error pattern row. Idempotent per (user, language, class).
create or replace function public.record_learner_error_pattern(
    p_user_id uuid,
    p_language_code text,
    p_rubric_ref text,
    p_error_class text,
    p_criterion_name text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if coalesce(auth.role(), '') <> 'service_role' then
        raise exception 'Service role required' using errcode = '42501';
    end if;
    if p_user_id is null then
        raise exception 'Verified user ID required' using errcode = '22023';
    end if;

    insert into public.learner_error_patterns
        (user_id, language_code, rubric_ref, error_class, criterion_name)
    values
        (p_user_id, p_language_code, p_rubric_ref, p_error_class,
         coalesce(p_criterion_name, ''))
    on conflict (user_id, language_code, error_class) do update
        set occurrences = least(learner_error_patterns.occurrences + 1, 100000),
            criterion_name = excluded.criterion_name,
            rubric_ref = excluded.rubric_ref,
            last_seen_at = now();
end;
$$;

revoke all on function public.record_learner_error_pattern(uuid, text, text, text, text)
    from public, anon, authenticated;

-- Read the learner's top recurring patterns for a language. Returns class +
-- occurrence count + last criterion label; bounded and ordered so callers
-- can inject a short, stable focus list into a system prompt.
create or replace function public.top_learner_error_patterns(
    p_user_id uuid,
    p_language_code text,
    p_limit integer default 5
)
returns table (
    error_class text,
    occurrences integer,
    criterion_name text
)
language plpgsql
security definer
set search_path = public
as $$
begin
    if coalesce(auth.role(), '') <> 'service_role' then
        raise exception 'Service role required' using errcode = '42501';
    end if;
    if p_user_id is null then
        raise exception 'Verified user ID required' using errcode = '22023';
    end if;

    return query
    select patterns.error_class,
           patterns.occurrences,
           patterns.criterion_name
    from public.learner_error_patterns as patterns
    where patterns.user_id = p_user_id
      and patterns.language_code = p_language_code
    order by patterns.occurrences desc, patterns.last_seen_at desc
    limit greatest(coalesce(p_limit, 5), 1);
end;
$$;

revoke all on function public.top_learner_error_patterns(uuid, text, integer)
    from public, anon, authenticated;
