# Route and state contract

## Existing public paths

| Path | Gate | Target RN route intent |
| --- | --- | --- |
| `/` | none | bootstrap/splash; resolve config and authenticated session |
| `/welcome` | anonymous allowed | welcome/auth entry |
| `/onboarding/select-language` | authenticated session required | onboarding language selection |
| `/home/:langCode` | selected target language required | learner home/course shell |
| `/paywall` | recoverable account + server billing gate | modal/stack purchase surface |
| `/settings` | public legal/help accessibility retained | settings/legal/help stack |

Chat, study, vocabulary, account deletion, and future exam preview currently
use modal/raw navigation. The RN implementation must add typed routes or typed
modal presentations for each; no feature may create an untyped escape route.

## Auth-state transitions

1. Invalid build configuration → unavailable screen; do not construct a
   backend client.
2. No current user → welcome, except public legal/help pages.
3. Authenticated user without an active language → language selection.
4. Authenticated user requesting an unselected language → active language.
5. Sign-out, deletion, or session expiry → clear all user-scoped caches, local
   drafts that contain sensitive content, billing identity, telemetry identity,
   and modal stacks before navigating to welcome.

## State ownership

| State | Owner | Rules |
| --- | --- | --- |
| Auth session/profile/consent/entitlement/curriculum/progress/chat history | TanStack Query repositories | Query keys include user ID and language where relevant; invalidation after every mutation; do not cache across sign-out. |
| Theme preference, selected language before server confirmation, input drafts, temporary modal state, active chat mode | small local UI store | Never use for entitlement, consent, scores, or server-authoritative progress. |
| Recording path/blob | screen-scoped hook | Never persist after screen completion; cleanup in `finally` and unmount paths. |
| AI request status | chat mutation state | Preserve user text for retry; never replace a failed request with an undisclosed canned reply. |

## Minimum cache keys and invalidation

- `['profile', userId]`: invalidate after language/display-name/onboarding update.
- `['curriculum', languageCode, contentVersion]`: invalidate after approved
  content version switch only.
- `['reviews', userId, languageCode]` and `['lessonProgress', userId, languageCode]`:
  invalidate after study/review/lesson completion.
- `['retention', userId]`: invalidate after XP award or daily-goal change.
- `['consent', userId, purpose, documentVersion]`: invalidate after record or
  withdrawal and block dependent actions while refreshing.
- `['billing', userId]`: invalidate after account identity transition,
  purchase/restore completion, and webhook reconciliation refresh.
- `['chatHistory', userId, languageCode]`: invalidate after persisted turn;
  clear at sign-out/deletion.

## Error contract

Repositories return a discriminated result or throw a typed domain error. UI
must distinguish loading, valid empty, offline/transport failure,
authorization/consent denial, quota/rate limit, configuration error, and
unexpected server shape. A valid empty list is never a substitute for an
unhandled request failure.
