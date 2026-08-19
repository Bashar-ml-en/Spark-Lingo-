# Prompt 01 — Project Scaffold & Dependency Setup

Paste this into Antigravity as the first task, with the Spark Lingo repo open as the workspace.

---

You are working in an existing Flutter app called Spark Lingo. The
current structure is documented in `PROJECT_STRUCTURE.md` at the repo
root — read it fully before making changes, and treat every path marked
`[NEW]` in that file as something you need to create in this and later
stages (not all in this one).

**Scope for this stage only:**

1. Add these folders if they don't exist, with a `.gitkeep` placeholder
   in each empty one: `assets/flags/`, `assets/symbols/`, `assets/fonts/`,
   `assets/audio/`, `lib/features/exam_prep/`, `lib/features/exam_prep/widgets/`,
   `lib/features/onboarding/widgets/`, `supabase/migrations/`,
   `content_pipeline/output/`.
2. Update `pubspec.yaml`:
   - Register `assets/flags/`, `assets/symbols/`, `assets/audio/` as
     asset directories.
   - Register font families `Inter`, `NotoSansJP`, `NotoSansKR`,
     `NotoSansSC`, `NotoSansArabic`, `NotoSansDevanagari`,
     `NotoSansThai` pointing at files under `assets/fonts/` (files
     themselves are added in a later stage — just wire the pubspec
     entries and leave a `# TODO: add font files` comment above each
     family block).
   - Add `flutter_svg` (for flag/symbol SVG rendering) and `intl` (if
     not already present) as dependencies.
3. Copy `supabase_schema_additions.sql` (provided separately) into
   `supabase/migrations/002_exam_module.sql` unchanged.
4. Copy `design/language_design_tokens.json` (provided separately) into
   `assets/language_design_tokens.json` and register it in pubspec's
   assets list — this is the runtime data source for theming, not a
   dev-time-only file.
5. Run `flutter pub get` and `flutter analyze`. Fix only errors caused
   by this stage's changes — do not touch unrelated existing code.

**Do not** build any UI or theming logic yet — that's Prompt 02. This
stage is purely structural so later prompts have somewhere correct to
put their output.

**Verify before ending this stage:** `flutter pub get` succeeds,
`flutter analyze` shows no new errors, and the folder tree matches
`PROJECT_STRUCTURE.md`'s `[NEW]` entries that were listed above.
