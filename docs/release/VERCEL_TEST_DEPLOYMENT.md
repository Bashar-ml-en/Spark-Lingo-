# Spark Lingo web staging deployment (Vercel)

This procedure is for an isolated, protected **staging** deployment only. It
does not authorize a public production deployment, consent bypass, anonymous
AI, or use of a production Supabase project.

## Preconditions

- The source is a protected immutable tag with a green Quality workflow.
- The Vercel project/environment is designated as staging and has no
  production domain alias, data, secrets, billing products, or credentials.
- The protected staging Environment supplies approved, non-production public
  build configuration. Do not place values in source, scripts, shell history,
  screenshots, issues, or chat.
- Legal, privacy, and AI owners approve the test cohort and access controls.

## Build and deploy sequence

1. Use the protected CI environment to build Flutter web with explicitly
   validated **staging** configuration. The build must not receive a test
   consent flag or an anonymous-AI bypass.
2. Verify the generated artifact comes from the tagged commit and record its
   hash with the release manifest/SBOM.
3. Copy `vercel.json` into the compiled web artifact only when the reviewed
   Vercel project requires its static/SPA configuration.
4. Deploy the compiled artifact to the staging Vercel project using a
   staging-scoped Vercel token released by the protected CI environment.
5. Keep deployment protection enabled unless the release manager, legal, and
   security owners explicitly approve a controlled external test cohort.

## Required checks

- The deployed app rejects missing/mismatched configuration before backend
  initialization.
- The staging URL and Supabase project reference match the protected staging
  Environment and differ from production.
- AI remains unavailable without a current server-backed consent record; an
  anonymous account remains denied unless a separately approved server policy
  and abuse controls are in place.
- Browser zoom, keyboard navigation, legal links, sign-in, sign-out, account
  deletion failure, AI failure, and offline states are tested with staging
  accounts only.

## Prohibited shortcuts

- Never deploy a staging build under a production alias or with production
  public configuration.
- Never enable `ENABLE_TEST_CONSENT`, `TEST_CONSENT_MODE`, or anonymous-AI
  bypasses in a shared or production environment.
- Never store a project reference, client key, access token, or deployment URL
  in this document as current evidence.

Attach only sanitized build hashes, CI/deployment URLs, target-confirmation
results, and owner approvals to the release tracker. Follow
`STAGING_DEPLOYMENT_RUNBOOK.md` and `PRE_RN_OPERATOR_HANDOFF.md` for the
broader release gate.
