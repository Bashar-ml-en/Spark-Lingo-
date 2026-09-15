# Mobile backend contract

The React Native client may use only the public Supabase Auth API, RLS-protected
tables/views, explicitly granted RPCs, and authenticated Edge Functions below.
No client is allowed to use a service-role key or bypass RLS.

## Auth and profile

| Contract | Client input | Expected result / rule |
| --- | --- | --- |
| Supabase Auth | email/OAuth/deep-link or anonymous sign-in | Use session access token only; permanent identity is required for billing/AI where server policy requires it. |
| `profiles` | own user ID is derived/checked by RLS | Read/update own profile; canonical language codes only. |
| `course_releases`, `course_release_units`, `lesson_exercises` | course key and expected content version | Read only a current `published` release through RLS. Draft, revoked, malformed, or missing content is an unavailable state, never an empty course. |
| `languages`, `units`, `lessons`, `flashcards` | release-selected language/unit/lesson | Legacy Flutter reads remain supported. RN reads them only through a current course-release mapping and validates every response at runtime. |
| `card_reviews`, `lesson_progress`, `lesson_attempts` | authenticated learner and language/card/lesson identifiers | Learners can read their own history. RN mutations use server RPCs; clear caches on account switch. |

## Server-authoritative RPCs

The names below are contracts, not permission to duplicate their logic client
side. Generate database TypeScript types only from a verified **non-production**
Supabase schema, for example:

```text
supabase gen types typescript --project-id <verified-staging-ref> --schema public > apps/mobile/src/generated/database.ts
```

Do not run that command against an unverified/project-production target and do
not commit generated types that were inferred manually.

| RPC / function | Client may supply | Server authority / expected handling |
| --- | --- | --- |
| `record_user_consent`, `withdraw_user_consent`, `has_current_user_consent`, `has_active_user_consent` | purpose/document-version tokens defined by current notice | User ID and timestamps derive from JWT; malformed/missing response blocks processing. |
| `complete_lesson` | lesson ID and canonical language code | Completion ownership and attempt tracking remain server-side. |
| `record_lesson_exercise_response` | published lesson/exercise IDs, language, content version, bounded response | Server checks exact current-release membership and accepted answers. It persists correctness only—not raw answer text—and reports whether all required exercises are complete. |
| `complete_published_lesson` | published lesson ID, language, content version | Server accepts completion only after all required exercises in that exact release were verified. |
| `record_card_review` | published card ID, language, honest rating (`again`, `hard`, `good`, `easy`) | Server validates current-release membership and calculates schedule, interval, repetitions, and ease factor. |
| `award_xp`, `xp_today`, `set_daily_goal` | activity source, bounded amount, language/local day, or a goal from 10–500 | XP/streak math and daily-goal writes are server-side; client displays returned/queried aggregate only. |
| `ensure_billing_customer`, `billing_runtime_status`, `has_active_billing_entitlement` | no arbitrary user ID; entitlement ID where accepted | Permanent account and server billing controls decide availability/premium. |
| Exam/readiness RPC/table access | none until feature is approved | Do not build client scoring or readiness UI around inactive/incomplete schema. |

## Edge Functions

| Function | Allowed client call | Required error handling |
| --- | --- | --- |
| `sparky-ai?action=chat` | authenticated, consented, bounded history and allowed mode/language | Handle 401/403/413/429/503 distinctly. Preserve draft/retry; never show a canned answer as live AI. |
| `sparky-ai?action=score` | authenticated, consented, bounded response plus server-approved rubric reference | Show only valid reviewed response with disclaimer/provenance; error remains error. |
| `sparky-ai?action=transcribe` | authenticated, voice-consented, bounded temporary audio multipart upload | Delete local file/blob after all outcomes; do not log transcript/audio paths. |
| `sparky-ai?action=history` | authenticated user and language | Treat persisted messages as untrusted display text; obey current server retention policy. |
| `delete-account` | authenticated session plus literal confirmation `DELETE` | Server derives user. Clear local session/cache only after the server result and show failure truthfully. |
| `revenuecat-webhook` | **never a mobile-client call** | Hosted RevenueCat only; HMAC/authorization/server role remain server-side. |

## Data integrity requirements

- Validate every Edge Function JSON response at runtime with a schema validator.
- Include the authenticated user ID and content version in course query keys;
  reject a course response whose version does not match the route selection.
- Put explicit page sizes/cursors on learner histories and never request an
  unbounded progress/event set.
- Query keys must include user ID; invalidate on mutation and clear on session
  change.
- Preserve current server-enforced request/audio-size, quota, consent, CORS,
  runtime-control, and entitlement boundaries.
- Test anonymous denial, cross-user denial, own-user permitted actions,
  withdrawn consent, quota exhaustion, kill switch, malformed response, and
  rejected webhook in a disposable local or dedicated staging environment.
