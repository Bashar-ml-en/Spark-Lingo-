# Worktree classification before the first release commit

This is a review aid, not permission to bulk-add the worktree. The engineering
lead must verify every changed path, run secret scanning on source *and
archives*, and split unrelated work into reviewable pull requests.

| Path/group | Initial classification | Required decision/evidence |
| --- | --- | --- |
| `lib/`, `test/`, `pubspec.*`, platform manifests, `web/` | Candidate application source | Code review, CI, device test results |
| `supabase/migrations/`, `supabase/functions/`, `supabase/config.toml` | Candidate backend source | Ordered migration review, local reset, staging migration/RLS/function evidence |
| `.github/`, `.gitleaks.toml`, `scripts/` | Candidate delivery controls | Review workflow permissions/tool versions; green CI from PR |
| `docs/`, `docs/release/` | Candidate release documentation | Named owners, live evidence links, legal review where applicable |
| `assets/`, `content_pipeline/` | Candidate content/assets | Licence/attribution inventory, reviewer approval, build validation |
| `spark_lingo_buildkit/`, `spark_lingo_pipeline/` | Unclassified design/pipeline material | Product/content owner must decide whether each file is source-of-truth; do not ship samples, prompts, or store copy without review |
| `spark_lingo_buildkit.zip`, `spark_lingo_pipeline.zip` | Archive copies, not release source | Scan without extracting into the repository; retain only in approved artifact storage if needed |
| `android/build/`, `temp_buildkit/` | Generated/local verification output | Keep ignored; regenerate from CI, never commit |
| `jdk/`, `jdk.zip` | Local toolchain/download | Keep ignored; pin and provision CI toolchains independently |
| `android/key.properties` | Local signing configuration | Must remain ignored; signing keys stay in managed CI/store signing, never inspect/commit values |

## Required review sequence

1. Create a candidate file list with a reason and reviewer for each group.
2. Secret-scan the Git history, candidate source, generated artifacts, and
   archives using protected tooling; record only the sanitized result.
3. Split product code, migrations, content, and CI/release controls into small
   reviewable pull requests where practical.
4. Confirm no build output, local JDK, signing material, copied archives, or
   secret-bearing configuration is staged.
5. Require a clean worktree and green protected-branch CI before creating the
   annotated release tag and manifest.

## 2026-08-19 PR-hygiene inventory (path-only)

This is an exhaustive classification by worktree group at the time of review.
It records filenames and metadata only; it does not inspect secret values or
make any claim that a candidate group is safe to release. Re-run the commands
below immediately before staging a pull request because this worktree is shared
and changes over time.

### Candidate application or delivery source — review and stage selectively

| Group | Snapshot count | Required review before staging |
| --- | ---: | --- |
| Modified tracked files in `.gitignore`, `README.md`, `pubspec.*`, `android/`, `ios/`, `lib/`, `test/`, and `web/` | 52 | Functional review, dependency review, formatting/tests, and platform/device validation as applicable |
| `.github/` | 4 | Pin actions, restrict workflow permissions, protect environments, and obtain green CI from a PR |
| `.gitleaks.toml` | 1 | Verify it extends defaults and detects the current secret-key formats |
| New Android resources | 14 | Asset provenance, density coverage, and Android build/device review |
| `assets/` | 44 | Font/image/SVG licence and attribution review; confirm only intended runtime assets are declared in `pubspec.yaml` |
| `content_pipeline/` | 3 | Data-source licence, rate-limit, and output-review controls; retain only the `.gitkeep` under `output/` until content is approved |
| `docs/` and `docs/release/` | 18 | Named owners and evidence links; legal text needs legal-owner approval, not engineering approval |
| New iOS resources | 8 | Asset provenance, Xcode project review, and physical-device validation |
| New `lib/` source | 30 | Code review, unit/widget tests, privacy/security review, and app build validation |
| `scripts/` | 10 | Confirm staging-only guardrails, non-production defaults, and no credential material in examples/logs |
| `supabase/` | 19 | Ordered migration review, secret scan, local reset, then staging-only deployment/RLS/function tests |
| `test/` | 7 | Execute through Flutter CI; review coverage for changed security boundaries |
| `web/` | 8 | Asset provenance, web build validation, manifest/privacy review |

### Hold out of the first release PR until a named owner decides

| Group | Snapshot count | Classification |
| --- | ---: | --- |
| `spark_lingo_buildkit/` | 19 | Design prompts, growth material, templates, and store/legal draft material; not runtime release source by default |
| `spark_lingo_pipeline/` | 6 | Sample curriculum/pipeline material; requires product, content-rights, and claims review before any selective source commit |

Do not hide these directories with `.gitignore`: their existence requires an
explicit owner decision. Do not stage them with a blanket `git add .`.

### Must remain ignored and never be staged

| Group | Snapshot count | Reason |
| --- | ---: | --- |
| `.dart_tool/`, `.flutter-plugins-dependencies`, `.idea/`, `spark_lingo.iml` | 31 | Local Flutter/IDE state |
| `build/` | 59 | Generated build output; may carry stale runtime configuration and must be regenerated from clean source |
| `android/.gradle/` and Android generated/signing paths | 33 | Local Gradle output and private signing material |
| iOS generated support paths | 9 | Pods/Flutter/generated local state |
| `jdk/`, `jdk.zip` | 489 | Downloaded local toolchain, not pinned release source |
| `temp_buildkit/` | 19 | Temporary local material |
| Supabase local temporary state | 1 | Local CLI/runtime state |
| `spark_lingo_buildkit.zip`, `spark_lingo_pipeline.zip` | 2 | Local archive copies; scan and retain outside the repository if needed |

The root ignore rules explicitly exclude local Android build directories,
mobile package formats, private signing-file formats, and the two local archive
copies. No tracked path matched those new ignore patterns at the time of this
review. Ignore rules reduce accidental staging only; protected CI secret scans
and reviewer inspection remain mandatory.

### Candidate PR groups

1. **Release controls:** `.gitignore`, `.gitleaks.toml`, `.github/`, release
   scripts, and release-operation documentation. Require CI workflow review.
2. **Backend security:** `supabase/`, the related Flutter service/config/test
   changes, and security-operation docs. Require a migration/RLS/Edge Function
   review before any staging deployment.
3. **Application and platform UX:** remaining `lib/`, `test/`, `android/`,
   `ios/`, `web/`, `pubspec.*`, and runtime assets. Require licence and device
   evidence.
4. **Content tooling/material:** `content_pipeline/` only after rights review.
   Keep `spark_lingo_buildkit/` and `spark_lingo_pipeline/` out unless their
   owners explicitly promote selected files into a separately reviewed change.

### Required final pre-PR check

Run `git status --porcelain=v1 --untracked-files=all`, review each intended
path with `git diff --check`, run the configured secret scanner on source and
archives using protected tooling, and stage named paths only. A pull request is
not ready if any ignored build, signing, archive, temporary, or local-state
path appears in its file list.
