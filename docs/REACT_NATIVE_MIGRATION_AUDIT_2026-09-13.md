# Spark Lingo: product, engineering, and React Native migration audit

**Audit date:** 2026-09-13
**Scope:** the Flutter client, Android/iOS/web shells, Supabase schema and Edge Functions, release automation, test strategy, content, accessibility, and the migration path to React Native.
**Important boundary:** this is a source-level audit. Production Supabase configuration, deployed Row-Level Security (RLS), hosted Edge Function secrets, store setup, and device behaviour still need environment-specific verification.

## Executive conclusion

Spark Lingo has a strong, security-conscious backend foundation and a visually ambitious multi-language learning client. It is **not ready to be described as a complete exam-prep or production learning service**. The largest risks are product honesty and release discipline, not the choice of Flutter itself:

1. The active mock-exam experience simulates submission, has no audio player or recording implementation, and presents hard-coded/fabricated readiness scores.
2. The Android release workflow falls back to a real production Supabase project reference and public key if release secrets are absent. It may be dispatched from a mutable ref, does not require the quality workflow, and builds an APK while the roadmap calls for an app bundle.
3. The home feature contains two incompatible AI-practice implementations and two flashcard session implementations. The active legacy flow includes a canned-response fallback and misleading local-evaluation success copy.
4. The migration should be a **controlled client rewrite**, keeping Supabase, Edge Functions, migrations, RevenueCat webhook, and curriculum contracts intact. Do not translate Dart widgets line-by-line into JSX.

The recommended target is **TypeScript + React Native using Expo development builds** (not Expo Go-only), with React Navigation/Expo Router, TanStack Query for server state, a small Zustand store for local UI state, and the existing Supabase/RevenueCat backend. This preserves native Android/iOS capabilities while avoiding a second backend rewrite.

## Evidence and current size

| Area | Verified finding | Meaning |
| --- | --- | --- |
| Client | 74 Dart files and 19,964 source lines; `home_screen.dart` alone is 2,977 lines, `settings_screen.dart` 973, and `sparky_chat_session.dart` 878. | The app is substantial, but feature orchestration is too concentrated to port safely as-is. |
| Tests | 17 Flutter test files / 1,505 lines. No `integration_test/` directory. | Good unit/widget foundation; no device-level confidence for auth redirects, microphone, billing, deep links, or migration parity. |
| Backend | 15 ordered SQL migrations plus three Edge Functions. | Preserve the backend and its security controls; a React Native move does not need new schema or AI gateway work. |
| Content | `syllabus_master.json` is 5.5 MB; `assets/audio/` has only `.gitkeep`. | The course is bundled and can fall back locally, but native-speaker/audio content is absent. |
| Tooling run here | Node syntax checks passed and the worktree/diff are clean. Flutter, Dart, and Deno are not installed/on PATH in this workspace, so static analysis, Flutter tests, builds, and Edge Function tests could not be rerun locally. | CI is the current executable source of truth; restore the documented toolchain before accepting any release or migration milestone. |

## What is strong

### Backend and privacy/security design

- **Server authority is correctly favoured.** SQL migrations enable RLS across learner data, restrict direct table access, and use narrowly granted security-definer functions for consent, quotas, completion, XP, and billing.
- **The AI boundary is unusually well designed.** `sparky-ai` verifies the user JWT, rejects anonymous AI unless explicitly enabled, applies consent and runtime kill switches before it reads the body, bounds JSON/audio sizes, validates actions and payloads, tracks quota lifecycle, restricts browser origins, and avoids logging prompts, transcripts, user IDs, or secrets.
- **Billing is fail-closed.** The client waits for a recoverable account, approved legal links, public SDK-key validity, server billing control, and a server-side entitlement check. The RevenueCat webhook validates authorization and a time-bounded HMAC before it can alter entitlements.
- **Sensitive permissions are treated carefully.** Android declares only Internet and microphone access, disables cleartext traffic and backups, and starts Firebase collection disabled. iOS has a concrete microphone-use reason. Consent is server-recorded in the current `SparkyChatSession` path.
- **Account deletion is server-side.** The function derives identity from the verified token and requires the literal deletion confirmation; a client never supplies a user ID.

### Product foundation

- The language catalogue, theme registry, RTL handling, script fonts, language art, SRS engine, curriculum schema, retention ledger, and adaptive goal logic make a credible reusable learning core.
- There are controlled, honest gates around legal links, OAuth, billing, AI enablement, and server environment configuration.
- The shared design tokens/components, dark theme, language branding, loading states, consent dialog, and score disclaimer provide a useful starting design system.
- Quality automation is real: formatting, analysis, Flutter test/build, secret scanning, migration reset/lint, TypeScript/Deno type checks, SBOM/release metadata, and staging guard scripts are represented in CI.

## Material weaknesses, ranked

| Priority | Finding and evidence | Impact | Required disposition |
| --- | --- | --- |
| P0 — do not launch as exam prep | `mock_exam_screen.dart` says it will “simulate submission,” uses a fixed 60-minute limit, shows **Audio Player Placeholder**, and has a no-op microphone control. `exam_readiness_dashboard.dart` defaults to Band 7.5/8.5, `progress: 0.78`, and invented skill scores even with no attempt. | Learners can be misled about an assessment result or product capability. | Hide the exam/readiness entry point behind an explicit beta/coming-soon state, or implement real capture, scoring, persistence, and empty states before release. Never display estimated bands without a real dated attempt. |
| P0 — release boundary | `release-android.yml` passes a production project ref and uses production URL/public-key fallbacks if secrets are absent. It can run manually without a protected-tag condition or dependency on the quality workflow. | A mutable or misconfigured build can target production; source/documentation promises fail-closed deployment but the workflow violates that promise. | Remove both fallbacks, require protected signed tags and a passed quality run, isolate staging and production projects, use an environment with reviewers, and emit a signed AAB plus provenance/manifest. Rotate/check the historically exposed credentials noted in `PRODUCTION_GATE.md`. |
| P1 — divergent core behaviour | `home_screen.dart` privately implements `_AISpeechPracticeSession` and `_FlashcardStudySession`, while standalone `sparky_chat_session.dart` and `flashcard_study_session.dart` also exist. Different entry points use different versions. The legacy AI path can substitute canned “intelligent” replies; its evaluation-error copy says “Evaluation completed locally” despite no local evaluator. | Bug fixes, consent handling, audio behaviour, analytics, and scoring can diverge by navigation path. The fallback can misrepresent a server failure as an AI tutor response. | Select the standalone chat and flashcard modules as the canonical behaviour, migrate callers to them, delete legacy code, and do this before porting. In the new app, show a truthful unavailable state—never an undisclosed generated fallback or a fake completed evaluation. |
| P1 — environment/operational isolation | The roadmap documents one shared Supabase project for development, staging, and production until ENV-001; the audit cannot verify current hosted state. | A staging test can mutate/observe production-adjacent data and secrets; a migration mistake has too large a blast radius. | Create separate staging and production projects, distinct Auth redirects/secrets/RevenueCat projects, protected CI environments, backup-and-restore proof, and a staging security smoke record. |
| P1 — accessibility | There is no l10n/ARB system or `flutter_localizations`; chrome is broadly hard-coded in English. Semantics appear in only three source files. `web/index.html` duplicates the viewport declaration and the last one sets `maximum-scale=1.0, user-scalable=no`. | Screen-reader coverage is incomplete and web users cannot zoom. A language-learning app especially needs accessible text and RTL verification. | Remove the zoom restriction now. Define translation keys and locale metadata during the React Native rewrite; require TalkBack/VoiceOver labels, dynamic text tests, contrast checks, RTL screenshots, and no clipped 200% text. |
| P1 — delivery confidence | CI type-checks each Edge Function but does not run the existing `providers_test.ts` and `error_patterns_test.ts`; it only runs a Deno test for a staging script. There are no integration/device tests. The release workflow does not run test gates itself. | High-risk paths can regress while CI stays green. | Run all Edge Function tests with the minimum scoped permissions; add backend contract/RLS tests, React Native component tests, Maestro/Detox device journeys, and release-gate dependencies. |
| P2 — data and performance evolution | Client services access Supabase directly and return `[]`, `{}`, or `null` for several network failures. Card reviews, lesson progress, and exam attempts have no cursor pagination; a 5.5 MB curriculum is parsed into a single in-memory map on fallback. | Empty/error states can be indistinguishable; the pattern will not scale cleanly as content and learner histories grow. | Introduce typed repositories and explicit `Result`/error states. Version content, load one language/unit at a time, cache deliberately, paginate learner histories, and add indexes/query budgets verified with `EXPLAIN`. |
| P2 — navigation and architecture | The root router has seven declarative routes while the code has at least 46 router/raw `Navigator`/`MaterialPageRoute` occurrences. | Deep links, back stacks, analytics, testing, and state restoration are inconsistent. | Create one typed route map (including modal/presentation rules) in the new client. Keep all user-facing flows reachable from it. |
| P2 — documentation drift | `ROADMAP.md` says “42 Dart files,” migrations “001–012,” and 44 tests as of an older commit; the current tree has 74 Dart files, migrations through 015, and 17 test files. The UX audit says no help center while one exists. | Operators can make release decisions from stale statements. | Turn release evidence into generated facts where possible; date/owner each manual claim and fail CI when inventory assertions drift. |
| P2 — legacy overlap | `firestore.rules` remains although the client uses Supabase for its data model; Firebase is only Analytics/Crashlytics. | Two data-security stories invite operational confusion. | Delete it if Firestore is retired, or document the exact deployed Firebase project and feature that still needs it. |
| P3 — action supply chain | Workflows mix tag references such as `actions/checkout@v4` with some SHA-pinned actions. | Lower but avoidable CI supply-chain exposure. | Pin third-party Actions to reviewed commit SHAs and use Dependabot/Renovate to update them. |

## Findings that are strengths only if deployment matches source

The RLS policies, consent ledger, HMAC webhook, AI controls, Firebase opt-in, and protected release scripts are strong **in source**. They cannot prove that the deployed database has every migration, that `TEST_CONSENT_MODE` is off, that AI/billing are disabled until approved, that production CORS only permits intended origins, or that a public URL is legally approved. Those must be asserted in staging and production smoke tests, not inferred from this repository.

## Recommended React Native architecture

Use a new TypeScript app in `apps/mobile/` during transition. Keep Flutter intact until native parity is accepted.

```text
React Native screens (typed routes, a11y primitives)
        |
        +-- feature hooks: auth, curriculum, review, chat, consent, billing
        |       |
        |       +-- TanStack Query: Supabase server state and cache/invalidation
        |       +-- Zustand: ephemeral UI state only (theme, selected language, drafts)
        |
        +-- typed repositories / API contracts
                |
                +-- Supabase Auth, PostgREST/RPC, Realtime, Edge Functions
                +-- RevenueCat SDK (client UI only)
                +-- Firebase Analytics/Crashlytics only after consent

Existing Supabase migrations + Edge Functions + RevenueCat webhook
```

### Stack decisions

- **React Native + TypeScript strict mode.** New React Native projects support TypeScript by default. Use runtime validation at the Supabase/Edge Function boundary rather than trusting casts.
- **Expo development build, not Expo Go-only.** It keeps a managed developer experience while allowing the native modules this app needs (RevenueCat, Firebase, microphone/audio, deep links). Rebuild the development client whenever native dependencies change.
- **Typed navigation.** Expo Router or React Navigation is acceptable; select one. Model authenticated, onboarding, language, study, chat, paywall, and settings routes in one typed map. Use native-stack presentations for expected Android/iOS back behaviour.
- **Supabase stays.** Use `@supabase/supabase-js` with a secure session-storage adapter. Reuse the schema, RPC names, Edge Function contracts, policies, and user IDs; generate TypeScript database types from the target schema and validate Edge Function responses.
- **RevenueCat stays server-authoritative.** Use the React Native RevenueCat SDK, but preserve the current server runtime switch and entitlement RPC. Client purchase completion never grants premium access by itself.
- **Audio is a privacy feature, not just a package choice.** Request permission only after an affirmative voice-consent record; delete local recording files after upload/failure; enforce maximum duration/size before upload; keep the server as transcription authority; test denied/revoked permission.
- **Do not carry Flutter UI mechanics forward.** Rebuild tokens as a semantic React Native design system (colour, typography, spacing, radius, elevation, motion). Use native controls where appropriate, including accessibility roles and dynamic type.

## Migration sequence

### Phase 0 — stop the unsafe drift (1–2 weeks)

1. Disable or label the incomplete exam routes and remove invented readiness values.
2. Repair the Android release workflow: no production defaults, protected-tag-only, quality-gated, separate environment credentials, signed AAB.
3. Make `SparkyChatSession` and `FlashcardStudySession` canonical; remove the legacy private copies and misleading fallbacks.
4. Restore Flutter/Dart/Deno locally or make CI results visible as a required check.
5. Establish staging as a separate Supabase project and run the documented cross-user/RLS, consent, quota, and webhook smoke tests.

### Phase 1 — build the React Native foundation (1–2 weeks)

1. Create `apps/mobile` as a TypeScript, strict-lint project with an Expo development build.
2. Add environment schema validation with no production fallback values. Secrets stay in CI/hosted secrets; public Supabase keys are build configuration only.
3. Implement deep-link auth, secure session persistence, the single route map, theme/dark mode, RTL, translation-key plumbing, error boundary, consent state, and telemetry-off-by-default.
4. Add CI: format, ESLint, `tsc --noEmit`, unit tests, dependency audit, Android/iOS build checks, and a signed release workflow that shares the repaired gate logic.

### Phase 2 — free-learning parity (2–3 weeks)

1. Port onboarding, profile/language selection, curriculum, card review, lesson completion, SRS, XP/streaks, settings/legal/data-rights links, and account deletion.
2. Use a repository per feature and TanStack Query invalidation after each mutation; preserve server-authoritative RPCs.
3. Split/course-version the bundled content and validate the JSON schema in CI. Do not claim offline-first unless login, cached content, and writes have an explicit offline contract.

### Phase 3 — AI, speech, and billing parity (2–3 weeks)

1. Port only the canonical AI chat flow. Preserve server consent, roleplay mode tokens, limits, cancellation/error states, message persistence, and score disclaimer.
2. Port microphone recording/transcription with local-file cleanup and physical-device tests for accepted, denied, revoked, oversized, offline, quota, and timeout cases.
3. Port RevenueCat purchase/restore UI but retain the server entitlement check. Complete sandbox webhook proof before enabling it.

### Phase 4 — exam product decision (separate scope)

Either implement a real exam system (content, audio licensing, timer state recovery, answer persistence, validated scoring, results provenance, and appeal/feedback policy) or explicitly ship it as a non-scored preview. This must not be bundled into the client migration as an unbounded feature.

### Phase 5 — parallel beta and cutover (2–4 weeks)

1. Run Flutter and React Native against staging with the same test accounts and scripted parity matrix.
2. Test Android and iOS physical devices: new/returning/anonymous/recoverable accounts, OAuth return, RTL, large text, VoiceOver/TalkBack, voice consent, microphone, network loss, SRS, deletion, paywall, restore, and AI quota.
3. Release an internal React Native cohort. Compare errors, retention, payments, and support tickets without sending PII to telemetry.
4. Cut over only when parity, privacy, store review, rollback, and production evidence are signed off. Archive Flutter after the RN release is stable; do not delete the existing client earlier.

## Acceptance gates for the migration

- No environment, URL, key, entitlement, score, progress, or AI response can silently fall back to a production/fabricated/default value.
- Every backend response is typed/validated and every mutation invalidates exactly the affected cache keys.
- No user audio remains on-device after the workflow completes or fails, except when the user explicitly saves it.
- All AI/voice traffic is impossible before valid consent on both client and server.
- No incomplete exam function is reachable as scored/official.
- 100% of named user flows have device-level happy-path and failure-path tests; the release pipeline blocks on them.
- Staging RLS proves anonymous denial, cross-user denial, authenticated allowed actions, consent withdrawal, quota exhaustion, kill switch, billing webhook signature rejection, and deletion.
- Accessibility review passes keyboard/screen-reader roles, Android font scale, iOS Dynamic Type, contrast, RTL, and web zoom if web remains in scope.

## Bottom line

React Native is a reasonable move here, especially if the team is stronger in TypeScript/React. It will not repair the high-risk product and release gaps on its own. Fix the P0/P1 issues first, then port feature-by-feature against the already strong Supabase security boundary. That gives Spark Lingo a safer native client rather than two versions of the same unresolved problems.
