# React Native cutover and rollback contract

## Before the first RN beta build

1. Every repository-controlled exit condition in
   `PRE_REACT_NATIVE_HARDENING_MASTER_PROMPT.md` passes in CI.
2. Every item in `../release/PRE_RN_EXTERNAL_BLOCKERS.md` has verified
   environment/device evidence or is explicitly accepted as an out-of-scope
   product capability.
3. The RN parity matrix has an owner and test evidence for every P0/P1 flow.
4. Staging is distinct from production. No dual-client test uses production
   credentials, customer data, or an enabled production billing switch.

## Staged rollout

| Cohort | Scope | Advance only when |
| --- | --- | --- |
| Internal engineering | Test accounts, all backend contracts, error injection | Auth, consent, RLS, chat, voice, deletion, billing gate, and logging checks pass. |
| Invite-only beta | Small monitored group with support route | Crash/error/latency, quota/cost, consent, purchase/restore, retention, and accessibility evidence meet agreed thresholds. |
| Progressive store rollout | Region/percentage rollout approved by product/security | No P0 privacy/security/product-honesty regression; rollback path rehearsed. |

## Compatibility rules

- Both Flutter and RN clients use the same authenticated Supabase contracts and
  canonical language identifiers during parallel beta.
- Do not change RLS, RPC semantics, consent documents, quota lifecycle, or
  entitlement identifiers solely to simplify the RN client without a backward
  compatibility plan.
- Version bundled curriculum/content and record the version used for any
  persisted learner attempt before selectively changing content delivery.
- Keep Flutter release/rollback capability until the RN store build has met the
  defined stability window and all data reconciliation checks pass.

## Observability with privacy boundaries

Track aggregate app version, route/feature outcome, latency bucket, failure
code, purchase/restore result, and consent-state transition only after consent
where required. Never send raw prompts, transcripts, audio, email, Supabase
user IDs, tokens, receipts, or error bodies to analytics/crash reporting.

## Rollback triggers

Immediately halt or roll back the RN cohort for:

- unauthorised cross-user data access, consent bypass, secret exposure, or
  entitlement grant without server verification;
- account deletion failure or persisted temporary recording;
- a user-visible fabricated score/evaluation/AI response;
- material OAuth, payment/restore, microphone, or accessibility regression;
- sustained error/cost/latency beyond the pre-approved operational threshold.

## Rollback actions

1. Disable affected server-controlled AI/billing feature if appropriate; do not
   delete user data or reset the database.
2. Pause store rollout and remove the affected client cohort/feature flag.
3. Preserve privacy-safe incident evidence, identify affected app versions, and
   notify the accountable owner.
4. Restore the prior verified Flutter/store build only after confirming its
   configuration and release evidence still apply.
5. Ship a tested corrective build before resuming rollout.

## Flutter retirement criteria

Archive—not delete—the Flutter client only after all supported platforms have a
stable RN release, migration/cutover evidence is signed, support/documentation
is updated, and an approved rollback/recovery period has elapsed. Preserve
database migrations, Edge Functions, release manifests, and audit evidence.
