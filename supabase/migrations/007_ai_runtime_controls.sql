-- Server-side AI runtime controls. This migration starts AI disabled so an
-- operator must explicitly enable it after the production readiness gates are
-- complete. The control table contains no learner content or identifiers.

create table if not exists public.ai_runtime_controls (
    id smallint primary key default 1 check (id = 1),
    enabled boolean not null default false,
    changed_at timestamptz not null default now(),
    change_reference text not null default 'initial-disabled'
        check (char_length(change_reference) between 3 and 160)
);

create table if not exists public.ai_runtime_control_audit (
    id bigint generated always as identity primary key,
    enabled boolean not null,
    changed_at timestamptz not null default now(),
    change_reference text not null
        check (char_length(change_reference) between 3 and 160)
);

alter table public.ai_runtime_controls enable row level security;
alter table public.ai_runtime_control_audit enable row level security;

revoke all on table public.ai_runtime_controls, public.ai_runtime_control_audit
    from public, anon, authenticated;

insert into public.ai_runtime_controls (id, enabled, change_reference)
values (1, false, 'initial-disabled')
on conflict (id) do nothing;

insert into public.ai_runtime_control_audit (enabled, change_reference)
select enabled, change_reference
from public.ai_runtime_controls
where id = 1
  and not exists (
      select 1
      from public.ai_runtime_control_audit
  );

-- The Edge Function calls this using the learner's authenticated JWT. It
-- exposes only the effective boolean, never change history or operator data.
create or replace function public.ai_runtime_status()
returns table (enabled boolean)
language sql
stable
security definer
set search_path = public
as $$
    select controls.enabled
    from public.ai_runtime_controls as controls
    where controls.id = 1;
$$;

-- Only a service-role-controlled operational path may change the switch.
-- `p_change_reference` must be a change/incident ticket ID, not a secret or
-- personal data. Direct table updates bypass the audit trail and are not an
-- approved operational mechanism.
create or replace function public.set_ai_runtime_control(
    p_enabled boolean,
    p_change_reference text
)
returns table (enabled boolean, changed_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_reference text := btrim(coalesce(p_change_reference, ''));
    v_changed_at timestamptz := now();
begin
    if p_enabled is null then
        raise exception 'An enabled or disabled value is required'
            using errcode = '22023';
    end if;
    if char_length(v_reference) < 3 or char_length(v_reference) > 160 then
        raise exception 'A 3-160 character non-secret change reference is required'
            using errcode = '22023';
    end if;

    insert into public.ai_runtime_controls (
        id,
        enabled,
        changed_at,
        change_reference
    )
    values (1, p_enabled, v_changed_at, v_reference)
    on conflict (id) do update
    set enabled = excluded.enabled,
        changed_at = excluded.changed_at,
        change_reference = excluded.change_reference;

    insert into public.ai_runtime_control_audit (
        enabled,
        changed_at,
        change_reference
    )
    values (p_enabled, v_changed_at, v_reference);

    return query select p_enabled, v_changed_at;
end;
$$;

revoke all on function public.ai_runtime_status() from public, anon;
grant execute on function public.ai_runtime_status() to authenticated, service_role;

revoke all on function public.set_ai_runtime_control(boolean, text)
    from public, anon, authenticated;
grant execute on function public.set_ai_runtime_control(boolean, text)
    to service_role;
