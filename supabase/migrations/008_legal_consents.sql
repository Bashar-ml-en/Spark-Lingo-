-- Server-backed, versioned consent evidence.
--
-- This migration intentionally contains no policy text or pre-populated URLs.
-- A legal/privacy owner must approve each document and an authorised operator
-- must register its exact HTTPS URL and version in each environment before
-- the mobile build can record consent or enable the related feature.

create table if not exists public.legal_document_versions (
    document_key text not null check (
        document_key in ('analytics', 'ai_processing', 'voice_processing')
    ),
    version text not null check (
        version ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'
    ),
    public_url text not null check (
        public_url ~ '^https://[^[:space:]@/]+'
    ),
    is_active boolean not null default false,
    activated_at timestamptz,
    retired_at timestamptz,
    change_reference text not null check (
        char_length(change_reference) between 3 and 160
    ),
    created_at timestamptz not null default now(),
    primary key (document_key, version),
    check (
        (is_active and activated_at is not null and retired_at is null)
        or not is_active
    )
);

-- One active version per processing purpose keeps the server-side decision
-- unambiguous. Historical rows remain as evidence for earlier consent events.
create unique index if not exists legal_document_versions_one_active_idx
    on public.legal_document_versions (document_key)
    where is_active;

create table if not exists public.user_consent_events (
    id bigint generated always as identity primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    document_key text not null,
    document_version text not null,
    event_type text not null check (event_type in ('accepted', 'withdrawn')),
    occurred_at timestamptz not null default now(),
    foreign key (document_key, document_version)
        references public.legal_document_versions (document_key, version)
        on delete restrict
);

create index if not exists user_consent_events_current_lookup_idx
    on public.user_consent_events (
        user_id,
        document_key,
        document_version,
        occurred_at desc,
        id desc
    );

alter table public.legal_document_versions enable row level security;
alter table public.user_consent_events enable row level security;

-- Neither document administration nor the raw consent ledger is directly
-- client writable/readable. The functions below derive user identity and
-- timestamps server-side, preventing a client from fabricating another
-- person's consent or backdating a record.
revoke all on table public.legal_document_versions, public.user_consent_events
    from public, anon, authenticated;

create or replace function public.has_active_user_consent(
    p_document_key text
)
returns table (
    has_consent boolean,
    document_version text,
    accepted_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_document_key text := lower(btrim(coalesce(p_document_key, '')));
    v_version text;
    v_event_type text;
    v_occurred_at timestamptz;
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;
    if v_document_key not in ('analytics', 'ai_processing', 'voice_processing') then
        raise exception 'Unsupported consent document' using errcode = '22023';
    end if;

    select version
    into v_version
    from public.legal_document_versions
    where document_key = v_document_key
      and is_active = true;

    if v_version is null then
        return query select false, null::text, null::timestamptz;
        return;
    end if;

    select event_type, occurred_at
    into v_event_type, v_occurred_at
    from public.user_consent_events
    where user_id = v_user_id
      and document_key = v_document_key
      and document_version = v_version
    order by occurred_at desc, id desc
    limit 1;

    return query select
        coalesce(v_event_type = 'accepted', false),
        v_version,
        case when v_event_type = 'accepted' then v_occurred_at else null end;
end;
$$;

create or replace function public.has_current_user_consent(
    p_document_key text,
    p_document_version text
)
returns table (
    has_consent boolean,
    accepted_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_document_key text := lower(btrim(coalesce(p_document_key, '')));
    v_document_version text := btrim(coalesce(p_document_version, ''));
    v_event_type text;
    v_occurred_at timestamptz;
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;
    if v_document_key not in ('analytics', 'ai_processing', 'voice_processing')
       or v_document_version !~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$' then
        raise exception 'Unsupported consent document' using errcode = '22023';
    end if;

    -- A release whose build-time version no longer matches the active,
    -- approved server registry must fail closed.
    if not exists (
        select 1
        from public.legal_document_versions
        where document_key = v_document_key
          and version = v_document_version
          and is_active = true
    ) then
        return query select false, null::timestamptz;
        return;
    end if;

    select event_type, occurred_at
    into v_event_type, v_occurred_at
    from public.user_consent_events
    where user_id = v_user_id
      and document_key = v_document_key
      and document_version = v_document_version
    order by occurred_at desc, id desc
    limit 1;

    return query select
        coalesce(v_event_type = 'accepted', false),
        case when v_event_type = 'accepted' then v_occurred_at else null end;
end;
$$;

create or replace function public.record_user_consent(
    p_document_key text,
    p_document_version text
)
returns table (
    accepted_at timestamptz,
    recorded boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_document_key text := lower(btrim(coalesce(p_document_key, '')));
    v_document_version text := btrim(coalesce(p_document_version, ''));
    v_event_type text;
    v_occurred_at timestamptz;
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;
    if v_document_key not in ('analytics', 'ai_processing', 'voice_processing')
       or v_document_version !~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$' then
        raise exception 'Unsupported consent document' using errcode = '22023';
    end if;

    if not exists (
        select 1
        from public.legal_document_versions
        where document_key = v_document_key
          and version = v_document_version
          and is_active = true
    ) then
        raise exception 'Consent document is not active' using errcode = '22023';
    end if;

    -- Make an accept/retry sequence idempotent even when two client actions
    -- reach the API at the same time.
    perform pg_advisory_xact_lock(
        hashtextextended(
            v_user_id::text || ':' || v_document_key || ':' || v_document_version,
            0
        )
    );

    select event_type, occurred_at
    into v_event_type, v_occurred_at
    from public.user_consent_events
    where user_id = v_user_id
      and document_key = v_document_key
      and document_version = v_document_version
    order by occurred_at desc, id desc
    limit 1;

    if v_event_type = 'accepted' then
        return query select v_occurred_at, false;
        return;
    end if;

    v_occurred_at := now();
    insert into public.user_consent_events (
        user_id,
        document_key,
        document_version,
        event_type,
        occurred_at
    )
    values (
        v_user_id,
        v_document_key,
        v_document_version,
        'accepted',
        v_occurred_at
    );

    return query select v_occurred_at, true;
end;
$$;

create or replace function public.withdraw_user_consent(
    p_document_key text,
    p_document_version text
)
returns table (
    withdrawn_at timestamptz,
    recorded boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_document_key text := lower(btrim(coalesce(p_document_key, '')));
    v_document_version text := btrim(coalesce(p_document_version, ''));
    v_event_type text;
    v_occurred_at timestamptz;
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;
    if v_document_key not in ('analytics', 'ai_processing', 'voice_processing')
       or v_document_version !~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$' then
        raise exception 'Unsupported consent document' using errcode = '22023';
    end if;

    -- Withdrawal remains possible after a version is retired, provided that
    -- it is a document registered by an authorised operator.
    if not exists (
        select 1
        from public.legal_document_versions
        where document_key = v_document_key
          and version = v_document_version
    ) then
        raise exception 'Unknown consent document' using errcode = '22023';
    end if;

    perform pg_advisory_xact_lock(
        hashtextextended(
            v_user_id::text || ':' || v_document_key || ':' || v_document_version,
            0
        )
    );

    select event_type
    into v_event_type
    from public.user_consent_events
    where user_id = v_user_id
      and document_key = v_document_key
      and document_version = v_document_version
    order by occurred_at desc, id desc
    limit 1;

    if v_event_type is distinct from 'accepted' then
        return query select null::timestamptz, false;
        return;
    end if;

    v_occurred_at := now();
    insert into public.user_consent_events (
        user_id,
        document_key,
        document_version,
        event_type,
        occurred_at
    )
    values (
        v_user_id,
        v_document_key,
        v_document_version,
        'withdrawn',
        v_occurred_at
    );

    return query select v_occurred_at, true;
end;
$$;

revoke all on function public.has_active_user_consent(text) from public, anon;
grant execute on function public.has_active_user_consent(text) to authenticated;
revoke all on function public.has_current_user_consent(text, text) from public, anon;
grant execute on function public.has_current_user_consent(text, text) to authenticated;
revoke all on function public.record_user_consent(text, text) from public, anon;
grant execute on function public.record_user_consent(text, text) to authenticated;
revoke all on function public.withdraw_user_consent(text, text) from public, anon;
grant execute on function public.withdraw_user_consent(text, text) to authenticated;
