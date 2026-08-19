# Spark Lingo release-readiness baseline

**Snapshot date:** 2026-08-16  
**Prepared by:** Release Program Lead (automated evidence baseline)  
**Decision:** Public release is blocked. This document is a baseline, not a
release approval.

## Evidence rules

A source file, local test, or checklist is not proof that a hosted control is
configured. A release gate is complete only with a dated evidence link such as
a deployment record, dashboard confirmation, approved policy, signed artifact,
automated test report, restore-drill result, or named-owner sign-off.

Do not place credentials, personal data, access tokens, or raw production logs
in this repository or in release evidence.

## Repository and release identity

| Item | Observed value | Status |
| --- | --- | --- |
| Source branch | `main` | Source-of-truth candidate only |
| Current committed HEAD | `580e4a2d554dc1e85bcc5f8f26ed2747e98698b7` | Not a release candidate |
| Remote | `origin` points to the Spark-Lingo GitHub repository | Unverified access/protection state |
| Working tree | Substantially modified and untracked; the count is intentionally dynamic while controlled hardening is in progress | **P0: every entry must be reviewed, committed, or excluded** |
| Release tag | No immutable release tag evidenced | Blocked |
| Signed artifacts | No signed AAB/IPA evidence | Blocked |
| Green remote CI | No run URL or immutable result evidenced | Blocked |

The worktree contains intended product source, assets, Supabase migrations and
functions, CI files, as well as local-looking JDK/build/archive artifacts.
Release engineering must classify every entry before a commit. Do not blindly
add the entire worktree.

## Current implemented capability

| Area | Source evidence | Current release interpretation |
| --- | --- | --- |
| Client | Flutter/Riverpod Android, iOS, web | Suitable for internal/staging validation |
| Identity/data | Supabase Auth/Postgres, versioned migrations, RLS | Hosted deployment and RLS behavior unverified |
| AI | Authenticated/consent-gated Edge Function, request bounds, per-user quota ledger, default-off runtime switch and global request ceiling | Hosted secrets, anti-abuse controls, provider budget alerts, ceiling activation, and AI evaluation unverified |
| Account deletion | Authenticated `delete-account` Edge Function and typed UI confirmation | External processor deletion/export path incomplete |
| Billing | Default-off server entitlement/webhook design; client fails closed without legal links, recoverable account, and server approval | No paid benefit is server-enforced or store-tested; do not charge users |
| Curriculum | Small bundled beginner curriculum and SRS | Not validated as a full course, CEFR level, exam preparation, or outcome-proven product |
| Exams | Entry point explicitly says unavailable | Do not market exam preparation/certification |
| CI | Secret scan, Flutter, Deno, and local Supabase smoke jobs are defined | Workflow is not yet proven green from a tagged commit |

## Environment baseline

| Dependency | Development | Staging | Production | Evidence required before release |
| --- | --- | --- | --- | --- |
| Supabase | Local template exists | Not evidenced | Not evidenced | Project IDs, access roles, migrations/functions deployment, RLS results |
| OpenAI | Local template exists | Not evidenced | Not evidenced | Server-only secret, approved model, spend cap, usage alert |
| Firebase | Client config exists | Not evidenced | Not evidenced | Separate project/restrictions/consent configuration |
| RevenueCat | Client build variables exist | Not evidenced | Not evidenced | Sandbox project, webhook, entitlement mapping, store products |
| Apple | Native configuration exists | Not evidenced | Not evidenced | Signing, TestFlight, privacy labels, review materials |
| Google Play | Android configuration exists | Not evidenced | Not evidenced | Signing, internal track, Data Safety, deletion URL |
| Domain/DNS/web | No managed hosting/DNS configuration evidenced | Not evidenced | Not evidenced | HTTPS domain, legal/help/deletion pages, security headers |
| Support/analytics/WAF | No production configuration evidenced | Not evidenced | Not evidenced | Support owner, dashboards, alert routing, CAPTCHA/WAF evidence |

## Go/no-go criteria by stage

| Stage | Current verdict | Minimum exit criteria |
| --- | --- | --- |
| Local/internal development | Go only with non-production data/secrets | Clean local checks and no production data |
| Internal alpha | Conditional no-go | Credential rotation, staging deployment, migration/RLS/AI smoke tests, CI result, signed-device smoke test |
| Closed beta (≤1,000 invited users) | No-go today | All alpha criteria plus CAPTCHA/WAF, cost cap/kill switch, dashboards/alerts, restore drill, legal minimum, support/rollback plan, 2× peak load test |
| Public launch | No-go | All P0/P1 tracker items, complete legal/store/billing evidence, staged rollout and named release authority |
| 100K MAU | No-go | Pagination/read models, CDN/versioned content, server entitlements, async AI/audio, capacity/cost tests and incident rotation |
| 1M MAU | No-go | Partitioned event data, aggregation, dedicated AI workload, DR and regional delivery plan |
| 10M MAU | No-go | Traffic model, multi-region resilience, global edge controls, worker fleet, mature SRE/on-call and sustained load evidence |

## Change-control plan

1. Create an issue for every P0/P1 tracker item and assign one accountable
   owner.
2. Make and review code changes through protected pull requests only.
3. Deploy every migration/function to staging first; do not reset, delete, or
   overwrite production data.
4. Record an approval, rollback/containment plan, and evidence link before any
   production change.
5. Create a release manifest from an immutable tag only after CI is green.
6. A named release owner makes the final go/no-go decision; automated tools do
   not self-approve a public release.

## Immediate safe work authorized in the repository

- Add non-secret release documentation, tests, and fail-closed configuration.
- Add global Settings/legal/help UI that remains unavailable without real URLs.
- Add server-side switches and staging-safe validation paths.
- Improve CI checks and non-production runbooks.

## External approval gates

The following require the service owner or designated accountable owner:

- Revoking/replacing provider credentials and viewing provider audit logs.
- Creating/configuring hosted Supabase, OpenAI, Firebase, RevenueCat, WAF,
  Apple, Google Play, DNS, email, and support accounts.
- Enabling paid billing, creating store products, or changing spend limits.
- Publishing legal policy, determining age/consent posture, and approving
  privacy retention/deletion terms.
- Deploying to production, running a production restore drill, or releasing to
  stores.
