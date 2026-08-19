# Spark Lingo production gate

This repository is designed to be deployed only after every gate below has an
identified owner and recorded evidence. A successful local build is not a
substitute for these controls.

## 1. Treat the exposed credentials as compromised

Before creating another distributable build, the service owner must:

1. Revoke and replace the OpenAI API key that was previously present in the
   client `.env` file.
2. Revoke and replace any exposed Supabase Management API token or secret API
   key.
3. Check provider audit logs and billing/usage for unexpected activity from the
   time those credentials were first created.
4. Store replacement secrets only in the provider's secret manager or protected
   CI environment. They must not be committed, added to Flutter assets, logged,
   or shared in chat.

The codebase intentionally uses the public Supabase project key in the client
and keeps all provider secrets on the Edge Function side. A public project key
is not a substitute for a user access token or server-side authorization.

## 2. Configure the AI boundary before enabling it

Set the following Edge Function secrets in the intended Supabase environment:

- `OPENAI_API_KEY`
- `OPENAI_CHAT_MODEL` (an approved, pinned model name)
- `OPENAI_TRANSCRIPTION_MODEL` (an approved, pinned transcription model name)
- `ALLOWED_ORIGINS` (a comma-separated allow-list of deployed HTTPS web origins)
- `AI_ENABLED` (leave unset for the database control; set `false` for an
  emergency environment-level block)
- `ALLOW_ANONYMOUS_AI` (leave `false` unless the security owner has approved
  the documented CAPTCHA/WAF exception)

The hosted Supabase Edge runtime provides `SUPABASE_URL`,
`SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` itself. Do not manually
paste, create, copy, or configure the service-role key as an Edge Function
secret; it must remain server-side and unavailable to app or browser clients.

Apply migrations `007_ai_runtime_controls.sql`, `008_legal_consents.sql`, and
`010_ai_global_request_ceiling.sql` before the current Edge Function. AI and
each global action ceiling start disabled; enable them only through the
service-role-controlled operational procedure after staging verification. An
optional `AI_ENABLED=false` Function secret is an independent emergency
override. See [`AI_OPERATIONS.md`](AI_OPERATIONS.md) for the exact safe toggle
procedure, controlled-beta request ceiling, and privacy-safe logging contract.

Use `supabase/.env.example` only as a local, non-secret template. Do not use
the local development origins in production. Deploy the database migration and
the `sparky-ai` function together, then verify that an anonymous public key
alone receives `401`, an anonymous Auth user receives `403`, an authenticated
user without current consent receives `403`, and only a consented,
recoverable-account request passes once the runtime switch and action ceiling
are enabled. Verify that a deliberately exceeded quota returns `429`. A
proven pre-send provider failure may release its reservation; a timeout or
other ambiguous post-submit failure must remain accounted until expiry or
reconciliation. The global ceiling is a controlled-beta request containment
mechanism; it is not a currency guarantee or high-scale rate limiter. Do not
advertise higher premium AI limits until a verified billing-webhook entitlement
and server enforcement of the advertised benefit are implemented.

Before enabling anonymous AI access, configure CAPTCHA/bot controls in hosted
Supabase, a WAF or equivalent rate limit at the edge, provider budget alerts
plus server-enforced request ceilings/kill switch, and
alerts for anonymous-account creation, quota rejections, and AI cost. Per-user
quotas alone do not stop an attacker from creating new anonymous identities.
Schedule the service-role-only `purge_ai_usage_events` retention job with a
privacy-approved cutoff; plan partitions/aggregates before 1M+ MAU.

## 3. Database and content release discipline

- Back up and review the target database before applying migrations. Do not run
  a destructive reset against a shared or production project.
- Run a clean local reset first. It must create the schema and load the seeded
  curriculum without manual SQL steps.
- Review Row Level Security with an anonymous user, a normal user, and a second
  normal user; cross-user reads and writes must fail.
- Publish only languages with reviewed curriculum, verified learning outcomes,
  and supported audio/assessment capabilities. Sample content must not be
  marketed as exam preparation.
- Keep production curriculum/media versioned and immutable; record the version
  used for each learner attempt.

## 4. Mobile, auth, and billing configuration

- Register the exact OAuth callback (`io.supabase.sparklingo://login-callback`)
  with Supabase and the identity provider, plus every production web redirect.
- OAuth controls are build-disabled by default. Turn on Google and Apple only
  after their hosted provider configuration and physical-device return flow are
  verified; iOS releases that expose Google must meet Apple's sign-in policy.
- Test Google OAuth return, microphone permission, AI practice, sign-out, and
  account recovery on physical Android and iOS release builds.
- Pass only RevenueCat *public SDK keys* through the documented build-time
  configuration. Configure offerings, entitlement identifiers, app-store
  products, and restore purchases in the RevenueCat dashboard before enabling
  the paywall.
- Supply real HTTPS Terms of Service and Privacy Policy URLs with
  `TERMS_OF_SERVICE_URL` and `PRIVACY_POLICY_URL`. The app fails closed and
  disables purchase/restore when either value is missing or invalid.
- Release signing must use a protected CI secret or a secured signing machine;
  the Android build is deliberately configured to fail instead of falling back
  to a debug signature.

## 5. Legal and user-rights gate

Before public distribution, provide real, public URLs and in-app access for:

- Privacy policy and terms of service, with the legal entity, support contact,
  data categories, AI/voice processing, retention, and subprocessors.
- Account deletion and data-export workflow, including how voice/transcript and
  analytics data are handled.
- Store privacy disclosures and age/consent treatment appropriate to every
  launch jurisdiction.
- Apple Sign in where it is required by the chosen third-party sign-in options.

Do not replace these materials with invented legal text or placeholder contact
information.

## 6. Evidence required for rollout

| Stage | Minimum evidence |
| --- | --- |
| Internal alpha | CI green, secure AI smoke test, RLS policy tests, signed mobile smoke tests, secret rotation evidence. |
| Controlled beta (up to 1,000 invited users) | Error/latency/AI-cost dashboards, anonymous-abuse alerts, retention job evidence, quota alerts, backup-restore rehearsal, support runbook, usability/accessibility review, and a load test at at least 2x expected peak. |
| 100K+ MAU | Cursor pagination and indexes for learner state, CDN/object storage for content, queue/back-pressure for transcription and scoring, server-side entitlements, SLOs, incident rotation, and capacity/cost testing. |
| 1M–10M MAU | Isolated AI workload, regional delivery/DR plan, partitioned high-volume events, aggregate read models, multi-region capacity plan, regular restore drills, and sustained load/cost tests at realistic peak concurrency. |

Define each target using MAU, DAU, peak concurrent learners, messages per
learner, transcription minutes, and token/output limits. “10 million users”
is not a capacity specification on its own.
