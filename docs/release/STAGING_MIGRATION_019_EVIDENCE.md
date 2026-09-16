# Staging migration 019 evidence record

**Status:** BLOCKED — prepared for protected staging workflow execution; not
applied or verified in a hosted project.

**Prepared:** 2026-09-16  
**Source commit:** `ed022eafe981276ac061821bf1cdfae4df3fcb82`  
**Staging target:** `dioisitgohusggmwowft` (ap-southeast-1)  
**Production deny target:** `stlzixqtvtfyrcbjappr` (ap-northeast-1)  
**Migration:** `supabase/migrations/019_versioned_course_releases.sql`

This record is intentionally not evidence of a staging deployment. It records
only source-level checks and the controlled procedure required to create live
evidence. Flutter is not changed by migration 019 and remains the fallback.

## Source-level checks completed

| Check | Result | Evidence |
| --- | --- | --- |
| React Native content contract | PASS | 4 tests passed with the draft fixture remaining unpublishable. |
| React Native suite | PASS | 33 tests across 9 files passed. |
| TypeScript | PASS | `tsc --noEmit` completed successfully. |
| Web export | PASS | Expo web export completed successfully. |
| Controlled staging workflow | PASS | Static workflow validator passed. |
| Android release workflow | PASS | Static workflow validator passed. |
| Learning-progress boundary | PASS | Boundary validator passed. |
| Correction-report boundary | PASS | Boundary validator passed. |

The static staging guard contains `stlzixqtvtfyrcbjappr` as its reviewed
production deny-list entry. The protected workflow requires canonical,
distinct staging and production URLs/refs and the exact confirmation string
`staging:<staging-project-ref>` before it exposes deployment credentials.

## Migration contract reviewed

Migration 019 adds a React-Native-only release layer without changing the
existing Flutter curriculum path:

- versioned `course_releases`, release-to-unit mapping, reviewed exercises,
  lesson attempts, and exercise-attempt correctness records;
- RLS that exposes only current, non-revoked published content, plus each
  learner's own attempt history;
- server-side exercise verification that does not persist raw learner
  responses;
- server-side completion gating and SRS scheduling RPCs;
- publication evidence and rights gates; and
- immutable published/revoked releases and their membership/exercises.

Source tests prove the client fails closed when the server rejects an exercise
or returns an invalid review schedule. They cannot prove hosted schema state,
RLS behavior, function grants, or migration history.

## Blockers before staging mutation

1. Create or select an immutable **protected release-candidate tag** that
   points to the reviewed source commit. This checkout currently has no tag at
   `ed022eafe981276ac061821bf1cdfae4df3fcb82`.
2. In GitHub's protected `staging` Environment, make the following non-secret
   variables available to the workflow:

   | Variable | Required value |
   | --- | --- |
   | `STAGING_ENVIRONMENT_GUARD` | `configured-staging-only` |
   | `SUPABASE_STAGING_URL` | `https://dioisitgohusggmwowft.supabase.co` |
   | `SUPABASE_STAGING_PROJECT_REF` | `dioisitgohusggmwowft` |
   | `SUPABASE_PRODUCTION_URL` | `https://stlzixqtvtfyrcbjappr.supabase.co` |
   | `SUPABASE_PRODUCTION_PROJECT_REF` | `stlzixqtvtfyrcbjappr` |

3. Release only the protected staging secrets required by the workflow after
   environment reviewer approval: `SUPABASE_STAGING_ACCESS_TOKEN` and
   `SUPABASE_STAGING_DB_PASSWORD`. Do not provide them in chat, commits, or a
   local `.env`.
4. Supply a reviewer-approved staging change reference. There is no change
   reference in the repository; it must be provided by the release owner.

The local checkout deliberately has no Supabase CLI, Deno runtime, deployment
credentials, Android device bridge, or iOS tooling. That is not evidence that
the protected environment lacks them; it means the repository cannot verify
or replace the controlled GitHub workflow.

## Required two-run controlled deployment

1. From the protected tag, dispatch **Controlled staging deployment** with:
   - `staging_target_confirmation`: `staging:dioisitgohusggmwowft`
   - `staging_change_reference`: the approved change reference
   - `apply_after_dry_run_review`: `false`
   - `deploy_billing_webhook`: `false`
2. Attach the sanitized `supabase db push --linked --dry-run` result to this
   evidence record. A reviewer must approve the ordered, forward-only plan.
3. Dispatch the same protected-tag workflow again with
   `apply_after_dry_run_review` set to `true`. Keep billing deployment false
   unless it has an independent written approval.
4. Record the GitHub run URLs, source tag, migration history confirmation,
   and UTC completion time below. Never record secret values or user tokens.

## Required post-apply verification

Run these checks using disposable staging accounts and retain sanitized
pass/fail results:

| Area | Required proof |
| --- | --- |
| Migration state | Migration 019 appears once in remote migration history; all expected tables, indexes, triggers, policies, and RPCs exist. |
| Published-only reads | Anonymous/authenticated learners cannot read draft or revoked releases, units, or exercises. |
| Attempt privacy | Learner A cannot read Learner B's attempts; no table stores a raw practice-response field. |
| Exercise RPC | An unauthenticated call is rejected; a published-release exercise accepts only reviewed answers and returns correctness without persisting input text. |
| Completion RPC | Completion fails before every required exercise is server-verified and succeeds only after all are correct. |
| SRS RPC | Invalid ratings are rejected; valid ratings update only the caller's schedule for a card in a published release. |
| Immutability | A published release and its membership/exercises cannot be edited or deleted; it may only transition to revoked. |
| Regression | The staging security-smoke workflow passes after migration evidence is accepted. |

## Live-evidence fields — complete only after the workflow runs

| Field | Value |
| --- | --- |
| Protected source tag | PENDING |
| Approved change reference | PENDING |
| Dry-run workflow URL | PENDING |
| Dry-run reviewer and approval time | PENDING |
| Apply workflow URL | PENDING |
| Remote migration-history proof | PENDING |
| Post-apply verification artifact | PENDING |
| Staging security-smoke workflow URL | PENDING |
| Result | BLOCKED |

## Stage decision

**Do not begin course import or device validation.** Stage 1 passes only when
all live-evidence fields above are complete and the post-apply checks pass.
