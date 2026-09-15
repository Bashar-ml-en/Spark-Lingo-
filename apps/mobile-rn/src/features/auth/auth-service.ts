import type { Session, SupabaseClient } from '@supabase/supabase-js';
import * as WebBrowser from 'expo-web-browser';
import { Platform } from 'react-native';

import type { PublicRuntimeConfig } from '../../config/runtime-config';
import {
  buildOAuthRedirectUrl,
  parseOAuthRedirect,
  type OAuthRedirect,
} from './oauth-redirect';

export type OAuthProvider = 'google' | 'apple';

export type EmailAuthResult =
  | { kind: 'authenticated' }
  | { kind: 'email-confirmation-required' };

export type OAuthResult =
  | { kind: 'authenticated' }
  | { kind: 'cancelled' };

export type SignOutResult =
  | { kind: 'remote-session-revoked' }
  | { kind: 'local-session-cleared' };

export type AuthErrorCode =
  | 'invalid-input'
  | 'invalid-credentials'
  | 'email-confirmation-required'
  | 'unsupported-provider'
  | 'redirect-invalid'
  | 'oauth-failed'
  | 'session-failed'
  | 'sign-out-failed';

export class AuthActionError extends Error {
  constructor(
    readonly code: AuthErrorCode,
    readonly userMessage: string,
  ) {
    super(userMessage);
    this.name = 'AuthActionError';
  }
}

let activeRedirectCompletion: Promise<'authenticated' | 'ignored'> | undefined;

function emailIsValid(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function errorText(error: unknown): string {
  return error instanceof Error ? error.message.toLowerCase() : '';
}

function fromAuthError(error: unknown, fallback: AuthErrorCode): AuthActionError {
  const message = errorText(error);
  if (message.includes('invalid login credentials')) {
    return new AuthActionError(
      'invalid-credentials',
      'The email address or password is incorrect.',
    );
  }
  if (message.includes('email not confirmed')) {
    return new AuthActionError(
      'email-confirmation-required',
      'Confirm your email, then sign in.',
    );
  }

  const userMessage =
    fallback === 'sign-out-failed'
      ? 'We could not sign you out securely. Check your connection and try again.'
      : fallback === 'session-failed'
        ? 'Your sign-in session could not be completed. Try again.'
        : fallback === 'oauth-failed'
          ? 'Sign-in could not be completed. Try again.'
          : 'Authentication could not be completed. Try again.';
  return new AuthActionError(fallback, userMessage);
}

function assertEmailAndPassword(email: string, password: string): void {
  if (!emailIsValid(email.trim())) {
    throw new AuthActionError('invalid-input', 'Enter a valid email address.');
  }
  if (password.length < 8) {
    throw new AuthActionError('invalid-input', 'Enter a password with at least 8 characters.');
  }
}

function providerIsEnabled(
  provider: OAuthProvider,
  config: PublicRuntimeConfig,
): boolean {
  return provider === 'google'
    ? config.oauth?.googleEnabled === true
    : config.oauth?.appleEnabled === true && Platform.OS === 'ios';
}

function assertProviderIsAvailable(
  provider: OAuthProvider,
  config: PublicRuntimeConfig,
): void {
  if (!providerIsEnabled(provider, config)) {
    throw new AuthActionError(
      'unsupported-provider',
      provider === 'apple' && Platform.OS !== 'ios'
        ? 'Apple sign-in is available on iPhone and iPad only.'
        : 'This sign-in method is not available in this build.',
    );
  }
}

function noSessionResult(session: Session | null): EmailAuthResult {
  return session ? { kind: 'authenticated' } : { kind: 'email-confirmation-required' };
}

/** Email sign-in never stores credentials outside the Supabase request. */
export async function signInWithEmail(
  client: SupabaseClient,
  email: string,
  password: string,
): Promise<EmailAuthResult> {
  assertEmailAndPassword(email, password);
  const { data, error } = await client.auth.signInWithPassword({
    email: email.trim(),
    password,
  });
  if (error) {
    throw fromAuthError(error, 'session-failed');
  }
  return noSessionResult(data.session);
}

/** Registration deliberately does not assume a session when confirmation is enabled. */
export async function signUpWithEmail(
  client: SupabaseClient,
  email: string,
  password: string,
  displayName: string,
): Promise<EmailAuthResult> {
  assertEmailAndPassword(email, password);
  const normalizedDisplayName = displayName.trim();
  if (!normalizedDisplayName || normalizedDisplayName.length > 80) {
    throw new AuthActionError('invalid-input', 'Enter a display name of up to 80 characters.');
  }

  const { data, error } = await client.auth.signUp({
    email: email.trim(),
    password,
    options: { data: { display_name: normalizedDisplayName } },
  });
  if (error) {
    throw fromAuthError(error, 'session-failed');
  }
  return noSessionResult(data.session);
}

export async function signInAnonymously(client: SupabaseClient): Promise<void> {
  const { error } = await client.auth.signInAnonymously();
  if (error) {
    throw fromAuthError(error, 'session-failed');
  }
}

export async function completeOAuthRedirect(
  client: SupabaseClient,
  callbackUrl: string,
  expectedRedirectUrl: string,
): Promise<'authenticated' | 'ignored'> {
  const redirect = parseOAuthRedirect(callbackUrl, expectedRedirectUrl);
  if (redirect.kind === 'ignored') {
    return 'ignored';
  }
  if (activeRedirectCompletion) {
    return activeRedirectCompletion;
  }

  const completion = completeParsedOAuthRedirect(client, redirect);
  activeRedirectCompletion = completion;
  return completion.finally(() => {
    if (activeRedirectCompletion === completion) {
      activeRedirectCompletion = undefined;
    }
  });
}

async function completeParsedOAuthRedirect(
  client: SupabaseClient,
  redirect: OAuthRedirect,
): Promise<'authenticated' | 'ignored'> {
  if (redirect.kind === 'ignored') {
    return 'ignored';
  }
  if (redirect.kind === 'provider-error') {
    throw new AuthActionError('oauth-failed', 'Sign-in was cancelled or declined.');
  }
  if (redirect.kind === 'invalid') {
    throw new AuthActionError(
      'redirect-invalid',
      'The sign-in link could not be verified. Start sign-in again.',
    );
  }

  // The native browser and the OS URL event can arrive almost together. If
  // either path has already established the session, do not spend a PKCE code
  // a second time.
  const currentSession = await client.auth.getSession();
  if (currentSession.data.session) {
    return 'authenticated';
  }

  const result =
    redirect.kind === 'pkce'
      ? await client.auth.exchangeCodeForSession(redirect.code)
      : await client.auth.setSession({
          access_token: redirect.accessToken,
          refresh_token: redirect.refreshToken,
        });
  if (result.error || !result.data.session) {
    throw fromAuthError(result.error, 'session-failed');
  }
  return 'authenticated';
}

export async function signInWithOAuth(
  client: SupabaseClient,
  config: PublicRuntimeConfig,
  provider: OAuthProvider,
): Promise<OAuthResult> {
  assertProviderIsAvailable(provider, config);
  const redirectUrl = buildOAuthRedirectUrl(config.appScheme);
  const { data, error } = await client.auth.signInWithOAuth({
    provider,
    options: { redirectTo: redirectUrl, skipBrowserRedirect: true },
  });
  if (error || !data.url) {
    throw fromAuthError(error, 'oauth-failed');
  }

  const browserResult = await WebBrowser.openAuthSessionAsync(data.url, redirectUrl);
  if (browserResult.type !== 'success' || !browserResult.url) {
    return { kind: 'cancelled' };
  }

  await completeOAuthRedirect(client, browserResult.url, redirectUrl);
  return { kind: 'authenticated' };
}

/**
 * Prefer revoking the remote session. If that request cannot be confirmed,
 * clear this device's protected session rather than leaving the app signed in.
 */
export async function signOut(client: SupabaseClient): Promise<SignOutResult> {
  const remoteResult = await client.auth.signOut();
  if (!remoteResult.error) {
    return { kind: 'remote-session-revoked' };
  }

  const localResult = await client.auth.signOut({ scope: 'local' });
  if (localResult.error) {
    throw fromAuthError(localResult.error, 'sign-out-failed');
  }
  return { kind: 'local-session-cleared' };
}
