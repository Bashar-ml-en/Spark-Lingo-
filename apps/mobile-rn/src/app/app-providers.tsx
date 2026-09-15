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

const SupabaseContext = createContext<SupabaseClient | undefined>(undefined);

export function AppProviders({
  config,
  children,
}: PropsWithChildren<{ config: PublicRuntimeConfig }>) {
  // Client construction occurs only after runtime configuration is valid.
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
      <SupabaseContext.Provider value={client}>
        <AuthSessionProvider client={client}>{children}</AuthSessionProvider>
      </SupabaseContext.Provider>
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
