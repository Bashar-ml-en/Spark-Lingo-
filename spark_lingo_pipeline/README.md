# Spark Lingo — Exam-Certification Content Pipeline

This package is the first real build-out of the "fill Duolingo's gap" plan:
sourcing real, openly-licensed content and structuring it around actual
international exams, in a way that scales to any language instead of
being hand-built one course at a time.

## What's in here

| File | Purpose |
|---|---|
| `exam_frameworks.json` | Verified exam bodies + CEFR/native-scale mapping for 12 languages. This is your single source of truth for "what does passing actually mean" per language — feed it into `exam_definitions` in Supabase. |
| `supabase_schema_additions.sql` | New tables (`exam_definitions`, `mock_exams`, `mock_exam_sections`, `user_mock_exam_attempts`, `user_exam_readiness`) that sit alongside your existing `units`/`lessons`/`flashcards`/`card_reviews` tables without touching them. |
| `content_pipeline/fetch_tatoeba.py` | Pulls real sentence/translation pairs from the Tatoeba public API (CC-BY 2.0) and shapes them into `flashcards` rows for the SM-2 engine. |
| `content_pipeline/process_common_voice.py` | Matches native-speaker audio from Mozilla Common Voice (CC0) to those flashcards, so vocabulary isn't just text — it's pronounced by real speakers. |
| `sample_curriculum_ielts_b2.json` | One fully worked unit showing the pattern: CEFR level → can-do statements → SRS vocab → AI speaking practice → AI-scored mock section. Replicate this shape per exam/level. |

## Why these two data sources specifically

- **Tatoeba**: the only sentence corpus with native contributor translations across 400+ languages, explicitly built for language learners, free for commercial use under CC-BY.
- **Common Voice**: the only large, quality-gated (two-upvote validation), CC0 speech corpus covering everything from major languages down to low-resource ones like Pashto and Quechua — genuinely open, no licensing fee, no attribution restriction beyond CC0's optional courtesy credit.

Both are real, running projects you can hit today — not placeholders.

## Running it (this sandbox has no outbound internet to Tatoeba/Common Voice, so run these on your own machine or in CI)

```bash
pip install requests

# 1. Pull ~500 English→French sentence pairs
python content_pipeline/fetch_tatoeba.py --from eng --to fra \
    --max-sentences 500 --out output/fr_flashcards_seed.json

# 2. Download the French Common Voice corpus from
#    https://commonvoice.mozilla.org/en/datasets, unzip it, then:
python content_pipeline/process_common_voice.py \
    --cv-dir ./cv-corpus-19.0-2024-09-13/fr \
    --flashcards output/fr_flashcards_seed.json \
    --out output/fr_flashcards_with_audio.json

# 3. Bulk-insert output/fr_flashcards_with_audio.json into Supabase
#    (supabase-py client, service-role key, batch insert into `flashcards`)
```

Repeat per language pair — `exam_frameworks.json` already lists the 12
languages to prioritize, plus a shortlist of languages Duolingo doesn't
support at all where you'd face far less competition.

## Where a human still has to be in the loop

- **Native-speaker review before publishing.** Tatoeba sentences are
  community-contributed and occasionally awkward or dated. Run generated
  units past a native speaker (or your AI pipeline with a strict
  "flag, don't fix silently" review pass) before they go live — this is
  what protects the "we get you exam-ready" promise from being undercut
  by a single bad translation.
- **Exam specimen papers.** `exam_frameworks.json` has the structurally
  correct exam formats, but scoring thresholds and question formats do
  shift between exam cycles — pull the current official handbook for
  each exam before finalizing `mock_exam_sections` content.
- **AI-scored practice ≠ official result.** Every mock exam section
  should carry the honesty disclaimer used in the sample unit. This is
  both an ethical line and a legal-safety one — none of these exam
  bodies endorse third-party AI scoring as equivalent to their own.

## Next build step

Wire `exam_level_mappings` so every existing unit in your curriculum
gets tagged with a CEFR/exam level, then add a placement-test flow that
routes a new user straight into the right unit instead of starting
everyone at zero.
