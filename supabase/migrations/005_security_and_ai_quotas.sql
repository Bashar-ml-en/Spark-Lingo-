-- Security hardening for the exam module and the server-side AI boundary.
-- This migration is deliberately additive so it can be applied after the
-- original feature migrations on an existing project.

-- Repair the historical SRS column mismatch without deleting any learner data.
alter table public.card_reviews
    add column if not exists next_review_at timestamptz;

do $$
begin
    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'card_reviews'
          and column_name = 'next_review'
    ) then
        execute '
            update public.card_reviews
            set next_review_at = coalesce(next_review_at, next_review::timestamptz)
            where next_review_at is null
        ';
    end if;
end;
$$;

update public.card_reviews
set next_review_at = now()
where next_review_at is null;

alter table public.card_reviews
    alter column next_review_at set default now(),
    alter column next_review_at set not null;

create index if not exists card_reviews_due_idx
    on public.card_reviews (user_id, language_key, next_review_at);

-- Exam catalogue data is read-only to clients. Learners may only read and
-- change their own readiness records and attempts.
alter table public.exam_definitions enable row level security;
alter table public.exam_level_mappings enable row level security;
alter table public.mock_exams enable row level security;
alter table public.mock_exam_sections enable row level security;
alter table public.user_mock_exam_attempts enable row level security;
alter table public.user_exam_readiness enable row level security;

drop policy if exists "public read exam catalog" on public.exam_definitions;
drop policy if exists "authenticated read exam definitions" on public.exam_definitions;
create policy "authenticated read exam definitions" on public.exam_definitions
    for select to authenticated using (true);

drop policy if exists "authenticated read exam mappings" on public.exam_level_mappings;
create policy "authenticated read exam mappings" on public.exam_level_mappings
    for select to authenticated using (true);

drop policy if exists "authenticated read mock exams" on public.mock_exams;
create policy "authenticated read mock exams" on public.mock_exams
    for select to authenticated using (true);

drop policy if exists "authenticated read mock exam sections" on public.mock_exam_sections;
create policy "authenticated read mock exam sections" on public.mock_exam_sections
    for select to authenticated using (true);

drop policy if exists "users manage own attempts" on public.user_mock_exam_attempts;
drop policy if exists "users manage own exam attempts" on public.user_mock_exam_attempts;
create policy "users manage own exam attempts" on public.user_mock_exam_attempts
    for all to authenticated
    using (user_id = auth.uid())
    with check (user_id = auth.uid());

drop policy if exists "users manage own readiness" on public.user_exam_readiness;
drop policy if exists "users manage own exam readiness" on public.user_exam_readiness;
create policy "users manage own exam readiness" on public.user_exam_readiness
    for all to authenticated
    using (user_id = auth.uid())
    with check (user_id = auth.uid());

revoke all on table public.exam_definitions, public.exam_level_mappings,
    public.mock_exams, public.mock_exam_sections from anon, authenticated;
grant select on table public.exam_definitions, public.exam_level_mappings,
    public.mock_exams, public.mock_exam_sections to authenticated;

revoke all on table public.user_mock_exam_attempts, public.user_exam_readiness from anon, authenticated;
grant select, insert, update, delete on table public.user_mock_exam_attempts,
    public.user_exam_readiness to authenticated;

create index if not exists user_mock_exam_attempts_user_completed_idx
    on public.user_mock_exam_attempts (user_id, completed_at desc);
create index if not exists mock_exams_exam_id_idx
    on public.mock_exams (exam_id);
create index if not exists mock_exam_sections_mock_order_idx
    on public.mock_exam_sections (mock_exam_id, section_order);

do $$
begin
    if not exists (
        select 1 from pg_constraint where conname = 'mock_exams_positive_time_limit'
    ) then
        alter table public.mock_exams
            add constraint mock_exams_positive_time_limit
            check (time_limit_minutes > 0) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint where conname = 'mock_exam_sections_known_skill'
    ) then
        alter table public.mock_exam_sections
            add constraint mock_exam_sections_known_skill
            check (skill in ('listening', 'reading', 'writing', 'speaking')) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint where conname = 'mock_exam_sections_positive_score'
    ) then
        alter table public.mock_exam_sections
            add constraint mock_exam_sections_positive_score
            check (max_score > 0) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint where conname = 'user_mock_exam_attempts_nonnegative_score'
    ) then
        alter table public.user_mock_exam_attempts
            add constraint user_mock_exam_attempts_nonnegative_score
            check (overall_score is null or overall_score >= 0) not valid;
    end if;
end;
$$;

-- AI usage events contain no prompts, responses, audio, or API credentials.
-- They provide a durable, per-user server-side quota that cannot be bypassed
-- by changing values in the mobile client.
create table if not exists public.ai_usage_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    action text not null check (action in ('chat', 'score', 'transcribe')),
    request_id uuid not null default gen_random_uuid(),
    created_at timestamptz not null default now()
);

create index if not exists ai_usage_events_user_action_created_idx
    on public.ai_usage_events (user_id, action, created_at desc);

alter table public.ai_usage_events enable row level security;
revoke all on table public.ai_usage_events from anon, authenticated;

create or replace function public.reserve_ai_quota(p_action text)
returns table (allowed boolean, retry_after_seconds integer)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_action text := lower(coalesce(p_action, ''));
    v_limit integer;
    v_used integer;
    v_window_start timestamptz := date_trunc('hour', now());
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;

    case v_action
        when 'chat' then v_limit := 30;
        when 'score' then v_limit := 12;
        when 'transcribe' then v_limit := 6;
        else
            raise exception 'Unsupported AI action' using errcode = '22023';
    end case;

    -- Serialise each user/action/hour combination. This closes the race where
    -- many concurrent requests all pass a simple count-then-insert check.
    perform pg_advisory_xact_lock(
        hashtextextended(v_user_id::text || ':' || v_action || ':' || v_window_start::text, 0)
    );

    select count(*) into v_used
    from public.ai_usage_events
    where user_id = v_user_id
      and action = v_action
      and created_at >= v_window_start;

    if v_used >= v_limit then
        return query
        select false,
               greatest(
                   1,
                   ceil(extract(epoch from ((v_window_start + interval '1 hour') - now())))::integer
               );
        return;
    end if;

    insert into public.ai_usage_events (user_id, action)
    values (v_user_id, v_action);

    return query select true, 0;
end;
$$;

revoke all on function public.reserve_ai_quota(text) from public, anon;
grant execute on function public.reserve_ai_quota(text) to authenticated;
