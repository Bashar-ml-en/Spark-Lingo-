# Spark Lingo mobile-store release checklist

Every item needs an evidence link before submitting to Apple or Google.

## Build and signing

- [ ] Immutable source tag and green CI run.
- [ ] Android signed AAB built from protected signing infrastructure.
- [ ] iOS signed archive/IPA built from protected signing infrastructure.
- [ ] Build number/version match release manifest.
- [ ] Crash symbol files uploaded to crash-reporting service.
- [ ] No debug endpoints, staging keys, test products, or hidden developer
      controls in the production artifact.

## Device validation

- [ ] Android physical-device test: onboarding, auth, callback, microphone,
      AI, SRS, deletion, legal links, network loss/retry.
- [ ] iOS physical-device test: same path plus Sign in with Apple when enabled.
- [ ] Large text, TalkBack/VoiceOver, keyboard, RTL, and microphone-denial
      recovery tests.
- [ ] Purchase/restore/cancellation/refund test only after billing is approved.

## Apple submission

- [ ] Privacy nutrition labels completed from approved data map.
- [ ] Account-deletion flow tested in-app.
- [ ] If a third-party social login is enabled for primary authentication,
      equivalent Apple-compliant sign-in option is enabled/tested.
- [ ] Review notes, demo account or full demo mode, and required test resources
      are supplied.
- [ ] Terms, privacy, support, and age-rating information are accurate.

## Google Play submission

- [ ] Data Safety form completed from approved data map.
- [ ] Privacy Policy linked in Play Console and available in-app.
- [ ] Public external deletion/request URL entered and tested.
- [ ] In-app account deletion route tested.
- [ ] Content rating, target audience/age, ads declaration, and permissions are
      accurate.
- [ ] Internal testing track completes before wider rollout.

## Rollout

- [ ] TestFlight and/or Play internal-testing approval obtained.
- [ ] Release manager, incident commander, support owner, and rollback owner
      are named.
- [ ] Staged rollout percentage and pause thresholds are documented.
- [ ] Monitoring dashboards and alert routes are verified during rollout.
- [ ] A rollback/feature-disable rehearsal has passed.
