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
(server ledger first, on-device fallback). Remove the flag for any store or
production build — the default is `false` and release pipelines must not set
it.

The client flag alone is not enough: the `sparky-ai` edge function enforces
the same gate server-side. For AI to respond in this test deployment, an
operator must also (HUMAN-ONLY):

1. Deploy the updated `sparky-ai` function (adds a default-off
   `TEST_CONSENT_MODE` bypass, audit-logged via operational events):
   `supabase functions deploy sparky-ai --project-ref dioisitgohusggmwowft`
2. Set the hosted secret: `TEST_CONSENT_MODE=true`
   (Dashboard → Edge Functions → sparky-ai → Secrets, or
   `supabase secrets set TEST_CONSENT_MODE=true --project-ref dioisitgohusggmwowft`)
3. Guest testing additionally requires `ALLOW_ANONYMOUS_AI=true`
   (anonymous users are denied by default; see `.env.example`).

Unset all three before any production or store release; the function fails
closed when they are absent.

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
