# Prompt 08 — Monetization & Paywall

Run after Prompt 07 — deliberately late, so the paywall is gating a real
product, not an empty shell.

---

**Build:**

1. Finish wiring `monetization_service.dart` to production RevenueCat
   keys (leave placeholders clearly marked `# TODO: insert prod key`
   rather than committing real keys to the repo — these belong in
   environment config / CI secrets, not source).

2. Tiers:
   - **Free**: SRS + basic Sparky correction, one placement test per
     language, limited mock-exam attempts per week (tie into the rate
     cap from Prompt 06).
   - **Premium (subscription)**: unlimited mock exams, full AI
     rubric-scored speaking/writing feedback, exam-readiness dashboard
     history beyond the last 3 attempts, offline audio download.
   - Optional **exam-specific bundle** (one-time purchase): full mock
     exam bank for a single exam (e.g. "IELTS Complete Prep") — useful
     for users who only care about one certification and don't want a
     recurring subscription.

3. Paywall screen: trigger it at natural gates (end of placement test →
   "see your full readiness breakdown", attempting a 2nd mock exam in
   free tier) rather than interrupting a lesson mid-flow. Apple and
   Google both flag paywalls that block core navigation or use
   countdown-timer urgency that resets on every visit — keep the copy
   honest about what's free vs. paid, no dark patterns.

4. Restore purchases flow (required by both stores) and a visible
   "Manage subscription" link to the platform's native subscription
   management screen from Settings.

**Verify:** complete a full sandbox purchase (App Store Connect
sandbox tester / Google Play test track) for both a subscription and
the one-time bundle, and confirm entitlements unlock the right features
and restore correctly on a fresh install with the same account.
