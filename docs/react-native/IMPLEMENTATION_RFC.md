# React Native implementation RFC: foundation and identity slice

## Status and scope

This RFC authorizes the React Native foundation and its first identity slice in
`apps/mobile-rn`. Flutter remains the production client and rollback target.
This change neither releases React Native to users nor ports a learner-facing
course feature.

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
- Keep OAuth providers disabled unless their native callback URI is registered
  for that build. Accept only the exact `scheme://auth/callback` callback and
  complete it through the native browser session.
- Treat consent as a server-authoritative, versioned capability. Missing notice
  configuration or unexpected RPC output means the governed action is denied.
- Clear all user-owned client state before displaying a sign-out or new-account
  session. Each future owner must register with the cleanup boundary.

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

- telemetry, billing, microphone, chat, scoring, or exam flows;
- profile/language/curriculum writes;
- generated database types or a linked EAS/Supabase production project.

## Implemented identity slice

- email registration/sign-in, anonymous session creation, and secure native
  OAuth initiation when a provider is explicitly enabled;
- deep-link validation and PKCE/token-session completion for auth callbacks;
- a protected privacy-permission screen backed by the existing authenticated
  consent RPCs, with versioned notice validation and fail-closed behavior;
- centralized query-cache and registered user-state cleanup on sign-out or
  identity change.

Before release, run staging-only integration tests for anonymous denial,
consent withdrawal, email-confirmation and OAuth redirects, and account-switch
cache clearing. No AI, voice, billing, or telemetry UI may ship until those
features enforce this slice's consent and identity boundaries.
