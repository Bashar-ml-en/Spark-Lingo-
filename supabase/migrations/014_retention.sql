-- Retention layer: XP ledger, streaks, daily goals.
--
-- Design (matches Workstream A4 of docs/REDESIGN_MASTER_PROMPT.md):
--   * xp_events is an append-only ledger — the single source of truth.
--     Every activity (lesson completion, review session, AI practice) emits
--     one row; all aggregates are derived from it.
--   * user_retention_stats is a denormalized per-user summary kept in sync
--     by security-definer functions so the streak math is atomic and cannot
--     be manipulated client-side. Clients write ONLY through the RPCs.
--   * Streak rule (Duolingo model): one qualifying activity per local
--     calendar day extends the streak; a gap of exactly one day breaks it
--     (freeze support comes later via inventory items).

create table if not exists public.xp_events (
    id bigint generated always as identity primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    source text not null check (source in (
        'lesson_complete', 'review_session', 'ai_chat', 'exam_attempt', 'bonus'
    )),
    amount integer not null check (amount between 1 and 10000),
    language_code text not null default ''
        check (language_code ~ '^([a-z]{2,3}(-[A-Za-z]{2})?)?$'),
    created_at timestamptz not null default now()
);

create index if not exists xp_events_user_time_idx
    on public.xp_events (user_id, created_at desc);

create table if not exists public.user_retention_stats (
    user_id uuid primary key references auth.users(id) on delete cascade,
    total_xp integer not null default 0 check (total_xp >= 0),
    streak_days integer not null default 0 check (streak_days >= 0),
    longest_streak_days integer not null default 0 check (longest_streak_days >= 0),
    last_activity_day date,
    daily_goal_xp integer not null default 30 check (daily_goal_xp between 10 and 500),
    updated_at timestamptz not null default now()
);

-- RLS: owner-only reads; writes happen exclusively through the definer RPCs.
alter table public.xp_events enable row level security;
alter table public.user_retention_stats enable row level security;

create policy "learners read own xp events"
    on public.xp_events for select
    using (auth.uid() = user_id);

create policy "learners read own retention stats"
    on public.user_retention_stats for select
    using (auth.uid() = user_id);

create policy "learners update own retention stats"
    on public.user_retention_stats for update
    using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Award XP and maintain the streak atomically. p_local_today is the
-- learner's calendar date (client-derived; acceptable for streak UX, never
-- for billing or security decisions).
create or replace function public.award_xp(
    p_source text,
    p_amount integer,
    p_language_code text default '',
    p_local_today date default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user uuid := auth.uid();
    v_today date := coalesce(p_local_today, (now() at time zone 'utc')::date);
    v_last date;
    v_streak integer;
    v_longest integer;
begin
    if v_user is null then
        raise exception 'Authentication required' using errcode = '28000';
    end if;
    if p_amount is null or p_amount < 1 or p_amount > 10000 then
        raise exception 'Invalid XP amount' using errcode = '22023';
    end if;
    if p_source is null or p_source not in (
        'lesson_complete', 'review_session', 'ai_chat', 'exam_attempt', 'bonus'
    ) then
        raise exception 'Invalid XP source' using errcode = '22023';
    end if;

    insert into public.xp_events (user_id, source, amount, language_code)
    values (v_user, p_source, p_amount, coalesce(p_language_code, ''));

    select streak_days, longest_streak_days, last_activity_day
    into v_streak, v_longest, v_last
    from public.user_retention_stats
    where user_id = v_user;

    if not found then
        insert into public.user_retention_stats
            (user_id, total_xp, streak_days, longest_streak_days, last_activity_day)
        values (v_user, p_amount, 1, 1, v_today);
        return;
    end if;

    if v_last is null or v_last < v_today - 1 then
        -- Gap of more than one day: streak resets to 1.
        v_streak := 1;
    elsif v_last < v_today then
        -- Consecutive new day: extend.
        v_streak := coalesce(v_streak, 0) + 1;
    end if;
    -- v_last = v_today: same-day activity keeps the current streak.

    v_longest := greatest(coalesce(v_longest, 0), v_streak);

    update public.user_retention_stats
    set total_xp = total_xp + p_amount,
        streak_days = v_streak,
        longest_streak_days = v_longest,
        last_activity_day = v_today,
        updated_at = now()
    where user_id = v_user;
end;
$$;

revoke all on function public.award_xp(text, integer, text, date)
    from public, anon, service_role;

-- Learner's XP earned today on their local calendar.
create or replace function public.xp_today(p_local_today date default null)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user uuid := auth.uid();
    v_today date := coalesce(p_local_today, (now() at time zone 'utc')::date);
begin
    if v_user is null then
        raise exception 'Authentication required' using errcode = '28000';
    end if;
    return coalesce((
        select sum(amount)
        from public.xp_events
        where user_id = v_user
          and created_at >= v_today::timestamptz
          and created_at < (v_today + 1)::timestamptz
    ), 0);
end;
$$;

revoke all on function public.xp_today(date)
    from public, anon, service_role;
