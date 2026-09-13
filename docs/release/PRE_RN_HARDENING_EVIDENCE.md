# Pre–React Native hardening evidence

**Recorded:** 2026-09-14
**Starting revision:** `6878680d71dc321891a9f63e7334d8a9cdbfc21c` on `main`

This is an honest, local evidence record. It does not claim any hosted
Supabase, RevenueCat, Firebase, store, or GitHub Environment action occurred.

## Initial repository state

- The worktree contained only the two untracked audit/prompt documents created
  in the preceding audit task; no pre-existing source modification was found.
- No `AGENTS.md` file was present in the repository search scope.
- The Flutter SDK is installed at `C:\flutter`; direct Dart reports
  `3.12.2 (stable)`. `flutter`/`dart` were not on PATH.
- Deno and the Supabase CLI were unavailable locally. Node and Git were
  available.

## Commands and results

| Command / check | Result | Notes |
| --- | --- | --- |
| Direct Dart `--version` | PASS | Dart 3.12.2. |
| `flutter pub get` after localization dependency correction | PASS | Added SDK `flutter_localizations`; lockfile now resolves `intl 0.20.2`. Flutter reported 71 newer incompatible packages; no upgrade was performed in this hardening work. |
| Focused Flutter tests: `exam_preview_honesty_test.dart`, `audio_file_cleanup_test.dart` | PASS | Four tests passed using safe development dart-defines. |
| `node scripts/validate_release_android_workflow.js` | PASS | Verifies no production defaults, protected-tag source check, pinned release actions, and AAB output. |
| `node scripts/validate_staging_deploy_workflow.js` | PASS | Existing staging control regression check. |
| `node scripts/validate_ai_quota_boundary.js` | PASS | Existing server-only quota regression check. |
| `node scripts/validate_canonical_learning_flows.js` | PASS | Prevents the retired private speech/flashcard implementations from returning to the home entry points. |
| `node scripts/validate_learning_progress_boundary.js` | PASS | Protects the lesson/XP/daily-goal server-authoritative RPC boundary from direct client-write regressions. |
| `node scripts/validate_correction_report_boundary.js` | PASS | Ensures server-only correction reporting, user-scoped local review cards, truthful report failures, and fail-closed OAuth/test-consent defaults. |
| Full `flutter analyze` | PASS | `No issues found!` after the final source changes. |
| Full Flutter suite | PASS | `flutter test --reporter compact` completed with `111` tests passed after merging the current remote source. Test-host `MissingPluginException` messages from existing SharedPreferences persistence tests were emitted but did not fail the suite. |
| Android debug APK build | INCOMPLETE | Started with non-production development defines, but no APK was produced after several minutes of local Gradle work. The build process was stopped; rerun it in a normal Android-capable developer/CI environment and retain the result. |
| Web release build | INCOMPLETE | Started with non-production development defines, but did not produce a fresh `main.dart.js` before the local compiler stopped making progress. The process was stopped; retain a clean CI/developer build result instead of relying on the pre-existing artifact. |
| Deno Edge Function checks/tests | NOT RUN | Deno is absent locally. CI now invokes the existing Edge Function unit tests. |
| Supabase migration reset/lint/RLS smoke | NOT RUN | Supabase CLI/Docker environment is unavailable locally; use only a disposable local or dedicated staging project. |
| Android/iOS physical-device verification | NOT RUN | Requires device, signing, OAuth, microphone, billing, and protected environment setup. |

## Repository-controlled evidence added in this hardening pass

- The workspace was verified against remote `main` at `017a599`; its three
  newer commits were merged into the review branch. The correction-report
  feature is retained through the canonical chat, while unsafe hard-coded
  production deployment and legacy-session changes are excluded.
- Incomplete exam and mock-exam screens are truthful previews. Regression tests
  ensure a fresh user does not see a fabricated band/CEFR score and cannot
  start/submit a scored mock exam.
- Android production release is a reusable workflow called only by the tagged
  quality workflow after its required jobs. It has no source production URL,
  project-ref, or public-key fallback and produces a signed `.aab` only.
- The static release-workflow guard runs locally and is included in CI.
- Home entry points now use the canonical public chat/study modules. Temporary
  native audio recordings are removed after transcription paths complete, and
  a native cleanup test passes.
- Lesson completion, XP, and daily-goal writes now have an explicit
  authenticated-RPC/read-only-table boundary. The prior direct retention-table
  upsert path was replaced by the bounded `set_daily_goal` server RPC.
- Browser zoom is no longer disabled. A source-generated English localization
  catalog and Flutter localization delegates are in place for new/updated UI.
- Historical release-tracker notes are explicitly non-authoritative for this
  worktree, and the next external owner actions are ordered in
  `PRE_RN_OPERATOR_HANDOFF.md` without disclosing credentials or personal
  contact details.

## Before a merge or release

Run the full quality suite in an environment with Flutter, Deno, Supabase CLI,
and Docker. Then complete every item in
[`PRE_RN_EXTERNAL_BLOCKERS.md`](PRE_RN_EXTERNAL_BLOCKERS.md) with attached
evidence. A green source-only run is not production authorization.
