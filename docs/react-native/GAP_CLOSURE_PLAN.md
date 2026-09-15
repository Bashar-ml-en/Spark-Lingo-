# Spark Lingo gap-closure plan

**Decision:** Build a narrow, evidence-backed React Native learner experience
before expanding language count, AI, billing, or release scope. Flutter remains
the rollback client until React Native passes the same staged acceptance gates.

**Current safe scope:** internal development only. The product must not be
described as a full course, CEFR course, exam-prep service, pronunciation
assessment, native-audio product, or public-scale platform.

This plan is grounded in:

- `READINESS_AND_CONTENT_BENCHMARK_2026-09-16.md`;
- `PRE_RN_EXTERNAL_BLOCKERS.md`;
- `CONTENT_AND_CLAIMS_REGISTER.md`; and
- the backend contract in `BACKEND_CONTRACT.md`.

## Non-negotiable operating rules

1. **One launch course first.** Select one learner-interface locale and one
   target language. Do not expand to 15 learner-facing courses before the
   first one proves its content quality and technical flow.
2. **Server authority stays intact.** The React Native client may not recreate
   consent, progress, XP, entitlement, quota, or scoring rules locally.
3. **No fabricated learning signal.** Empty states, failed requests, or
   flashcard completion must never become a CEFR level, exam score,
   pronunciation score, or readiness claim.
4. **Evidence beats status labels.** A gate is complete only when its named
   output exists: reviewed content record, test result, signed device result,
   dashboard record, or approved policy—not when code is merely present.
5. **Flutter is not deleted during migration.** It remains the production
   fallback until the React Native cohort has stable, measured parity.

## Gap register and priority

| Priority | Gap | Why it matters | Closure evidence | Primary owner |
| --- | --- | --- | --- | --- |
| P0 | No reviewed launch curriculum | 21,600 source cards are a corpus, not a pedagogical course. They lack objectives, levels, review records, and audio capability metadata. | Versioned manifest; native-speaker and learning-designer approval for every published item. | Content lead + native reviewer |
| P0 | RN has no learning-core parity | RN has identity/consent, but no language/profile persistence, curriculum reads, study, SRS sync, progress, or data-rights flow. | Device-tested learner journey from sign-in to review to progress restore. | Mobile engineering |
| P0 | No verified staging/environment evidence | Source cannot prove separate projects, deployed RLS/functions, or safe production isolation. | Dedicated staging project and a current source-tag smoke record. | Platform/SRE |
| P0 | Legal, privacy, deletion, and support evidence missing | The app cannot safely enable governed features or publish truthful store disclosures without approved public policies. | Counsel-approved, versioned HTTPS pages and end-to-end deletion/export test. | Legal/DPO + support |
| P1 | No real listening/audio coverage | Audio directory is empty; TTS is not a substitute for a native-audio claim. | Licensed audio coverage report and language-specific QA. | Content/audio lead |
| P1 | AI/voice/billing controls not proven in RN | The backend has strong boundaries, but the high-risk client paths are not ported or device-tested. | Staging contract tests plus Android/iOS failure-path recordings. | Mobile + backend + billing |
| P1 | Accessibility/localization parity missing | A multi-language app needs an accessible UI independent of target language. | Screen-reader, large-text, contrast, RTL, and offline matrix for launch scope. | Product + QA |
| P1 | Release/operations evidence missing | No public launch is credible without secrets rotation, backup recovery, alerts, support, and store proof. | Dated drills, dashboards, signed artifacts, store-track results. | Security + SRE + release owner |
| P2 | Scale architecture not demonstrated | The current content and learner-history access patterns are not sufficient evidence for 100K+ users. | Capacity model, pagination/CDN/async-work plan, and load/cost report. | Architecture/SRE |

## Sequenced delivery plan

### Stage 0 — lock scope and remove misleading signals

**Goal:** make every active claim match evidence before more features are built.

**Repository work**

- Correct the curriculum-count drift (`600` versus the actual `1,440` cards
  per language) and quarantine the current Play listing draft until it is
  approved against a manifest.
- Keep exam/readiness, native-audio, pronunciation, premium, and public-scale
  claims unavailable.
- Create a single feature/capability matrix: language, interface locale,
  reviewed levels, scripts, audio coverage, AI availability, and support
  status.

**Team decisions required**

- Name a content lead, learning designer, native reviewer, and release owner.
- Select the first course. Recommended decision to validate: Malay-interface
  learners studying English, text-first.
- Define the first cohort as content validation, not a public launch.

**Exit gate**

- Approved one-sentence product positioning, a named first course, and no
  user-facing copy contradicting the content-and-claims register.

### Stage 1 — build a publishable content package

**Goal:** turn one seed corpus into a reviewed course that engineering can
reliably render and roll back.

**Required content package**

1. A level/entry assumption and 20–40 measurable CEFR-style can-do outcomes.
2. A unit and lesson prerequisite graph with vocabulary, grammar, register,
   dialect, and cultural notes.
3. Exercise items for recognition, recall, guided writing, and remediation;
   each has accepted answers, distractors, hints, and source/licence fields.
4. A publication manifest with content version, reviewer identities/approval
   references, attribution, audio capability, and rollback version.
5. A review pass resolving duplicate translations deliberately; retain only
   variants labelled as valid alternatives.

**Acceptance tests**

- Schema validation fails for a missing objective, licence, reviewer state,
  content version, or answer specification.
- A native reviewer and a learning designer sign off every published lesson.
- Credits display the required Tatoeba attribution where relevant.
- The course can be restored to its prior manifest without a store release.

**Do not do yet**

- Do not call the course A1/A2, exam preparation, or comprehensive.
- Do not manufacture unreviewed lessons with AI just to increase volume.

### Stage 2 — implement the React Native free-learning core

**Goal:** provide a complete, small learning loop using only reviewed content.

**Build order**

1. Profile and canonical language selection using the RLS-protected contract.
2. Curriculum repository with runtime response validation, explicit error
   states, content-version awareness, and deliberate offline caching.
3. Unit/lesson navigation, card learning, recognition, typed recall, and SRS
   review. Query keys include user and content version.
4. Server-authoritative lesson completion, XP, streak, and daily goal.
5. Settings/legal/data-rights navigation, account deletion flow, attribution,
   and an honest capability screen.
6. Event instrumentation only after analytics consent; no learning text,
   prompts, transcripts, or identifiers in analytics payloads.

**Acceptance tests**

- A learner can sign in, select the launch language, complete/retry a lesson,
  review due cards, restart the app, and see correct restored progress.
- Account switch, sign-out, expiry, and deletion remove all user-scoped data
  before a different session is shown.
- Network/RLS/content failures remain visible errors, never empty courses or
  fabricated progress.
- Android and iOS automated/device tests cover happy and failure paths.

### Stage 3 — establish staging and release safety in parallel

**Goal:** prove that the backend and release path are safe before the cohort
can receive real learner data.

**Required owner actions**

- Create a dedicated staging Supabase project, protected CI environment,
  distinct OAuth redirects, and non-production data.
- Rotate/audit historically exposed credentials; preserve only sanitized
  evidence.
- Publish reviewed Terms, Privacy, AI/voice notice, support, export, deletion,
  age, and subscription-help pages with version identifiers.
- Configure backups/PITR, retention scheduling, support routing, alerting, and
  a restore/incident drill.

**Staging test matrix**

| Test | Required result |
| --- | --- |
| Anonymous access | Cannot read/write protected learner data or use governed AI. |
| User A vs. user B | Cross-user reads/writes fail. |
| Consent | Denial/withdrawal blocks the governed action immediately. |
| AI | Disabled, invalid-consent, quota, timeout, and kill-switch paths are truthful and provider-safe. |
| Deletion/export | Identity-derived deletion and external support/export paths complete as promised. |
| Release config | Missing protected values fail before an artifact is made. |

**Exit gate**

- Current source-tag evidence is attached to the release tracker; no historical
  dashboard claim is accepted as replacement evidence.

### Stage 4 — add audio, AI, voice, and billing only after core validation

**Audio and listening**

- License a Common Voice or equivalent dataset for the chosen course, track
  coverage by item/dialect/quality, and show text-only fallback where absent.
- Introduce listening exercises only when the corresponding audio has passed
  review and rights checks.

**AI and voice**

- Ground prompts in reviewed current-course objectives and vocabulary.
- Preserve consent, authenticated-user, quota, CORS, kill-switch, and
  server-only model/credential boundaries.
- Test permission accepted/denied/revoked, oversized input, offline,
  cancellation, timeout, quota, and temporary-file cleanup on real devices.

**Billing**

- Keep billing disabled until a server-authoritative RevenueCat entitlement
  lifecycle passes sandbox purchase, restore, renewal, cancellation, refund,
  cross-device, duplicate-webhook, and tamper tests.

**Exit gate**

- Every enabled premium/governed feature has a user-visible honest failure
  state and a staging evidence record.

### Stage 5 — internal validation cohort, then controlled beta

**Internal cohort success measures**

- first-lesson completion and first-review completion;
- objective-level task success and 7/30-day recall;
- learner-reported clarity and native-reviewer issue rate;
- crash-free sessions, error rate, support tickets, and accessibility defects;
- AI success/latency/cost only if AI is enabled.

**Promotion rule**

Move from internal validation to a closed beta only when the launch course,
device/accessibility matrix, staging evidence, legal/user-rights workflow,
backup/incident drill, support plan, and load/cost plan all pass. A beta must
have a cohort cap, feature flags, pause thresholds, and an accountable release
owner.

## What can be done now

### Source implementation status (2026-09-16)

The repository now contains the technical portion of the first content and
learning slice: a draft-only manifest contract, deterministic validation,
versioned course-release migration, server-verified practice/completion, and
React Native catalogue/course/lesson screens with truthful unavailable states.
The pilot package is deliberately unpublishable because its rights and reviewer
approvals are pending. This does **not** close Stage 1, Stage 2, or any cohort
gate; it prepares their implementation evidence. The remaining release work is
recorded in `CONTENT_RELEASE_IMPLEMENTATION.md`.

| Workstream | Start now | Requires external owner first |
| --- | --- | --- |
| RN learning core | Repository architecture, validated repositories, study/SRS UI, tests, and error states. | Reviewed launch-course manifest and a verified staging schema. |
| Content | Manifest schema, deterministic validation, duplicate-report tooling, and attribution UI. | Native-speaker/learning review, source rights confirmation, and editorial decisions. |
| Security/release | CI guards, test harnesses, safe configuration validation, and runbooks. | Staging project, secret rotation, protected environments, store/device evidence. |
| AI/voice/billing | Contract-preserving client scaffolding and failure-path tests. | Provider/consent/legal/audio/billing configuration and sandbox evidence. |

## Final release decision rules

- **Continue RN implementation:** yes, beginning with Stage 1 content package
  and Stage 2 free-learning core.
- **Invite an internal content-validation cohort:** not yet.
- **Enable AI, voice, or billing for a cohort:** not yet.
- **Publicly market or replace Flutter:** not yet.

The next engineering change should therefore be a reviewed-content manifest
and the first React Native curriculum/SRS slice—not another broad platform
feature.
