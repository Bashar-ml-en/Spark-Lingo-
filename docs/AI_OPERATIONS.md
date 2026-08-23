# AI operations, kill switch, and telemetry contract

This document defines the local code contract for Spark Lingo's AI Edge
Function. It does **not** prove that a dashboard, alert, WAF, spend limit,
retention job, or on-call rotation has been configured. Those are external
release gates and need operator evidence.

## Runtime controls

AI is fail-closed behind two server-side controls. Neither requires a mobile
or web client release.

1. The database control is created by migration
   `007_ai_runtime_controls.sql`. Its initial state is disabled. The Edge
   Function checks `ai_runtime_status()` after authentication and before it
   reads request content, reserves quota, or calls an AI provider.
2. The optional `AI_ENABLED` Edge Function environment value is an emergency
   override. Leave it unset to use the database control. Set it to `false` or
   any value other than `true`/`1` to block AI. This is deliberately
   fail-closed for malformed values.
3. Anonymous Supabase users are denied AI by default. The only exception is
   an explicit `ALLOW_ANONYMOUS_AI=true` server setting, which may be used only
   after the security owner has recorded evidence that hosted CAPTCHA, WAF, and
   abuse controls protect that exact environment. Absent or malformed values
   deny anonymous AI access. This exception does not replace the database
   runtime switch.
4. Migration `010_ai_global_request_ceiling.sql` adds a server-owned hourly
   ceiling per action. All ceilings begin at zero, so even an enabled runtime
   switch cannot send provider traffic until a service-role operator records
   an approved non-zero beta limit. It bounds requests, not currency: pair it
   with pinned models and bounded request/output sizes to bound worst-case
   usage.
5. Migration `011_server_only_ai_quota_lifecycle.sql` is required before the
   matching `sparky-ai` Edge Function version. It removes authenticated-client
   execute access to the legacy quota RPCs. The function validates the
   incoming learner JWT first, then uses the hosted service-role secret only
   for four server-only quota lifecycle RPCs. A user JWT, anon key, mobile
   client, or browser must never be able to invoke those mutation RPCs.

To change the primary control, use a service-role-protected operational path
after an approved change or incident record exists. Do not put an actual
token, customer data, prompt, transcript, or password in the change reference.

```sql
-- Disable first during an incident. The second argument is a non-secret
-- change/incident ticket reference.
select * from public.set_ai_runtime_control(false, 'INC-1234');

-- Re-enable only after the recovery checks in the incident runbook pass.
select * from public.set_ai_runtime_control(true, 'CHG-5678');

-- Set an approved controlled-beta request ceiling before enabling AI. Zero
-- immediately blocks that action; this is not a substitute for the incident
-- kill switch above.
select * from public.set_ai_global_request_ceiling('chat', 200, 'CHG-5678');
```

The function's change audit contains only `enabled`, `changed_at`, and a
non-secret change reference. Clients cannot write the controls or read audit
history. When the database control RPC is missing or unhealthy, the Edge
Function returns `503 ai_control_unavailable`; it never fails open.

## Quota mutation boundary and conservative accounting

The quota ledger is a spend/abuse containment control. It is not a client
preference and it must not be used as a Data API endpoint by learners.

`011_server_only_ai_quota_lifecycle.sql` establishes this lifecycle:

```text
verified JWT -> server-only reservation -> submitted marker -> provider fetch -> completed
                                      \-> proven pre-send failure -> deleted reservation
```

- `reserved` means the Edge Function has reserved capacity but has not
  persisted intent to call the provider.
- `submitted` is written immediately before the only provider-fetch helper.
  A timeout, lost network response, provider 4xx/5xx, invalid provider body,
  or lost marker RPC result is treated as potentially billable and remains
  accounted for.
- `completed` means the function received and validated a usable response.
- Only a still-`reserved` row without a submission marker may be removed. The
  release RPC itself enforces this condition, even for a trusted caller.

This intentionally favors cost and abuse safety over retry convenience. A
request whose upstream outcome is ambiguous counts until the hourly window
expires or a documented operator reconciliation process resolves it. Never
"fix" a timeout by deleting its reservation.

The Edge Function needs `SUPABASE_SERVICE_ROLE_KEY` only in its hosted secret
environment. Supabase supplies it to Edge Functions; do not create a custom
mobile configuration value for it. Deployment order is: migration `010`, then
`011`, then the Edge Function code that calls the `_for_user` lifecycle RPCs.
Deploying the function first fails closed because the new RPCs do not exist.

Run the read-only local regression check before review:

```powershell
node scripts/validate_ai_quota_boundary.js
```

Before enabling AI in staging, record all of this evidence:

1. A direct authenticated Data API call to each legacy quota RPC and each new
   server-only lifecycle RPC is rejected (`401`/`403` or equivalent permission
   denial); no test prompt or provider request is sent.
2. A valid Edge Function request can reserve, mark, and complete a quota row
   only after identity, runtime, and consent checks pass.
3. A controlled upstream timeout/failure leaves a `submitted` row that counts
   toward both user and global ceilings. A deliberately proven pre-send
   failure leaves no row.
4. An operator inspects the `submitted` reconciliation index without storing
   prompts, audio, transcripts, identities in dashboards, or provider secrets.

Do these tests only with disposable staging users and an approved test
configuration. They are not safe to run against production by default.

Deployment order is mandatory: apply migration `007` before deploying the
Edge Function version that calls `ai_runtime_status()`. After deployment,
verify all four cases in staging:

| Case | Expected result | Quota/provider behavior |
| --- | --- | --- |
| Database disabled | `503 ai_temporarily_disabled` | No request body parsed, quota reserved, or provider call. |
| `AI_ENABLED=false` | `503 ai_temporarily_disabled` | Same as above. |
| Database enabled, environment unset/true | Normal authenticated AI path | Normal quota/provider path. |
| Status RPC unavailable | `503 ai_control_unavailable` | No quota/provider call. |
| Global ceiling missing or zero | `429 quota_exceeded` | No provider call. |

An operator must also confirm real runtime propagation after changing Edge
Function environment values. The database switch is the primary immediate
control; the environment override is a second containment path.

## Provider selection (provider-agnostic gateway)

The `sparky-ai` function resolves its AI provider from environment only;
the client can never influence the choice. All provider configuration is
fail-closed: any missing or malformed value returns `503
configuration_error` before a quota reservation or provider call.

| `AI_PROVIDER` | Endpoint | Required secrets | Use case |
| --- | --- | --- | --- |
| unset / `openai` | `https://api.openai.com/v1` | `OPENAI_API_KEY`, `OPENAI_CHAT_MODEL`, `OPENAI_TRANSCRIPTION_MODEL` | Default; historical behaviour |
| `dashscope` | `https://dashscope-intl.aliyuncs.com/compatible-mode/v1` (override with `AI_PROVIDER_BASE_URL`) | `DASHSCOPE_API_KEY`, `DASHSCOPE_CHAT_MODEL`, `DASHSCOPE_TRANSCRIPTION_MODEL` | Qwen models via DashScope OpenAI-compatible mode |
| `openai_compatible` | `AI_PROVIDER_BASE_URL` (required) | `AI_PROVIDER_API_KEY`, `AI_PROVIDER_CHAT_MODEL`, `AI_PROVIDER_TRANSCRIPTION_MODEL` | Self-hosted vLLM / Ollama / Speaches |

Optional STT override: `AI_STT_PROVIDER=openai_compatible` +
`AI_STT_BASE_URL` + `AI_STT_MODEL` routes only transcription to a
dedicated self-hosted faster-whisper/Speaches server (MIT-licensed;
verified alternatives at SYSTRAN/faster-whisper and fedirz/speaches).
Chat stays on the primary provider. Cleartext `http` endpoints are
rejected unless the host is loopback, so a bearer key can never be sent
unencrypted to a remote host.

### Deployment commands (HUMAN-ONLY — hosted secrets)

Run from a machine with the Supabase CLI authenticated
(`supabase login`), project ref `dioisitgohusggmwowft` (or the approved
staging/production ref):

```bash
# Switch the gateway to Qwen via DashScope (example):
supabase secrets set AI_PROVIDER=dashscope --project-ref <ref>
supabase secrets set DASHSCOPE_API_KEY=<server-only key> --project-ref <ref>
supabase secrets set DASHSCOPE_CHAT_MODEL=<approved pinned model> --project-ref <ref>
supabase secrets set DASHSCOPE_TRANSCRIPTION_MODEL=<approved pinned model> --project-ref <ref>

# Self-hosted STT override (optional, example):
supabase secrets set AI_STT_PROVIDER=openai_compatible --project-ref <ref>
supabase secrets set AI_STT_BASE_URL=https://<approved speaches host>/v1 --project-ref <ref>
supabase secrets set AI_STT_MODEL=Systran/faster-whisper-large-v3 --project-ref <ref>
```

Then redeploy the function and verify the fail-closed contract:

```bash
supabase functions deploy sparky-ai --project-ref <ref>
# With the database runtime control enabled, a normal authenticated chat
# request must succeed; with AI_PROVIDER set to an unknown value it must
# return 503 configuration_error with no provider traffic (check the
# ai_provider_failure log stream is silent).
```

Never place provider keys in source, client builds, or `--dart-define`
values. Migration `012` (learner error patterns) must be applied before
deploying the matching function version; deploying the function first
degrades gracefully (focus list empty) but the ledger will be absent.

## Privacy-safe telemetry schema

The Edge Function emits newline-delimited JSON to its platform log sink using
an allow-listed schema. It does not emit request bodies, user IDs, email
addresses, access tokens, prompts, model responses, transcripts, audio,
filenames, provider credentials, or raw provider/database error messages.

`request_id` is a random UUID generated per Edge Function invocation. It is a
short-lived support correlation value, not a learner identifier. Never join it
to learner data in a dashboard without a documented privacy review.

| Event | Allowed fields | Purpose |
| --- | --- | --- |
| `ai_request_completed` | `request_id`, optional `action`, `outcome`, `status`, `code`, `latency_ms` | Request volume, success/error rate, latency, and safe error-code trend. |
| `ai_control_blocked` | `request_id`, `action`, `status`, `code`, `control` | Confirms emergency/database controls stop work before quota/provider calls. |
| `ai_control_unavailable` | `request_id`, `action`, `status`, `code`, `control` | Detects a fail-closed control-plane fault. |
| `ai_quota_operation_failure` | `request_id`, optional `action`, `code`, `operation` | Detects failures reserving/finalizing/releasing quota. |
| `ai_provider_failure` | `request_id`, `action`, optional `code`, `upstream_status` | Provider health without response content or upstream request IDs. |

Derived metrics may use only the allow-listed fields:

```text
ai_requests_total{action,outcome,status_class}
ai_request_latency_ms{action}
ai_control_blocks_total{control}
ai_control_unavailable_total
ai_quota_operation_failures_total{operation,code}
ai_provider_failures_total{action,upstream_status_or_code}
```

Do not use high-cardinality `request_id` as a metric label. It is for an
individual support investigation in logs only. Keep platform logs access
restricted, apply a privacy-approved retention period, and delete/rotate
downstream exports according to the approved data-retention policy.

## Required external operational configuration

Before enabling AI for any beta user, the platform/security owner must produce
evidence for all of the following:

- Hosted secret storage for provider credentials; no provider key in source or
  client builds.
- An approved, pinned chat model and transcription model.
- A WAF or equivalent IP/device rate limit, plus CAPTCHA or verified-account
  requirements that prevent anonymous-account abuse.
- OpenAI project monthly budget and budget alerts at 50%, 80%, and 100%.
  Treat those provider budgets as notifications, not a hard stop: combine them
  with the server request ceiling and kill switch before enabling AI. For the
  current database counter, keep ceilings at controlled-beta volumes; a
  load-tested distributed rate limiter is required before 100K MAU.
- A dashboard for the derived metrics above, alert routing, and an on-call
  owner.
- A kill-switch drill proving an operator can disable AI and that requests
  return the expected `503` without provider calls or quota consumption.
- A privacy-approved log and `ai_usage_events` retention schedule, with a
  scheduled `purge_ai_usage_events` run and evidence of execution.

Do not enable higher AI limits for paid users until a verified server-to-server
billing entitlement source exists. Client flags and local preferences are not
authorization.
