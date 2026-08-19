-- Spark Lingo: exam-certification module
-- Extends the existing curriculum tables (units, lessons, flashcards, card_reviews)
-- with a parallel "exam readiness" layer. Run as a new Supabase migration.

-- One row per real exam body/qualification (seeded from exam_frameworks.json)
create table if not exists exam_definitions (
    id text primary key,                 -- e.g. 'ielts_academic', 'hsk', 'delf'
    language_code text not null,         -- ISO 639-1, e.g. 'en', 'zh', 'fr'
    display_name text not null,
    issuing_body text not null,
    framework text not null,             -- 'CEFR' | 'HSK' | 'JLPT' | 'own_scale'
    skills_tested text[] not null,       -- e.g. {listening,reading,writing,speaking}
    scoring_notes text,
    source_url text,                     -- link to the official current handbook/specimen paper
    last_verified_at date not null       -- forces you to re-check formats periodically
);

-- Maps your existing curriculum units to a target exam level, so any unit
-- can say "this gets you to DELF B1" instead of just an internal difficulty tier.
create table if not exists exam_level_mappings (
    id uuid primary key default gen_random_uuid(),
    exam_id text references exam_definitions(id) on delete cascade,
    cefr_or_native_level text not null,  -- 'B1', 'HSK3', 'N4', 'TOPIK-II-4'
    -- Curriculum IDs are stable text IDs (for example `es_unit_1`), not UUIDs.
    unit_id text references units(id) on delete cascade,
    sort_order int not null default 0
);

-- Timed, scored practice tests per exam
create table if not exists mock_exams (
    id uuid primary key default gen_random_uuid(),
    exam_id text references exam_definitions(id) on delete cascade,
    title text not null,
    target_level text not null,
    time_limit_minutes int not null,
    is_full_length boolean not null default true, -- false = single-section drill
    created_at timestamptz not null default now()
);

create table if not exists mock_exam_sections (
    id uuid primary key default gen_random_uuid(),
    mock_exam_id uuid references mock_exams(id) on delete cascade,
    skill text not null,                 -- 'listening' | 'reading' | 'writing' | 'speaking'
    section_order int not null,
    prompt_content jsonb not null,       -- question text, audio_url, passage, rubric reference
    max_score numeric not null
);

-- User attempts + AI-scored results
create table if not exists user_mock_exam_attempts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade,
    mock_exam_id uuid references mock_exams(id),
    started_at timestamptz not null default now(),
    completed_at timestamptz,
    overall_score numeric,
    overall_band_or_level text,          -- e.g. 'Band 6.5', 'HSK4 pass'
    ai_feedback jsonb                    -- structured per-section rubric feedback from Sparky
);

create table if not exists user_exam_readiness (
    user_id uuid references auth.users(id) on delete cascade,
    exam_id text references exam_definitions(id) on delete cascade,
    current_estimated_level text,
    target_level text,
    target_date date,
    updated_at timestamptz not null default now(),
    primary key (user_id, exam_id)
);

-- RLS: users only see their own attempts/readiness; exam catalog is public read
alter table user_mock_exam_attempts enable row level security;
alter table user_exam_readiness enable row level security;
alter table exam_definitions enable row level security;

create policy "public read exam catalog" on exam_definitions for select using (true);
create policy "users manage own attempts" on user_mock_exam_attempts
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users manage own readiness" on user_exam_readiness
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
