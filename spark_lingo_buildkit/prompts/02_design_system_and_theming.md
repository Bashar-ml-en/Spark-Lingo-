# Prompt 02 — Design System & Per-Language Theming

Run this after Prompt 01 is verified complete.

---

You are implementing a **per-language theming system** for Spark Lingo,
driven entirely by data in `assets/language_design_tokens.json` (already
added to the project in Prompt 01) — not by hardcoded per-language Dart
files. Read that JSON file's structure fully before writing code.

**Build:**

1. `lib/shared/models/language_theme.dart` — a `LanguageTheme` class
   with fields matching the JSON schema: `displayName`, `flags` (list of
   locale/flagAsset/countryName), `primaryColor`, `accentColor`,
   `fontFamily`, `textDirection` (enum `ltr`/`rtl`), `motif`,
   `motifAsset`. Include a `fromJson` factory.

2. `lib/core/theme/language_theme_registry.dart` — loads and parses
   `assets/language_design_tokens.json` once at app start (cache in
   memory), exposes:
   - `LanguageTheme themeFor(String langCode)` — returns the matching
     entry or the `fallback_theme` if the code isn't found. Never throw
     on an unknown code; always fall back gracefully.
   - A method to build a Flutter `ThemeData` from a `LanguageTheme`,
     extending the existing `SparkTheme` base (don't replace it —
     override `colorScheme.primary`/`secondary` and `textTheme`'s font
     family, keep everything else from the base theme so spacing,
     component shapes, and elevation stay consistent app-wide).

3. Wrap the app (or at minimum every screen from Home onward) so that
   once a language is selected, `Directionality` is set from
   `LanguageTheme.textDirection` — this must actually flip layout for
   RTL languages (test with Arabic: nav icons, back chevrons, and
   progress indicators should mirror). Do not hand-flip individual
   widgets; rely on Flutter's built-in RTL-aware widgets
   (`EdgeInsetsDirectional`, `AlignmentDirectional`) wherever you touch
   existing layout code for this.

4. Do NOT redesign the Home screen's structure/layout in this stage —
   only make it theme-aware (colors, font, motif asset slot in the
   header). Structural changes to Home come in Prompt 04.

**Verify:** write a small widget test that loads two `LanguageTheme`s
(e.g. `en` and `ar`) and asserts the resulting `ThemeData.primaryColor`
and `Directionality` differ correctly. Run `flutter test` and confirm it
passes before ending this stage.
