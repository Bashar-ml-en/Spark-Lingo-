<!--
  Do not paste secrets, keys, tokens, provider URLs containing credentials,
  customer data, prompts, audio, access tokens, or unredacted logs here.
  Attach only sanitized evidence links or pass/fail summaries.
-->

## What changed and why

<!-- State the user-facing/security impact and link the tracker item(s). -->

## Scope

- [ ] Flutter client / platform configuration
- [ ] Supabase migration(s) — list filenames below
- [ ] Edge Function(s) — list names below
- [ ] CI, release tooling, or dependency control
- [ ] Content, assets, or public claims
- [ ] Documentation only

## Data, function, and client review

### Migrations

<!-- N/A is acceptable only when no migration is changed. -->

- [ ] N/A
- [ ] New migrations are forward-only and do not alter an already-applied migration.
- [ ] RLS, grants/revokes, privileged RPCs, retention, and data migration impact were reviewed.
- [ ] Deployment order and forward-only containment/repair plan are recorded.

### Edge Functions

- [ ] N/A
- [ ] Function names and the expected `verify_jwt` setting are recorded.
- [ ] Authentication, authorization, consent, quota, error, and logging changes were reviewed.
- [ ] Required configuration names only (never values) and the staging test plan are recorded.

### Flutter, build, and mobile configuration

- [ ] N/A
- [ ] No secret/server credential or production default was added to source, assets, or build output.
- [ ] Any `--dart-define`, OAuth callback, permission, URL, billing, legal-link, or telemetry change is documented.
- [ ] Production-targeting behavior remains fail-closed and device validation needs are recorded.

## Validation evidence

<!-- Link only sanitized CI/log/artifact evidence. Mark "not run" with a reason. -->

- [ ] `git diff --check`
- [ ] Dart format, analysis, and Flutter tests/builds
- [ ] Deno checks for affected functions and staging smoke script
- [ ] Local disposable Supabase reset/lint for migration changes
- [ ] Gitleaks source/history scan; archives and release artifacts are separately covered
- [ ] AI quota-boundary validator, if AI/migration/function code changed
- [ ] Required documentation/tracker updates are included

Evidence links or sanitized result summary:

## Deployment and rollback impact

- [ ] No hosted deployment is requested by this PR.
- [ ] Staging-only deployment is requested and follows `docs/release/STAGING_DEPLOYMENT_RUNBOOK.md`.
- [ ] Production deployment is requested through a separate approved change record.
- [ ] Rollback/containment owner and action are recorded.

## Reviewer decision

- [ ] Approved for source merge only; hosted gates remain open.
- [ ] Blocked — missing evidence or unsafe scope is described below.

Reviewer notes:
