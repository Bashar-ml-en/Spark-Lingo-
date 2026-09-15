import { describe, expect, it, vi } from 'vitest';

vi.mock('expo-web-browser', () => ({}));
vi.mock('react-native', () => ({ Platform: { OS: 'ios' } }));

import { completeOAuthRedirect } from './auth-service';

const expectedRedirectUrl = 'sparklingo-development://auth/callback';

function clientWithAuth(overrides: Record<string, unknown> = {}) {
  return {
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
      exchangeCodeForSession: vi.fn().mockResolvedValue({
        data: { session: { access_token: 'session' } },
        error: null,
      }),
      setSession: vi.fn(),
      ...overrides,
    },
  };
}

describe('completeOAuthRedirect', () => {
  it('exchanges only a verified PKCE callback', async () => {
    const client = clientWithAuth();

    await expect(
      completeOAuthRedirect(
        client as never,
        `${expectedRedirectUrl}?code=one-time-code`,
        expectedRedirectUrl,
      ),
    ).resolves.toBe('authenticated');

    expect(client.auth.exchangeCodeForSession).toHaveBeenCalledWith('one-time-code');
  });

  it('does not call Supabase for an invalid callback', async () => {
    const client = clientWithAuth();

    await expect(
      completeOAuthRedirect(
        client as never,
        `${expectedRedirectUrl}?code=one&code=two`,
        expectedRedirectUrl,
      ),
    ).rejects.toMatchObject({ code: 'redirect-invalid' });

    expect(client.auth.getSession).not.toHaveBeenCalled();
    expect(client.auth.exchangeCodeForSession).not.toHaveBeenCalled();
  });

  it('shares one exchange when a browser result and OS callback arrive together', async () => {
    let resolveExchange: ((value: unknown) => void) | undefined;
    const exchangeCodeForSession = vi.fn(
      () =>
        new Promise((resolve) => {
          resolveExchange = resolve;
        }),
    );
    const client = clientWithAuth({ exchangeCodeForSession });

    const first = completeOAuthRedirect(
      client as never,
      `${expectedRedirectUrl}?code=one-time-code`,
      expectedRedirectUrl,
    );
    const second = completeOAuthRedirect(
      client as never,
      `${expectedRedirectUrl}?code=one-time-code`,
      expectedRedirectUrl,
    );
    await vi.waitFor(() => expect(exchangeCodeForSession).toHaveBeenCalledTimes(1));
    resolveExchange?.({ data: { session: { access_token: 'session' } }, error: null });

    await expect(Promise.all([first, second])).resolves.toEqual([
      'authenticated',
      'authenticated',
    ]);
  });
});
