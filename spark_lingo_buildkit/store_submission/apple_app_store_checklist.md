# Apple App Store Submission Checklist (current as of Aug 2026)

## Privacy manifest (required since May 1, 2024 — still enforced)
- [ ] `PrivacyInfo.xcprivacy` present in the app bundle, declaring every
      "required reason API" your code or SDKs use (file timestamp APIs,
      user defaults, disk space, active keyboard, system boot time are
      the common categories that trip apps up).
- [ ] Every third-party SDK (Supabase client, Firebase, RevenueCat,
      any ad/analytics SDK) supplies its own `PrivacyInfo.xcprivacy` —
      check each vendor's current docs; missing SDK manifests are a
      frequent rejection (`ITMS-91053: Missing API declaration`).
- [ ] Run Xcode's built-in Privacy Report before archiving to catch
      undeclared API usage.

## Permissions
- [ ] `NSMicrophoneUsageDescription` — specific, honest reason text
      (Sparky speaking practice), not generic boilerplate.
- [ ] Any other permission strings (notifications, etc.) equally
      specific.

## Sign-in
- [ ] If Google/social OAuth is offered, **Sign in with Apple must also
      be offered** as an equivalent option — this is one of Apple's
      most consistently enforced rules for apps with third-party login.

## App Store Privacy labels (Nutrition Label)
- [ ] Complete accurately in App Store Connect — must match what
      `PrivacyInfo.xcprivacy` and your actual data practices say. These
      two must not contradict each other; reviewers do check.
- [ ] Data deletion: apps with account creation must provide in-app
      account + data deletion, not just "contact support to delete."

## App Tracking Transparency
- [ ] If any cross-app/cross-site tracking occurs (most ad SDKs, some
      attribution SDKs), the ATT prompt must be implemented — audit
      RevenueCat/analytics config for whether this applies to you.

## Content & guidelines
- [ ] AI-generated speaking/writing feedback: be accurate in metadata
      about AI use — Apple's guidelines require disclosure of
      AI-generated content where relevant to app function.
- [ ] Subscription terms clearly disclosed in the paywall UI itself
      (price, billing period, auto-renewal terms) — not just in a
      linked terms page.
- [ ] Restore Purchases button present and functional.

## Submission process
- [ ] TestFlight beta with external testers before public submission.
- [ ] Archive validated in Xcode, uploaded via Xcode or Transporter.
- [ ] Full localized screenshots per language you're launching with,
      showing actual in-app per-language theming.
- [ ] Age rating questionnaire completed — account creation, user-
      generated audio, and AI-generated feedback are all relevant to
      answer accurately.
