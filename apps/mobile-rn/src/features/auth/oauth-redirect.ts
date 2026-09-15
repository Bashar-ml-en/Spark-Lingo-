/**
 * OAuth callback validation is deliberately independent of Expo and Supabase.
 * A native deep link is untrusted input until its exact scheme, authority, and
 * path match the redirect URI that started the authorization request.
 */
export type OAuthRedirect =
  | { kind: 'ignored' }
  | { kind: 'provider-error' }
  | { kind: 'invalid' }
  | { kind: 'pkce'; code: string }
  | { kind: 'implicit'; accessToken: string; refreshToken: string };

function parseExpectedRedirect(expectedRedirectUrl: string): URL | undefined {
  try {
    const expected = new URL(expectedRedirectUrl);
    if (
      expected.protocol === 'http:' ||
      expected.protocol === 'https:' ||
      expected.username ||
      expected.password ||
      expected.search ||
      expected.hash
    ) {
      return undefined;
    }
    return expected;
  } catch {
    return undefined;
  }
}

function hasExactCallbackOrigin(candidate: URL, expected: URL): boolean {
  return (
    candidate.protocol === expected.protocol &&
    candidate.hostname === expected.hostname &&
    candidate.port === expected.port &&
    candidate.pathname === expected.pathname &&
    !candidate.username &&
    !candidate.password
  );
}

function parameterValues(url: URL, name: string): readonly string[] {
  const fragment = new URLSearchParams(url.hash.startsWith('#') ? url.hash.slice(1) : url.hash);
  return [...url.searchParams.getAll(name), ...fragment.getAll(name)].filter(Boolean);
}

function singleParameter(url: URL, name: string): string | undefined | null {
  const values = parameterValues(url, name);
  if (values.length === 0) {
    return undefined;
  }
  return values.length === 1 ? values[0] : null;
}

export function buildOAuthRedirectUrl(appScheme: string): string {
  return `${appScheme}://auth/callback`;
}

export function parseOAuthRedirect(
  candidateUrl: string,
  expectedRedirectUrl: string,
): OAuthRedirect {
  const expected = parseExpectedRedirect(expectedRedirectUrl);
  if (!expected) {
    return { kind: 'invalid' };
  }

  let candidate: URL;
  try {
    candidate = new URL(candidateUrl);
  } catch {
    return { kind: 'ignored' };
  }

  if (!hasExactCallbackOrigin(candidate, expected)) {
    return { kind: 'ignored' };
  }

  if (parameterValues(candidate, 'error').length > 0) {
    return { kind: 'provider-error' };
  }

  const code = singleParameter(candidate, 'code');
  const accessToken = singleParameter(candidate, 'access_token');
  const refreshToken = singleParameter(candidate, 'refresh_token');
  if (code === null || accessToken === null || refreshToken === null) {
    return { kind: 'invalid' };
  }

  if (code && !accessToken && !refreshToken) {
    return { kind: 'pkce', code };
  }

  if (!code && accessToken && refreshToken) {
    return { kind: 'implicit', accessToken, refreshToken };
  }

  return { kind: 'invalid' };
}
