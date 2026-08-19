# Spark Lingo external configuration matrix

This document records configuration by environment without storing secret
values. The accountable owner attaches a dashboard screenshot, change record,
or audit evidence for each completed cell.

| Service | Development | Staging | Production | Owner | Required evidence |
| --- | --- | --- | --- | --- | --- |
| Supabase | Separate local project/container | Separate hosted project | Separate hosted project | Platform | Project IDs, access roles, migration/function history, RLS test report |
| OpenAI | Non-production project/key | Separate project/key/budget | Separate project/key/budget | AI/platform | Project identity, approved models, budget notifications, data controls, alert route |
| Firebase | Development project | Staging project | Production project | Mobile/platform | App registration, API restrictions, consent setting, Crashlytics/analytics evidence |
| RevenueCat | Sandbox products | Sandbox/staging webhook | Production products/webhook | Billing | Entitlement ID, webhook auth, lifecycle test report |
| Apple | Development signing/TestFlight | TestFlight build | App Store release | Mobile release | Signing access review, privacy labels, review notes, build evidence |
| Google Play | Internal test track | Closed test track | Production track | Mobile release | Signing access review, Data Safety, external deletion URL, staged rollout settings |
| Web/DNS | Local only | Staging HTTPS host | Production HTTPS host | Web/platform | Domain ownership, TLS, CSP/security headers, allowed origins |
| WAF/CAPTCHA | Optional local bypass | Enabled/tested | Enabled/enforced | Security/platform | Rules, rate limits, bot test, alert route |
| Support/status | Test inbox | Staging test route | Public support/status route | Support owner | Contact URL, escalation SLA, incident template |

## Non-negotiable separation rules

1. A staging service must not use production credentials, customer data, store
   products, or unrestricted spend budgets.
2. Each environment has its own approved origin list, callback URLs, API keys,
   Firebase app IDs, RevenueCat webhook configuration, and AI project/key.
3. Production access uses least privilege and named human/service identities.
4. Secret values remain in the approved secret manager or protected CI; this
   repository records only secret names and configuration evidence.
5. Production changes require the release-manager approval recorded in
   `RELEASE_TRACKER.md`.

## Required production secret names

| Scope | Secret/configuration name | Notes |
| --- | --- | --- |
| Edge AI | `OPENAI_API_KEY` | Server-only; rotate immediately if exposure is suspected |
| Edge AI | `OPENAI_CHAT_MODEL` | Approved pinned model name |
| Edge AI | `OPENAI_TRANSCRIPTION_MODEL` | Approved pinned transcription model name |
| Edge/Web | `ALLOWED_ORIGINS` | Exact deployed HTTPS origins only |
| Edge AI | `AI_ENABLED` | Emergency environment override; use `false` to block AI |
| Edge AI | `ALLOW_ANONYMOUS_AI` | Keep false unless a security-reviewed CAPTCHA/WAF exception exists |
| Deletion | Platform-provided `SUPABASE_SERVICE_ROLE_KEY` | Hosted Edge runtime only; do not manually configure, copy, or bundle it |
| Billing webhook | `BILLING_WEBHOOK_ENABLED` | Keep false until reviewed staging lifecycle tests pass |
| Billing webhook | `REVENUECAT_WEBHOOK_AUTHORIZATION` / `REVENUECAT_WEBHOOK_SIGNING_SECRET` | Server-only raw-body authorization/HMAC verification |
| Billing webhook | `REVENUECAT_ALLOWED_APP_IDS` / `REVENUECAT_ALLOWED_ENTITLEMENT_IDS` / `REVENUECAT_ALLOWED_ENVIRONMENTS` | Exact allow-lists, never wildcard values |
| Mobile build | RevenueCat public SDK key | Build-time public SDK value, not a RevenueCat secret API key |
| Mobile legal | Terms/Privacy/support/deletion URLs | Public HTTPS values, reviewed by legal/support |
| Mobile legal | `ANALYTICS_NOTICE_*` / `AI_AND_VOICE_NOTICE_*` | Approved public notice URLs and immutable versions; must match the server registry |

## Required production runtime controls

- AI enabled/disabled control and audit record.
- Per-user and global AI quota/budget limits.
- CAPTCHA and WAF rate/bot controls.
- Alert routes for security, spend, availability, payment, and deletion failures.
- Backup/PITR and tested restore procedure.
- Explicit rollout pause/rollback authority.
