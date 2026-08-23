# SEC-002 evidence: full-history secret scan (gitleaks 8.18.4)

Scan date: 2026-08-23 (MYT)
Scanner: gitleaks 8.18.4 (`gitleaks detect` over full git history, .gitleaksignore honoured)
Scope: repository history (55 commits scanned). Release artifacts require authenticated GitHub access and are tracked separately below.

## Result: no live secrets found

All 5 findings are PUBLIC-BY-DESIGN client identifiers already listed in `.gitleaksignore`:

| Rule | File | Commit | Classification |
| --- | --- | --- | --- |
| gcp-api-key | `.gitleaksignore` line 4 | 8a10ca0f | public Firebase web API key (client identifier, not a secret) |
| gcp-api-key | `lib/firebase_options.dart` line 26 | 793139c5 | public Firebase web API key (client identifier, not a secret) |
| gcp-api-key | `lib/firebase_options.dart` line 36 | 793139c5 | public Firebase web API key (client identifier, not a secret) |
| gcp-api-key | `lib/firebase_options.dart` line 44 | 793139c5 | public Firebase web API key (client identifier, not a secret) |
| generic-api-key | `lib/core/constants/supabase_config.dart` line 3 | 010d9bc7 | public Supabase publishable key (by design in mobile client) |

Independent history checks (every commit, `git grep`):
- OpenAI `sk-` keys: 0 occurrences
- GitHub PATs (`ghp_`/`github_pat_`): 0 occurrences
- Supabase service-role key values (`sbp_…` literals): 0 occurrences (the only `sbp_` strings are detection rules inside `.gitleaks.toml`)
- JWT-format secrets (eyJ… with 30+ char body): 0 occurrences
- Hardcoded password values: 0 occurrences

## Open items (HUMAN-ONLY)
- Confirm OpenAI key revocation + PAT revocation records in provider dashboards (SEC-001).
- 35 GitHub Actions artifacts (historical APKs + gitleaks SARIFs) need authenticated byte-level scan or deletion — public API exposes names/sizes only.
- Rotate any credential that ever shipped inside a historical APK before the JWT-secret rotation noted in the tracker.
