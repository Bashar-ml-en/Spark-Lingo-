-- Real lesson progress: per-user completion of curriculum lessons.
--
-- Powers the redesigned home path: unit progress rings, lesson checkmarks,
-- and the "continue where you left off" affordance. Writes go through the
-- security-definer RPC so completion can only be recorded server-side after
-- a session that actually ran; clients cannot upsert rows directly.

create table if not exists public.lesson_progress (
    user_id uuid not null references auth.users(id) on delete cascade,
    lesson_id text not null
        check (length(lesson_id) between 1 and 64),
    language_code text not null default ''
        check (language_code ~ '^([a-z]{2,3}(-[A-Za-z]{2})?)?$'),
    attempts integer not null default 1 check (attempts >= 1),
    first_completed_at timestamptz not null default now(),
    last_completed_at timestamptz not null default now(),
    primary key (user_id, lesson_id)
);

create index if not exists lesson_progress_user_lang_idx
    on public.lesson_progress (user_id, language_code);

alter table public.lesson_progress enable row level security;

create policy "learners read own lesson progress"
    on public.lesson_progress for select
    using (auth.uid() = user_id);

-- No INSERT/UPDATE policies: writes happen exclusively through the RPC.

-- Record one completion of a lesson. Idempotent per (user, lesson): repeat
-- completions bump attempts + last_completed_at.
create or replace function public.complete_lesson(
    p_lesson_id text,
    p_language_code text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user uuid := auth.uid();
begin
    if v_user is null then
        raise exception 'Authentication required' using errcode = '28000';
    end if;
    if p_lesson_id is null or length(p_lesson_id) = 0
        or length(p_lesson_id) > 64 then
        raise exception 'Invalid lesson id' using errcode = '22023';
    end if;

    insert into public.lesson_progress
        (user_id, lesson_id, language_code)
    values (v_user, p_lesson_id, coalesce(p_language_code, ''))
    on conflict (user_id, lesson_id) do update
    set attempts = lesson_progress.attempts + 1,
        last_completed_at = now();
end;
$$;

revoke all on function public.complete_lesson(text, text)
    from public, anon, service_role;
