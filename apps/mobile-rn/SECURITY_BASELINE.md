# React Native foundation security baseline

Checked: 2026-09-15

## Enforced client boundaries

- The app validates public runtime configuration before constructing Supabase.
- Source contains no staging or production Supabase URL/key fallback.
- The client accepts only a publishable Supabase key and rejects clear-text
  service-role/secret markers.
- Native Auth session storage uses Expo SecureStore; there is no AsyncStorage
  or browser-storage fallback for session material.
- React Native web refuses authenticated initialization pending its separate
  parity and security approval.
- Staging/production build identifiers and deep-link scheme are mandatory
  protected build inputs, not source defaults.
- OAuth is opt-in per build. It opens authorization only in the native browser,
  verifies the exact configured scheme/host/path callback, and exchanges a PKCE
  code (or a complete token pair) without logging callback material.
- Authenticated consent uses the existing server RPCs only. The client never
  supplies a user ID or acceptance timestamp, and malformed/failed responses
  deny processing.
- All user-scoped query data is cleared before a sign-out or account-switch
  session is displayed. Future drafts, billing UI, telemetry, and modal state
  must register the same cleanup boundary.

## Dependency review

`npm audit --omit=dev --json` reported zero high and zero critical runtime
findings. It reported 13 moderate findings in the Expo SDK/router toolchain,
including transitive CLI/config and `query-string` paths. npm's only proposed
"fix" is an incompatible downgrade to Expo 46, so it was not applied.

The quality workflow blocks high/critical runtime advisories with
`npm audit --omit=dev --audit-level=high`. Re-evaluate the moderate advisory
set on each Expo SDK or Expo Router update; do not use `npm audit fix --force`
to downgrade or bypass SDK compatibility.

## Verification performed

- `npm run typecheck`
- `npm test` (runtime configuration policy tests)
- `expo export --platform web` with synthetic local public configuration
- Expo Doctor: 21 of 21 checks passed
- production config guard: missing build identifiers fail during config load
