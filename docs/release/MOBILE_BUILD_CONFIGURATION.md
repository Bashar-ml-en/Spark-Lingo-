# Mobile build configuration boundary

Spark Lingo has no built-in Supabase URL, client key, project reference, or
default environment. Every client build must explicitly supply its deployment
target using Flutter `--dart-define` values. A missing, malformed, or
cross-environment configuration displays the unavailable screen instead of
initializing Supabase.

This is a deployment guard, not an authorization mechanism. The mobile
publishable key is visible in a shipped app by design; database access remains
protected by Supabase Auth, RLS, Edge Function authorization, rate limits, and
server-side runtime controls. Never pass a Supabase secret/service-role key,
management token, OpenAI key, signing credential, or RevenueCat secret through
`--dart-define`.

## Required values

| Build value | Allowed values / format | Where it belongs |
| --- | --- | --- |
| `SPARK_LINGO_ENV` | `development`, `staging`, or `production` | Explicit command or protected CI environment |
| `SUPABASE_DEPLOYMENT` | `local` or `hosted` | Explicit command or protected CI environment |
| `SUPABASE_URL` | Local HTTP endpoint for local development, or `https://<project-ref>.supabase.co` for hosted builds | Explicit command or protected CI environment |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase **publishable** client key; never a secret key | Protected CI variable or build command |
| `SUPABASE_PROJECT_REF` | Hosted project reference; required for hosted builds | Protected CI variable |
| `SPARK_LINGO_PRODUCTION_PROJECT_REF` | Production project reference; required for hosted builds | Protected CI variable |

`SPARK_LINGO_PRODUCTION_PROJECT_REF` gives the client an explicit production
boundary: a staging or hosted-development build fails when its project matches
that reference, and a production build fails when it does not. It is a public
identifier, not a credential, but it should be controlled with the other
release configuration to prevent build mistakes.

## Enforced rules

- No value has a production default.
- A local deployment is valid only for `development`, uses HTTP, and is limited
  to loopback, emulator, or RFC1918 private IPv4 hosts.
- Staging and production must use hosted HTTPS projects.
- A hosted URL must exactly match `SUPABASE_PROJECT_REF`.
- Hosted builds accept only `sb_publishable_...` client keys; secret/server
  key formats are rejected.
- `staging` and hosted `development` must not use the production project.
- `production` must use the configured production project.
- A production-configured app must be a Flutter release build. Debug/profile
  builds show the unavailable screen even if production values were supplied.

No client-side check can protect a deliberately altered build. GitHub branch
protection, protected CI environments, code review, Supabase RLS, and server
authorization remain mandatory controls.

## Local development commands

Start a disposable local Supabase stack before running the app. Use the
Android emulator address in place of loopback when required; a physical device
may use a private LAN address only.

```text
flutter run \
  --dart-define=SPARK_LINGO_ENV=development \
  --dart-define=SUPABASE_DEPLOYMENT=local \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<local-public-client-key>
```

For PowerShell, use the same command on one line (or replace each trailing
backslash with PowerShell's backtick):

```powershell
flutter run --dart-define=SPARK_LINGO_ENV=development --dart-define=SUPABASE_DEPLOYMENT=local --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=<local-public-client-key>
```

Local builds intentionally do not require a production project reference:
their URL validation makes a hosted production endpoint invalid.

## Hosted staging commands

Use a separate staging Supabase project only. Do not paste any value into a
ticket, chat transcript, committed file, or shell history shared with others.
The publishable key below is a client value, but it should still be handled via
the approved CI/build configuration process.

```text
flutter build apk --release \
  --dart-define=SPARK_LINGO_ENV=staging \
  --dart-define=SUPABASE_DEPLOYMENT=hosted \
  --dart-define=SUPABASE_URL=https://<staging-project-ref>.supabase.co \
  --dart-define=SUPABASE_PROJECT_REF=<staging-project-ref> \
  --dart-define=SPARK_LINGO_PRODUCTION_PROJECT_REF=<production-project-ref> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<staging-publishable-client-key>
```

PowerShell equivalent:

```powershell
flutter build apk --release --dart-define=SPARK_LINGO_ENV=staging --dart-define=SUPABASE_DEPLOYMENT=hosted --dart-define=SUPABASE_URL=https://<staging-project-ref>.supabase.co --dart-define=SUPABASE_PROJECT_REF=<staging-project-ref> --dart-define=SPARK_LINGO_PRODUCTION_PROJECT_REF=<production-project-ref> --dart-define=SUPABASE_PUBLISHABLE_KEY=<staging-publishable-client-key>
```

Use the same six values for a staging iOS build, substituting `flutter build
ipa --release` after the iOS signing prerequisites are satisfied.

## Production release command pattern

Run a production build only from the approved immutable release tag, in the
GitHub `production` Environment, after the release manager grants a specific
production approval. Supply the production values through protected CI
variables, never a checked-in configuration file. The Android signing workflow
must produce an app bundle, not a debug APK.

```text
flutter build appbundle --release \
  --build-name=<approved-version> \
  --build-number=<approved-build-number> \
  --dart-define=SPARK_LINGO_ENV=production \
  --dart-define=SUPABASE_DEPLOYMENT=hosted \
  --dart-define=SUPABASE_URL=https://<production-project-ref>.supabase.co \
  --dart-define=SUPABASE_PROJECT_REF=<production-project-ref> \
  --dart-define=SPARK_LINGO_PRODUCTION_PROJECT_REF=<production-project-ref> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<production-publishable-client-key>
```

For iOS, use the same values with the signed `flutter build ipa --release`
workflow. Attach the exact command template, immutable tag, CI run URL, build
number, artifact hash, and configuration **names** (not values) to the release
record.

## CI requirements

The repository quality workflow now builds with synthetic local-only values.
Those values are deliberately unable to reach a hosted project and prove that
the code does not depend on a source-embedded production configuration.

Before a staging or production build is permitted, the release owner must:

1. Create separate GitHub `staging` and `production` Environments with required
   reviewers. Production must require the release manager’s approval.
2. Store the hosted build values as environment-scoped GitHub variables or the
   approved CI secret store. Do not place secret/server credentials there for
   use by the mobile build.
3. Keep the staging project reference distinct from the production project
   reference, then validate the release artifact on a physical device.
4. Add the signed Android/iOS build job only after signing material is in the
   approved secret store and its artifact provenance/SBOM step is reviewed.
5. Require green quality CI and the staging security-smoke workflow before a
   production build job can run.

## Evidence before release

- Screenshot or audited export of the two distinct Supabase project references
  (without secret values).
- CI log showing a staging build used `SPARK_LINGO_ENV=staging` and passed the
  configuration test.
- Physical-device proof that the staging artifact creates/authenticates only
  against staging.
- Protected production-environment approval, immutable tag, signed artifact,
  and artifact hash before any store upload.
