# Prompt 05 — SRS Content Population from the Real-Data Pipeline

Run after Prompt 04. This connects the content pipeline (delivered
separately: `fetch_tatoeba.py`, `process_common_voice.py`) to the live
app data your Flutter code reads.

---

Your SM-2 engine and `card_reviews` sync already work (per
`spark_lingo_project_history.md`). This stage is about getting **real,
sourced content** into `units`/`lessons`/`flashcards` instead of
`syllabus_master.json` placeholder data, per language.

**Build:**

1. A small internal `scripts/import_flashcards.dart` (or a Supabase
   Edge Function if you prefer server-side) that takes the JSON output
   of `process_common_voice.py` (flashcard rows with
   `front_text`/`back_text`/`audio_url`/`srs_state`) and bulk-inserts
   into the `flashcards` table, linked to a `unit_id` you pass in.
   Include a dry-run flag that prints a diff instead of writing, so
   content can be reviewed before it goes live.

2. Extend the `Unit`/`Lesson` models if needed so a unit can carry a
   `sourceAttribution` string (surfaced in Prompt 09's Credits screen —
   Tatoeba requires CC-BY attribution, Common Voice CC0 doesn't require
   it but crediting it is good practice).

3. Keep `syllabus_master.json`'s offline-fallback role exactly as-is —
   don't remove it, just make sure the live Supabase data it falls back
   from is now real sourced content, not placeholder text.

4. Do not auto-publish imported content to users. Add an `isReviewed`
   boolean on units defaulting to `false`; only units flipped to `true`
   (by you, after native-speaker review — this is a manual step, not
   something to automate away) appear in the live curriculum query from
   Prompt 04.

**Verify:** import a small real batch (run `fetch_tatoeba.py` for one
language pair yourself, feed the output through the import script in
dry-run, inspect the diff) and confirm the shape matches what
`DatabaseService` expects before doing a real write.
