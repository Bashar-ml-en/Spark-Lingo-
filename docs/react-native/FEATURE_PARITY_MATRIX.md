# Feature parity matrix

Only canonical, honest behaviour may be ported. An incomplete or retired
Flutter surface is not a parity requirement.

| Flow | Flutter owner / current canonical behaviour | Backend and privacy boundary | RN priority / acceptance test |
| --- | --- | --- | --- |
| Bootstrap/config | `lib/main.dart`, `supabase_config.dart`; invalid configuration shows unavailable state. | Build-time public config only; no default production target. | P0: malformed/missing configuration fails closed before network calls. |
| Auth and account type | `auth_service.dart`; anonymous free learner, permanent email/OAuth account for recovery/billing. | Supabase Auth, user JWT, OAuth deep link. | P0: fresh, returning, anonymous, sign-out, recovery, bad deep-link device tests. |
| Consent and legal | `consent_service.dart`, request dialog, settings. | Versioned consent RPCs; server is authoritative. | P0: no AI/voice/analytics traffic before consent; withdrawal and ledger failure tests. |
| Language/onboarding | welcome and language-selection features. | Profile `target_languages` / `active_language`. | P0: canonical code, empty profile redirect, RTL language, profile invalidation. |
| Curriculum | `database_service.dart`, home curriculum views. | Current server-published course release plus reviewed units/lessons/flashcards; no bundled learner fallback. | P1: loading/unavailable/error distinct; current version only; cache-version mismatch test. |
| Flashcard/SRS | **`flashcard_study_session.dart` only**. | `record_lesson_exercise_response`, `complete_published_lesson`, `record_card_review`, server ownership/RLS. | P1: correct/incorrect progression, retry, server-confirmed completion, schedule refresh, cross-account isolation. |
| Retention | `retention_service.dart`, header/adaptive goal. | Server-side XP/streak RPCs and learner rows. | P1: one award per qualifying activity, goal mutation refresh, timezone/day boundary tests. |
| AI chat | **`sparky_chat_session.dart` only**. | Authenticated `sparky-ai`, current consent, runtime switch, quota, CORS, chat persistence. | P0: consent denial, anonymous denial, quota, kill switch, timeout, retry, no canned-success fallback. |
| Voice/transcription/TTS | canonical chat + `voice_controller.dart`. | Voice consent and AI Edge Function; temporary recording deletion. | P0: accepted/denied/revoked permission, max size, cleanup, transcript failure, physical device tests. |
| AI scoring | canonical chat scorecard, only where reviewed rubric exists. | Server rubric/AI gateway; disclaimer. | P1: error is error—not local success; result has rubric/provenance/disclaimer. |
| Session report/correction review | canonical chat → `session_report_screen.dart`; report failures are visible and saved correction cards are user-scoped. | Authenticated `sparky-ai?action=report`; service-role-only correction ledger; local deck is cleared after successful account deletion. | P1: unavailable vs empty state, cross-account isolation, add/dedupe/review/delete deck tests, server RPC/RLS smoke test. |
| Exam readiness/mock exam | preview-only screens after hardening. | No live assessment contract is currently approved. | Do **not** port as a score feature. Port only an honest preview if product needs it. |
| Billing/paywall | `revenuecat_service.dart`, paywall. | Server billing switch, recoverable account, entitlement RPC, signed RevenueCat webhook. | P0: no client grant, unavailable gate, purchase/restore sandbox physical-device proof. |
| Account deletion | settings/home sheets and `delete-account`. | Authenticated Edge Function derives user identity. | P0: typed confirmation, user data/session transition, failure message, legal link. |
| Telemetry | `telemetry_consent_service.dart`, analytics. | Firebase starts disabled and only uses consented aggregate events. | P1: no identifier/prompt/audio in events, opt-out disables collection. |
| Help/settings/theme | settings/help/theme services. | Local preferences plus legal links. | P1: Dynamic Type, screen-reader labels, RTL, dark/light persistence. |
| Web/PWA | Flutter web shell. | Same server rules; browser origin gate for AI. | Product decision: retain only if RN web meets keyboard, zoom, deep-link, and bundle-size acceptance. |

## Explicitly retired behaviour

- The private home-screen AI session with local canned tutoring and a false
  local-evaluation success message must not be ported.
- The private home-screen flashcard implementation must not be ported.
- Placeholder/simulated mock exam behaviour and fabricated readiness values
  must not be recreated.
