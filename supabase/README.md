# Supabase release runbook

The database schema is defined by ordered migrations and the development seed
is generated from `assets/curriculum/syllabus_master.json`.

## Local setup

1. Copy `.env.example` to a local, ignored `.env` file and fill in only local
   development secrets.
2. Regenerate curriculum data after editing the JSON:

   ```powershell
   node scripts/generate_seed.js
   ```

3. Run `supabase db reset` to apply migrations and load
   `../scripts/seed.sql`. The seed includes all eight current languages and
   marks only that reviewed curriculum as available to learners.

## Required production setup

Do these from the account owner’s Supabase/OpenAI dashboards; no source change
can safely perform them.

1. Revoke and replace every secret that was previously present in local source
   or bundled app assets. In particular, rotate the OpenAI key and the
   Supabase Management API token before deploying.
2. Set Edge Function secrets:

   ```text
   OPENAI_API_KEY=<new server-only key>
   OPENAI_CHAT_MODEL=<approved pinned chat model>
   OPENAI_TRANSCRIPTION_MODEL=<approved transcription model>
   ALLOWED_ORIGINS=https://your-production-web-domain.example
   # Optional emergency override; false disables AI without a client release.
   AI_ENABLED=false
   ```

   The hosted runtime supplies `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
   `SUPABASE_SERVICE_ROLE_KEY`. The service-role key must never be sent to an
   app or web browser.
3. Deploy the database migrations and all reviewed functions (`sparky-ai`,
   `delete-account`, and `revenuecat-webhook`) to staging first. The AI and
   deletion functions require an authenticated user JWT at the gateway and
   validate it again in code. The RevenueCat webhook is the narrowly scoped
   exception: it has gateway JWT verification disabled because RevenueCat is a
   third-party server caller, but rejects every request unless its configured
   authorization value and raw-body HMAC both validate.
4. Configure the same approved web origins, native OAuth callback
   `io.supabase.sparklingo://login-callback`, site URL, email confirmation,
   SMTP, and a production CAPTCHA provider in the hosted Supabase dashboard.
   `config.toml` is a local-development template; it does not alter an
   existing hosted project by itself.
5. Configure backups, point-in-time recovery (where available), database
   network restrictions, spend alerts, and monitoring before public release.

## AI quota and entitlements

`reserve_ai_quota_for_user` records no prompt, response, or audio. It applies
a server-side free-user cap per verified user: 30 chats, 12 scores, and 6
transcriptions per hour. It intentionally does **not** trust
`profiles.is_premium` or any client flag.

Migration `011_server_only_ai_quota_lifecycle.sql` revokes every legacy quota
RPC from `anon`, `authenticated`, and `service_role`; those functions are
retained only for forward-only migration compatibility. Its replacement
lifecycle RPCs are executable only by `service_role` and verify that role in
the function body. The Edge Function independently verifies the learner JWT,
then passes the verified user ID through its hosted service-role client. Never
call these RPCs from Flutter, a browser, or the Data API with a learner token.

The Edge Function creates a short-lived `reserved` row, writes `submitted`
immediately before its only provider fetch helper, and finalizes a valid reply
as `completed`. It can delete only an unmarked `reserved` row after a proven
pre-send failure. A timeout, transport fault, upstream error, malformed reply,
or lost marker result remains counted until hourly expiry or documented
reconciliation. Do not enable AI until this state transition has passed the
staging tests in [`../docs/AI_OPERATIONS.md`](../docs/AI_OPERATIONS.md).

Schedule the service-role-only `purge_ai_usage_events()` function (daily is a
reasonable starting cadence)
with a privacy-approved retention cutoff. At 1M+ MAU, move this ledger to a
partitioned/aggregated design before relying on it for high-volume reporting.

Migration `009_server_billing_entitlements.sql` and the `revenuecat-webhook`
function provide a local, fail-closed entitlement scaffold. They are not
deployment or billing proof. Billing remains disabled until a separate staging
RevenueCat webhook has HMAC/authorization secrets, a narrow environment/app
allow-list, lifecycle tests, account-recovery tests, and explicit approval.
The current AI quota function does **not** grant premium limits from this
ledger; do not advertise premium server-side AI benefits until the owning
function has been changed and tested to read the verified entitlement.

## AI runtime control and operational telemetry

Migration `007_ai_runtime_controls.sql` starts AI disabled and provides a
service-role-only, audited database kill switch. Apply it before deploying the
current `sparky-ai` function. The function also accepts an optional
`AI_ENABLED=false` Edge Function environment override. Both controls stop work
before quota reservation or an OpenAI call. See
[`../docs/AI_OPERATIONS.md`](../docs/AI_OPERATIONS.md) for the approved
toggle procedure, JSON log allow-list, verification cases, and the external
monitoring/abuse-control evidence required before enabling AI.

## Account deletion

`delete-account` requires `POST` with an authenticated bearer token and the
exact JSON confirmation `{ "confirmation": "DELETE" }`. It derives the user
only from the verified token and permanently deletes that Supabase Auth user;
the schema’s foreign keys cascade to the app’s user-owned tables.

The app includes a deliberate typed-confirmation UI. Deletion from Supabase
does not automatically erase records in external providers such as RevenueCat,
Firebase, email/support systems, analytics, backups, or legal-retention stores.
Add and test those provider-specific deletion workflows before representing
full deletion to users.

## Seed upload script

`scripts/seed_database.py` is a **legacy demo-data tool**, not the reviewed
curriculum pipeline. It has no production mode and sends no request unless an
operator specifies `--apply` plus the matching `--confirm-target` value. It
accepts only a loopback HTTP target for `local`, or a URL that exactly matches
the separately configured staging project for `staging`. It never prints the
target URL, service-role key, or response body.

For local disposable data, configure `SPARK_LINGO_SEED_URL` and the local
`SUPABASE_SERVICE_ROLE_KEY` only in a private shell or ignored local secret
store, then first run:

```powershell
python scripts/seed_database.py --environment local
```

That is a dry run. An authorized developer may use the matching explicit
confirmation only after checking the local target:

```powershell
python scripts/seed_database.py --environment local --apply --confirm-target local-seed
```

For hosted staging, run the same tool only in a protected staging environment.
It requires `SPARK_LINGO_STAGING_PROJECT_REF` and
`SPARK_LINGO_PRODUCTION_PROJECT_REF` to be different, and requires the staging
URL/optional `--project-ref` to match the configured staging reference exactly.
Keep the service-role key in protected staging secrets; never use a production
key in a developer shell, commit, chat, app, or CI log.

`scripts/upload_seed.js` sends the generated, reviewed `scripts/seed.sql` via
the Supabase Management API. It is **staging-only** and now refuses to send a
request unless all of these protected environment values are present and
consistent: `SPARK_LINGO_SEED_ENV=staging`, `SUPABASE_PROJECT_REF`,
`SPARK_LINGO_STAGING_PROJECT_REF`, `SPARK_LINGO_PRODUCTION_PROJECT_REF`, and
`SUPABASE_ACCESS_TOKEN`. The target and staging refs must match; the production
and staging refs must differ. It also requires an explicit `--apply` argument.
Use it only from a protected staging CI environment after reviewed approval;
the preferred local workflow remains `supabase db reset` with `scripts/seed.sql`.
