# Onboarding & Language Selection — Flow Spec

## Flow

```
Splash
  → Welcome (value prop, "Get exam-ready in the language you choose")
    → Sign up / Continue as guest  (auth_service.dart, existing)
      → Language Selection Screen  [NEW]
        → (per-language) Localized Home  [NEW theming, existing home screen]
```

## Screen 3: Language Selection (flag grid)

- Grid of flag tiles (`FlagTile` widget), 2 columns on mobile / 3 on
  tablet / 4 on desktop, matching your existing 390/810/1200px
  breakpoints.
- Each tile: flag SVG (from `assets/flags/`), language display name in
  its **own script** (e.g. "日本語" not "Japanese"), and a subtitle in
  the user's UI language ("Japanese").
- Languages with multiple flags (English → US/UK, Spanish → Spain/Mexico,
  Portuguese → Portugal/Brazil) show a small secondary picker (bottom
  sheet with both flags) after the language is tapped, rather than
  doubling the grid with near-duplicate tiles.
- Tapping a tile: brief flag animation (scale + subtle flag-wave via
  `AnimatedScale`/Lottie — keep it under 400ms, this is a funnel step,
  not a moment to linger), then navigate to `/home/:langCode`.
- Search/filter field at top for the 12+ language list; type-ahead
  matches both English name and native-script name.
- Include the "not offered by Duolingo" languages (Thai, Tagalog, etc.
  per `language_design_tokens.json`) in the same grid, not a hidden
  "more languages" overflow — that's where your real differentiation
  shows up first, in the very first screen.

## Screen 4: Localized Home (per-language design)

Once a language is selected, `language_theme_registry.dart` resolves
the `LanguageTheme` for that code and the **same underlying Home widget
tree** renders with:

- Primary/accent color from the token file (not a full redesign per
  language — see PROJECT_STRUCTURE.md's theming rationale).
- Script-correct font family (`NotoSansJP`, `NotoSansArabic`, etc.).
- The language's motif asset used in the header illustration and empty
  states (streak-zero state, no-cards-due state).
- `Directionality.rtl` applied automatically for Arabic (and any future
  RTL language) — this flips nav icons, progress bars, and swipe
  gesture direction on flashcards without any per-screen RTL code.
- Content itself (units/lessons/flashcards) is fetched filtered to that
  `langCode` — the user only ever sees that language's curriculum
  from this point until they explicitly add another language from
  settings.

## Adding a second language later

Settings → "Add a language" reopens the same flag grid component
(`FlagGrid` shared widget) rather than a separate screen — this is the
payoff of building it as a reusable component instead of a one-off
onboarding screen. Multi-language users get a language switcher (flag
icon, top-left of Home) that re-resolves the theme instantly.
