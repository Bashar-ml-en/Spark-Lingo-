-- Keep AI quotas fair when the upstream provider fails and make the event
-- ledger maintainable. Requests are reserved before the provider call, then
-- finalized only after a valid response is produced.

alter table public.ai_usage_events
    add column if not exists status text not null default 'completed';

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'ai_usage_events_status_valid'
    ) then
        alter table public.ai_usage_events
            add constraint ai_usage_events_status_valid
            check (status in ('reserved', 'completed'));
    end if;
end;
$$;

create unique index if not exists ai_usage_events_user_request_id_uidx
    on public.ai_usage_events (user_id, request_id);

-- The two-argument version is used by the Edge Function. It is idempotent for
-- one authenticated user/request ID and counts in-flight reservations so a
-- burst cannot overrun the hourly cap.
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
    v_limit integer;
    v_used integer;
    v_window_start timestamptz := date_trunc('hour', now());
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;
    if p_request_id is null then
        raise exception 'Request ID required' using errcode = '22023';
    end if;

    case v_action
        when 'chat' then v_limit := 30;
        when 'score' then v_limit := 12;
        when 'transcribe' then v_limit := 6;
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

    perform pg_advisory_xact_lock(
        hashtextextended(v_user_id::text || ':' || v_action || ':' || v_window_start::text, 0)
    );

    select count(*) into v_used
    from public.ai_usage_events
    where user_id = v_user_id
      and action = v_action
      and status in ('reserved', 'completed')
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

    insert into public.ai_usage_events (user_id, action, request_id, status)
    values (v_user_id, v_action, p_request_id, 'reserved');

    return query select true, 0;
end;
$$;

create or replace function public.complete_ai_quota(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;
    if p_request_id is null then
        raise exception 'Request ID required' using errcode = '22023';
    end if;

    update public.ai_usage_events
    set status = 'completed'
    where user_id = v_user_id
      and request_id = p_request_id
      and status = 'reserved';
end;
$$;

create or replace function public.release_ai_quota(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;
    if p_request_id is null then
        raise exception 'Request ID required' using errcode = '22023';
    end if;

    -- Failed provider calls do not consume a learner's quota. Completed rows
    -- are intentionally immutable through this user-facing function.
    delete from public.ai_usage_events
    where user_id = v_user_id
      and request_id = p_request_id
      and status = 'reserved';
end;
$$;

revoke all on function public.reserve_ai_quota(text, uuid) from public, anon;
grant execute on function public.reserve_ai_quota(text, uuid) to authenticated;
revoke all on function public.complete_ai_quota(uuid) from public, anon;
grant execute on function public.complete_ai_quota(uuid) to authenticated;
revoke all on function public.release_ai_quota(uuid) from public, anon;
grant execute on function public.release_ai_quota(uuid) to authenticated;

-- This is deliberately callable only by a protected scheduler/service role.
-- Schedule it in the hosted environment (for example daily) after choosing a
-- retention period approved by privacy/legal owners.
create or replace function public.purge_ai_usage_events(
    p_before timestamptz default (now() - interval '90 days')
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
    v_deleted bigint;
begin
    if p_before is null or p_before > now() - interval '1 day' then
        raise exception 'Retention cutoff must be at least one day old' using errcode = '22023';
    end if;

    delete from public.ai_usage_events
    where created_at < p_before;
    get diagnostics v_deleted = row_count;
    return v_deleted;
end;
$$;

revoke all on function public.purge_ai_usage_events(timestamptz) from public, anon, authenticated;
grant execute on function public.purge_ai_usage_events(timestamptz) to service_role;
