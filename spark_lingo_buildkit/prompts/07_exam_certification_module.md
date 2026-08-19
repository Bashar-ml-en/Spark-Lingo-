# Prompt 07 — Exam Certification Module

Run after Prompt 06. This is the core differentiator feature — take your
time on this one.

---

Build the full exam-prep module on top of the Supabase tables from
`supabase_schema_additions.sql` (`exam_definitions`, `mock_exams`,
`mock_exam_sections`, `user_mock_exam_attempts`, `user_exam_readiness`)
and the content shape from `sample_curriculum_ielts_b2.json`.

**Build:**

1. `lib/features/exam_prep/placement_test_screen.dart` — a short
   adaptive-feel diagnostic (10-15 items mixing reading/listening
   snippets and one speaking prompt) shown once per language, on first
   entry to exam-prep for that language. Result writes an initial
   `current_estimated_level` into `user_exam_readiness`. Keep this
   under 10 minutes to complete — a long diagnostic is a drop-off point.

2. `lib/features/exam_prep/mock_exam_screen.dart` — timed, sectioned
   exam UI driven by `mock_exam_sections` rows (`skill`, `prompt_content`,
   `time_limit_minutes` from the parent `mock_exams` row). Support all
   four skills' UI patterns: reading (passage + questions), listening
   (audio player + questions), writing (timed text entry + word count),
   speaking (record button, uses the Prompt 06 scoring pipeline).
   Auto-submit when the timer hits zero, matching real exam conditions
   — don't let users pause mid-section, since that's part of what makes
   practice predictive of the real thing.

3. `lib/features/exam_prep/exam_readiness_dashboard.dart` — shows
   `current_estimated_level` → `target_level` progress using
   `score_band_gauge.dart` (a simple radial/linear gauge widget) and a
   per-skill breakdown via `skill_breakdown_chart.dart` (bar chart,
   one bar per skill, pulling from recent `user_mock_exam_attempts.
   ai_feedback`). Let the user set/edit `target_level` and
   `target_date` here — this drives retention nudges (see Prompt 08 for
   notification logic, keep this screen just the data view + editor).

4. Exam picker: a user's active language determines which
   `exam_definitions` rows are shown (filter by `language_code`) — for
   languages with no standardized global exam (Arabic, Hindi per
   `exam_frameworks.json`'s notes), show a CEFR-style proficiency-ladder
   view instead of a specific exam name, and say so plainly in the UI
   rather than presenting an invented exam as if it were standardized.

**Verify:** complete one full placement test → dashboard → mock exam →
updated dashboard cycle for one language and confirm the readiness
numbers update correctly and persist across app restarts.
