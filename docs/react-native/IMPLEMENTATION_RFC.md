# React Native implementation RFC: foundation

## Status and scope

This RFC authorizes only the React Native **foundation** in
`apps/mobile-rn`. Flutter remains the production client and rollback target.
This change neither releases React Native to users nor ports a learner-facing
feature.

## Decisions

- Use Expo SDK 57 development builds, not Expo Go-only development.
- Use Expo Router with typed routes as the single navigation system.
- Use TypeScript strict mode, TanStack Query for future server state, and a
  small local state surface only when a specific feature needs it.
- Construct Supabase only after public runtime configuration is validated.
- Persist native Auth session material only through Expo SecureStore. RN web
  refuses authenticated initialization until it has its own approved security
  and parity decision.
- Keep public Supabase URL/publishable-key values in protected build
  environment configuration. Never put service-role, provider, billing, or
  webhook credentials in the client or `EXPO_PUBLIC_*` values.

## Build identity policy

Development has isolated identifiers. Staging and production require explicit
build-time Android package, iOS bundle ID, and URL-scheme values; source has no
staging or production identifier fallback. The production identifiers and
store-signing relationship must be reviewed during the final store cutover so
the RN release updates the existing Flutter listing rather than creating an
unrelated public app.

## Current acceptance evidence

- `npm run typecheck`
- `npm test`
- Expo Doctor (21/21 checks passed)
- runtime configuration tests covering absent configuration, HTTPS policy, and
  accidental clear-text service credential markers
- CI web export compilation only; it is not approval for RN web auth or a web
  release

## Explicitly not included

- authentication UI or OAuth redirect handling;
- consent, telemetry, billing, microphone, chat, scoring, or exam flows;
- profile/language/curriculum writes;
- generated database types or a linked EAS/Supabase production project.

The first feature slice is Auth + consent + session transition cleanup, with
staging-only integration tests for anonymous denial, consent withdrawal, deep
links, and account-switch cache clearing before any AI, voice, or billing UI.
