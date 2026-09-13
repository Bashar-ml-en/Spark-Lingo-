# Native capability parity

Choose packages only after verifying compatibility with the selected React
Native/Expo SDK, Android/iOS deployment targets, and the New Architecture.
The capability and acceptance test matter more than a one-to-one package name.

| Current capability | Flutter implementation | RN design requirement | Acceptance evidence |
| --- | --- | --- | --- |
| Auth/deep links | `supabase_flutter`, Android/iOS callback registration | Secure Supabase session adapter, universal/custom URL handling, typed auth redirect state | Real Android/iOS OAuth return and malicious/unregistered redirect rejection. |
| Secure local storage | Supabase plugin/session persistence, shared preferences | OS-backed secure storage for refresh/session material; non-sensitive UI preferences separated | Device reboot, sign-out, expired refresh, no token in logs/analytics. |
| Purchases | `purchases_flutter` | React Native RevenueCat SDK; Android launch mode compatible with purchase return; server entitlement check retained | Sandbox purchase, cancel, restore, webhook delay, account change, server-disabled state. |
| Microphone/audio | `record` and Edge transcription | Native audio module with explicit permission, duration/size bound, temporary-file cleanup | accepted/denied/revoked permission, cleanup, offline/upload timeout, physical audio transcription. |
| Text-to-speech | `flutter_tts` and browser speech wrapper | Native TTS abstraction and an independently tested web path if web remains | language/voice fallback, stop on unmount, accessibility non-autoplay rules. |
| Firebase telemetry | Firebase Analytics/Crashlytics | Native Firebase integration compatible with the chosen build model | disabled until consent, opt-out clears collection, no learner ID/prompt/transcript/audio. |
| Notifications | none currently | Do not add during parity work | Separate product/security proposal required. |
| Theme/fonts/RTL | language registry, bundled Noto fonts | Semantic token system, font fallback per script, `I18nManager`/directional layout rules | Arabic RTL screenshot; Thai/CJK/Devanagari/Arabic text; Dynamic Type. |
| Assets/content | bundled JSON/SVG/fonts; no audio assets | Content version manifest, smallest useful downloads/cache scope | schema validation, cache invalidation, offline claim tested rather than assumed. |
| Accessibility | Flutter semantics; web viewport formerly blocked zoom | Native accessibility roles/labels/hints plus web zoom/keyboard if retained | TalkBack, VoiceOver, font scaling, contrast, touch-target and focus tests. |

## Build choice

Use Expo development builds unless a dependency or verified native integration
requires a bare project. This is still a real native application: it supports
native modules while retaining Expo tooling. A development build must be
rebuilt after native dependency changes. [Expo development builds](https://docs.expo.dev/develop/development-builds/use-development-builds/)

React Native provides native-component and native-module integration rather
than a browser WebView model. If a missing capability requires custom native
code, define a typed TurboModule specification and isolate it behind a
capability interface. [React Native native modules](https://reactnative.dev/docs/turbo-native-modules-introduction)

## Required configuration parity

- Preserve Android app ID, deep-link scheme, microphone permission reason,
  cleartext policy, backup policy, signing, and store capabilities after a
  verified migration review.
- Preserve iOS bundle ID, microphone purpose string, URL types, scene/app
  lifecycle behaviour, and in-app purchase entitlement capability.
- No production project refs/keys/URLs are source defaults. Runtime public
  configuration is validated before client initialization.
