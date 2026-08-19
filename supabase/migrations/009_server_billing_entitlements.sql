-- Server-authoritative billing controls and entitlement ledger.
--
-- This migration intentionally starts billing disabled. The mobile client may
-- display a paywall, but it cannot grant premium access or enable purchases
-- until a service-role operator has completed the external RevenueCat, store,
-- legal, and sandbox-evidence gates and records that approval here.

create table if not exists public.billing_runtime_controls (
    id smallint primary key default 1 check (id = 1),
    enabled boolean not null default false,
    allow_sandbox boolean not null default false,
    changed_at timestamptz not null default now(),
    change_reference text not null default 'initial-disabled'
        check (char_length(change_reference) between 3 and 160)
);

create table if not exists public.billing_runtime_control_audit (
    id bigint generated always as identity primary key,
    enabled boolean not null,
    allow_sandbox boolean not null,
    changed_at timestamptz not null default now(),
    change_reference text not null
        check (char_length(change_reference) between 3 and 160)
);

alter table public.billing_runtime_controls enable row level security;
alter table public.billing_runtime_control_audit enable row level security;

revoke all on table public.billing_runtime_controls,
    public.billing_runtime_control_audit from public, anon, authenticated;

insert into public.billing_runtime_controls (id, enabled, allow_sandbox, change_reference)
values (1, false, false, 'initial-disabled')
on conflict (id) do nothing;

insert into public.billing_runtime_control_audit (
    enabled,
    allow_sandbox,
    changed_at,
    change_reference
)
select enabled, allow_sandbox, changed_at, change_reference
from public.billing_runtime_controls
where id = 1
  and not exists (
      select 1 from public.billing_runtime_control_audit
  );

-- The app may learn whether billing is enabled, but never receives the
-- operator audit history or a way to change this control.
create or replace function public.billing_runtime_status()
returns table (enabled boolean)
language sql
stable
security definer
set search_path = public
as $$
    select controls.enabled
    from public.billing_runtime_controls as controls
    where controls.id = 1;
$$;

-- A service-role-only control path keeps an audited kill switch independent of
-- a mobile release. `p_change_reference` must be an incident/change record,
-- never a secret, purchase token, or learner data.
create or replace function public.set_billing_runtime_control(
    p_enabled boolean,
    p_allow_sandbox boolean,
    p_change_reference text
)
returns table (enabled boolean, allow_sandbox boolean, changed_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_reference text := btrim(coalesce(p_change_reference, ''));
    v_changed_at timestamptz := now();
begin
    if auth.role() <> 'service_role' then
        raise exception 'Service role required' using errcode = '42501';
    end if;
    if p_enabled is null or p_allow_sandbox is null then
        raise exception 'Enabled and allow_sandbox values are required'
            using errcode = '22023';
    end if;
    if char_length(v_reference) < 3 or char_length(v_reference) > 160 then
        raise exception 'A 3-160 character non-secret change reference is required'
            using errcode = '22023';
    end if;

    insert into public.billing_runtime_controls (
        id,
        enabled,
        allow_sandbox,
        changed_at,
        change_reference
    )
    values (1, p_enabled, p_allow_sandbox, v_changed_at, v_reference)
    on conflict (id) do update
    set enabled = excluded.enabled,
        allow_sandbox = excluded.allow_sandbox,
        changed_at = excluded.changed_at,
        change_reference = excluded.change_reference;

    insert into public.billing_runtime_control_audit (
        enabled,
        allow_sandbox,
        changed_at,
        change_reference
    )
    values (p_enabled, p_allow_sandbox, v_changed_at, v_reference);

    return query select p_enabled, p_allow_sandbox, v_changed_at;
end;
$$;

revoke all on function public.billing_runtime_status() from public, anon;
grant execute on function public.billing_runtime_status() to authenticated, service_role;

revoke all on function public.set_billing_runtime_control(boolean, boolean, text)
    from public, anon, authenticated;
grant execute on function public.set_billing_runtime_control(boolean, boolean, text)
    to service_role;

-- A recoverable account is explicitly registered before it can be used as a
-- RevenueCat App User ID. Anonymous Supabase users are authenticated database
-- users, so role checks alone are not sufficient to protect purchases.
create table if not exists public.billing_customer_accounts (
    user_id uuid primary key references auth.users(id) on delete cascade,
    revenuecat_app_user_id text not null unique
        check (
            char_length(revenuecat_app_user_id) between 36 and 64
            and revenuecat_app_user_id = user_id::text
        ),
    registered_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.billing_customer_accounts enable row level security;
revoke all on table public.billing_customer_accounts from public, anon, authenticated;

create trigger billing_customer_accounts_set_updated_at
before update on public.billing_customer_accounts
for each row execute function public.set_updated_at();

-- This function has no caller-supplied user ID. A caller can register only the
-- verified session's own permanent, confirmed identity; an anonymous session
-- deliberately receives `ready = false`.
create or replace function public.ensure_billing_customer()
returns table (ready boolean)
language plpgsql
security definer
set search_path = public, auth
as $$
declare
    v_user_id uuid := auth.uid();
    v_is_confirmed boolean;
    v_has_identity boolean;
begin
    if v_user_id is null then
        raise exception 'Authenticated user required' using errcode = '42501';
    end if;

    -- The JWT claim blocks an anonymous session even if the auth row changes
    -- between token issue and this request. The database values provide a
    -- second, server-side check.
    if coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then
        return query select false;
        return;
    end if;

    select
        users.confirmed_at is not null,
        exists (
            select 1
            from auth.identities as identities
            where identities.user_id = users.id
        )
    into v_is_confirmed, v_has_identity
    from auth.users as users
    where users.id = v_user_id;

    if not coalesce(v_is_confirmed, false)
       or not coalesce(v_has_identity, false) then
        return query select false;
        return;
    end if;

    insert into public.billing_customer_accounts (
        user_id,
        revenuecat_app_user_id
    )
    values (v_user_id, v_user_id::text)
    on conflict (user_id) do update
    set revenuecat_app_user_id = excluded.revenuecat_app_user_id;

    return query select true;
end;
$$;

revoke all on function public.ensure_billing_customer() from public, anon;
grant execute on function public.ensure_billing_customer() to authenticated, service_role;

-- The immutable event ledger stores only the minimum payment-operational data
-- needed for idempotency and support. It never stores a receipt, raw webhook
-- body, payment instrument, RevenueCat secret, or subscriber attributes.
create table if not exists public.billing_webhook_events (
    event_id text not null check (char_length(event_id) between 1 and 256),
    entitlement_id text not null check (char_length(entitlement_id) between 1 and 128),
    user_id uuid not null references auth.users(id) on delete cascade,
    event_type text not null check (char_length(event_type) between 1 and 64),
    environment text not null check (environment in ('SANDBOX', 'PRODUCTION')),
    product_id text check (product_id is null or char_length(product_id) <= 256),
    payload_sha256 text not null check (payload_sha256 ~ '^[0-9a-f]{64}$'),
    provider_event_at timestamptz not null,
    received_at timestamptz not null default now(),
    primary key (event_id, entitlement_id)
);

create table if not exists public.billing_entitlements (
    user_id uuid not null references auth.users(id) on delete cascade,
    entitlement_id text not null check (char_length(entitlement_id) between 1 and 128),
    environment text not null check (environment in ('SANDBOX', 'PRODUCTION')),
    product_id text check (product_id is null or char_length(product_id) <= 256),
    access_active boolean not null default false,
    access_expires_at timestamptz,
    auto_renewing boolean not null default false,
    last_event_type text not null check (char_length(last_event_type) between 1 and 64),
    source_event_id text not null check (char_length(source_event_id) between 1 and 256),
    last_event_at timestamptz not null,
    updated_at timestamptz not null default now(),
    primary key (user_id, entitlement_id, environment)
);

create index if not exists billing_entitlements_active_lookup_idx
    on public.billing_entitlements (
        user_id,
        entitlement_id,
        environment,
        access_active,
        access_expires_at
    );

alter table public.billing_webhook_events enable row level security;
alter table public.billing_entitlements enable row level security;

revoke all on table public.billing_webhook_events, public.billing_entitlements
    from public, anon, authenticated;

-- Returns only a boolean for the currently authenticated customer. The client
-- has no table grants and cannot write or select a premium state directly.
create or replace function public.has_active_billing_entitlement(
    p_entitlement_id text default 'spark_premium'
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
begin
    if v_user_id is null
       or p_entitlement_id is null
       or char_length(p_entitlement_id) < 1
       or char_length(p_entitlement_id) > 128
       or coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then
        return false;
    end if;

    return exists (
        select 1
        from public.billing_runtime_controls as controls
        join public.billing_customer_accounts as customers
            on customers.user_id = v_user_id
        join public.billing_entitlements as entitlements
            on entitlements.user_id = customers.user_id
           and entitlements.entitlement_id = p_entitlement_id
        where controls.id = 1
          and controls.enabled
          and (
              entitlements.environment = 'PRODUCTION'
              or (controls.allow_sandbox and entitlements.environment = 'SANDBOX')
          )
          and entitlements.access_active
          and (
              entitlements.access_expires_at is null
              or entitlements.access_expires_at > now()
          )
    );
end;
$$;

revoke all on function public.has_active_billing_entitlement(text) from public, anon;
grant execute on function public.has_active_billing_entitlement(text)
    to authenticated, service_role;

-- Called only by the authenticated RevenueCat webhook Edge Function using the
-- service role. It finds a pre-registered recoverable account across the
-- current/original/alias IDs, makes duplicate deliveries harmless, and never
-- lets a non-grant event create access for a new customer.
create or replace function public.apply_revenuecat_entitlement_event(
    p_event_id text,
    p_event_type text,
    p_customer_ids text[],
    p_entitlement_id text,
    p_environment text,
    p_product_id text,
    p_event_at timestamptz,
    p_expires_at timestamptz,
    p_payload_sha256 text
)
returns table (processed boolean, active boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_ids uuid[];
    v_user_id uuid;
    v_inserted boolean := false;
    v_existing_active boolean := false;
    v_existing_expires_at timestamptz;
    v_existing_auto_renewing boolean := false;
    v_existing_event_at timestamptz;
    v_has_existing boolean := false;
    v_next_active boolean := false;
    v_next_expires_at timestamptz;
    v_next_auto_renewing boolean := false;
    v_effective_active boolean := false;
begin
    if auth.role() <> 'service_role' then
        raise exception 'Service role required' using errcode = '42501';
    end if;

    if p_event_id is null or char_length(p_event_id) < 1 or char_length(p_event_id) > 256
       or p_event_type is null or char_length(p_event_type) < 1 or char_length(p_event_type) > 64
       or p_entitlement_id is null or char_length(p_entitlement_id) < 1 or char_length(p_entitlement_id) > 128
       or p_product_id is not null and char_length(p_product_id) > 256
       or p_event_at is null
       or p_payload_sha256 is null or p_payload_sha256 !~ '^[0-9a-f]{64}$'
       or coalesce(array_length(p_customer_ids, 1), 0) < 1
       or coalesce(array_length(p_customer_ids, 1), 0) > 32
       or exists (
           select 1
           from unnest(p_customer_ids) as customer_id
           where customer_id is null
              or char_length(customer_id) < 1
              or char_length(customer_id) > 256
       ) then
        raise exception 'Invalid billing webhook event' using errcode = '22023';
    end if;

    if p_environment is null or p_environment not in ('SANDBOX', 'PRODUCTION') then
        raise exception 'Unsupported billing environment' using errcode = '22023';
    end if;
    if p_event_type not in (
        'INITIAL_PURCHASE',
        'RENEWAL',
        'NON_RENEWING_PURCHASE',
        'CANCELLATION',
        'UNCANCELLATION',
        'EXPIRATION',
        'BILLING_ISSUE',
        'SUBSCRIPTION_PAUSED',
        'PRODUCT_CHANGE',
        'SUBSCRIPTION_EXTENDED',
        'REFUND_REVERSED'
    ) then
        raise exception 'Unsupported billing event type' using errcode = '22023';
    end if;

    select array_agg(distinct customers.user_id)
    into v_user_ids
    from public.billing_customer_accounts as customers
    where customers.revenuecat_app_user_id = any(p_customer_ids);

    if coalesce(array_length(v_user_ids, 1), 0) <> 1 then
        -- Do not manufacture a customer mapping from a webhook. Returning an
        -- error makes the endpoint retryable while the account-linking issue is
        -- investigated, and prevents guest or cross-account grants.
        raise exception 'No unique recoverable billing customer mapping'
            using errcode = 'P0001';
    end if;
    v_user_id := v_user_ids[1];

    insert into public.billing_webhook_events (
        event_id,
        entitlement_id,
        user_id,
        event_type,
        environment,
        product_id,
        payload_sha256,
        provider_event_at
    )
    values (
        p_event_id,
        p_entitlement_id,
        v_user_id,
        p_event_type,
        p_environment,
        p_product_id,
        p_payload_sha256,
        p_event_at
    )
    on conflict (event_id, entitlement_id) do nothing
    returning true into v_inserted;

    if not coalesce(v_inserted, false) then
        select
            entitlements.access_active
            and (
                entitlements.access_expires_at is null
                or entitlements.access_expires_at > now()
            )
        into v_effective_active
        from public.billing_entitlements as entitlements
        where entitlements.user_id = v_user_id
          and entitlements.entitlement_id = p_entitlement_id
          and entitlements.environment = p_environment;

        return query select false, coalesce(v_effective_active, false);
        return;
    end if;

    select
        entitlements.access_active,
        entitlements.access_expires_at,
        entitlements.auto_renewing,
        entitlements.last_event_at
    into
        v_existing_active,
        v_existing_expires_at,
        v_existing_auto_renewing,
        v_existing_event_at
    from public.billing_entitlements as entitlements
    where entitlements.user_id = v_user_id
      and entitlements.entitlement_id = p_entitlement_id
      and entitlements.environment = p_environment
    for update;
    v_has_existing := found;

    -- Older deliveries are recorded for idempotency/audit purposes but cannot
    -- roll a newer entitlement state backward.
    if v_has_existing and p_event_at < v_existing_event_at then
        v_effective_active := v_existing_active
            and (
                v_existing_expires_at is null
                or v_existing_expires_at > now()
            );
        return query select true, v_effective_active;
        return;
    end if;

    v_next_active := v_existing_active;
    v_next_expires_at := v_existing_expires_at;
    v_next_auto_renewing := v_existing_auto_renewing;

    case p_event_type
        when 'INITIAL_PURCHASE', 'RENEWAL' then
            v_next_active := true;
            v_next_expires_at := p_expires_at;
            v_next_auto_renewing := true;
        when 'NON_RENEWING_PURCHASE' then
            v_next_active := true;
            v_next_expires_at := p_expires_at;
            v_next_auto_renewing := false;
        when 'UNCANCELLATION' then
            v_next_active := true;
            v_next_expires_at := p_expires_at;
            v_next_auto_renewing := true;
        when 'EXPIRATION' then
            v_next_active := false;
            v_next_expires_at := coalesce(p_expires_at, now());
            v_next_auto_renewing := false;
        when 'CANCELLATION' then
            -- A normal cancellation retains paid-through access. A null or
            -- elapsed expiry (for example an immediate lifetime refund) fails
            -- closed rather than preserving access indefinitely.
            v_next_expires_at := coalesce(p_expires_at, v_existing_expires_at);
            v_next_active := coalesce(v_existing_active, false)
                and p_expires_at is not null
                and p_expires_at > now();
            v_next_auto_renewing := false;
        when 'BILLING_ISSUE', 'PRODUCT_CHANGE', 'SUBSCRIPTION_EXTENDED',
             'REFUND_REVERSED' then
            -- These signals must not create a new entitlement by themselves.
            -- Preserve a prior active state and use a later verified purchase,
            -- renewal, or reconciliation to make a new grant.
            v_next_expires_at := coalesce(p_expires_at, v_existing_expires_at);
        when 'SUBSCRIPTION_PAUSED' then
            -- RevenueCat says access is removed on EXPIRATION, not when a
            -- pause is scheduled. Preserve existing access until then.
            v_next_expires_at := coalesce(p_expires_at, v_existing_expires_at);
            v_next_auto_renewing := false;
    end case;

    v_effective_active := coalesce(v_next_active, false)
        and (
            v_next_expires_at is null
            or v_next_expires_at > now()
        );

    insert into public.billing_entitlements (
        user_id,
        entitlement_id,
        environment,
        product_id,
        access_active,
        access_expires_at,
        auto_renewing,
        last_event_type,
        source_event_id,
        last_event_at
    )
    values (
        v_user_id,
        p_entitlement_id,
        p_environment,
        p_product_id,
        v_effective_active,
        v_next_expires_at,
        v_next_auto_renewing,
        p_event_type,
        p_event_id,
        p_event_at
    )
    on conflict (user_id, entitlement_id, environment) do update
    set product_id = excluded.product_id,
        access_active = excluded.access_active,
        access_expires_at = excluded.access_expires_at,
        auto_renewing = excluded.auto_renewing,
        last_event_type = excluded.last_event_type,
        source_event_id = excluded.source_event_id,
        last_event_at = excluded.last_event_at,
        updated_at = now()
    where public.billing_entitlements.last_event_at <= excluded.last_event_at;

    return query select true, v_effective_active;
end;
$$;

revoke all on function public.apply_revenuecat_entitlement_event(
    text, text, text[], text, text, text, timestamptz, timestamptz, text
) from public, anon, authenticated;
grant execute on function public.apply_revenuecat_entitlement_event(
    text, text, text[], text, text, text, timestamptz, timestamptz, text
) to service_role;
