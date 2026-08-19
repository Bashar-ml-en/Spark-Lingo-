# PR and release-evidence preflight

This is a reviewer aid for a source pull request and a later release
candidate. It is **not** permission to deploy, migrate, rotate credentials,
enable AI/billing, or change a hosted project. Record links to sanitized
evidence only; never place values, access tokens, customer data, prompts,
audio, or full provider logs in Git, CI output, issues, or chat.

Use the GitHub PR template together with this document. The authoritative
release gates remain in [RELEASE_TRACKER.md](RELEASE_TRACKER.md), and a
staging deployment must follow
[STAGING_DEPLOYMENT_RUNBOOK.md](STAGING_DEPLOYMENT_RUNBOOK.md).

## 1. Split and review the candidate

Before opening a PR, use [WORKTREE_CLASSIFICATION.md](WORKTREE_CLASSIFICATION.md)
to separate intended source from local JDKs, build output, archives, copied
pipelines, signing material, and unknown files. Do not bulk-add an existing
dirty worktree. Prefer separate PRs for:

1. Flutter/product source and platform files.
2. Database migrations and Edge Functions.
3. CI, secret scanning, manifest/SBOM tooling, and release documentation.
4. Content/assets, after rights and reviewer evidence exists.

The PR author must identify changed migration filenames, changed Edge Function
names, configuration **names** (not values), and any user-data, billing,
consent, or production-targeting impact. A reviewer must reject a PR that
modifies an already-applied migration, silently widens RLS/privileged access,
or mixes generated artifacts and source without an explicit reason.

## 2. Minimum source and CI evidence

Run the applicable checks from the PR branch using only local or synthetic CI
configuration. `supabase db reset` is permitted only for disposable local
containers; it must never be given a hosted target.

```text
git diff --check
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
deno check supabase/functions/sparky-ai/index.ts
deno check supabase/functions/delete-account/index.ts
deno check supabase/functions/revenuecat-webhook/index.ts
deno check scripts/staging_security_smoke.ts
node --check scripts/generate_release_manifest.js
node --check scripts/generate_sbom.js
node --check scripts/validate_ai_quota_boundary.js
node scripts/validate_ai_quota_boundary.js
supabase start
supabase db reset --local
supabase db lint --local
```

When a changed area requires it, also run the synthetic-value Flutter test and
build commands in [quality.yml](../../.github/workflows/quality.yml). The
protected CI run—not a local result—is the release-quality source of truth.

The secret-scan evidence must cover all four scopes below. A source-only scan
does not close `SEC-002`:

| Scope | Required evidence | Safe handling |
| --- | --- | --- |
| Candidate source and Git history | Green Gitleaks result from protected CI or an approved protected runner | Retain redacted pass/fail output only |
| Archives and copied pipelines | Scan each archive before approval; retain its name, hash, scanner/version, and pass/fail result | Do not extract unknown archives into the release checkout |
| Generated build artifacts | Scan a freshly generated release artifact before signing/store upload | Quarantine stale output; do not inspect or share any suspected value |
| CI/deployment logs | Confirm logs redact secret values and do not print build/server configuration | Keep only sanitized log links |

`quality.yml` runs Gitleaks with the repository configuration. The current
local environment cannot prove the hosted scan, GitHub log redaction, or
archive/artifact result; mark those as pending until independent evidence is
attached.

## 3. Reviewer checks by change type

### Database migrations

- Review ordered filenames and dependencies through the latest candidate
  migration, currently `011_server_only_ai_quota_lifecycle.sql`.
- Confirm new migrations are forward-only and have a containment or repair
  path; no reset, repair, prune, or destructive rollback is proposed for a
  hosted database.
- Review every RLS policy, `GRANT`/`REVOKE`, security-definer function,
  service-role check, retention change, and data backfill for least privilege.
- State the staging deployment order: migration first, then matching Edge
  Function, then the corresponding negative and cross-user smoke tests.

### Edge Functions

- List every affected function: `sparky-ai`, `delete-account`, and/or
  `revenuecat-webhook`.
- Confirm the expected gateway policy in `supabase/config.toml`: user-facing
  functions require JWT verification; the webhook exception must validate its
  own raw-body authorization/HMAC and stay disabled until its approved test.
- Review verified identity derivation, anonymous-user handling, consent,
  quota reservation/finalization, timeouts, response validation, and
  privacy-safe logs.
- List only required hosted secret/configuration names. Verify their values
  exist in the target environment later; never include them in the PR.

### Flutter and release configuration

- Verify builds explicitly set the target values defined in
  [MOBILE_BUILD_CONFIGURATION.md](MOBILE_BUILD_CONFIGURATION.md), and that a
  missing/cross-target configuration fails closed.
- Verify no secret key, management token, server credential, production URL
  default, or bundled `.env` is introduced in source/assets/build output.
- Flag Android/iOS permission, signing, OAuth callback, billing, telemetry,
  legal-link, store metadata, and device-test changes for the mobile release
  owner. Source review never replaces physical-device or signed-artifact proof.

### CI, manifest, SBOM, and rollback

- Confirm `quality.yml` is green for the exact reviewed commit and that its
  required jobs include secret scan, Flutter checks, Edge checks, and a
  disposable local Supabase reset/lint.
- Require branch protection and required checks in the hosting dashboard; a
  workflow file alone does not enforce either control.
- The tagged CI metadata job creates a source manifest and deterministic SBOM.
  It does **not** build or hash signed Android/iOS artifacts. A separate
  protected signing workflow must rebuild the manifest with each signed AAB,
  IPA, and SBOM supplied as `--artifact`, as described in
  [RELEASE_MANIFEST.md](RELEASE_MANIFEST.md).
- Record the forward-only containment action, named rollback authority, and
  the point at which AI/billing/rollout can be disabled without a mobile
  release.

## 4. Staging handoff and approval — no secrets

Before a staging deployment request, the account/release owner should confirm
the following by replying only with **yes/no, owner name/role, and a sanitized
evidence link or record title**. Do **not** provide project URLs/references,
keys, tokens, screenshots containing them, account passwords, customer data,
or provider logs.

1. Both chat-exposed secret credentials have been revoked, their provider
   audit/usage review is complete, and no replacement secret was shared.
2. A separate staging Supabase project exists; it is distinct from production,
   contains no production customer data or credentials, and is the only target
   authorized for the next deployment.
3. Staging and production GitHub Environments exist with the correct
   approvals/access controls; staging CI has only staging values and
   production remains protected.
4. A release owner, technical change owner, reviewer, and rollback authority
   are named for this change.
5. The proposed source is a reviewed PR; all intended files are classified,
   untracked artifacts are excluded, and protected CI must be green before
   deployment.
6. Billing remains disabled. AI remains disabled unless the named owner
   explicitly approves the narrowly scoped staging test after its controls,
   consent records, synthetic accounts, quota/cost ceiling, and kill switch
   are ready.
7. A staging backup/disposable restore point and the test-account cleanup plan
   are available. The team will not reset, repair, prune, or delete any hosted
   database.
8. The requested authority is exactly: **staging-only, forward-only migration
   and matching-function deployment from the reviewed commit, followed by the
   documented smoke tests. No production action is approved.**

If every item is confirmed, the next safe action is to use the protected
staging deployment process and collect the sanitized migration/function/RLS/AI
smoke evidence. A confirmation does not authorize production deployment,
provider-cost tests beyond the defined staging scope, credential rotation, or
store submission.

## 5. Evidence package for the release owner

For a merge candidate, attach the PR URL, reviewed commit SHA, CI URL, checked
file inventory, sanitized test results, and tracker updates. For a release
candidate, add all of the following:

- immutable annotated tag and clean tagged checkout;
- green tag CI URL;
- release manifest, SBOM, signed-artifact hashes, and provenance from the
  protected signing environment;
- staging deployment IDs, migration history, function versions, and smoke
  results;
- approved dashboard/legal/store/restore/device evidence listed in the
  release tracker; and
- named release owner decision plus rollout/containment authority.

Do not tag, sign, upload, or call an artifact a release candidate solely
because its source PR is approved.

## 6. Items that cannot be automated locally

The following remain manual or hosted gates and must stay `Blocked` until
independent evidence exists:

- credential revocation, provider audit/usage review, hosted secret presence,
  spend caps/alerts, CAPTCHA/WAF, and AI kill-switch operation;
- project/environment separation, GitHub branch protection/environment
  reviewers, deployment provenance, and actual hosted function configuration;
- production backup/PITR, isolated restore drill, monitoring/alert delivery,
  and incident exercise;
- legal/privacy approvals, public policy pages, consent/deletion/export
  processing, support readiness, and store disclosures;
- RevenueCat/store sandbox lifecycle, server entitlement enforcement, signed
  AAB/IPA provenance, physical-device validation, and store-track approval;
- staging/load/security tests that create data, trigger an AI provider, or
  exercise a hosted endpoint.

These limitations are intentional. A local pass is useful source evidence,
not proof that Spark Lingo is ready to deploy or launch.
