-- A beta-safe, server-owned ceiling for AI requests. Provider project budgets
-- are alerting thresholds, not a guaranteed hard stop, so this cap is checked
-- before a request can reach the provider. It deliberately starts at zero for
-- every action: an operator must set an approved non-zero value per
-- environment before enabling AI.
--
-- This database counter is suitable as a containment control for internal and
-- limited beta traffic. It is not the 100K+ MAU rate-limiting architecture;
-- replace/augment it with a tested distributed rate limiter before that stage.

create table if not exists public.ai_global_request_limits (
    action text primary key check (action in ('chat', 'score', 'transcribe')),
    max_requests_per_hour integer not null default 0
        check (max_requests_per_hour >= 0 and max_requests_per_hour <= 1000000),
    changed_at timestamptz not null default now(),
    change_reference text not null default 'initial-disabled'
        check (char_length(change_reference) between 3 and 160)
);

create table if not exists public.ai_global_request_limit_audit (
    id bigint generated always as identity primary key,
    action text not null check (action in ('chat', 'score', 'transcribe')),
    max_requests_per_hour integer not null check (max_requests_per_hour >= 0),
    changed_at timestamptz not null default now(),
    change_reference text not null
        check (char_length(change_reference) between 3 and 160)
);

alter table public.ai_global_request_limits enable row level security;
alter table public.ai_global_request_limit_audit enable row level security;

revoke all on table public.ai_global_request_limits,
    public.ai_global_request_limit_audit from public, anon, authenticated;

insert into public.ai_global_request_limits (
    action,
    max_requests_per_hour,
    change_reference
)
values
    ('chat', 0, 'initial-disabled'),
    ('score', 0, 'initial-disabled'),
    ('transcribe', 0, 'initial-disabled')
on conflict (action) do nothing;

insert into public.ai_global_request_limit_audit (
    action,
    max_requests_per_hour,
    change_reference
)
select limits.action, limits.max_requests_per_hour, limits.change_reference
from public.ai_global_request_limits as limits
where not exists (
    select 1
    from public.ai_global_request_limit_audit as audit
    where audit.action = limits.action
);

-- Only a service-role operational path can change this limit. The reference
-- must be a non-secret change or incident ticket, never a prompt or user data.
create or replace function public.set_ai_global_request_ceiling(
    p_action text,
    p_max_requests_per_hour integer,
    p_change_reference text
)
returns table (
    action text,
    max_requests_per_hour integer,
    changed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_action text := lower(btrim(coalesce(p_action, '')));
    v_reference text := btrim(coalesce(p_change_reference, ''));
    v_changed_at timestamptz := now();
begin
    if v_action not in ('chat', 'score', 'transcribe') then
        raise exception 'Unsupported AI action' using errcode = '22023';
    end if;
    if p_max_requests_per_hour is null
       or p_max_requests_per_hour < 0
       or p_max_requests_per_hour > 1000000 then
        raise exception 'A request ceiling between 0 and 1000000 is required'
            using errcode = '22023';
    end if;
    if char_length(v_reference) < 3 or char_length(v_reference) > 160 then
        raise exception 'A 3-160 character non-secret change reference is required'
            using errcode = '22023';
    end if;

    insert into public.ai_global_request_limits (
        action,
        max_requests_per_hour,
        changed_at,
        change_reference
    )
    values (v_action, p_max_requests_per_hour, v_changed_at, v_reference)
    on conflict (action) do update
    set max_requests_per_hour = excluded.max_requests_per_hour,
        changed_at = excluded.changed_at,
        change_reference = excluded.change_reference;

    insert into public.ai_global_request_limit_audit (
        action,
        max_requests_per_hour,
        changed_at,
        change_reference
    )
    values (v_action, p_max_requests_per_hour, v_changed_at, v_reference);

    return query select v_action, p_max_requests_per_hour, v_changed_at;
end;
$$;

-- Replace the two-argument reservation path used by sparky-ai. The request is
-- counted only while reserved or completed, and release_ai_quota removes a
-- reservation after a provider failure. A retry with the same request ID stays
-- idempotent and is not counted twice.
create or replace function public.reserve_ai_quota(
    p_action text,
    p_request_id uuid
)
returns table (allowed boolean, retry_after_seconds integer)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_action text := lower(coalesce(p_action, ''));
    v_user_limit integer;
    v_global_limit integer;
    v_user_used integer;
    v_global_used integer;
    v_window_start timestamptz := date_trunc('hour', now());
    v_retry_after integer := greatest(
        1,
        ceil(extract(epoch from ((date_trunc('hour', now()) + interval '1 hour') - now())))::integer
    );
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;
    if p_request_id is null then
        raise exception 'Request ID required' using errcode = '22023';
    end if;

    case v_action
        when 'chat' then v_user_limit := 30;
        when 'score' then v_user_limit := 12;
        when 'transcribe' then v_user_limit := 6;
        else
            raise exception 'Unsupported AI action' using errcode = '22023';
    end case;

    -- A retry with the same server-created request ID must not spend twice.
    if exists (
        select 1
        from public.ai_usage_events
        where user_id = v_user_id
          and request_id = p_request_id
    ) then
        return query select true, 0;
        return;
    end if;

    select limits.max_requests_per_hour into v_global_limit
    from public.ai_global_request_limits as limits
    where limits.action = v_action;

    -- Missing control data is a deployment/configuration fault. Fail closed.
    if coalesce(v_global_limit, 0) <= 0 then
        return query select false, v_retry_after;
        return;
    end if;

    -- Serialize each global action/hour combination first, then the user
    -- action/hour. This is intentionally a controlled-beta containment path;
    -- use a distributed limiter before high-scale rollout.
    perform pg_advisory_xact_lock(
        hashtextextended('global:' || v_action || ':' || v_window_start::text, 0)
    );
    perform pg_advisory_xact_lock(
        hashtextextended(v_user_id::text || ':' || v_action || ':' || v_window_start::text, 0)
    );

    select count(*) into v_global_used
    from public.ai_usage_events
    where action = v_action
      and status in ('reserved', 'completed')
      and created_at >= v_window_start;

    if v_global_used >= v_global_limit then
        return query select false, v_retry_after;
        return;
    end if;

    select count(*) into v_user_used
    from public.ai_usage_events
    where user_id = v_user_id
      and action = v_action
      and status in ('reserved', 'completed')
      and created_at >= v_window_start;

    if v_user_used >= v_user_limit then
        return query select false, v_retry_after;
        return;
    end if;

    insert into public.ai_usage_events (user_id, action, request_id, status)
    values (v_user_id, v_action, p_request_id, 'reserved');

    return query select true, 0;
end;
$$;

-- Remove the legacy client-callable one-argument reservation path. The Edge
-- Function is the only supported caller and uses the request-ID-aware path.
revoke all on function public.reserve_ai_quota(text) from public, anon, authenticated;
revoke all on function public.reserve_ai_quota(text, uuid) from public, anon;
grant execute on function public.reserve_ai_quota(text, uuid) to authenticated;

revoke all on function public.set_ai_global_request_ceiling(text, integer, text)
    from public, anon, authenticated;
grant execute on function public.set_ai_global_request_ceiling(text, integer, text)
    to service_role;

create index if not exists ai_usage_events_action_status_created_idx
    on public.ai_usage_events (action, status, created_at desc);
