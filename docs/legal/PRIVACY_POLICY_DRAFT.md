# PRIVACY POLICY — Spark Lingo (DRAFT FOR COUNSEL REVIEW)

> STATUS: DRAFT — every technical statement below was verified against the
> actual codebase on 2026-08-28 (file references included). NOT legal
> advice. Counsel must review, adapt jurisdiction language (Malaysia PDPA
> 2010, EU GDPR if targeting EU, Google Play Data Safety requirements),
> and approve before publication at the production URL.
> PUBLICATION REQUIREMENT: must be hosted at a stable HTTPS URL and
> registered in the app's LegalConfig (lib/core/constants/legal_config.dart)
> — the app fails closed (AI features disabled) until these URLs exist.

Last updated: [DATE]

## 1. Who we are
Spark Lingo ("the App") is a language-learning application. Contact for
privacy matters: abulithbisha@gmail.com.

## 2. What data we collect and why

| Category | What | Purpose | Verified in code |
|----------|------|---------|------------------|
| Account | Email address and display name when you sign in with Google; anonymous guest ID if you explore without signing in | Authentication, saving progress | auth_service.dart, Supabase Auth |
| Learning progress | Lesson completions, card review history, XP, streaks, practice scores | Spaced-repetition scheduling, progress display | database_service.dart, migrations 001/014/015 |
| AI interactions | Chat messages with the Sparky AI tutor; chat session history | AI tutoring, conversation continuity | ai_service.dart, migrations 013 |
| Voice input | When you use voice input, audio is sent to our server for transcription | Converting speech to practice text | ai_service.dart transcribeAudio() |
| Purchases | Purchase entitlements processed by RevenueCat | Subscription status | revenuecat_service.dart, migration 009 |
| Analytics & crash reports | Firebase Analytics events (lesson_completed, card_reviewed, ai_lesson_requested) and Crashlytics crash reports — COLLECTED ONLY AFTER YOU OPT IN via the in-app analytics consent | Product improvement, stability | analytics_service.dart, telemetry_consent_service.dart |

## 3. What we do NOT collect
- No precise location data.
- No contacts, calendar, or health data.
- No advertising identifiers; no third-party ad SDKs.
- Analytics and crash collection starts DISABLED and remains off until a
  signed-in user grants consent recorded on our servers
  (telemetry_consent_service.dart — verified).

## 4. Consent
AI processing requires your consent, recorded server-side, before Sparky
AI features operate. Analytics/crash telemetry requires a separate
affirmative opt-in. You can withdraw consent; telemetry collection stops
and error handlers are removed from the running session.

## 5. Third parties
| Provider | Role | Data |
|----------|------|------|
| Supabase | Backend, database, authentication | Account + progress data (hosted ap-southeast-1) |
| Google Sign-In | Authentication | Email, name (per your Google permissions) |
| Google Gemini (via our server) | AI tutoring | Chat text you send |
| RevenueCat | Purchase processing | Purchase status |
| Firebase | Analytics/crashes (only after opt-in) | Aggregate events, crash reports — no Supabase user ID is linked |

## 6. Your rights
- Access: your progress and chat history are visible in the app.
- Deletion: deleting your account (Settings → Delete account) permanently
  removes your account AND all associated data — every user-data table is
  linked with ON DELETE CASCADE (verified in migrations 001–015).
- Contact: abulithbisha@gmail.com for any privacy request.

## 7. Security
All data travels over HTTPS/TLS. AI endpoints validate your session token
and enforce per-user rate limits (migration 005). Secrets are server-side
only; no service credentials ship in the app.

## 8. Children
The app does not knowingly collect data from children under 13. [Counsel:
confirm age-gating/parental consent requirements for target markets.]

## 9. Changes
Material changes will be announced in-app before taking effect.
