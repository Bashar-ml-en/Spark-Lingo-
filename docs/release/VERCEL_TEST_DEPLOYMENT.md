# Spark Lingo web test deployment (Vercel)

Deploys the compiled Flutter web app to Vercel for pre-store testing.

## Why this is not `vercel deploy .`

`build/` is gitignored by design. `vercel deploy` from the repo root uploads
the git tree (source files, no compiled output) and produces a deployment
that serves nothing (404). The compiled output must be deployed directly.

## Deploy commands (run from the repo root)

```text
1. flutter pub get
2. flutter build web --release \
     --dart-define=SPARK_LINGO_ENV=production \
     --dart-define=SUPABASE_DEPLOYMENT=hosted \
     --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=<public client key> \
     --dart-define=SUPABASE_PROJECT_REF=<project-ref> \
     --dart-define=SPARK_LINGO_PRODUCTION_PROJECT_REF=<project-ref> \
     --dart-define=ENABLE_TEST_CONSENT=true
3. copy vercel.json build\web\vercel.json
4. vercel deploy build/web --prod --name spark-lingo
```

`ENABLE_TEST_CONSENT=true` unlocks Sparky AI chat/score/voice in this web
test deployment: approved policy URLs do not exist yet (LEG-001), so the
consent flow shows a clearly-labelled draft notice and records the choice
on-device. Remove the flag for any store or production build — the default
is `false` and release pipelines must not set it.

`vercel.json` configures `@vercel/static` over `**` plus an SPA fallback
rewrite to `/index.html` for Flutter's URL-strategy routes.

## Deployment Protection

Vercel Hobby projects enable "Vercel Authentication" by default: the test
URL redirects to vercel.com/login for anyone without a Vercel account.
To make the test URL publicly open:

Dashboard -> spark-lingo -> Settings -> Deployment Protection ->
"Vercel Authentication" -> Disabled.

## Current production alias

https://spark-lingo.vercel.app
