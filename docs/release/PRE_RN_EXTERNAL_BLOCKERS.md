# Pre–React Native external blockers and required evidence

Every item below requires a verified external system or physical device. None
may be marked complete from source review alone.

| Status | Owner/action required | Evidence needed before React Native implementation/cutover |
| --- | --- | --- |
| **BLOCKED — environment owner** | Create a dedicated Supabase staging project distinct from production; configure protected CI variables/secrets for its URL/project ref and production comparison values. | Project refs and URLs recorded in the protected environment; staging-target guard and non-destructive smoke run proving they differ. |
| **BLOCKED — security owner** | Rotate/audit any historically exposed OpenAI, Supabase Management, or other secret described in `PRODUCTION_GATE.md`. | Provider audit window reviewed, old credentials revoked, replacement-secret location confirmed without sharing secret values. |
| **BLOCKED — legal owner** | Publish counsel-approved HTTPS Terms, Privacy, AI/voice notice, support, export, deletion, and subscription-help pages. | Approved public URLs, legal version identifiers, store disclosure review, and configuration proof in protected environment. |
| **BLOCKED — GitHub administrator** | Create protected `production` Environment with required reviewers and add every required release secret plus the reviewed Flutter archive URL/SHA variables. | Environment policy screenshot/export and a deliberately incomplete dry run that fails before build; no secret values in evidence. |
| **BLOCKED — identity owner** | Register production OAuth redirects and test Google/Apple return paths. | Android and iOS physical-device recording for first sign-in, return, sign-out, recovery, and rejected redirect. |
| **BLOCKED — AI/security owner** | Configure approved AI provider models/secrets, exact web origins, global kill switch, cost alerts, CAPTCHA/WAF/rate controls before any anonymous-AI exception. | Staging evidence: anonymous denial, consent denial, accepted current consent, quota 429, kill-switch 503, origin rejection, and privacy-safe logs. |
| **BLOCKED — billing owner** | Configure RevenueCat products/entitlement and a signed webhook in a sandbox; keep server billing disabled until verified. | Signature rejection and valid lifecycle-event test, server entitlement update, purchase/restore tests on Android/iOS, and approved runtime-control audit record. |
| **BLOCKED — operations owner** | Rehearse backup/restore, retention purge, incident response, support path, load/cost testing, and RLS cross-user checks. | Dated runbooks and evidence from disposable/staging data, including recovery objective and escalation owner. |
| **BLOCKED — content owner** | Supply reviewed language content and licensed/native-speaker audio before exam/audio claims are enabled. | Versioned content manifest, license/attribution review, QA results, and clear capability/support matrix by language. |
| **BLOCKED — Firebase/architecture owner** | Confirm whether `firestore.rules` protects a deployed, still-used Firestore product. | Either documented project/feature/owner and deployment evidence, or explicit authorization and change record to remove the retired rule file. |
| **BLOCKED — QA owner** | Run accessibility and device matrix for Android/iOS/web retained scope. | TalkBack/VoiceOver, font scale/Dynamic Type, RTL, web zoom/keyboard, microphone denied/revoked, offline, OAuth, deletion, paywall, restore, and AI error-path results. |

## Release safeguard

The hardened repository deliberately fails a production Android build when
protected configuration is absent. That failure is expected until the GitHub
administrator has completed the environment item above; do not add fallback
values to bypass it.
