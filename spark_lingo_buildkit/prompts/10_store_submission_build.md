# Prompt 10 — Store Submission Build Configuration

Run last, once Prompts 01-09 are complete and QA-passed. This stage
prepares the actual submittable builds — cross-reference every step
against `store_submission/google_play_checklist.md` and
`store_submission/apple_app_store_checklist.md`, which have the
authoritative, current platform requirements.

---

**Android build:**

1. Set `targetSdkVersion 36` (Android 16) in `android/app/build.gradle`
   — required for all new app submissions to Google Play starting
   August 31, 2026 (see checklist for the exact current rule and any
   extension deadline).
2. Generate a proper Android App Bundle (`.aab`, not `.apk`) signed with
   a release keystore — set up Play App Signing if not already done.
3. Complete the Play Console **Data Safety** section accurately: this
   app collects account info (auth), user-generated audio (speaking
   practice), and progress data — declare all of it, don't
   under-declare to look more privacy-friendly than the app actually is.
4. Generate real device launcher icons per the existing pubspec
   config (gap flagged in your original project doc) — run
   `flutter_launcher_icons` or equivalent, verify on-device, not just in
   the emulator.

**iOS build:**

1. Add `PrivacyInfo.xcprivacy` (created as a stub in Prompt 01) with
   actual required-reason API declarations for every SDK you use
   (Supabase client, Firebase Crashlytics, RevenueCat, any analytics) —
   pull each SDK's own privacy manifest where they provide one rather
   than guessing at required-reason categories.
2. Native permission strings: `NSMicrophoneUsageDescription` (Sparky
   speaking practice) must describe the actual reason ("Spark Lingo uses
   your microphone to let you practice speaking and get pronunciation
   feedback"), not a generic placeholder — vague strings are a common
   rejection reason.
3. Configure Sign in with Apple if Google OAuth is offered as a sign-in
   option — Apple requires an equivalent Apple sign-in option in that
   case.
4. Archive and validate in Xcode before submitting to App Store
   Connect; run through TestFlight with at least a few external
   testers first.

**Both platforms:**

1. Publish the privacy policy (`store_submission/privacy_policy_template.md`
   as the starting draft) at a real, stable public URL and link it in
   both store listings.
2. Prepare localized store listings (title, subtitle/short description,
   full description, screenshots) for at least the languages you're
   launching with — screenshots should show the actual per-language
   theming from Prompts 02-04, not just English screens with translated
   captions pasted over them.
3. Set an accurate age rating / content rating questionnaire — AI
   speaking/writing feedback and user-generated audio content are
   relevant disclosures on both platforms' rating questionnaires.

**Verify:** a clean release build installs on a physical device (not
just simulator/emulator) for both platforms, completes the full user
journey without crashing, and every checklist item in
`store_submission/` is checked off before you hit submit.
