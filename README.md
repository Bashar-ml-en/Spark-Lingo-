# Spark Lingo

Spark Lingo is a Flutter language-practice application with guided curriculum,
spaced repetition, recoverable-account AI conversation, and optional
store-managed premium access.

The repository is for a controlled beta until the production gate in
[`docs/PRODUCTION_GATE.md`](docs/PRODUCTION_GATE.md) is complete. It must not
be marketed as a full exam-preparation service, a human-accent audio product,
or a 10M-user platform until the corresponding content and operational evidence
exists.

## Architecture

- Flutter/Riverpod client for Android, iOS, and web.
- Supabase Auth/Postgres for identity, curriculum, learner state, and
  server-side AI usage accounting.
- Supabase Edge Functions for authenticated AI and account deletion. Provider
  secrets live only in Edge Function secrets.
- RevenueCat for store-verified entitlements; the client has no authority to
  grant premium access.
- Firebase Analytics/Crashlytics for mobile telemetry when configured.

## Local development

1. Install a Flutter SDK compatible with the SDK constraint in `pubspec.yaml`.
2. Run `flutter pub get` and then `flutter run`.
3. Start a local Supabase project and apply the versioned migrations. A local
   reset may be used only for disposable development data; never reset a shared
   or production project.
4. Copy `supabase/.env.example` to an ignored local environment file and supply
   only non-production development values before serving Edge Functions.

The mobile application uses the public Supabase project key and per-user
session tokens. Do not add `.env` to Flutter assets or put OpenAI, Supabase
management/service-role, signing, or RevenueCat secret keys in the app.

## Build configuration

Supabase has no source-embedded production URL or client key. Every mobile
build must explicitly select `development`, `staging`, or `production` and its
matching Supabase target with `--dart-define`; an incomplete or cross-target
configuration fails closed at app startup. The exact value contract, local,
staging, production, and CI command patterns are in
[`docs/release/MOBILE_BUILD_CONFIGURATION.md`](docs/release/MOBILE_BUILD_CONFIGURATION.md).

RevenueCat public SDK keys and the public legal URLs are provided at build time,
not from a bundled environment file. They are necessary but **not sufficient**
for billing: the server-owned billing runtime control starts disabled, and the
RevenueCat webhook must be deployed, HMAC-authenticated, lifecycle-tested, and
explicitly approved before any package can be offered. An absent or non-HTTPS
legal URL, anonymous account, unavailable server control, or incomplete billing
configuration leaves purchases and restoration unavailable rather than charging
users against an unconfigured project. Use only live, approved HTTPS endpoints
in protected release configuration; never copy example or placeholder URLs into
a distributable build.

```text
--dart-define=REVENUECAT_APPLE_KEY=appl_...
--dart-define=REVENUECAT_GOOGLE_KEY=goog_...
--dart-define=TERMS_OF_SERVICE_URL=<approved HTTPS Terms URL>
--dart-define=PRIVACY_POLICY_URL=<approved HTTPS Privacy URL>
```

The public Settings & help screen additionally supports approved HTTPS links
for support, external account deletion, data export, and subscription help.
See [`docs/LEGAL_LINK_CONFIGURATION.md`](docs/LEGAL_LINK_CONFIGURATION.md)
for the full release configuration and verification requirements.

Before testing OAuth on a device, register
`io.supabase.sparklingo://login-callback` with Supabase and the identity
provider. Before testing production web OAuth, add each exact deployed HTTPS
redirect URL in the Supabase project settings. OAuth buttons are hidden by
default; enable each only after this setup and device testing with
`--dart-define=ENABLE_GOOGLE_OAUTH=true` and, on iOS where applicable,
`--dart-define=ENABLE_APPLE_OAUTH=true`.

## Quality gates

GitHub Actions runs secret scanning, Flutter formatting/analysis/tests/builds,
Edge Function type checks, and a disposable Supabase migration/seed smoke test.
Run the equivalent checks locally before opening a release pull request:

```text
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
deno check supabase/functions/sparky-ai/index.ts
deno check supabase/functions/delete-account/index.ts
deno check supabase/functions/revenuecat-webhook/index.ts
deno check scripts/staging_security_smoke.ts
supabase start
supabase db reset --local
```

See [`docs/PRODUCTION_GATE.md`](docs/PRODUCTION_GATE.md) for the mandatory
security, legal, billing, data, and scale-release steps that source code alone
cannot complete. AI runtime-control, safe telemetry, and kill-switch
procedures are documented in [`docs/AI_OPERATIONS.md`](docs/AI_OPERATIONS.md).
The accountable release plan and evidence tracker are in
[`docs/release/GO_LIVE_EXECUTION_PLAN.md`](docs/release/GO_LIVE_EXECUTION_PLAN.md)
and [`docs/release/RELEASE_TRACKER.md`](docs/release/RELEASE_TRACKER.md).
