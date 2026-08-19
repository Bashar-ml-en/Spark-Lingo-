# Google Play Submission Checklist (current as of Aug 2026)

## Technical requirements
- [ ] **Target API level**: New apps and updates must target **Android 16
      (API level 36)** starting **August 31, 2026** to be submitted. If
      you submit before that date, Android 15 (API level 35) is the
      current floor. An extension to November 1, 2026 can be requested
      in Play Console if you need it — don't rely on it as your primary
      plan.
- [ ] Signed Android App Bundle (`.aab`), Play App Signing enabled.
- [ ] 64-bit support (required — Play Console blocks 32-bit-only
      submissions).
- [ ] All permissions requested (microphone, notifications) have a
      clear runtime rationale shown before the OS prompt.

## Store listing
- [ ] App title (≤30 chars), short description (≤80 chars), full
      description (≤4000 chars).
- [ ] Feature graphic (1024x500), min 2 phone screenshots, tablet
      screenshots if you support tablet layouts (you do — 810px
      breakpoint).
- [ ] Screenshots reflect actual per-language theming — show at least
      3-4 different `LanguageTheme` variants, not just English.
- [ ] Content rating questionnaire completed accurately (AI-generated
      speech feedback, user-generated audio recordings, account
      creation are all relevant disclosures).

## Data Safety section
- [ ] Declare: account info (email/OAuth), audio recordings (speaking
      practice), app activity (SRS/progress data), and any analytics/
      crash data (Firebase Crashlytics).
- [ ] State whether data is encrypted in transit (yes, via Supabase/
      HTTPS) and whether users can request deletion (must be yes — add
      account deletion in Settings if not already present, this is a
      hard Play Store requirement for apps with account creation).

## Policy compliance
- [ ] Privacy policy URL live and accessible (see
      `privacy_policy_template.md`).
- [ ] No deceptive paywall patterns (fake countdown timers, pre-checked
      subscription boxes) — Google actively enforces against these.
- [ ] If targeting children/families category: additional Families
      Policy requirements apply and are stricter — only pursue this if
      the app is genuinely designed for it; general-audience language
      learning is the more accurate category for Spark Lingo as
      currently scoped.

## Pre-submission testing
- [ ] Internal testing track → closed testing track with real external
      testers before production release.
- [ ] Test the full purchase flow on the Play Console test track (not
      just RevenueCat sandbox in isolation).
