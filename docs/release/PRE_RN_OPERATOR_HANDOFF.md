# Pre–React Native operator handoff

This is the executable handoff after repository hardening. It does not
authorize production deployment, React Native app creation, or secret sharing
in chat. Run every hosted action from a protected environment and attach only
sanitized evidence to the release tracker.

## Starting condition

The current worktree is not a release candidate until an engineering owner
reviews it, commits the intended changes, and creates a protected immutable
tag after a green Quality workflow. Do not reuse historical evidence from an
older tag.

## Ordered owner actions

1. **Engineering lead:** review the current diff; merge the intended source;
   create a protected version tag only after CI is green. Attach the fresh
   manifest and SBOM to that tag.
2. **GitHub administrator:** configure protected `staging` and `production`
   Environments, required reviewers, no self-review where available, and the
   variable/secret *names* in
   [STAGING_DEPLOYMENT_RUNBOOK.md](STAGING_DEPLOYMENT_RUNBOOK.md) and
   [EXTERNAL_CONFIGURATION_MATRIX.md](EXTERNAL_CONFIGURATION_MATRIX.md).
   Never place a value in repository files, workflow inputs, logs, or chat.
3. **Platform/SRE:** prove staging and production are distinct before any
   networked command. From the protected tag, run the controlled staging
   deployment workflow first in dry-run mode. A reviewer must approve the
   sanitized plan before the forward-only apply/deploy run.
4. **Backend/SRE:** run the protected staging security-smoke workflow with
   disposable users. It must prove the current RLS, consent, AI quota,
   deletion, and newly hardened lesson/XP/daily-goal boundaries.
5. **Security/AI/operations owners:** complete credential-rotation audit,
   provider budget/alert/CAPTCHA controls, backup-restore drill, and incident
   rehearsal. Keep AI and billing disabled until their independent evidence
   is accepted.
6. **Legal, billing, content, and QA owners:** complete the live-policy,
   sandbox purchase/webhook, content-rights, and physical device/accessibility
   evidence defined in `PRE_RN_EXTERNAL_BLOCKERS.md`.
7. **Release manager:** compare the fresh evidence packet to the tracker and
   issue an explicit written decision: remain blocked, permit an internal
   Flutter validation release, or permit the first React Native beta
   implementation. No other role infers this approval.

## Mandatory evidence packet

- Protected tag and green CI URLs; manifest/SBOM/artifact hashes.
- Staging target-preflight, migration dry-run/apply, function version, and
  security-smoke pass/fail records.
- Sanitized dashboard evidence for credential rotation, budgets/alerts,
  CAPTCHA/WAF, backups/PITR, and restore exercise.
- Legal URL/version approval, billing sandbox lifecycle, content provenance,
  and Android/iOS accessibility/device matrix results.
- Named release manager, incident commander, rollback authority, support
  owner, approved rollout thresholds, and final go/no-go decision.

## Stop immediately when

- any target reference/URL does not match its protected environment;
- a migration plan is not independently approved;
- a test leaks a token, prompt, transcript, audio path, or customer data;
- RLS, consent, billing, deletion, or runtime-control proof fails; or
- any owner evidence is absent, stale, or tied to another source tag.

The detailed technical procedures remain in
[STAGING_DEPLOYMENT_RUNBOOK.md](STAGING_DEPLOYMENT_RUNBOOK.md),
[GO_LIVE_EXECUTION_PLAN.md](GO_LIVE_EXECUTION_PLAN.md), and
[PRE_RN_EXTERNAL_BLOCKERS.md](PRE_RN_EXTERNAL_BLOCKERS.md).
