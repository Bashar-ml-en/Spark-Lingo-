# Spark Lingo go-live execution plan

**Current decision:** no public launch. Source-level controls are being
prepared, but no hosted provider, legal, store, backup, or operational evidence
has been accepted. A named release manager—not this document—makes each
go/no-go decision.

Use this plan with [`RELEASE_TRACKER.md`](RELEASE_TRACKER.md). A requirement is
complete only when its evidence is linked in the tracker and independently
reviewable.

## Release gates and accountable owners

| Gate | Risk | Accountable owner | Technical/operational mechanism | Acceptance evidence | Blocks |
| --- | --- | --- | --- | --- | --- |
| Immutable source | P0 | Engineering/release lead | Classify worktree; protected PR; pin toolchain; run CI; annotate a tag; generate manifest/SBOM/hashes | PR approval, branch-protection screenshot, green tag CI, clean checkout, manifest | Every distribution stage |
| Credential incident | P0 | Security/platform | Revoke historic provider credentials; issue least-privilege replacements; store only in hosted secrets; inspect audit/usage logs; scan Git history, archives and artifacts | Revocation timestamps, sanitized audit review, clean scan report, rotation owner/calendar | Every hosted environment |
| Environment separation | P0 | Platform/SRE | Separate Supabase/OpenAI/Firebase/RevenueCat projects and callbacks for dev/staging/prod; grant named least-privilege access | Environment matrix, project IDs, access review, no production data in staging | Staging and public launch |
| Database/functions | P0 | Backend/SRE | Forward-only migrations to staging; deploy functions after their migrations; exercise RLS with anon/user A/user B/service role | Deployment log, schema/migration report, RLS and Edge smoke report | Any data/AI release |
| AI safety/cost | P0 | AI owner/security/SRE | Server-only key; non-anonymous/captcha guard; WAF/rate limits; approved models; quotas; database + environment kill switch; cost dashboard/alerts | Abuse tests, kill-switch drill, alert drill, budget screenshots, privacy review | Any user-facing AI |
| Backup/DR | P0 | SRE | Enable PITR/backups; define RPO/RTO; restore into isolated environment; validate application invariants; schedule retention | PITR status, dated restore drill, integrity report, on-call rota/runbooks | Closed beta and public launch |
| Legal/user rights | P0 | Legal/DPO/product | Legal owner publishes real versioned policies; app exposes Settings links; server records consent; test deletion/export/processor workflow | Legal approval, HTTPS page tests, consent audit, deletion/export test record, store disclosures | Public beta/public launch |
| Billing | P0 | Billing/backend/product | Keep purchase disabled; verify RevenueCat webhook server-side; idempotent entitlement ledger; enforce server-side; prohibit guest purchase unless linking is tested | Webhook/signature tests, full sandbox lifecycle, tamper test, approved copy | Paid launch |
| Content and claims | P0 | Content/legal/product | Rights/reviewer/version record for each lesson/media; native review; approve only substantiated wording | Content ledger, rights evidence, QA samples, approved store/marketing copy | Broad public positioning |
| Mobile/store release | P1 | Mobile release owner | Signed tagged AAB/IPA; test physical devices; upload symbols; complete store forms/review notes; staged rollout | Artifact provenance/hashes, device matrix, TestFlight/internal-track evidence, store checklist | Public mobile release |
| Operations/support | P1 | SRE/product ops | Privacy-safe dashboards, status/support channel, alert routing, incident exercises and rollout pause conditions | Dashboard/alert drill, test ticket, incident/rollback rehearsal | Closed beta and public launch |
| Scale programme | P1–P3 | Architecture/SRE | Pagination/read models, cache/CDN, async AI/audio, aggregates/partitioning, load/cost/DR tests | Capacity model and load reports at each approved tier | 100K+ claims |

## Execution order

### 0. Governance and repository integrity

1. Review `WORKTREE_CLASSIFICATION.md`; split candidate source, migrations,
   assets, docs and pipelines into reviewable PRs. Do not stage local JDKs,
   build outputs, archives, signing files, or unknown material.
2. Enable main-branch protection in the Git hosting service: pull-request
   review, required Quality workflow, no force push, and restricted release
   tag creation.
3. Merge only green reviewed PRs. From the exact resulting clean commit,
   create an annotated tag. The tag triggers Quality CI; do not create a store
   artifact until that tag has a green run.
4. Build signed artifacts in a protected release environment. Generate the
   manifest with `scripts/generate_release_manifest.js` and attach it with
   hashes/SBOM to the release record.

**Containment:** reject the candidate and create a new forward commit/tag. Do
not retag, force-push, or use an unreproducible worktree.

### 1. Credential incident response

1. Security owner inventories the formerly exposed OpenAI and Supabase
   Management credentials by provider account and creation date—not value.
2. With explicit production approval, revoke the old credentials in their
   dashboards. Record timestamps and inspect audit/usage/billing events for
   anomalous use.
3. Create narrowly scoped replacement credentials. Put server secrets only in
   the corresponding environment's hosted secret store/protected CI secrets;
   publish mobile values only when they are designated public keys.
4. Run Git-history, archive, source, artifact and CI-log secret scans. Open an
   incident if any match is real; do not paste it into an issue or chat.

**Acceptance:** the tracker contains sanitized audit/revocation evidence and a
named owner/rotation schedule. A source scan alone never closes this gate.

### 2. Staging-first data and function deployment

1. Provision a separate staging project with disposable or synthetic data.
   Verify the project reference in the dashboard before every CLI command.
2. Store staging-only Edge secrets in the hosted secret manager. Use exact
   staging web origins/callbacks and disable billing/production products.
3. From the annotated source, preview ordered migrations, apply them forward
   only, then deploy the matching Edge Functions. Never run a reset, prune, or
   migration repair against production as a shortcut.
4. Test all access combinations: unauthenticated request, anonymous Auth user,
   authenticated user A, authenticated user B, and server role. Specifically
   prove cross-user data denial, premium self-grant denial, AI auth/consent/
   quota enforcement, and identity-derived deletion.

**Acceptance:** `STAGING_DEPLOYMENT_RUNBOOK.md` smoke table is complete with
sanitized timestamps/statuses and a reviewer sign-off.

### 3. AI safety, abuse and cost controls

The application code defaults the database AI control to disabled and denies
anonymous AI users unless an explicit server exception exists. This is only a
foundation. Before enabling it for anyone:

1. Configure the provider key/model only in staging or production function
   secrets. Set a project monthly budget and 50/80/100% alerts. OpenAI project
   budgets are notification thresholds rather than a hard spending stop, so
   pair them with the server request ceiling and kill switch.
2. Enable CAPTCHA/verified-account policy, WAF/CDN bot controls, IP/device
   rate limits, and global cost caps for the relevant environment.
3. Send only the reviewed telemetry fields to operations. Do not retain
   prompts, answers, transcripts, audio, credentials, or raw model errors in
   logs/analytics unless legal privacy review explicitly permits a separate
   controlled process.
4. Run adversarial and reliability tests: unauthenticated, anonymous, invalid
   consent, quota race, long input, malformed model result, timeout, provider
   failure, kill switch, and cost alert.
5. Enable the runtime control only under a change record. Test immediate
   disable/re-enable in staging before beta.

**Acceptance:** dashboard and alert drill screenshots, request status evidence
showing no provider call when disabled, and signed AI safety/privacy approval.

### 4. Reliability, backup and incident response

1. Configure database backup/PITR, availability monitoring, storage lifecycle,
   and a scheduled AI-usage retention task. Set explicit beta RPO/RTO (for
   example, the business owner chooses the allowed data-loss and recovery
   windows; do not invent them).
2. Restore a production-like backup into an isolated environment. Check login,
   RLS, curriculum, SRS review state, deletion behavior, and migration history.
3. Assign an incident commander, communications owner, security owner, and
   rollback authority. Test the runbooks in `INCIDENT_AND_BETA_RUNBOOK.md`.

**Acceptance:** dated successful restore record, scheduler/job logs, on-call
rota, and at least one incident/rollback rehearsal.

### 5. Legal, consent and user rights

Legal wording and regional decisions belong to qualified counsel/DPO. The
engineering mechanism is:

1. Publish approved HTTPS Terms, Privacy, AI/voice notice, retention/
   subprocessors, support, age policy, deletion, export, and billing/refund
   paths on a controlled domain.
2. Inject only approved public URLs and document versions through build-time
   configuration. The Settings UI fails closed if values are absent/unsafe.
3. Record affirmative, versioned consent server-side before processing AI,
   voice/transcription, or optional analytics where required. Make denial and
   withdrawal safe; do not make core learning depend on optional analytics.
4. Test in-app deletion, the post-uninstall deletion path, data-export request,
   processor erasure workflow, legal holds/backups, and final user
   communication.
5. Complete Apple privacy labels and Google Play Data Safety/deletion forms
   from actual data flows, not a template.

**Acceptance:** legal approval and live-page tests, policy/consent audit query
for a test account, end-to-end rights test, and store disclosure screenshots.

### 6. Billing and account continuity

The current safe state is **billing off**. To turn it on, implement and prove
the server-side authority model in `BILLING_ENTITLEMENT_DESIGN.md`:

1. Decide account recovery first. A guest cannot buy or restore until a
   recoverable identity or explicitly tested guest-link/merge design exists.
2. Configure RevenueCat server webhook authentication in the dashboard and a
   protected function secret. Validate raw body/authentication, idempotency,
   event timestamps, user mapping, environment, and entitlement state.
3. Populate the server-owned entitlement ledger and have AI/premium routes
   consult that ledger, not client cache/SharedPreferences.
4. Exercise purchase, restore, renewal, cancellation, billing issue, expiry,
   refund/revocation, duplicate delivery, second device, and tampered client
   in Apple/Google sandbox tracks.

**Acceptance:** webhook receiver/signature evidence, sandbox lifecycle report,
cross-device proof, client tamper test, and approved pricing/legal copy.

### 7. Content, accessibility and honest product claims

1. Build the content registry using the template in
   `CONTENT_AND_CLAIMS_REGISTER.md`. Publish only reviewed, rights-cleared
   material with attribution/version data.
2. Make the UI language separate from the learner's target language. Test RTL,
   large text, dynamic font, keyboard/screen reader, contrast, orientation,
   no-network, microphone denial/retry, and all advertised locales on devices.
3. Restrict copy to the current controlled beginner phrase-practice beta until
   learning/outcome/audio/exam/scale evidence exists.

**Acceptance:** content/legal/reviewer sign-offs, accessibility matrix and
screenshots, beta learner feedback, and a marketing/legal approval record.

### 8. Store engineering

1. Build a signed Android AAB and iOS IPA only from the tagged commit in a
   protected signing environment. Upload crash-symbol files as required.
2. Execute the physical-device matrix in
   `MOBILE_STORE_RELEASE_CHECKLIST.md`, including auth/OAuth callback,
   permissions, AI, SRS, deletion, offline recovery, restore, and billing.
3. Use Play Internal/Closed testing and TestFlight before public rollout.
   Complete store listing, review notes/demo path, content rating, privacy/data
   declarations, account-deletion URL, screenshots, and staged rollout limits.

**Acceptance:** artifact provenance, actual device results, internal-track or
TestFlight evidence, symbol upload, and store-owner approval.

### 9. Controlled beta

1. Invite no more than 1,000 users initially. Set geography, age scope,
   support hours, feature flags, AI/billing state, expected concurrency and
   cost envelope in writing.
2. Load test ≥2× the approved peak with synthetic accounts/data. Include lesson
   reads, SRS writes, AI chat/scoring/transcription and concurrent auth.
3. Monitor activation, D1/D7 retention, lesson/review completion, crash-free
   sessions, AI success/latency/quota, cost per active learner, abuse signals,
   support SLA, and privacy/billing incidents.
4. Pause automatically/manually on the thresholds signed by the release owner.
   Review the cohort weekly before any expansion.

**Acceptance:** load report, dashboard/alert drill, support report, beta
feedback summary, rollback rehearsal, and dated go/no-go sign-off.

## Stage decisions

| Stage | Current verdict | Minimum conditions to change verdict |
| --- | --- | --- |
| Internal development | Conditional go, non-production only | Local checks, synthetic data, no production credentials |
| Internal alpha | No-go | Immutable source/CI, staging deploy, RLS/AI smoke, credential response, signed-device smoke |
| Closed beta ≤1K | No-go | All alpha gates plus legal/consent, WAF/CAPTCHA, cost/kill-switch/alerts, restore drill, support/rollback, 2× load test |
| Public launch | No-go | All P0/P1 tracker evidence, completed store/legal flows, approved staged rollout, named release owner |
| 100K MAU | No-go | Pagination/cursors, CDN/versioned content, cache/read model, server billing, async AI/audio pipeline, capacity/cost/DR evidence |
| 1M MAU | No-go | Partitioned/aggregated event data, queue/worker architecture, autoscaling/capacity testing, mature on-call/DR evidence |
| 10M MAU | No-go | Multi-region traffic plan, regional failover, global abuse/cost controls, sustained performance and incident evidence |

## Target architecture by scale

```text
Mobile/web client
  → CDN/WAF/rate controls
  → Supabase Auth + RLS API (curriculum/progress)
  → Edge gateway (auth, consent, quota, kill switch)
       → async queue/worker for long audio/AI work at scale
       → provider API with per-project budget controls
  → Postgres (transactional learner data)
       → partitioned/retained usage ledger + aggregate metrics
  → observability, alerting, backup/PITR, support/status
```

- **≤1K:** managed Postgres/Edge functions may be sufficient with tight quotas,
  bounded requests and manual operational review.
- **100K:** paginate client reads, cache/version curriculum, remove long audio
  from synchronous functions, introduce queues/workers and load-tested global
  limits.
- **1M:** retain only necessary event data; partition/aggregate usage; isolate
  AI workloads; automate capacity/DR tests and on-call.
- **10M:** independently scale read delivery, identity, workers and regional
  failover; require proven multi-region and incident maturity before claiming
  readiness.

## Initial beta SLOs and limits to approve, not assume

The product, finance, security, and SRE owners must set actual values before
beta. Record them in the tracker and alert dashboard:

| Signal | Suggested mechanism | Must be approved before beta |
| --- | --- | --- |
| Availability | Synthetic auth/lesson/AI checks; status page | Core journey SLO and measurement window |
| Reliability | Crash-free sessions, API 5xx, RLS/AI security failures | Error budget and pause threshold |
| Latency | p50/p95 lesson read and AI endpoint latency | Per-action latency target/timeouts |
| Cost | OpenAI project budget + per-user/global quotas + kill switch | Daily/monthly budget alerts and a server-enforced request/control stop |
| Abuse | CAPTCHA/WAF/rate-limit rejects, identity churn | Alert threshold and containment owner |
| Support | First-response and resolution age | Support SLA and escalation roster |
| Learning | Activation, completed lesson/review, D1/D7 retention | Baseline and decision threshold; not marketing proof |
| Recovery | Backup age and completed restore duration | RPO/RTO targets and restore acceptance criteria |

## 30/60/90-day sequence after release ownership is assigned

| Window | Deliverables | Decision |
| --- | --- | --- |
| Days 0–30 | Close credential incident; commit/review/tag source; staging environment; CI/RLS/AI smoke; legal drafts/owner; billing authority design; initial restore drill | Alpha only if all P0 alpha evidence is accepted |
| Days 31–60 | Hosted anti-abuse/cost/alerts; live legal/rights flows; server billing webhook/lifecycle tests; signed device matrix; content/a11y QA; beta load/rollback rehearsal | Invite ≤1K only if beta gate is accepted |
| Days 61–90 | Measured beta, weekly reviews, content/claims evidence, support/on-call maturity, capacity assessment and remediation | Public launch decision or extend beta; do not widen automatically |

## Authoritative references

- [Supabase database migrations](https://supabase.com/docs/guides/deployment/database-migrations), [Edge Function deployment](https://supabase.com/docs/guides/functions/deploy), and [hosted secrets](https://supabase.com/docs/guides/functions/secrets)
- [Supabase anonymous-user security guidance](https://supabase.com/docs/guides/auth/auth-anonymous)
- [OpenAI project budgets and usage controls](https://help.openai.com/en/articles/9186755-managing-projects-in-the-api-platform)
- [RevenueCat webhooks](https://www.revenuecat.com/docs/integrations/webhooks)
- [Apple account-deletion guidance](https://developer.apple.com/support/offering-account-deletion-in-your-app/) and [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play account-deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
