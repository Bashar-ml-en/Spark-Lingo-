# Spark Lingo — Evaluation, State & Roadmap

_Last verified: 2026-08-24, commit 3274770 (origin/main in sync). Every label below was verified against the working tree, not assumed._

## A. Project state at a glance

| Area | Status | Evidence |
| --- | --- | --- |
| Flutter app source | DONE | 42 Dart files under lib/ (splash, onboarding, home+study loop, exam prep, paywall, settings) |
| Curriculum content | DONE | assets/curriculum/syllabus_master.json — 15 languages × 10 units × 50 lessons × 600 cards = 9,000 cards (verified by script) |
| Backend schema | DONE | supabase/migrations/ 001–012 (core schema, exams, security/quotas, billing, error patterns) |
| Edge functions | DONE | sparky-ai (provider-agnostic AI gateway + tests), delete-account, revenuecat-webhook |
| Unit/widget tests | DONE | 44/44 passing (flutter test, 2026-08-24); flutter analyze: 0 issues |
| CI | DONE | .github/workflows/: quality, release-android, staging-deploy, staging-security-smoke |
| Web test deployment | DONE | https://spark-lingo.vercel.app live (HTTP 200); vercel.json SPA fallback committed |
| Supabase project | EXISTS | dioisitgohusggmwowft — single shared project; separate staging project NOT provisioned (ENV-001 blocked, HUMAN-ONLY) |
| Native audio (CC0) | MISSING | assets/audio/ contains only .gitkeep; Mozilla Common Voice subscription registered (HTTP 200) but tarball not yet received (CONT-002, HUMAN-ONLY) |
| Live legal URLs | MISSING | No TERMS/PRIVACY dart-defines in any build script; LEG-001 blocked on counsel-approved HTTPS URLs (HUMAN-ONLY) |
| Store accounts | MISSING | Google Play / App Store checklists exist in archive/ but no accounts/console wired (HUMAN-ONLY) |

## B. What was fixed today (this session, verified)

1. legal_config.dart — removed hardcoded fallback URLs to the dead domain sparklingo.app (000 HTTP) that silently satisfied hasRequiredPurchaseLinks, violating the documented fail-closed design and failing legal_config_test.dart:37. Purchases now gate on real build-time policy URLs again.
2. settings_screen.dart — removed the sparklingo.app host hack; in-app legal viewer now shows reviewed draft text clearly labelled "DRAFT — review copy only" when no HTTPS endpoint is configured.
3. analytics_service.dart — removed unused import (last flutter analyze warning).
4. Deleted stray repo-root file `-w` (accidental artifact; contained a Vercel 404 page body).
5. Re-verified: flutter analyze = 0 issues; flutter test = 44/44 pass; SDK restored to C:\flutter (3.44.4 stable).

## C. Roadmap — remaining steps, in dependency order

### Phase 1 — Engineering (AGENT-DOABLE, no external blockers)
1. **Rebuild & redeploy web test build** — `flutter build web --release` with the six dart-defines, copy vercel.json into build/web, `vercel deploy build/web --prod`. (Deploy step is HUMAN-ONLY without a logged-in Vercel CLI; project already linked: prj_5TPNlIQdcx2ExZjqtBgQQ5ygLPqm, alias spark-lingo.vercel.app.)
2. **Staging smoke re-run** — .github/workflows/staging-security-smoke.yml against the shared project (dedicated staging project still blocked on ENV-001).
3. **Load report** — run scripts/simulate_1k_beta_load.ts at 2× peak; attach report for SCALE-001.
4. **Retention purge test** — run scripts/verify_retention_purge.ts for OPS-001 agent-side evidence.

### Phase 2 — Human-only unlocks (blockers you must do, Bashar)
5. **ENV-001**: create a dedicated STAGING Supabase project; give its ref to CI. Until then staging tests share production project dioisitgohusggmwowft.
6. **SEC-001 completion**: finish PAT revocation + OpenAI key rotation in dashboards.
7. **LEG-001/LEG-002**: counsel-reviewed Terms/Privacy/AI-notice on a real HTTPS domain; then add `--dart-define=TERMS_OF_SERVICE_URL=... --dart-define=PRIVACY_POLICY_URL=...` to the release build command. Until then purchases stay correctly disabled (fail-closed).
8. **CONT-002**: confirm the Mozilla Common Voice email for abulithbisha@gmail.com, download the tarball, then the agent can run the audio-match pipeline (CC0 files only; ~99% of Tatoeba audio is CC-BY-NC and unusable).
9. **AI-001**: provider budget alerts + CAPTCHA in the hosted dashboards.
10. **BILL-001**: RevenueCat sandbox purchases + webhook signature verification, then set the three REVENUECAT_* function secrets.

### Phase 3 — Launch (after Phase 2 unlocks)
11. Signed Android app bundle from the release tag (release-android.yml), Play Console internal track.
12. iOS build needs macOS signing prerequisites — no Mac on this machine; flag as external.
13. GO_LIVE_EXECUTION_PLAN.md gates: PROD-002 provenance check, SCALE-001 sign-off, LEG-001 live.

## D. Known risks / honest gaps

- **No native-speaker audio yet** — TTS (flutter_tts) is the current voice path; Common Voice CC0 audio is the plan but unfulfilled.
- **15 languages × 600 cards are Tatoeba CC-BY sentence pairs**, machine-QA'd (CONTENT_REVIEW_RECORD.md: 7,997 clean of 8,000). Native-speaker sign-offs (CONT-001) are still outstanding for all languages.
- **Single Supabase project** for dev/staging/prod is the biggest architectural risk until ENV-001 lands.
- **49 packages have newer versions** (pub outdated) — none breaking; upgrade after launch, not before.
- The cached git token can read+push but cannot delete Actions artifacts (401) — artifact cleanup is HUMAN-ONLY.
