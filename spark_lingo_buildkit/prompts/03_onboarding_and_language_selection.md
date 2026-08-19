# Prompt 03 — Onboarding & Language Selection (Flag Grid)

Run after Prompt 02 is verified. Read `design/onboarding_flow_spec.md`
in full before starting — it is the authoritative spec for this stage,
this prompt is just the instruction to execute it.

---

Implement the flow described in `design/onboarding_flow_spec.md`:
Splash → Welcome → Auth → **Language Selection (flag grid)** →
Localized Home.

**Build:**

1. `lib/shared/widgets/flag_grid.dart` — a reusable `FlagGrid` widget
   taking the list of languages from `language_design_tokens.json`
   (via `language_theme_registry.dart`), rendering a responsive grid
   (2/3/4 columns at your existing 390/810/1200px breakpoints) of
   `FlagTile` widgets. Include a search field that filters by both
   English name and native-script `displayName`.

2. `lib/features/onboarding/widgets/flag_tile.dart` — flag SVG (via
   `flutter_svg`), native-script name as the primary label, English
   name as a smaller subtitle, tap target at least 48x48dp for
   accessibility. On tap, run a short (<400ms) scale/fade transition —
   do not block navigation waiting for the animation to finish.

3. `lib/features/onboarding/language_selection_screen.dart` — hosts
   `FlagGrid`. For languages with multiple flags (English, Spanish,
   Portuguese — check the JSON's `flags` array length), show a bottom
   sheet with the sub-options after the initial tap, per the spec.
   On final selection, persist the chosen `langCode` to the user's
   profile (extend `UserProfile` model + `DatabaseService` with an
   `activeLanguage` field) and navigate to `/home/:langCode`.

4. Update `app_router.dart`: add the `/onboarding/select-language` route
   in the GoRouter redirect chain — authenticated users with no
   `activeLanguage` set get redirected here before reaching `/home`,
   same pattern as your existing auth guard redirect to `/welcome`.

5. Wire `LanguageSelectionScreen` to actually apply the resolved
   `LanguageTheme` (from Prompt 02) to the navigator context before
   pushing to Home, so the transition into Home is already themed —
   no flash of default-theme content.

**Verify:** manually walk through the flow for at least one LTR
language (e.g. French) and the RTL language (Arabic) and confirm: flag
grid renders, search filters correctly, selection persists, and Home
renders in the correct theme/direction immediately on arrival.
