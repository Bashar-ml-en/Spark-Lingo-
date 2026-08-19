# Spark Lingo — Target Project Structure

Extends your existing `lib/` layout. New additions marked `[NEW]`.

```
spark_lingo/
├── android/                              # standard Flutter Android project
│   └── app/
│       └── build.gradle                  # targetSdkVersion 36 (Android 16) — see store_submission/google_play_checklist.md
├── ios/
│   └── Runner/
│       └── PrivacyInfo.xcprivacy         # [NEW] required since May 2024, mandatory for submission
├── assets/
│   ├── flags/                            # [NEW] SVG flag icons, one per supported language/locale
│   │   ├── en_gb.svg / en_us.svg
│   │   ├── fr_fr.svg
│   │   ├── de_de.svg
│   │   ├── es_es.svg / es_mx.svg
│   │   ├── zh_cn.svg
│   │   ├── ja_jp.svg
│   │   ├── ko_kr.svg
│   │   └── ... (see design/language_design_tokens.json for full list)
│   ├── symbols/                          # [NEW] per-language motif icon set (see design spec)
│   │   ├── en_symbol.svg
│   │   ├── fr_symbol.svg
│   │   └── ...
│   ├── fonts/                            # [NEW] script-appropriate font families
│   │   ├── NotoSansJP-Regular.ttf        # Japanese
│   │   ├── NotoSansKR-Regular.ttf        # Korean
│   │   ├── NotoSansSC-Regular.ttf        # Simplified Chinese
│   │   ├── NotoSansArabic-Regular.ttf    # Arabic (RTL)
│   │   └── Inter-Variable.ttf            # Latin-script default
│   └── audio/                            # native-speaker clips from Common Voice pipeline
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── router/
│   │   │   └── app_router.dart           # add /onboarding/select-language, /home/:langCode routes
│   │   ├── services/
│   │   │   ├── ai_service.dart
│   │   │   ├── database_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── srs_service.dart
│   │   │   ├── tts_service.dart
│   │   │   ├── monetization_service.dart
│   │   │   └── exam_service.dart         # [NEW] mock exam fetch/scoring calls
│   │   └── theme/
│   │       ├── spark_theme.dart          # base theme (existing)
│   │       └── language_theme_registry.dart  # [NEW] resolves LanguageTheme per language code from design tokens
│   ├── features/
│   │   ├── home/
│   │   ├── monetization/
│   │   ├── onboarding/
│   │   │   ├── welcome_screen.dart
│   │   │   ├── language_selection_screen.dart   # [NEW] flag grid
│   │   │   └── widgets/
│   │   │       └── flag_tile.dart               # [NEW]
│   │   ├── splash/
│   │   └── exam_prep/                    # [NEW] full module
│   │       ├── placement_test_screen.dart
│   │       ├── mock_exam_screen.dart
│   │       ├── exam_readiness_dashboard.dart
│   │       └── widgets/
│   │           ├── score_band_gauge.dart
│   │           └── skill_breakdown_chart.dart
│   └── shared/
│       ├── models/
│       │   ├── user_profile.dart
│       │   ├── unit.dart
│       │   ├── lesson.dart
│       │   ├── flashcard.dart
│       │   ├── language_theme.dart       # [NEW] color/font/motif per language
│       │   └── exam_models.dart          # [NEW] ExamDefinition, MockExam, ExamAttempt
│       └── widgets/
│           ├── flag_grid.dart            # [NEW] reusable flag-selection grid
│           └── language_symbol_badge.dart # [NEW]
├── content_pipeline/                     # from the previous package — data sourcing, run outside the app build
│   ├── fetch_tatoeba.py
│   ├── process_common_voice.py
│   └── output/
├── supabase/
│   └── migrations/
│       └── 002_exam_module.sql           # supabase_schema_additions.sql from the previous package
└── pubspec.yaml                          # register assets/flags, assets/symbols, assets/fonts, new font families
```

## Key structural decision: theming per language

Rather than hardcoding per-language screens, use a **`LanguageTheme` data
class** (color scheme, font family, flag asset, symbol asset, text
direction) resolved at runtime by `language_theme_registry.dart` from
`design/language_design_tokens.json`. This means:

- Adding a new language later is a data change (add a JSON entry + assets), not a new Dart screen.
- The "different design per language" requirement is satisfied by
  `Theme.of(context)` resolving differently per language, not by
  maintaining N parallel copies of every screen — which would be an
  enormous, unmaintainable amount of duplicated UI code and a real risk
  to your launch timeline.
