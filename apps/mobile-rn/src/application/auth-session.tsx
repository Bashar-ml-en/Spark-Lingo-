import type { Session, SupabaseClient } from '@supabase/supabase-js';
import * as Linking from 'expo-linking';
import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type PropsWithChildren,
} from 'react';

import type { PublicRuntimeConfig } from '../config/runtime-config';
import {
  AuthActionError,
  completeOAuthRedirect,
} from '../features/auth/auth-service';
import {
  buildOAuthRedirectUrl,
  parseOAuthRedirect,
} from '../features/auth/oauth-redirect';
import { useUserScopeCleanup } from './user-scope-cleanup';

type SessionStatus = 'loading' | 'ready' | 'error';

type AuthSessionState = {
  session: Session | null;
  status: SessionStatus;
  authMessage?: string;
};

const AuthSessionContext = createContext<AuthSessionState | undefined>(undefined);

export function AuthSessionProvider({
  client,
  config,
  children,
}: PropsWithChildren<{ client: SupabaseClient; config: PublicRuntimeConfig }>) {
  const { clearUserScope } = useUserScopeCleanup();
  const priorUserId = useRef<string | undefined>(undefined);
  const [state, setState] = useState<AuthSessionState>({
    session: null,
    status: 'loading',
  });

  useEffect(() => {
    let isMounted = true;

    void client.auth.getSession().then(({ data, error }) => {
      if (!isMounted) {
        return;
      }

      priorUserId.current = data.session?.user.id;
      setState({
        session: data.session,
        status: error ? 'error' : 'ready',
        authMessage: error ? 'Your secure session could not be restored. Sign in again.' : undefined,
      });
    });

    const {
      data: { subscription },
    } = client.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT') {
        clearUserScope('signed-out');
      } else if (
        priorUserId.current &&
        session?.user.id &&
        priorUserId.current !== session.user.id
      ) {
        clearUserScope('identity-changed');
      }
      priorUserId.current = session?.user.id;

      if (isMounted) {
        setState({ session, status: 'ready' });
      }
    });

    return () => {
      isMounted = false;
      subscription.unsubscribe();
    };
  }, [client, clearUserScope]);

  useEffect(() => {
    let isMounted = true;
    let callbackInFlight = false;
    const expectedRedirectUrl = buildOAuthRedirectUrl(config.appScheme);

    const handleUrl = async (url: string): Promise<void> => {
      const parsed = parseOAuthRedirect(url, expectedRedirectUrl);
      if (parsed.kind === 'ignored' || callbackInFlight) {
        return;
      }

      callbackInFlight = true;
      try {
        // The in-app browser may already have completed the same callback.
        // Avoid exchanging a one-time code twice if the OS also emits a URL.
        const currentSession = await client.auth.getSession();
        if (currentSession.data.session) {
          return;
        }
        await completeOAuthRedirect(client, url, expectedRedirectUrl);
        if (isMounted) {
          setState((current) => ({
            ...current,
            authMessage: 'Sign-in completed.',
          }));
        }
      } catch (error) {
        const message =
          error instanceof AuthActionError
            ? error.userMessage
            : 'The sign-in link could not be completed. Start sign-in again.';
        if (isMounted) {
          setState((current) => ({ ...current, authMessage: message }));
        }
      } finally {
        callbackInFlight = false;
      }
    };

    void Linking.getInitialURL().then((url) => {
      if (url) {
        void handleUrl(url);
      }
    });
    const subscription = Linking.addEventListener('url', ({ url }) => {
      void handleUrl(url);
    });

    return () => {
      isMounted = false;
      subscription.remove();
    };
  }, [client, config.appScheme]);

  const value = useMemo(() => state, [state]);
  return <AuthSessionContext.Provider value={value}>{children}</AuthSessionContext.Provider>;
}

export function useAuthSession(): AuthSessionState {
  const value = useContext(AuthSessionContext);
  if (!value) {
    throw new Error('useAuthSession must be used inside AuthSessionProvider.');
  }
  return value;
}
