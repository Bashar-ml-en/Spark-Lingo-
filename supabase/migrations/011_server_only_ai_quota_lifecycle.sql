-- Quota mutation is an internal capability, not a learner capability.
--
-- The prior quota RPCs derived identity from auth.uid() and were executable by
-- authenticated clients. A client could therefore reserve its own requests
-- directly and consume the shared global ceiling without passing the Edge
-- Function's consent, runtime-control, and provider boundary. This migration
-- replaces that public lifecycle with service-role-only functions. The Edge
-- Function first validates the learner JWT using the anon client, then passes
-- that verified user ID through its server-only service-role client.
--
-- Do not grant these functions to anon or authenticated. The service-role key
-- belongs only in hosted Edge Function secrets; it must never be bundled in a
-- mobile/web client or used from a browser.

-- A reservation moves to submitted immediately before an upstream fetch. A
-- timeout, transport failure, non-2xx response, or malformed provider reply
-- therefore remains accounted for until the hourly window expires or an
-- operator reconciles it. Historical completed rows predate this marker, so
-- use their original event time as the conservative submission time.
alter table public.ai_usage_events
    add column if not exists provider_submission_started_at timestamptz;

update public.ai_usage_events
set provider_submission_started_at = created_at
where status = 'completed'
  and provider_submission_started_at is null;

alter table public.ai_usage_events
    drop constraint if exists ai_usage_events_status_valid;

alter table public.ai_usage_events
    add constraint ai_usage_events_status_valid
    check (status in ('reserved', 'submitted', 'completed'));

alter table public.ai_usage_events
    drop constraint if exists ai_usage_events_submission_state_valid;

alter table public.ai_usage_events
    add constraint ai_usage_events_submission_state_valid
    check (
        (status = 'reserved' and provider_submission_started_at is null)
        or (status in ('submitted', 'completed') and provider_submission_started_at is not null)
    );

create index if not exists ai_usage_events_submitted_reconciliation_idx
    on public.ai_usage_events (provider_submission_started_at asc)
    where status = 'submitted';

-- Explicitly disable every previous Data API quota mutation path. The
-- functions are retained only to make this a forward-only migration for an
-- existing database; no client or service code may invoke them after this
-- migration.
revoke all on function public.reserve_ai_quota(text)
    from public, anon, authenticated, service_role;
revoke all on function public.reserve_ai_quota(text, uuid)
    from public, anon, authenticated, service_role;
revoke all on function public.complete_ai_quota(uuid)
    from public, anon, authenticated, service_role;
revoke all on function public.release_ai_quota(uuid)
    from public, anon, authenticated, service_role;

-- The following functions intentionally accept a user ID only after checking
-- that the caller is the service role. That allows the Edge Function to use a
-- server credential for mutation while binding the event to the identity it
-- independently verified from the incoming JWT.
create or replace function public.reserve_ai_quota_for_user(
    p_user_id uuid,
    p_action text,
    p_request_id uuid
)
returns table (allowed boolean, retry_after_seconds integer)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_action text := lower(btrim(coalesce(p_action, '')));
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
    if coalesce(auth.role(), '') <> 'service_role' then
        raise exception 'Service role required' using errcode = '42501';
    end if;
    if p_user_id is null then
        raise exception 'Verified user ID required' using errcode = '22023';
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

    -- A retry of an already server-created request is idempotent. The Edge
    -- Function never accepts an arbitrary user ID from the client.
    if exists (
        select 1
        from public.ai_usage_events
        where user_id = p_user_id
          and request_id = p_request_id
    ) then
        return query select true, 0;
        return;
    end if;

    select limits.max_requests_per_hour into v_global_limit
    from public.ai_global_request_limits as limits
    where limits.action = v_action;

    -- Missing/zero control data is an operational fault or an intentional
    -- pause. In either case, fail closed before sending upstream traffic.
    if coalesce(v_global_limit, 0) <= 0 then
        return query select false, v_retry_after;
        return;
    end if;

    -- Serialize global first, then per-user. Keep the lock order identical
    -- across calls to avoid deadlocks under beta concurrency.
    perform pg_advisory_xact_lock(
        hashtextextended('global:' || v_action || ':' || v_window_start::text, 0)
    );
    perform pg_advisory_xact_lock(
        hashtextextended(p_user_id::text || ':' || v_action || ':' || v_window_start::text, 0)
    );

    -- Recheck after acquiring the same locks used by every reservation. This
    -- keeps a concurrent retry of one request ID idempotent instead of letting
    -- it fall through to the unique index and surface a transient failure.
    if exists (
        select 1
        from public.ai_usage_events
        where user_id = p_user_id
          and request_id = p_request_id
    ) then
        return query select true, 0;
        return;
    end if;

    select count(*) into v_global_used
    from public.ai_usage_events
    where action = v_action
      and status in ('reserved', 'submitted', 'completed')
      and created_at >= v_window_start;

    if v_global_used >= v_global_limit then
        return query select false, v_retry_after;
        return;
    end if;

    select count(*) into v_user_used
    from public.ai_usage_events
    where user_id = p_user_id
      and action = v_action
      and status in ('reserved', 'submitted', 'completed')
      and created_at >= v_window_start;

    if v_user_used >= v_user_limit then
        return query select false, v_retry_after;
        return;
    end if;

    insert into public.ai_usage_events (user_id, action, request_id, status)
    values (p_user_id, v_action, p_request_id, 'reserved');

    return query select true, 0;
end;
$$;

create or replace function public.mark_ai_quota_provider_submission(
    p_user_id uuid,
    p_request_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
    v_marked_count bigint := 0;
begin
    if coalesce(auth.role(), '') <> 'service_role' then
        raise exception 'Service role required' using errcode = '42501';
    end if;
    if p_user_id is null or p_request_id is null then
        raise exception 'Verified user ID and request ID are required' using errcode = '22023';
    end if;

    update public.ai_usage_events
    set status = 'submitted',
        provider_submission_started_at = now()
    where user_id = p_user_id
      and request_id = p_request_id
      and status = 'reserved'
      and provider_submission_started_at is null;

    get diagnostics v_marked_count = row_count;
    if v_marked_count > 0 then
        return true;
    end if;

    -- Treat a repeated marker on an already submitted/completed reservation as
    -- idempotent. Any unknown row/status must stop before the provider call.
    return exists (
        select 1
        from public.ai_usage_events
        where user_id = p_user_id
          and request_id = p_request_id
          and status in ('submitted', 'completed')
          and provider_submission_started_at is not null
    );
end;
$$;

create or replace function public.complete_ai_quota_for_user(
    p_user_id uuid,
    p_request_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
    v_completed_count bigint := 0;
begin
    if coalesce(auth.role(), '') <> 'service_role' then
        raise exception 'Service role required' using errcode = '42501';
    end if;
    if p_user_id is null or p_request_id is null then
        raise exception 'Verified user ID and request ID are required' using errcode = '22023';
    end if;

    update public.ai_usage_events
    set status = 'completed'
    where user_id = p_user_id
      and request_id = p_request_id
      and status = 'submitted'
      and provider_submission_started_at is not null;

    get diagnostics v_completed_count = row_count;
    if v_completed_count > 0 then
        return true;
    end if;

    return exists (
        select 1
        from public.ai_usage_events
        where user_id = p_user_id
          and request_id = p_request_id
          and status = 'completed'
          and provider_submission_started_at is not null
    );
end;
$$;

create or replace function public.release_ai_quota_pre_send_failure(
    p_user_id uuid,
    p_request_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
    v_released_count bigint := 0;
begin
    if coalesce(auth.role(), '') <> 'service_role' then
        raise exception 'Service role required' using errcode = '42501';
    end if;
    if p_user_id is null or p_request_id is null then
        raise exception 'Verified user ID and request ID are required' using errcode = '22023';
    end if;

    -- A row can be released only while it has never crossed the persisted
    -- provider-submission boundary. In particular, a lost RPC response while
    -- marking submission, a provider timeout, or an upstream 5xx cannot be
    -- deleted by this function.
    delete from public.ai_usage_events
    where user_id = p_user_id
      and request_id = p_request_id
      and status = 'reserved'
      and provider_submission_started_at is null;

    get diagnostics v_released_count = row_count;
    return v_released_count > 0;
end;
$$;

revoke all on function public.reserve_ai_quota_for_user(uuid, text, uuid)
    from public, anon, authenticated;
revoke all on function public.mark_ai_quota_provider_submission(uuid, uuid)
    from public, anon, authenticated;
revoke all on function public.complete_ai_quota_for_user(uuid, uuid)
    from public, anon, authenticated;
revoke all on function public.release_ai_quota_pre_send_failure(uuid, uuid)
    from public, anon, authenticated;

grant execute on function public.reserve_ai_quota_for_user(uuid, text, uuid)
    to service_role;
grant execute on function public.mark_ai_quota_provider_submission(uuid, uuid)
    to service_role;
grant execute on function public.complete_ai_quota_for_user(uuid, uuid)
    to service_role;
grant execute on function public.release_ai_quota_pre_send_failure(uuid, uuid)
    to service_role;
