-- Spark Lingo core schema.
--
-- This repository previously had seed data and feature migrations without a
-- reproducible definition of the tables they depend on.  Keep identifiers as
-- text because curriculum IDs are stable, human-readable values (for example
-- `es_unit_1`) shared by the bundled curriculum and the database.

create extension if not exists pgcrypto;

create table if not exists public.languages (
    id text primary key check (id ~ '^[a-z]{2,3}(-[A-Za-z]{2})?$'),
    name text not null check (char_length(name) between 1 and 80),
    code text not null unique check (code ~ '^[a-z]{2,3}(-[A-Za-z]{2})?$'),
    created_at timestamptz not null default now()
);

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    trial_expires_at timestamptz not null default (now() + interval '7 days'),
    is_premium boolean not null default false,
    native_language text,
    target_languages text[] not null default '{}'::text[],
    active_language text
);

create table if not exists public.units (
    id text primary key,
    language_id text not null references public.languages(id) on delete cascade,
    title text not null check (char_length(title) between 1 and 160),
    description text not null default '',
    order_index integer not null default 0 check (order_index >= 0),
    is_reviewed boolean not null default false,
    source_attribution text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (language_id, order_index)
);

create table if not exists public.lessons (
    id text primary key,
    unit_id text not null references public.units(id) on delete cascade,
    title text not null check (char_length(title) between 1 and 160),
    description text not null default '',
    order_index integer not null default 0 check (order_index >= 0),
    type text,
    skill text,
    rubric_ref text,
    honesty_disclaimer text,
    sparky_prompt_template text,
    source_attribution text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (unit_id, order_index)
);

create table if not exists public.flashcards (
    id text primary key,
    lesson_id text not null references public.lessons(id) on delete cascade,
    front_text text not null check (char_length(front_text) between 1 and 4000),
    back_text text not null check (char_length(back_text) between 1 and 4000),
    context_sentence text,
    audio_url text,
    source text,
    source_attribution text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.card_reviews (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    card_id text not null references public.flashcards(id) on delete cascade,
    language_key text not null check (language_key ~ '^[a-z]{2,3}(-[A-Za-z]{2})?$'),
    interval integer not null default 0 check (interval >= 0),
    repetitions integer not null default 0 check (repetitions >= 0),
    efactor numeric(4,2) not null default 2.50 check (efactor >= 1.30 and efactor <= 5.00),
    next_review_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, card_id, language_key)
);

create index if not exists card_reviews_due_idx
    on public.card_reviews (user_id, language_key, next_review_at);
create index if not exists units_language_order_idx
    on public.units (language_id, order_index);
create index if not exists lessons_unit_order_idx
    on public.lessons (unit_id, order_index);
create index if not exists flashcards_lesson_idx
    on public.flashcards (lesson_id);

-- Keep server-managed timestamps trustworthy and avoid relying on client clocks.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

create or replace function public.enforce_profile_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.role() in ('anon', 'authenticated') then
        if tg_op = 'INSERT' then
            if auth.uid() is null or new.id <> auth.uid() then
                raise exception 'A profile can only be created for the current user';
            end if;

            -- Subscription entitlement and trial timing are only managed by a
            -- trusted server-side billing workflow.
            new.is_premium := false;
            new.created_at := now();
            new.trial_expires_at := now() + interval '7 days';
        else
            if auth.uid() is null or old.id <> auth.uid() then
                raise exception 'A profile can only be changed by its owner';
            end if;

            new.id := old.id;
            new.created_at := old.created_at;
            new.is_premium := old.is_premium;
            new.trial_expires_at := old.trial_expires_at;
        end if;
    end if;

    new.display_name := nullif(trim(coalesce(new.display_name, '')), '');
    if new.display_name is not null and char_length(new.display_name) > 80 then
        raise exception 'Display name is too long';
    end if;

    if new.native_language is not null and new.native_language !~ '^[a-z]{2,3}(-[A-Za-z]{2})?$' then
        raise exception 'Native language must be a language code';
    end if;

    new.target_languages := coalesce(new.target_languages, '{}'::text[]);
    if cardinality(new.target_languages) > 10
       or exists (
           select 1
           from unnest(new.target_languages) as language_code
           where language_code !~ '^[a-z]{2,3}(-[A-Za-z]{2})?$'
       ) then
        raise exception 'Target languages must contain at most ten language codes';
    end if;

    if new.active_language is not null and new.active_language !~ '^[a-z]{2,3}(-[A-Za-z]{2})?$' then
        raise exception 'Active language must be a language code';
    end if;

    -- Do not leave an active language pointing outside the learner's selection.
    if new.active_language is not null and not (new.active_language = any(new.target_languages)) then
        new.active_language := null;
    end if;

    return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, display_name)
    values (
        new.id,
        nullif(left(trim(coalesce(new.raw_user_meta_data ->> 'display_name', '')), 80), '')
    )
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists profiles_enforce_safe_writes on public.profiles;
create trigger profiles_enforce_safe_writes
before insert or update on public.profiles
for each row execute function public.enforce_profile_write();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists units_set_updated_at on public.units;
create trigger units_set_updated_at
before update on public.units
for each row execute function public.set_updated_at();

drop trigger if exists lessons_set_updated_at on public.lessons;
create trigger lessons_set_updated_at
before update on public.lessons
for each row execute function public.set_updated_at();

drop trigger if exists flashcards_set_updated_at on public.flashcards;
create trigger flashcards_set_updated_at
before update on public.flashcards
for each row execute function public.set_updated_at();

drop trigger if exists card_reviews_set_updated_at on public.card_reviews;
create trigger card_reviews_set_updated_at
before update on public.card_reviews
for each row execute function public.set_updated_at();

-- Do not replace an existing production auth trigger. A legacy installation
-- may already create profiles through a different audited mechanism; in that
-- case the client-side idempotent profile upsert remains a safe fallback.
do $$
begin
    if not exists (
        select 1
        from pg_trigger
        where tgrelid = 'auth.users'::regclass
          and tgname = 'on_auth_user_created'
          and not tgisinternal
    ) then
        create trigger on_auth_user_created
        after insert on auth.users
        for each row execute function public.handle_new_user();
    end if;
end;
$$;

alter table public.languages enable row level security;
alter table public.profiles enable row level security;
alter table public.units enable row level security;
alter table public.lessons enable row level security;
alter table public.flashcards enable row level security;
alter table public.card_reviews enable row level security;

drop policy if exists "read curriculum languages" on public.languages;
create policy "read curriculum languages" on public.languages
    for select to anon, authenticated using (true);

drop policy if exists "read reviewed units" on public.units;
create policy "read reviewed units" on public.units
    for select to anon, authenticated using (is_reviewed = true);

drop policy if exists "read lessons in reviewed units" on public.lessons;
create policy "read lessons in reviewed units" on public.lessons
    for select to anon, authenticated
    using (
        exists (
            select 1 from public.units
            where public.units.id = lessons.unit_id
              and public.units.is_reviewed = true
        )
    );

drop policy if exists "read flashcards in reviewed units" on public.flashcards;
create policy "read flashcards in reviewed units" on public.flashcards
    for select to anon, authenticated
    using (
        exists (
            select 1
            from public.lessons
            join public.units on public.units.id = public.lessons.unit_id
            where public.lessons.id = flashcards.lesson_id
              and public.units.is_reviewed = true
        )
    );

drop policy if exists "users read own profile" on public.profiles;
create policy "users read own profile" on public.profiles
    for select to authenticated using (id = auth.uid());

drop policy if exists "users create own profile" on public.profiles;
create policy "users create own profile" on public.profiles
    for insert to authenticated with check (id = auth.uid());

drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles
    for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "users read own card reviews" on public.card_reviews;
create policy "users read own card reviews" on public.card_reviews
    for select to authenticated using (user_id = auth.uid());

drop policy if exists "users create own card reviews" on public.card_reviews;
create policy "users create own card reviews" on public.card_reviews
    for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "users update own card reviews" on public.card_reviews;
create policy "users update own card reviews" on public.card_reviews
    for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "users delete own card reviews" on public.card_reviews;
create policy "users delete own card reviews" on public.card_reviews
    for delete to authenticated using (user_id = auth.uid());

revoke all on table public.languages, public.units, public.lessons, public.flashcards from anon, authenticated;
grant select on table public.languages, public.units, public.lessons, public.flashcards to anon, authenticated;

revoke all on table public.profiles from anon, authenticated;
grant select, insert, update on table public.profiles to authenticated;

revoke all on table public.card_reviews from anon, authenticated;
grant select, insert, update, delete on table public.card_reviews to authenticated;

revoke all on function public.set_updated_at() from public;
revoke all on function public.enforce_profile_write() from public;
revoke all on function public.handle_new_user() from public;
