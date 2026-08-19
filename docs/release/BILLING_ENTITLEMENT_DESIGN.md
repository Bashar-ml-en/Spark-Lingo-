# Spark Lingo server-authoritative billing design

## Current position

The local release candidate now contains a fail-closed implementation in
`supabase/migrations/009_server_billing_entitlements.sql` and
`supabase/functions/revenuecat-webhook/index.ts`. It is **not deployed,
configured, tested with a store, or approved**. Billing starts disabled in the
database and the webhook rejects every request unless protected hosted secrets
explicitly enable it.

Client-side RevenueCat state may initiate a store transaction but is never the
authority for protected server resources or paid content. The client reports a
purchase as pending until the server ledger confirms it.

## Authority model

```text
Apple / Google purchase
  → RevenueCat verification
  → authenticated RevenueCat webhook
  → Spark Lingo entitlement ledger (server-owned)
  → server/RLS/Edge Function access decision
  → client UI reflects the server decision
```

## Required server data

The shipped additive migration contains:

- a service-role-controlled `billing_runtime_controls` kill switch and audit
  log, initially `enabled = false`;
- a recoverable `billing_customer_accounts` mapping created only for a
  confirmed permanent account, never for an anonymous session;
- a private, idempotent `billing_webhook_events` ledger and private
  `billing_entitlements` projection;
- `has_active_billing_entitlement`, which exposes only the current user's
  boolean server decision; and
- a service-role-only event application RPC.

Do not store raw payment instruments, store receipts, webhook secrets, or
unnecessary personal data in client-readable tables.

## Webhook behavior

1. Receive the raw request body at a server-only endpoint with a bounded body
   size and no browser CORS path.
2. Verify both the configured authorization header and RevenueCat HMAC over
   `timestamp.raw_body` before parsing/trusting the payload. Reject stale,
   malformed, unsigned, or incorrectly signed input.
3. Enforce idempotency using the provider event ID.
4. Validate user identity mapping and sandbox/production environment.
5. Process the allow-listed core lifecycle events. A non-grant event cannot
   create access for a new account; expiry revokes access; cancellation keeps
   access only through a future paid-through expiry.
6. Update the entitlement ledger transactionally.
7. Respond quickly and defer non-critical work; failed webhooks may retry.
8. Alert on signature failure, unknown user mapping, repeated failure, and
   entitlement drift.

RevenueCat supports authenticated webhooks and HMAC signing. Test with sandbox
purchases or dashboard test events; see the official
[webhook documentation](https://www.revenuecat.com/docs/integrations/webhooks).

`TRANSFER`, `TEMPORARY_ENTITLEMENT_GRANT`, dashboard `TEST`, and unknown event
types are intentionally acknowledged without creating access in this release
candidate. Before enabling a product that relies on any of them, the billing
owner must approve and test an explicit reconciliation/mapping design. This is
safer than granting from a partially specified event.

## Required hosted configuration and approval (not completed)

The billing owner must configure separate staging and production RevenueCat
webhooks, each with an exact HTTPS function URL, a unique authorization value,
HMAC signing, a narrow app-ID allow-list, the `spark_premium` entitlement
allow-list, and the correct environment allow-list. Store values only in
protected hosted function secrets under these names:

- `BILLING_WEBHOOK_ENABLED`
- `REVENUECAT_WEBHOOK_AUTHORIZATION`
- `REVENUECAT_WEBHOOK_SIGNING_SECRET`
- `REVENUECAT_ALLOWED_APP_IDS`
- `REVENUECAT_ALLOWED_ENTITLEMENT_IDS`
- `REVENUECAT_ALLOWED_ENVIRONMENTS`

Do not enable the database runtime switch or set `BILLING_WEBHOOK_ENABLED=true`
until staging has recorded successful HMAC, duplicate-delivery, lifecycle, and
cross-device tests. Production needs separate explicit release-manager,
security, legal, store, and billing-owner approval. Never put these secret
values in a Dart define, mobile build, repository, or support ticket.

## Enforcement rules

- The current release candidate does **not** increase any server-side AI quota
  or unlock a server-protected premium resource from this ledger yet. Do not
  claim that premium AI limits are live. Before a paid server benefit is
  enabled, the owning Edge Function/RPC must read only
  `has_active_billing_entitlement` (or an equivalent server-owned decision),
  never a mobile flag or SharedPreferences value.
- Existing local-only counters and Flutter locks are not billing enforcement.
  The product owner must publish a benefit-by-benefit matrix and engineering
  must implement and test a server check for every paid data, API, media, or
  quota benefit before enabling the billing runtime control.
- Premium curriculum/media must use an entitlement-aware policy, RPC, function,
  or signed URL. Do not rely only on a Flutter lock icon.
- The client may cache UI state but revalidates after purchase/restore and on a
  bounded schedule.
- A guest may not purchase until a recoverable account exists or a tested
  guest-to-account linking/merge flow exists.

This release candidate deliberately chooses the first option: confirmed,
recoverable accounts are required and no guest-to-account purchase migration is
implemented.

## Required test matrix

| Event | Required result |
| --- | --- |
| New purchase | Server grants only approved entitlement |
| Restore on second device | Same authenticated account receives entitlement |
| Renewal | Expiry extends idempotently |
| Cancellation | Access follows paid-through time |
| Billing issue/grace period | Policy applies consistently |
| Expiration | Server revokes protected access |
| Refund/revocation | Server revokes access promptly |
| Duplicate webhook | No duplicate state change |
| Bad authorization/signature | Request denied and alert generated |
| Tampered client | Cannot read server-protected benefit |
| Anonymous account | Purchase and restore remain unavailable; no billing mapping exists |
| Disabled runtime switch | No package is offered and no entitlement is returned to the app |
| Unsupported transfer/temporary event | Acknowledged without a new grant; reviewed reconciliation evidence required |

## Store/legal dependencies

Before enabling billing, approve product names, price/period, trial,
auto-renewal, cancellation, restore, refund, regional eligibility, legal links,
privacy disclosures, and support workflow. Store and legal owners provide the
final evidence; code alone cannot satisfy this gate.

Before public billing, also run a scheduled or operator-owned RevenueCat
subscriber reconciliation procedure. Webhooks are at-least-once and can be
delayed; the official guidance recommends syncing subscriber state after
webhooks. The reconciliation design, failure alert, and a recovery drill remain
P0 release blockers.
