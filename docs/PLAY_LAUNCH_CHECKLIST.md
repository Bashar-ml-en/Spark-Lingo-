# Google Play — launch checklist for Spark Lingo

Generated 2026-08-28 from a live audit of the repo + environment.
Mark items [x] as they are completed. HUMAN = needs the account owner.

## A. Build & signing  (owner: agent, this machine)
[x] Android SDK installed (platforms 35/36, build-tools 36)
[x] Upload keystore generated: android/upload-keystore.jks
    - RSA-2048, validity 10000 days (~27 years — never expires mid-app-life)
    - Passwords: android/key.properties (git-ignored, verified with `git check-ignore`)
    - SHA1: 8F:3C:FE:64:84:E5:E3:DF:8D:95:45:B1:B7:99:E3:05:09:A7:F6:CD
[ ] First signed AAB produced & upload verified  <- running now
[ ] Play App Signing enrollment (HUMAN, during first upload — accept Google
    re-signing; back up NOTHING extra, but note the app-signing cert in the
    Console for future OAuth SHA-1)

## B. Google OAuth for the Android app (see ANDROID_GOOGLE_OAUTH_HANDOFF.md)
[ ] HUMAN: create ANDROID-type OAuth client in the "Spark Lingo" Google
    Cloud project with package com.sparklingo.spark_lingo + upload SHA-1
[ ] HUMAN: after Play App Signing, add second client with the PLAY
    app-signing SHA-1 (Play Console -> Setup -> App signing)
[ ] Agent: verify sign-in on a signed release build

## C. Play Console setup (HUMAN, needs Google Play developer account $25 one-time)
[ ] Create app listing (title ≤30 chars, short desc ≤80, full desc ≤4000)
[ ] App icon 512x512 + feature graphic 1024x500 + ≥2 phone screenshots
[ ] Content rating questionnaire (educational — expect Everyone/Teen)
[ ] Target audience & teacher-approved program (if marketing to under-18)
[ ] Ads declaration: NO ads
[ ] Data safety form — use the answers below
[ ] Testing track: internal testing with ≥1 tester email before production

## D. Data safety form — draft answers (verified against the codebase)
- Does the app collect/share user data? YES — collects:
  * Account info: email (Google sign-in), anonymous user id
  * Learning progress: card review states, lesson completions, XP/streaks
  * AI conversations: chat messages with Sparky (stored to provide the service)
- Shared with third parties? NO (Supabase is the processor, not a recipient
  of shared data for their purposes — verify Supabase DPA wording)
- Is data encrypted in transit? YES (HTTPS everywhere — enforced by
  LegalConfig.parseSecureWebUri + Supabase/TLS)
- Can users request deletion? YES — in-app account deletion exists
  (home drawer -> Delete account; confirm it deletes profile + reviews)
- Voice data: TTS audio is generated client-side by the OS speech engine;
  no audio is recorded or uploaded (mic permission declared but the current
  speech practice does NOT record — re-verify before submission; if unused,
  consider removing RECORD_AUDIO)

## E. Legal gates (HUMAN — LEG-001)
[ ] Privacy policy drafted, counsel-reviewed, hosted at HTTPS URL
[ ] Terms of service drafted, counsel-reviewed, hosted at HTTPS URL
[ ] Agent: register consent document server-side (consent_documents table)
    and rebuild with PRIVACY_POLICY_URL / TERMS_OF_SERVICE_URL defines
[ ] Decision: ENABLE_TEST_CONSENT must be OFF in store builds (it already is
    by default — store builds never pass the flag)

## F. Pre-submission QA (HUMAN + agent)
[ ] Install the release build on a physical Android phone (MOB-001)
[ ] Smoke test: Google sign-in, pick language, full lesson cycle, Sparky chat
[ ] Rotate the Google OAuth client secret (leaked in earlier chat history)
[ ] Remove old PAT / revoke (SEC-001)

## What is NOT a blocker (already compliant)
- App fails CLOSED on missing legal config — no fabricated consent
- RECORD_AUDIO has a purpose string (Android) + NSMicrophoneUsageDescription (iOS)
- No analytics SDKs configured -> minimal data collection surface
