# Prompt 04 — Per-Language Localized Home Experience

Run after Prompt 03 is verified.

---

Make the Home screen show **only the selected language's content**, and
make its content query filtered rather than showing a mixed feed.

**Build:**

1. Update `DatabaseService`'s curriculum queries (units/lessons/
   flashcards) to accept and always filter by `langCode`, sourced from
   the route param set in Prompt 03 (`/home/:langCode`). Audit every
   existing query in this service — none should return unfiltered
   cross-language content once a language is active.

2. Home screen header: render the active language's `motifAsset` (from
   `LanguageTheme`) as a subtle background/header illustration element,
   plus a small flag badge (tap to open the language switcher — see
   below) next to the app title.

3. `lib/shared/widgets/language_symbol_badge.dart` — small reusable
   widget combining flag + motif accent, used in: Home header, Settings
   "current language" row, and the exam-readiness dashboard header
   (Prompt 07). Build it once, reuse in all three rather than
   duplicating.

4. Settings → "Add a language" / "Switch language" re-opens `FlagGrid`
   (built in Prompt 03) rather than a new screen. Switching languages
   re-resolves `LanguageTheme` and re-filters all Home queries
   immediately — no app restart required.

5. Empty states (zero flashcards due, no units yet for a newly-added
   under-resourced language like Thai or Tagalog) must use the
   language's own motif asset and a message in the UI language, not a
   generic empty-state graphic — this is a real difference users will
   notice on day one for languages with less content built out yet.

**Verify:** switch between at least three languages (one CJK, one RTL,
one Latin-script) in the same session and confirm Home content, theme,
and empty states all update correctly with no stale data from the
previous language.
