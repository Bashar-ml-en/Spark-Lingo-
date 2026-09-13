-- Session error report → SRS loop (Phase 1, gap vs Langua).
--
-- Purpose: after every AI-scored practice attempt (sparky-ai `score`),
-- the Edge Function persists the scorer's short `top_correction` together
-- with its allow-listed error class. The new sparky-ai `report` action
-- aggregates these rows plus the learner's recurring error patterns into
-- a post-session report the client renders and can convert into review
-- cards (SM-2 on device).
--
-- Privacy contract (same discipline as 012_learner_error_patterns.sql and
-- AI_OPERATIONS.md):
--   * Stores only the server-truncated corrected-form snippet (<=200
--     chars, produced by the scorer — never a learner transcript, prompt,
--     full answer, or audio) and allow-listed class/criterion tokens.
--   * Service-role-only mutations and reads; RLS enabled with zero
--     policies so any non-service access is denied fail-closed.
--   * Bounded per (user, language, class, corrected_form); repeats update
--     last_seen_at/occurrences instead of growing the table.
--   * Eligible for the retention purge policy once OPS-001 covers it.

create table if not exists public.learner_correction_items (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    language_code text not null
        check (language_code ~ '^[a-z]{2,3}(-[A-Za-z]{2})?$'),
    -- Server-matched allow-list token from the sparky-ai taxonomy
    -- (error_patterns.ts ERROR_CLASSES); nothing unlisted is stored.
    error_class text not null
        check (char_length(error_class) between 1 and 60),
    -- Short criterion label echoed from the scorer (display/dedupe only).
    criterion_name text not null default ''
        check (char_length(criterion_name) between 0 and 80),
    -- The scorer's top_correction, server-truncated to 200 chars. This is
    -- AI-generated corrective text, not learner input.
    corrected_form text not null
        check (char_length(corrected_form) between 1 and 200),
    -- Which sparky-ai action produced the item ('score' in v1).
    source_action text not null default 'score'
        check (source_action in ('score')),
    occurrences integer not null default 1
        check (occurrences between 1 and 100000),
    first_seen_at timestamptz not null default now(),
    last_seen_at timestamptz not null default now(),
    unique (user_id, language_code, error_class, corrected_form)
);

create index if not exists learner_correction_items_user_lang_idx
    on public.learner_correction_items (user_id, language_code, last_seen_at desc);

alter table public.learner_correction_items enable row level security;
-- Deliberately no policies: RLS with zero policies denies all non-service
-- access, fail-closed, matching 011/012 containment intent.

-- Upsert one correction item. Idempotent per (user, language, class, form).
create or replace function public.record_learner_correction_item(
    p_user_id uuid,
    p_language_code text,
    p_error_class text,
    p_criterion_name text,
    p_corrected_form text,
    p_source_action text default 'score'
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
    if p_corrected_form is null or char_length(p_corrected_form) not between 1 and 200 then
        raise exception 'Corrected form must be 1-200 chars' using errcode = '22023';
    end if;

    insert into public.learner_correction_items
        (user_id, language_code, error_class, criterion_name,
         corrected_form, source_action)
    values
        (p_user_id, p_language_code, p_error_class,
         coalesce(p_criterion_name, ''), p_corrected_form,
         coalesce(p_source_action, 'score'))
    on conflict (user_id, language_code, error_class, corrected_form) do update
        set occurrences = least(learner_correction_items.occurrences + 1, 100000),
            criterion_name = excluded.criterion_name,
            last_seen_at = now();
end;
$$;

revoke all on function public.record_learner_correction_item(uuid, text, text, text, text, text)
    from public, anon, authenticated;

-- Read a learner's recent correction items for one language, most recent
-- first, bounded. Backs the sparky-ai `report` action.
create or replace function public.recent_learner_correction_items(
    p_user_id uuid,
    p_language_code text,
    p_limit integer default 20
)
returns table (
    error_class text,
    criterion_name text,
    corrected_form text,
    occurrences integer,
    first_seen_at timestamptz,
    last_seen_at timestamptz
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
    select items.error_class,
           items.criterion_name,
           items.corrected_form,
           items.occurrences,
           items.first_seen_at,
           items.last_seen_at
    from public.learner_correction_items as items
    where items.user_id = p_user_id
      and items.language_code = p_language_code
    order by items.last_seen_at desc
    limit least(greatest(coalesce(p_limit, 20), 1), 50);
end;
$$;

revoke all on function public.recent_learner_correction_items(uuid, text, integer)
    from public, anon, authenticated;
