import type { SupabaseClient } from '@supabase/supabase-js';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  createContext,
  useContext,
  useEffect,
  useState,
  type PropsWithChildren,
} from 'react';

import type { PublicRuntimeConfig } from '../config/runtime-config';
import {
  attachForegroundTokenRefresh,
  createSupabaseClient,
} from '../lib/supabase-client';
import { AuthSessionProvider } from './auth-session';
import { UserScopeCleanupProvider } from './user-scope-cleanup';

const SupabaseContext = createContext<SupabaseClient | undefined>(undefined);
const RuntimeConfigContext = createContext<PublicRuntimeConfig | undefined>(undefined);

export function AppProviders({
  config,
  children,
}: PropsWithChildren<{ config: PublicRuntimeConfig }>) {
  const [client] = useState(() => createSupabaseClient(config));
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            retry: 1,
            staleTime: 30_000,
          },
        },
      }),
  );

  useEffect(() => attachForegroundTokenRefresh(client), [client]);

  return (
    <QueryClientProvider client={queryClient}>
      <RuntimeConfigContext.Provider value={config}>
        <SupabaseContext.Provider value={client}>
          <UserScopeCleanupProvider queryClient={queryClient}>
            <AuthSessionProvider client={client} config={config}>
              {children}
            </AuthSessionProvider>
          </UserScopeCleanupProvider>
        </SupabaseContext.Provider>
      </RuntimeConfigContext.Provider>
    </QueryClientProvider>
  );
}

export function useSupabaseClient(): SupabaseClient {
  const client = useContext(SupabaseContext);
  if (!client) {
    throw new Error('useSupabaseClient must be used inside AppProviders.');
  }
  return client;
}

export function useRuntimeConfig(): PublicRuntimeConfig {
  const config = useContext(RuntimeConfigContext);
  if (!config) {
    throw new Error('useRuntimeConfig must be used inside AppProviders.');
  }
  return config;
}
