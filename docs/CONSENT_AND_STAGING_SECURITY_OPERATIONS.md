# Consent and staging-security operations

This document describes code that is present in the repository, not evidence
that any legal, provider, or hosted configuration has been completed.

## What the code enforces

- The native Android and iOS builds start Firebase Analytics and Crashlytics
  collection disabled. The app does not attach a Supabase user ID to Firebase.
- Analytics/diagnostics can be enabled only after the current authenticated
  user has an active, server-backed `analytics` consent record.
- AI chat/scoring requires active `ai_processing` consent; transcription
  requires active `voice_processing` consent. The Edge Function checks this
  before it reads request content, reserves quota, or calls an AI provider.
- `legal_document_versions` contains only a document key, version, public URL,
  lifecycle fields, and a non-secret change reference. It contains no policy
  content and starts empty.
- `user_consent_events` contains only the authenticated user id, document key,
  version, accepted/withdrawn event, and server timestamp. It contains no
  prompt, transcript, audio, provider credential, IP address, or custom text.
- Direct client access to both tables is revoked. RPCs derive the user and time
  from the verified Supabase session. Account deletion cascades consent events
  through their foreign key to `auth.users`.

## Required external/legal activation steps

These are P0 release gates and require a legal/privacy owner plus an approved
staging or production change. Do not invent values or mark them complete from
source code alone.

1. Publish and approve the actual analytics and AI/voice notices at HTTPS URLs.
2. Assign immutable, legal-owner-approved versions such as a publication date
   or controlled document identifier. A version may contain only letters,
   digits, `.`, `_`, and `-`, and must be 1–64 characters.
3. Build each app environment with matching values:

   - `ANALYTICS_NOTICE_URL`
   - `ANALYTICS_NOTICE_VERSION`
   - `AI_AND_VOICE_NOTICE_URL`
   - `AI_AND_VOICE_NOTICE_VERSION`

4. In the corresponding Supabase environment, an authorised database owner
   must register one active row for each of `analytics`, `ai_processing`, and
   `voice_processing` using the exact approved URL/version and a non-secret
   change ticket reference. Retire prior rows rather than deleting them.
5. Record the legal approval, database migration/deployment record, row
   verification, build configuration names (never values), and a functional
   test account result in the release tracker.

The build and database registry must agree. If either is absent, stale, or
unavailable, the associated feature remains off.

## Data-rights and deletion boundary

The in-app delete action removes `auth.users`, which cascades Spark Lingo
consent events. This does **not** prove deletion from Firebase, support tools,
RevenueCat, analytics exports, backups, or legal holds. The privacy owner must
maintain the cross-processor deletion/export workflow and retention schedule.
The external account-deletion and export URLs remain separate legal/domain
launch gates.

## Staging smoke-test protocol

The repository includes `scripts/staging_security_smoke.ts` and a manually
dispatched `Staging security smoke` GitHub workflow. They are intentionally
not run on every pull request because they require protected staging test
accounts and make authenticated test requests.

Before a run:

1. Configure a protected GitHub `staging` Environment with reviewer approval,
   self-review prevention where available, a protected immutable source-tag
   rule, and the non-secret target-identity variables described in
   `docs/release/STAGING_DEPLOYMENT_RUNBOOK.md`. The workflow must reject an
   unprotected tag or a target that matches the reviewed production project.
   Put every key/token only in its protected variables or secrets, never in a
   repository file, terminal output, issue, or chat.
2. Create four recoverable staging-only fixtures: user A, user B, an anonymous
   user, and (only for the enabled-AI drill) a recoverable user with no current
   AI consent. Give A/B normal profiles; do not use real learner data.
3. Set `SMOKE_EXPECT_AI_RUNTIME=disabled` for the normal release gate. This
   validates the kill switch without invoking an AI provider. The `enabled`
   drill validates missing-consent denial with the no-consent fixture and also
   stops before provider use.
4. Preserve the workflow log as evidence. It prints only pass/fail labels, not
   variables, tokens, URLs, profiles, or API payloads.

The script first runs a no-network target guard. It refuses to run unless all
required target variables are supplied, the environment label is exactly
`staging`, the source is a protected immutable tag, the explicit confirmation
is exactly `staging:<staging-project-ref>`, staging and production canonical
URL/ref pairs are both valid and distinct, and the target is not the reviewed
production project. The network smoke script imports the same guard, so it
cannot bypass the preflight. This is a guardrail, not a substitute for GitHub
Environment protection and human review.

The smoke gate verifies anonymous profile denial, A/B profile isolation,
anonymous consent-RPC denial, deletion confirmation/identity binding, unauthenticated
AI denial, anonymous-AI denial, and either the AI kill switch or server-side
missing-consent boundary. It does not modify user data.

## Evidence required before public release

- Legal/privacy owner approval and live HTTPS notice screenshots.
- Staging migration deployment record for `008_legal_consents.sql`.
- Exact active registry rows independently checked by an authorised operator.
- Consent acceptance, withdrawal, relaunch, and stale-version test results.
- Protected-workflow run URL with passing staging security smoke output.
- A physical iOS and Android test showing that the microphone prompt appears
  only after the voice-processing notice and that decline/unavailable states
  send no AI request.
- Privacy review of Firebase, OpenAI, Supabase, support, billing, backups, and
  store disclosures. These code changes alone do not satisfy that review.
