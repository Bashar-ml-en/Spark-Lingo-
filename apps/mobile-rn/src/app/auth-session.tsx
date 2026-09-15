import type { Session, SupabaseClient } from '@supabase/supabase-js';
import { useQueryClient } from '@tanstack/react-query';
import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type PropsWithChildren,
} from 'react';

type SessionStatus = 'loading' | 'ready' | 'error';

type AuthSessionState = {
  session: Session | null;
  status: SessionStatus;
};

const AuthSessionContext = createContext<AuthSessionState | undefined>(undefined);

export function AuthSessionProvider({
  client,
  children,
}: PropsWithChildren<{ client: SupabaseClient }>) {
  const queryClient = useQueryClient();
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

      setState({
        session: data.session,
        status: error ? 'error' : 'ready',
      });
    });

    const {
      data: { subscription },
    } = client.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT') {
        // Every persisted user-scoped cache must be introduced through a
        // named owner and cleared here before a new session is displayed.
        queryClient.clear();
      }

      if (isMounted) {
        setState({ session, status: 'ready' });
      }
    });

    return () => {
      isMounted = false;
      subscription.unsubscribe();
    };
  }, [client, queryClient]);

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
