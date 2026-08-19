# Spark Lingo staging deployment runbook

This runbook is staging-first. It is not permission to deploy to production.
Never paste credentials into a terminal transcript, issue tracker, or this
repository.

## Preconditions

- A named change owner, reviewer, and rollback authority exist.
- The intended source is an immutable release-candidate tag with a green CI
  result.
- The GitHub `staging` Environment exists, has required reviewer protection
  (with self-review disabled where available), and releases its secrets only
  after approval. The source tag is protected by a GitHub ruleset.
- Staging is separate from production and contains no production customer data,
  billing products, or secrets.
- A staging database backup or disposable restore point exists.
- Required values exist only in the approved secret manager:
  `OPENAI_API_KEY`, `OPENAI_CHAT_MODEL`, `OPENAI_TRANSCRIPTION_MODEL`,
  `ALLOWED_ORIGINS`, and approved runtime controls. The hosted Supabase Edge
  runtime supplies its own service-role credential; do not paste or configure
  it manually.
  Billing webhook values remain disabled unless that separately approved staging
  lifecycle test is being run. Their values must not appear in evidence.

## Target identity and protected-workflow setup

Before enabling the `Staging security smoke` workflow, a GitHub administrator
must configure the protected **`staging` Environment**. It must contain the
following non-secret variables, alongside the existing staging test fixture
variables and secrets:

| Variable | Required value / purpose |
| --- | --- |
| `STAGING_ENVIRONMENT_GUARD` | Exact value `configured-staging-only`; proves the workflow is using the configured Environment rather than an unconfigured fallback. |
| `SUPABASE_STAGING_URL` | Canonical staging project HTTPS base URL only. |
| `SUPABASE_STAGING_PROJECT_REF` | Staging Supabase project reference. |
| `SUPABASE_PRODUCTION_URL` | Canonical production project HTTPS base URL, used only for a no-network equality check. |
| `SUPABASE_PRODUCTION_PROJECT_REF` | Production project reference, used only for a no-network equality check. |

The production project reference is public project metadata, not a credential.
It is needed so the workflow can fail closed if a staging variable is pointed
at production. Do not put service-role, secret, management, database, OpenAI,
or user-token values in GitHub variables. Those belong only in staging
Environment **secrets**.

For the manual **Controlled staging deployment** workflow, configure these
additional staging-only secrets after the credential incident is closed. Store
their values only in the protected GitHub Environment; do not put them in a
local `.env`, workflow input, issue, log, or chat.

| Secret name | Purpose | Required when |
| --- | --- | --- |
| `SUPABASE_STAGING_ACCESS_TOKEN` | Dedicated deployment credential with access limited to staging | Migration preview/apply and Edge Function deployment |
| `SUPABASE_STAGING_DB_PASSWORD` | Password for the staging database link used by the CLI | Migration preview/apply only |
| `SUPABASE_STAGING_ANON_KEY` | Staging client key used by the security-smoke workflow | Smoke tests only |
| `STAGING_SMOKE_*_ACCESS_TOKEN` | Disposable staging-user sessions | Smoke tests only |

Use a dedicated staging-only service identity for the deployment token where
the provider's access model permits it. Do not reuse a production management
credential or a credential previously exposed in chat. The deploy workflow
does not set Edge Function secrets; configure and verify those separately in
the staging dashboard before it is run.

The workflow runs only from a protected immutable tag. It requires an approved
staging change reference and an operator-entered confirmation in the exact
form `staging:<staging-project-ref>`. It first runs
`scripts/validate_staging_target.ts` with no network permission and then
passes the same target guard to the network smoke suite. The guard rejects a
target unless its canonical URL/ref match, the configured production URL/ref
also match, and the two refs are distinct. It additionally rejects the
reviewed production project in source even if a GitHub variable is
misconfigured.

This is defense in depth, not a replacement for reviewer protection. GitHub
Environment secrets are only released after configured protection rules pass;
configure and evidence that rule before relying on this workflow. See
[GitHub deployment environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments).

## Local immutable-source checks

Run these from the tagged checkout. Retain only pass/fail output and artifact
hashes as evidence.

```text
git status --short
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
deno check supabase/functions/sparky-ai/index.ts
deno check supabase/functions/delete-account/index.ts
supabase start
supabase db reset --local
supabase db lint --local
```

The reset above is for disposable local containers only. Never point it at a
hosted, shared, or production database.

## Staging secret and configuration review

In protected dashboards or CI:

1. Confirm the staging project identity before every action.
2. Confirm allowed web origins contain only staging HTTPS domains.
3. Verify no production key, billing product, or customer data is present.
4. Configure approved model names and the AI runtime kill switch.
5. Verify CAPTCHA/bot protection, spending limits, alert routing, and storage
   rules are enabled for staging.
6. Record secret names only, never values.

Supabase supports dry-run database pushes; its `--dry-run` mode lists pending
migrations without applying them. Use protected authentication and obtain
reviewer approval of that output before any change. See the official
[database push reference](https://supabase.com/docs/reference/cli/supabase-db-push),
[function deployment reference](https://supabase.com/docs/reference/cli/supabase-functions-deploy),
and [Edge Function secrets guidance](https://supabase.com/docs/guides/functions/secrets).

## Migration and function deployment

Use the manual **Controlled staging deployment** workflow from the protected
source tag. Its first run is a plan: it runs the target guard and migration
dry-run only. Attach that sanitized output to the change record and obtain a
reviewer approval before a second manual run enables
`apply_after_dry_run_review` to apply migrations and deploy functions.

1. Run the protected workflow's non-network target preflight with staging
   target metadata only; do not load any secret into a local shell before it
   passes. Record only its pass/fail result.
2. Link the CLI only to the approved staging project, independently compare its
   displayed project identity with the protected staging reference, and stop
   on any mismatch. Never use a saved production link.
3. Run `supabase db push --dry-run`; have a reviewer inspect the ordered,
   forward-only migrations before giving explicit staging change approval.
4. Apply forward-only migrations to staging only after the documented approval.
5. Deploy `sparky-ai` and `delete-account` from the tagged source. Deploy
   `revenuecat-webhook` only for its separately approved billing test; its
   `verify_jwt = false` exception is permitted solely because it verifies the
   provider authorization and raw-body HMAC itself. Do not disable JWT
   verification for any user-facing function.
6. Record migration history, function version, source tag, and timestamp in
   the release tracker.

Do not use migration-history repair, destructive resets, function pruning, or
database deletion without a separate reviewed change request.

## Mandatory staging smoke tests

| Test | Expected result |
| --- | --- |
| Unauthenticated AI request | `401` or equivalent auth rejection |
| Anonymous Auth AI request | `403`; no provider call |
| Authenticated AI request without current consent | `403`; no provider call |
| Consented, recoverable-account AI request | Valid response only when runtime switch and approved action ceiling permit |
| Disabled AI switch | Safe unavailable response; no provider call |
| Quota exhaustion | `429` with retry guidance; no raw content logged |
| Proven pre-send provider failure | Safe failure and quota reservation released |
| Ambiguous or post-submission provider failure | Safe failure; reservation remains counted and is reconciled only by the server-side expiry/reconciliation policy |
| User A → User B profile/review read | Denied by RLS |
| Client update of premium/trial | Denied or ignored server-side |
| Account deletion | Only current authenticated test user is deleted |
| Legal links absent | Purchases and restore remain disabled |
| OAuth callback | Tested only after provider approval/configuration |

Capture sanitized request IDs, status codes, test-user IDs, timestamps, and
screenshots. Do not capture access tokens, prompts, audio, or secret values.

## Production handoff

Production deployment needs separate explicit approval containing:

- approved immutable tag and green CI URL;
- production backup/PITR confirmation and containment plan;
- staging migration/function/RLS smoke evidence;
- legal, billing, and AI-feature approval status;
- named release manager, incident commander, and communication owner;
- planned rollout window and pause thresholds.

The production operator repeats dry run, migration, function, secret-name, and
smoke-test evidence steps against the verified production project. Never copy
staging secrets into production or vice versa.
