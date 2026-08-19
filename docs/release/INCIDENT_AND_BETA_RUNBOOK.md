# Spark Lingo incident response and controlled-beta runbook

## Incident severity

| Severity | Examples | Initial response | Authority |
| --- | --- | --- | --- |
| SEV-1 | Credential exposure, confirmed data breach, destructive data loss, uncontrolled AI spend | Disable affected access/AI, preserve evidence, page incident commander | Incident commander + security owner |
| SEV-2 | Auth outage, sustained AI/provider outage, failed migration, payment failure, major RLS issue | Pause rollout/feature, investigate, notify owners | Incident commander |
| SEV-3 | Isolated user failure, degraded non-critical feature, content defect | Triage in business hours and provide workaround | Product/support owner |

## First 30 minutes

1. Open an incident record with time, reporter, severity, systems, and incident
   commander.
2. Stop the blast radius: disable AI, pause billing/rollout, revoke suspected
   credentials, or isolate the affected service.
3. Preserve sanitized evidence: timestamps, dashboards, deployment ID, request
   IDs, and status codes. Never copy secrets, prompts, audio, access tokens, or
   full personal records into incident channels.
4. Determine whether customer data, billing, or store users are affected.
5. Send a factual initial update through the approved communication route.

## Required incident runbooks

- Credential exposure: revoke, rotate, audit usage, scan source/artifacts,
  validate replacements, and document follow-up.
- AI cost spike: disable AI, preserve aggregate usage data, enforce budget,
  identify abuse cohort, and re-enable only after review.
- Provider outage: keep learner progress available, show safe retry messaging,
  release failed quota reservations, and monitor recovery.
- Database outage/data loss: halt writes if needed, restore only into an
  isolated target first, validate integrity/RLS, then obtain production approval.
- Failed migration: stop rollout; use forward-only remediation or approved
  containment. Never reset production.
- Payment problem: disable purchase path if entitlement integrity is uncertain.
- Deletion failure: stop claiming completion, open the verified support flow,
  retry through the approved processor runbook, and retain audit evidence.

## Controlled beta definition

The first beta is invite-only and capped at 1,000 users. The release manager
sets cohort size, approved geographies, age policy, and feature set before
enrollment.

### Required evidence before invitations

- P0 tracker items are complete or formally deferred from beta scope by the
  named release owner.
- AI spend cap, alerts, CAPTCHA/WAF, and kill switch are tested.
- Restore drill and staging smoke tests are complete.
- Support contact and status/incident communication route are live.
- Legal links, consent, deletion policy, and external deletion request route
  are approved for the beta geography.
- Physical-device and signed-build matrix has passed.
- Load test covers at least 2× defined peak workload.

### Pause conditions

Pause invitations and evaluate rollback if any of the following occurs:

- confirmed security/privacy incident or cross-user access;
- AI budget reaches approved emergency threshold;
- crash-free sessions fall below agreed target;
- core auth/database or AI failures exceed approved SLO;
- payment entitlement inconsistency occurs;
- support backlog exceeds response SLA;
- policy, store, or legal issue is identified.

## Weekly go/no-go review

Record cohort size, activation, D1/D7 retention, lesson/review completion,
crash-free sessions, AI success/failure, cost per active learner, abuse signals,
support volume/response time, incidents, unresolved P0/P1 items, and the next
cohort decision. Only the named release owner may expand, pause, or end beta.
