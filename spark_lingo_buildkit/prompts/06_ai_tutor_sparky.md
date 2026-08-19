# Prompt 06 — Sparky: Exam-Rubric-Aware Speaking/Writing Feedback

Run after Prompt 05.

---

Your `AIService`/Sparky pipeline already handles live conversation
correction via Supabase Edge Functions. Extend it to score practice
attempts against **real exam rubrics**, not just general grammar
correction.

**Build:**

1. Add a `rubricRef` parameter to the existing Sparky Edge Function call
   — when set (e.g. `ielts_speaking_band_descriptors_5_7`), the prompt
   sent to the model should include the actual band descriptor text for
   that rubric (source these from each exam body's public specimen
   materials — see `exam_frameworks.json`'s `source_url` fields; do not
   invent scoring criteria) and ask for structured output: a numeric/
   band estimate per criterion plus one specific, actionable correction
   — not a wall of feedback. Match the tone/scope already used in your
   general correction flow.

2. Response shape (Edge Function → client): 
   ```json
   { "estimated_band": "6.0-6.5", "criteria": [{"name": "fluency_coherence", "note": "..."}], "top_correction": "..." }
   ```
   Store this on `user_mock_exam_attempts.ai_feedback` (table from
   `supabase_schema_additions.sql`).

3. Every screen that surfaces an AI-estimated score MUST show the
   honesty disclaimer text from `sample_curriculum_ielts_b2.json`'s
   `honesty_disclaimer` field (or the section-specific equivalent) —
   make this a shared widget (`ai_score_disclaimer.dart`) so it can't be
   accidentally omitted on a new screen later.

4. Rate-limit/cost-guard: exam-rubric scoring calls are more
   token-heavy than casual correction — add a simple daily cap per user
   on the free tier (tie into `monetization_service.dart`, full paywall
   logic comes in Prompt 08).

**Verify:** run one full mock speaking attempt end-to-end (record →
transcribe → score against a real rubric → display result with
disclaimer) for at least one language and confirm the returned
`estimated_band` is plausible given a deliberately good and a
deliberately weak sample response.
