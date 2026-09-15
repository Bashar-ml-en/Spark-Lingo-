import { describe, expect, it } from 'vitest';

import {
  buildOAuthRedirectUrl,
  parseOAuthRedirect,
} from './oauth-redirect';

const expectedRedirectUrl = 'sparklingo-development://auth/callback';

describe('OAuth redirect validation', () => {
  it('creates an explicit native callback URI', () => {
    expect(buildOAuthRedirectUrl('sparklingo-development')).toBe(expectedRedirectUrl);
  });

  it('accepts exactly one PKCE code on the expected callback', () => {
    expect(
      parseOAuthRedirect(`${expectedRedirectUrl}?code=one-time-code`, expectedRedirectUrl),
    ).toEqual({ kind: 'pkce', code: 'one-time-code' });
  });

  it('accepts a complete implicit callback only on the expected callback', () => {
    expect(
      parseOAuthRedirect(
        `${expectedRedirectUrl}#access_token=access&refresh_token=refresh`,
        expectedRedirectUrl,
      ),
    ).toEqual({ kind: 'implicit', accessToken: 'access', refreshToken: 'refresh' });
  });

  it('ignores a callback from any other deep-link host or scheme', () => {
    expect(
      parseOAuthRedirect('sparklingo-development://other/callback?code=nope', expectedRedirectUrl),
    ).toEqual({ kind: 'ignored' });
    expect(
      parseOAuthRedirect('untrusted://auth/callback?code=nope', expectedRedirectUrl),
    ).toEqual({ kind: 'ignored' });
  });

  it('rejects ambiguous or incomplete token material', () => {
    expect(
      parseOAuthRedirect(`${expectedRedirectUrl}?code=one&code=two`, expectedRedirectUrl),
    ).toEqual({ kind: 'invalid' });
    expect(
      parseOAuthRedirect(`${expectedRedirectUrl}#access_token=access`, expectedRedirectUrl),
    ).toEqual({ kind: 'invalid' });
  });

  it('does not expose provider error content to callers', () => {
    expect(
      parseOAuthRedirect(
        `${expectedRedirectUrl}?error=access_denied&error_description=private`,
        expectedRedirectUrl,
      ),
    ).toEqual({ kind: 'provider-error' });
  });
});
