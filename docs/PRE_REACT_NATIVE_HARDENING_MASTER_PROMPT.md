# Pre–React Native hardening master prompt

Copy AI Events in Kuala Lumpur | AI Tinkerers Meetups 2026the prompt below into a new implementation task. It is deliberately written to require code, test, CI, and release-control changes—not a planning-only response.

---

You are the lead engineer responsible for making the Spark Lingo repository safe, honest, testable, and migration-ready **before any React Native client is built**.

## Mission

Perform the following work in the exact dependency order below. Make real, minimal, production-quality changes in the repository; do not merely write recommendations, create mock “done” records, or claim a hosted configuration was changed when you cannot verify it. Preserve the existing Supabase schema, RLS model, Edge Functions, and RevenueCat server-authoritative entitlement boundary unless a change is necessary to fix a verified defect.

The final result must leave the Flutter client in a safer state and produce precise React Native transition artifacts. **Do not create the React Native app yet.** The transition begins only after the gates in this prompt pass or an external/human blocker is recorded accurately.

## Repository context

- Workspace: `C:\Spark_Lingo`
- Current client: Flutter/Dart with Riverpod and GoRouter; Android, iOS, and Flutter web are in scope.
- Backend: Supabase Auth/Postgres/RLS, migrations `001` through `015`, and Edge Functions (`sparky-ai`, `delete-account`, `revenuecat-webhook`).
- Operations: Firebase Analytics/Crashlytics only after consent, RevenueCat purchases with a server-side entitlement check, GitHub Actions release workflows.
- Existing assessment: `docs/REACT_NATIVE_MIGRATION_AUDIT_2026-09-13.md`. Treat it as the starting evidence, but re-check every conclusion against the current code before changing it.
- Existing stated production gates: `docs/PRODUCTION_GATE.md`.

## Non-negotiable safety and honesty rules

1. Never add, print, commit, or use fallback values for production secrets, service-role keys, OpenAI keys, signing keys, RevenueCat webhook secrets, Supabase Management tokens, or real customer data.
2. Do not make external deployments, alter hosted Supabase data, rotate secrets, create store products, or modify a cloud environment unless the task has explicit authority and the exact target is verified. Put externally required steps in a clearly labelled blocker/evidence file instead.
3. Do not use destructive Git commands, reset another author’s work, delete unrelated files, or overwrite existing user changes. Check the worktree first and preserve unrelated changes.
4. Do not conceal an unavailable feature with a fabricated score, canned answer presented as live AI, placeholder that looks functional, local “success” message when no work occurred, or an empty result that is indistinguishable from a transport failure.
5. Every new privacy-sensitive client control must fail closed. Client checks improve UX; the server remains the authority for identity, consent, quotas, billing, and entitlements.
6. Do not claim tests pass unless you ran them in this task and report their exact commands/results. If Flutter/Dart/Deno/device tooling is missing, install or restore it only when authorized; otherwise report that limitation and keep CI configuration executable.
7. Keep commits focused if commits are requested. Do not start a React Native rewrite, copy Flutter widgets into JSX, or replace the backend in this task.

## Required implementation sequence

### Stage 0 — establish a trustworthy baseline

1. Inspect `git status`, the current branch, relevant `AGENTS.md` instructions, tool availability, and all files that will be changed.
2. Run the existing local quality checks that are actually available: formatting, analysis, unit/widget tests, Edge Function type checks/tests, migration reset/lint, and static workflow checks. Use the repository’s safe development configuration only.
3. Record a concise baseline in `docs/release/PRE_RN_HARDENING_EVIDENCE.md` with date, commit SHA, commands, results, and environment limits. Do not manufacture test results.
4. If tests reveal unrelated pre-existing failures, isolate them clearly before changing code. Fix them only when they block this mission or directly overlap its scope.

### Stage 1 — remove product-deception paths before changing architecture

Fix the currently reachable exam/readiness experience. Verified source evidence includes `lib/features/exam_prep/mock_exam_screen.dart` and `lib/features/exam_prep/exam_readiness_dashboard.dart`.

1. Do **not** build an unfinished scoring engine as a token gesture. Until a genuine exam system exists, make the entry point explicitly a non-scored preview/coming-soon flow or remove it from normal navigation.
2. Ensure no reachable UI presents an estimated IELTS/CEFR level, progress fraction, band title, skill breakdown, “submitted for scoring,” or examiner result unless it is derived from an actual persisted and validated attempt.
3. Remove or disable all fake assessment interactions, including the simulated submission, fixed default duration if it is represented as a real exam limit, audio-player placeholder, and no-op record action. Replace them with truthful, accessible explanatory UI.
4. Retain genuinely persisted assessment data only if the screen can show its provenance/date and clearly distinguish unavailable, empty, loading, and error states.
5. Add regression tests proving that a new user sees no invented score and that an incomplete exam cannot be started/submitted as a scored assessment.

**Stage 1 exit condition:** a learner cannot mistake any incomplete exam feature for a real scored exam, and automated tests prove the default/empty state is honest.

### Stage 2 — harden the Android release boundary

Fix `.github/workflows/release-android.yml` and any supporting scripts/configuration. The current workflow must not remain capable of silently compiling with a production Supabase fallback.

1. Remove all source-embedded production URL, project-reference, and public-key fallback expressions from release commands. A missing required value must stop the build before producing an artifact.
2. Require a protected immutable version tag as the release source. Validate that `HEAD` is exactly that tag. A manually dispatched workflow from a branch or arbitrary commit must fail before credentials/build work starts.
3. Put the release job behind a protected `production` GitHub Environment with required reviewers and least-privilege permissions. Add explicit `permissions: contents: read` unless another permission is demonstrably required.
4. Make release depend on the same commit having passed mandatory quality checks. Do this with a real enforceable workflow design—not a comment, convention, or a cross-workflow `needs` reference that GitHub cannot enforce.
5. Build a signed Android App Bundle (`.aab`) for store delivery, not only an APK. Retain a debug/internal APK only if it is explicitly named and segregated from the store artifact.
6. Require every runtime configuration used by production: environment, hosted deployment, Supabase URL/key/project refs, OAuth enablement, legal URLs, and any public RevenueCat SDK key needed by the selected platform. Validate inputs without echoing sensitive values.
7. Pin third-party GitHub Actions to reviewed commit SHAs, including this release workflow. Keep the pinned version as a comment when useful.
8. Add a safe static test/script that fails CI if the release workflow regains a production fallback, lacks tag validation, builds an APK-only store artifact, or omits required protected configuration. Extend the existing workflow-validation pattern where practical.
9. Update the release documentation and manifest expectations so they match the actual workflow. Do not state that a production release has occurred.

**Stage 2 exit condition:** an unprotected/misconfigured release cannot build, and CI has a machine-checkable regression test for the invariant.

### Stage 3 — establish real environment and external-operation gates

1. Review every source/build configuration path for development, staging, and production. Remove ambiguous defaults and preserve existing fail-closed validation in `lib/core/constants/supabase_config.dart`.
2. Add a precise, short evidence checklist for the external work that code alone cannot perform: separate staging project, production secret rotation/audit, live legal URLs, OAuth callback verification, provider budget/CAPTCHA/WAF controls, RevenueCat sandbox/webhook proof, backups/restore, and mobile-device validation.
3. Enforce whatever can be enforced locally/CI (for example, no staging target may equal production target). For anything requiring credentials or dashboards, mark it **BLOCKED — HUMAN/ENVIRONMENT ACTION REQUIRED** with exact owner input/evidence required. Never invent project references or availability.
4. If `firestore.rules` has no current product/deployment owner, either remove it only after proving it is unused or document its exact deployed purpose and owner. Do not leave an ambiguous second data-security model.

**Stage 3 exit condition:** every environment boundary is code-validated where possible and external prerequisites are explicit, factual, and non-bypassable by a release build.

### Stage 4 — choose one canonical learning and AI implementation

The app currently has duplicated flows: private `_AISpeechPracticeSession` and `_FlashcardStudySession` in `lib/features/home/home_screen.dart`, plus public `SparkyChatSession` and `FlashcardStudySession` modules.

1. Use the standalone public `SparkyChatSession` and `FlashcardStudySession` as the default canonical candidates, but verify current behaviour and tests before deciding. Document the decision in code/architecture notes.
2. Route all reachable entry points through one chat implementation and one flashcard implementation. Remove the duplicate code only after all callers are migrated and tests cover the shared behaviour.
3. Delete the legacy canned-response fallback that can look like a live AI answer. When AI is unavailable, unavailable is the honest state: preserve the learner’s message/draft and offer a retry without presenting fabricated tutoring output.
4. Delete the legacy “evaluation completed locally” success message unless a real local, validated evaluator and clearly labelled local-result model is implemented. A failed evaluation must say that it failed and preserve retryable input.
5. In every AI/voice entry point, require successful current consent before sending user content; a consent-ledger transport failure must fail closed in the client. Preserve server-side consent enforcement as the ultimate boundary.
6. Ensure audio files are deleted after successful upload, upload failure, cancellation, and screen disposal when platform APIs permit. Do not log local audio paths in release mode. Respect web/native platform differences without breaking compilation.
7. Add tests for denied/missing consent, failed consent recording, unauthenticated/anonymous paths, AI failure, retry, score failure, and audio cleanup abstraction. Device-level voice checks may be recorded as an external test requirement, not fabricated as unit tests.

**Stage 4 exit condition:** exactly one implementation powers each learning flow, failures are truthful and recoverable, consent is fail-closed at both layers, and the client does not retain unnecessary audio.

### Stage 5 — accessibility, internationalization, and navigation integrity

1. Immediately remove `maximum-scale=1.0` / `user-scalable=no` and duplicate conflicting viewport declarations from `web/index.html`.
2. Introduce a maintainable localization architecture for Flutter UI chrome (ARB/generated localizations or an equivalent strongly typed system). Do not fabricate translations. Start with a complete English key set and retain the target-language curriculum as content; add reviewed translations only when supplied. No new user-visible feature text may be hard-coded outside the localization layer except appropriately documented developer-only diagnostics.
3. Add semantic labels/roles/hints to every icon-only actionable control and meaningful visual progress/status component. Preserve RTL with directional layout APIs; never mirror content incorrectly.
4. Test Android font scale / iOS Dynamic Type equivalents, 200% web text scaling, keyboard navigation where web is retained, TalkBack/VoiceOver labelling, light/dark contrast, and Arabic RTL. Add automated widget tests wherever they can provide a durable assertion; list required physical-device checks separately.
5. Replace mixed GoRouter/raw `Navigator` navigation with a documented route inventory and reduce new raw navigation. Do not conduct a risky complete router rewrite unless required to remove a broken/deceptive flow. Every reachable screen must have predictable back behaviour and a testable deep-link/presentation contract.

**Stage 5 exit condition:** zoom is allowed, UI strings are localizable, actionable controls are labelled, and the most important RTL/text-scale/navigation paths are regression-tested.

### Stage 6 — data, error, and scale readiness

1. For every Supabase operation in `DatabaseService` and related services, distinguish an empty valid result from a fetch/mutation error. Do not silently convert an error to `[]`, `{}`, or `null` where the UI will claim there is no learner data.
2. Introduce feature-scoped repository interfaces and typed result/error models at the boundary. Avoid a large speculative rewrite; migrate the high-risk user profile, progress, SRS, exam, consent, AI, and billing call sites first.
3. Add deterministic cache invalidation/refresh after profile, language, lesson, review, XP, consent, billing, and deletion mutations. Ensure an auth change cannot show the prior user’s data.
4. Define and enforce pagination/query limits for unbounded learner histories. Keep the current curriculum fallback cache only if it remains versioned, schema-validated, and loaded by the smallest useful content scope. Do not invent performance numbers.
5. Add contract tests for critical RPC/Edge Function response shapes and database/RLS tests for anonymous denial, cross-user denial, own-user allowed actions, consent withdrawal, quota limits, kill switch, and billing webhook rejection. Use only disposable local/staging data.

**Stage 6 exit condition:** error states are unambiguous, server data boundaries are typed/tested, user/session invalidation is safe, and scale-related queries have explicit limits.

### Stage 7 — make the quality gate executable and accurate

1. Ensure CI actually runs all existing Edge Function tests, including `supabase/functions/sparky-ai/providers_test.ts` and `error_patterns_test.ts`, with the narrow permissions they require. Keep `deno check` as a separate type check.
2. Keep Flutter format/analyze/test/build gates. Add or improve integration tests for the highest-risk routes: sign in/out/onboarding, consent, chat failure/retry, microphone permission, course/SRS persistence, account deletion, paywall/restore gate, and incomplete-exam denial.
3. Use a suitable device test layer (for example, Maestro or Detox) only after choosing a tool and creating an executable Android/iOS target. At minimum, create a real test plan and CI hook; do not claim simulator/device coverage that does not run.
4. Include workflow/config validation, secret scan, dependency/SBOM checks, database migration reset/lint, RLS smoke coverage, and release-metadata generation in the final quality design.
5. Correct stale counts, claims, and dates in `README.md`, `ROADMAP.md`, UX audit, and release documentation. Prefer generated inventories or scripts for facts that drift. Preserve historical documents only when explicitly labelled as historical.

**Stage 7 exit condition:** CI executes—not merely type-checks—the important tests, and its documentation reflects today’s real repository and verified limitations.

### Stage 8 — produce React Native transition-ready artifacts, but no RN app yet

Create the following concrete artifacts from the now-hardened implementation:

1. `docs/react-native/FEATURE_PARITY_MATRIX.md`: every Flutter user flow, current owner/file, canonical behaviour, backend calls/RPCs, analytics events, consent/billing needs, migration priority, test coverage, and acceptance criteria.
2. `docs/react-native/ROUTE_AND_STATE_CONTRACT.md`: typed route inventory; auth/onboarding gates; modal/back semantics; server state versus ephemeral UI state; cache keys and invalidation rules.
3. `docs/react-native/BACKEND_CONTRACT.md`: Supabase tables/RPCs/Edge Functions the mobile client may use, input/output/error shapes, RLS expectations, rate/size limits, and server-authoritative decisions. Generate TypeScript DB types only from a verified non-production schema; otherwise provide the safe generation command and leave generation blocked.
4. `docs/react-native/NATIVE_CAPABILITY_PARITY.md`: Android/iOS requirements for deep links, secure auth storage, microphone/audio, TTS, purchases, consent, Firebase, notifications if any, app links, assets, and accessibility. Identify each Flutter package’s migration destination by capability, not by blindly matching package names.
5. `docs/react-native/CUTOVER_AND_ROLLBACK.md`: staging parity runbook, dual-client release cohort, metrics with no PII, feature flags/kill switches, rollback criteria, store rollout, data compatibility, and the exact conditions for retiring Flutter.
6. A `docs/react-native/README.md` with the proposed target architecture: TypeScript strict mode, Expo development build or a justified bare React Native choice, one typed navigation solution, TanStack Query for server state, a small local store only for ephemeral UI state, runtime validation at APIs, secure session storage, and retained Supabase/RevenueCat server controls. Cite official vendor documentation only for implementation-sensitive claims.

**Stage 8 exit condition:** another engineer can begin the React Native client without rediscovering requirements, weakening backend security, or porting obsolete Flutter flows.

## Definition of done

Do not mark this task complete until all possible stages have working changes and evidence. The final response must contain:

1. A concise outcome summary, followed by a table of every changed file and why it changed.
2. The exact commands run and their results. Separate passed, failed, and not-run checks.
3. A finding-to-fix matrix showing every P0/P1 issue from the audit, the specific code/CI/test that resolves it, and any remaining limitation.
4. A list of external blockers that could not be completed in the repository, the required owner/action, and the precise evidence needed to close each blocker.
5. Links to each React Native transition artifact.
6. A direct statement: **“React Native implementation may begin”** only if all repository-controlled exit conditions are met. Otherwise state exactly which gate blocks it.

Work method: inspect first, implement one stage at a time, run the smallest relevant tests after each stage, keep changes reviewable, and stop rather than guessing when real-world authority/configuration is required.

---
