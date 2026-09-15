# React Native transition architecture

This directory is the contract for a future React Native client. It is not an
authorization to start that client until the pre-RN exit gates are complete.

## Decision

Build a TypeScript-strict React Native app using **Expo development builds**,
not Expo Go-only and not a Flutter-widget-to-JSX conversion. Expo development
builds support the native dependencies required for purchases, telemetry,
audio, secure storage, and deep links; each native dependency change requires
a rebuilt development client. [Expo documentation](https://docs.expo.dev/develop/development-builds/use-development-builds/)

Use one typed navigation solution (Expo Router or React Navigation; decide in
the implementation RFC), TanStack Query for server state, and a small local
store only for ephemeral UI state. React Native supports TypeScript directly,
and native-stack navigation maps to native iOS/Android navigation primitives.
[React Native TypeScript](https://reactnative.dev/docs/typescript), [React Native navigation](https://reactnative.dev/docs/navigation)

## Non-negotiable retained boundaries

- Supabase remains the identity, Postgres, RLS, and Edge Function authority.
- The client never receives service-role, provider, webhook-signing, or store
  verification credentials.
- Edge Functions remain the AI/transcription, account-deletion, and
  RevenueCat-webhook boundary.
- A store SDK result never grants premium; the server entitlement RPC does.
- Consent, runtime controls, quotas, and billing switches fail closed.

## Proposed client layers

```text
screens + accessible design system
        |
typed routes / auth gates / modal rules
        |
feature hooks (auth, learning, chat, consent, billing, settings)
        |
TanStack Query             small local store
server cache + mutations   theme, selected language, drafts only
        |
typed repositories + runtime validation
        |
Supabase Auth / PostgREST RPC / Edge Functions / RevenueCat client SDK
```

## Security implementation constraints

- Configure `@supabase/supabase-js` with a secure React Native session-storage
  adapter; do not use an unprotected ad-hoc token store. Supabase’s React
  Native guidance describes protected storage considerations. [Supabase React
  Native auth guidance](https://supabase.com/blog/react-native-authentication)
- Use RevenueCat’s React Native SDK only for purchase UI and store interaction;
  retain the existing server entitlement check and webhook processing.
  [RevenueCat React Native installation](https://www-docs.revenuecat.com/docs/getting-started/installation/reactnative)
- Request microphone permission only after a current consent record. Delete
  temporary local recordings after a transcription path ends.
- Validate every Edge Function response at runtime. Type generation is useful
  for database rows but does not validate untrusted network payloads.

Read the remaining files in this directory before creating any mobile source.

The foundation implementation decision is recorded in
`IMPLEMENTATION_RFC.md`. Its source lives in `apps/mobile-rn`; it does not
retire or relocate the Flutter client.
